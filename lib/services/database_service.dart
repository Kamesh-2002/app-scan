import 'package:app_scan/services/auth_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_record.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<void> init() async {
    _database = await _initDB('app_scan.db');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_scan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scan_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rawData TEXT NOT NULL,
        decryptedName TEXT,
        decryptedPhone TEXT,
        isEncrypted INTEGER NOT NULL DEFAULT 0,
        scannedAt TEXT NOT NULL,
        scanCount INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<ScanRecord> insertOrUpdateScan(ScanRecord record) async {
    final db = await database;
    int newCount;
    int maxScanCount = (await AuthService.getMaxCount())[0];
    int maxScanCountPerDay = (await AuthService.getMaxCount())[1];

    // Check if the same QR data already exists
    final existing = await db.query(
      'scan_records',
      where: 'rawData = ?',
      whereArgs: [record.rawData],
    );

    if (existing.isNotEmpty) {
      final existingRecord = ScanRecord.fromMap(existing.first);
      newCount = existing.length + 1;
      final scansPreviousRecors = await getScansByNameAndPhone(
          existingRecord.decryptedName!, existingRecord.decryptedPhone!);
      final previousRecordLength = scansPreviousRecors.length;
      final todayRecordCount = await getTodayRecordCount(
          name: existingRecord.decryptedName!,
          phone: existingRecord.decryptedPhone!);
      if ((previousRecordLength + 1) > maxScanCount ||
          (todayRecordCount + 1) > maxScanCountPerDay) {
        return ScanRecord(
          id: existingRecord.id,
          rawData: existingRecord.rawData,
          decryptedName: existingRecord.decryptedName,
          decryptedPhone: existingRecord.decryptedPhone,
          isEncrypted: existingRecord.isEncrypted,
          scannedAt: existingRecord.scannedAt,
          numScanCount: scansPreviousRecors.length,
          error: true,
          errorCode: (previousRecordLength + 1) > maxScanCount
              ? 0
              : 1,
          errorMsg: "Already ${(previousRecordLength + 1) > maxScanCount? previousRecordLength: todayRecordCount} scans occured",
        );
      }
    } else {
      newCount = 1;
    }
    //   final newCount = existingRecord.scanCount + 1;
    //   await db.update(
    //     'scan_records',
    //     {
    //       'scanCount': newCount,
    //       'scannedAt': DateTime.now().toIso8601String(),
    //     },
    //     where: 'id = ?',
    //     whereArgs: [existingRecord.id],
    //   );
    //   return ScanRecord(
    //     id: existingRecord.id,
    //     rawData: existingRecord.rawData,
    //     decryptedName: existingRecord.decryptedName,
    //     decryptedPhone: existingRecord.decryptedPhone,
    //     isEncrypted: existingRecord.isEncrypted,
    //     scannedAt: DateTime.now(),
    //     scanCount: newCount,
    //   );
    // } else {
    final id = await db.insert('scan_records', record.toMap()..remove('id'));
    return ScanRecord(
      id: id,
      rawData: record.rawData,
      decryptedName: record.decryptedName,
      decryptedPhone: record.decryptedPhone,
      isEncrypted: record.isEncrypted,
      scannedAt: record.scannedAt,
      numScanCount: newCount,
    );
    // }
  }

  Future<List<Map<String, Object?>>> getScansCountGroup() async {
    final db = await database;
    //  get name,phone, and number of records in each name and phone
    final result = await db.rawQuery(
        'SELECT decryptedName as name, decryptedPhone as phone, COUNT(*) as scanCount FROM scan_records GROUP BY decryptedName, decryptedPhone');
    return result;
  }

  Future<List<ScanRecord>> getScansByNameAndPhone(
      String name, String phone) async {
    final db = await database;
    final maps = await db.query(
      'scan_records',
      where: 'decryptedName = ? AND decryptedPhone = ?',
      whereArgs: [name, phone],
      orderBy: 'scannedAt DESC',
    );
    return maps.map((map) => ScanRecord.fromMap(map)).toList();
  }

  Future<int> getTodayRecordCount({
  required String name,
  required String phone,
}) async {
  final db = await database;

  final now = DateTime.now();

  final startOfDay = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final endOfDay = startOfDay.add(const Duration(days: 1));

  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) AS count
    FROM scan_records
    WHERE decryptedName = ?
      AND decryptedPhone = ?
      AND scannedAt >= ?
      AND scannedAt < ?
    ''',
    [
      name,
      phone,
      startOfDay.toIso8601String(),
      endOfDay.toIso8601String(),
    ],
  );

  return Sqflite.firstIntValue(result) ?? 0;
}

  Future<List<ScanRecord>> getAllScans() async {
    final db = await database;
    final maps = await db.query(
      'scan_records',
      orderBy: 'scannedAt DESC',
    );
    return maps.map((map) => ScanRecord.fromMap(map)).toList();
  }

  Future<void> deleteScan(int id) async {
    final db = await database;
    await db.delete('scan_records', where: 'id = ?', whereArgs: [id]);
  }
  Future<void> deleteAllScan(String decryptedName, String decryptedPhone) async {
    final db = await database;
    await db.delete('scan_records', where: 'decryptedName = ? AND decryptedPhone = ?', whereArgs: [decryptedName, decryptedPhone]);
  }

  Future<void> clearAllScans() async {
    final db = await database;
    // await db.delete('scan_records');
  }

  Future<int> getTotalScans() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(scanCount) as total FROM scan_records',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getUniqueQRCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scan_records',
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
