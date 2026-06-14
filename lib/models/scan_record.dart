class ScanRecord {
  final int? id;
  final String rawData;
  final String? decryptedName;
  final String? decryptedPhone;
  final bool isEncrypted;
  final DateTime scannedAt;
  final int? numScanCount;
  final bool error;
  final int errorCode;
  final String errorMsg;

  ScanRecord({
    this.id,
    required this.rawData,
    this.decryptedName,
    this.decryptedPhone,
    required this.isEncrypted,
    required this.scannedAt,
    this.numScanCount,
    this.error = false,
    this.errorCode = 0,
    this.errorMsg = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rawData': rawData,
      'decryptedName': decryptedName,
      'decryptedPhone': decryptedPhone,
      'isEncrypted': isEncrypted ? 1 : 0,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'],
      rawData: map['rawData'],
      decryptedName: map['decryptedName'],
      decryptedPhone: map['decryptedPhone'],
      isEncrypted: map['isEncrypted'] == 1,
      scannedAt: DateTime.parse(map['scannedAt']),
    );
  }

  String get displayTitle {
    if (decryptedName != null && decryptedName!.isNotEmpty) {
      return decryptedName!;
    }
    return rawData.length > 40 ? '${rawData.substring(0, 40)}...' : rawData;
  }

  String get displaySubtitle {
    if (decryptedPhone != null && decryptedPhone!.isNotEmpty) {
      return decryptedPhone!;
    }
    return rawData;
  }
}
