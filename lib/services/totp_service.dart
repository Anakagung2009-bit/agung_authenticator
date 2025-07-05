import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:base32/base32.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class TOTPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;  
  // Kunci untuk menyimpan encryption key di secure storage  
  // Mendapatkan atau membuat kunci enkripsi
  Future<String> _getOrCreateEncryptionKey() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User tidak terautentikasi');
    }
    
    String? encryptionKey;
    
    try {
      // Coba ambil kunci dari Firestore
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      final userData = docSnapshot.data();
      
      if (userData != null && userData.containsKey('encryptionKey')) {
        // Jika ada di Firestore, gunakan kunci tersebut
        encryptionKey = userData['encryptionKey'];
        print('Berhasil mengambil kunci enkripsi dari Firestore');
      } else {
        // Jika tidak ada di Firestore, buat kunci baru
        final random = Random.secure();
        final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
        encryptionKey = base64Encode(keyBytes);
        
        // Simpan kunci di Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'encryptionKey': encryptionKey,
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('Membuat dan menyimpan kunci enkripsi baru ke Firestore');
      }
    } catch (e) {
      print('Error saat mengambil kunci dari Firestore: $e');
      // Coba sekali lagi dengan get() untuk memastikan
      try {
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
        if (docSnapshot.exists && docSnapshot.data()!.containsKey('encryptionKey')) {
          encryptionKey = docSnapshot.data()!['encryptionKey'];
          print('Berhasil mengambil kunci enkripsi dari Firestore pada percobaan kedua');
        } else {
          // Jika benar-benar tidak ada, baru buat kunci baru
          final random = Random.secure();
          final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
          encryptionKey = base64Encode(keyBytes);
          
          // Simpan kunci di Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'encryptionKey': encryptionKey,
            'email': user.email,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('Membuat dan menyimpan kunci enkripsi baru ke Firestore setelah error');
        }
      } catch (secondError) {
        print('Error kedua saat mengambil kunci dari Firestore: $secondError');
        throw Exception('Gagal mendapatkan atau membuat encryption key: $secondError');
      }
    }
    
    if (encryptionKey == null) {
      throw Exception('Gagal mendapatkan encryption key');
    }
    return encryptionKey;
  }
  
  // Enkripsi data dengan AES
  Future<Map<String, String>> _encryptData({
    required String data,
    String? encryptionKey,
  }) async {
    // Dapatkan kunci enkripsi jika tidak disediakan
    final key = encryptionKey ?? await _getOrCreateEncryptionKey();
    
    // Buat IV random untuk setiap enkripsi
    final iv = encrypt.IV.fromSecureRandom(16);
    
    // Siapkan enkripsi
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key.fromBase64(key), mode: encrypt.AESMode.cbc),
    );
    
    // Enkripsi data
    final encrypted = encrypter.encrypt(data, iv: iv);
    
    // Kembalikan data terenkripsi dan IV
    return {
      'data': encrypted.base64,
      'iv': iv.base64,
    };
  }
  
  // Dekripsi data dengan AES
  Future<String> _decryptData({
  required String encryptedData,
  required String ivString,
  String? encryptionKey,
}) async {
  if (ivString.isEmpty) throw Exception('IV kosong untuk dekripsi');

  final key = encryptionKey ?? await _getOrCreateEncryptionKey();

  final encrypter = encrypt.Encrypter(
    encrypt.AES(encrypt.Key.fromBase64(key), mode: encrypt.AESMode.cbc),
  );

  final decrypted = encrypter.decrypt64(
    encryptedData,
    iv: encrypt.IV.fromBase64(ivString),
  );

  return decrypted;
}

  
  // Metode untuk memaksa sinkronisasi kunci enkripsi dari Firestore
  Future<bool> syncEncryptionKey() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User tidak terautentikasi');
    }
    
    try {
      // Ambil kunci dari Firestore
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists && docSnapshot.data()!.containsKey('encryptionKey')) {
        print('Berhasil menyinkronkan kunci enkripsi dari Firestore');
        return true;
      } else {
        print('Tidak ada kunci enkripsi di Firestore untuk disinkronkan');
        return false;
      }
    } catch (e) {
      print('Error saat menyinkronkan kunci enkripsi: $e');
      return false;
    }
  }
  
  // Mendapatkan semua TOTP untuk user saat ini
   Stream<List<Map<String, dynamic>>> getTOTPs() {
    final user = _auth.currentUser ;
    if (user == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('totps')
        .snapshots()
        .asyncMap((snapshot) async {
          final encryptionKey = await _getOrCreateEncryptionKey();
          final List<Map<String, dynamic>> result = [];
          
          for (final doc in snapshot.docs) {
            final data = doc.data();
            data['id'] = doc.id;
            
            // Dekripsi data sensitif
            if (data.containsKey('encryptedSecret') && data.containsKey('secretIv')) {
              try {
                data['secret'] = await _decryptData(
                  encryptedData: data['encryptedSecret'],
                  ivString: data['secretIv'],
                  encryptionKey: encryptionKey,
                );
              } catch (e) {
                continue; // Skip entri ini agar tidak crash
              }
            }
            
            if (data.containsKey('encryptedName') && 
                data.containsKey('nameIv')) {
              data['name'] = await _decryptData(
                encryptedData: data['encryptedName'],
                ivString: data['nameIv'],
                encryptionKey: encryptionKey,
              );
            }
            
            if (data.containsKey('encryptedIssuer') && 
                data.containsKey('issuerIv')) {
              data['issuer'] = await _decryptData(
                encryptedData: data['encryptedIssuer'],
                ivString: data['issuerIv'],
                encryptionKey: encryptionKey,
              );
            }
            
            result.add(data);
          }
          
          return result;
        });
  }
  
  // Menambahkan TOTP baru
   // Menambahkan TOTP baru
  Future<void> addTOTP({
    required String name,
    required String secret,
  }) async {
    final user = _auth.currentUser ;
    if (user == null) {
      throw Exception('User  tidak terautentikasi');
    }
    
    // Dapatkan kunci enkripsi
    final encryptionKey = await _getOrCreateEncryptionKey();
    
    // Enkripsi data sensitif
    final encryptedSecret = await _encryptData(
      data: secret,
      encryptionKey: encryptionKey,
    );
    
    final encryptedName = await _encryptData(
      data: name,
      encryptionKey: encryptionKey,
    );
    
    // Simpan data terenkripsi ke Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('totps')
        .add({
          // Data terenkripsi
          'encryptedSecret': encryptedSecret['data'],
          'secretIv': encryptedSecret['iv'],
          'encryptedName': encryptedName['data'],
          'nameIv': encryptedName['iv'],
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  
  // Menghapus TOTP
 Future<void> deleteTOTP(String id) async {
    final user = _auth.currentUser ;
    if (user == null) {
      throw Exception('User  tidak terautentikasi');
    }
    
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('totps')
        .doc(id)
        .delete();
  }
  
  // Menghasilkan kode TOTP
    String generateTOTP(String secret, {int digits = 6, int period = 30, int? counter}) {
    // Normalisasi secret agar bisa di-decode oleh Base32
    String normalizedSecret = secret.toUpperCase();
    while (normalizedSecret.length % 8 != 0) {
      normalizedSecret += '='; // Tambahkan padding agar bisa dibagi 8
    }

    final secretBytes = base32.decode(normalizedSecret);

    final timeCounter = counter ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ period;
    final timeBytes = _int64ToBytes(timeCounter);
    final hmac = Hmac(sha1, secretBytes);
    final hash = hmac.convert(timeBytes).bytes;

    final offset = (hash.last & 0xf).clamp(0, hash.length - 4);
    final binary = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);

    final otp = binary % pow(10, digits);
    return otp.toString().padLeft(digits, '0');
  }

  
  // Menghasilkan secret key baru
  String generateSecret() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(20, (_) => random.nextInt(256)),
    );
    return base32.encode(bytes).replaceAll('=', '');
  }
  
  // Konversi int64 ke bytes
  List<int> _int64ToBytes(int value) {
    final result = List<int>.filled(8, 0);
    for (var i = 7; i >= 0; i--) {
      result[i] = value & 0xff;
      value >>= 8;
    }
    return result;
  }
  
  // Parse URI TOTP dari QR Code
  Map<String, String> parseTotpUri(String uri) {
    uri = uri.trim(); // bersihkan newline/spasi ekstra

    if (!uri.startsWith('otpauth://totp/')) {
      throw Exception('URI tidak valid');
    }

    final result = <String, String>{};

    try {
      final uriParts = uri.split('?');
      final prefix = 'otpauth://totp/';
      final labelRaw = uriParts[0];

      // Perbaikan: Pastikan labelRaw lebih panjang dari prefix sebelum melakukan substring
      String labelPart = '';
      if (labelRaw.length > prefix.length) {
        labelPart = labelRaw.substring(prefix.length);
      } else {
        throw Exception('Format label tidak valid');
      }

      // Ekstrak nama dan issuer dari label (jika ada)
      if (labelPart.contains(':')) {
        final labelParts = labelPart.split(':');
        // Hapus bagian publisher/issuer dari label
        result['name'] = Uri.decodeComponent(labelParts.length > 1 ? labelParts[1] : labelParts[0]);
      } else {
        result['name'] = Uri.decodeComponent(labelPart);
      }

      // Jika ada parameter tambahan
      if (uriParts.length > 1) {
        final params = Uri.splitQueryString(uriParts[1]);
        
        // Ambil secret (wajib)
        if (params.containsKey('secret')) {
          result['secret'] = params['secret']!;
        }
        
        // Hapus parameter issuer karena tidak digunakan
        // Kita tidak perlu mengambil parameter issuer lagi
      }

      // Validasi hasil
      if (!result.containsKey('secret') || result['secret']!.isEmpty) {
        throw Exception('Secret key tidak ditemukan');
      }

      return result;
    } catch (e) {
      print('Error parsing TOTP URI: $e');
      throw Exception('Gagal memproses URI TOTP: ${e.toString()}');
    }
  }
  
  // Fungsi baru untuk memaksa refresh data TOTP
  Future<bool> refreshTOTPData() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    
    try {
      // Sinkronkan kunci enkripsi terlebih dahulu
      final syncResult = await syncEncryptionKey();
      if (!syncResult) {
        print('Gagal menyinkronkan kunci enkripsi');
        return false;
      }
      
      // Hapus cache jika ada
      // Tidak perlu melakukan apa-apa karena kita menggunakan stream
      // yang akan otomatis memperbarui data
      
      print('Berhasil refresh data TOTP');
      return true;
    } catch (e) {
      print('Error saat refresh data TOTP: $e');
      return false;
    }
  }

  // Fungsi untuk memaksa membuat kunci enkripsi di Firestore
  Future<bool> forceCreateEncryptionKey() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User tidak terautentikasi');
    }
    
    try {
      // Buat kunci baru
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      final encryptionKey = base64Encode(keyBytes);
      
      // Simpan kunci ke Firestore (paksa overwrite)
      await _firestore.collection('users').doc(user.uid).set({
        'encryptionKey': encryptionKey,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('Berhasil membuat dan menyimpan kunci enkripsi ke Firestore');
      return true;
    } catch (e) {
      print('Error saat membuat kunci enkripsi: $e');
      return false;
    }
  }
}
