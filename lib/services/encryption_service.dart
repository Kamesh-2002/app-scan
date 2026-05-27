import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  static const String _secretKey = 'AppScan@SecretKey2026!QREncrypt##';

  static enc.Key _getKey() {
    final keyBytes = utf8.encode(_secretKey);
    final digest = sha256.convert(keyBytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  static enc.IV _getIV() {
    return enc.IV.fromUtf8('AppScanIV123456!');
  }

  static String encrypt(String plainText) {
    try {
      final key = _getKey();
      final iv = _getIV();
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return encrypted.base64;
    } catch (e) {
      return plainText;
    }
  }

  static String? decrypt(String encryptedText) {
    try {
      final key = _getKey();
      final iv = _getIV();
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
      return decrypted;
    } catch (e) {
      return null;
    }
  }

  static String encodeContactToQR(String name, String phone) {
    final contactJson = jsonEncode({'name': name, 'phone': phone});
    final encrypted = encrypt(contactJson);
    // Prefix to identify our encrypted QR codes
    return 'APPSCAN:$encrypted';
  }

  static Map<String, String>? decodeContactFromQR(String qrData) {
    if (!qrData.startsWith('APPSCAN:')) return null;
    final encryptedPart = qrData.substring(8);
    final decrypted = decrypt(encryptedPart);
    if (decrypted == null) return null;
    try {
      final map = jsonDecode(decrypted) as Map<String, dynamic>;
      return {
        'name': map['name']?.toString() ?? '',
        'phone': map['phone']?.toString() ?? '',
      };
    } catch (e) {
      return null;
    }
  }
}