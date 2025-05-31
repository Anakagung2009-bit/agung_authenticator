import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../models/password_model.dart';

class PasswordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get or create encryption key (reusing the same approach as in TOTP service)
  Future<String> _getOrCreateEncryptionKey() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    String? encryptionKey;
    
    try {
      // Try to get the key from Firestore
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      final userData = docSnapshot.data();
      
      if (userData != null && userData.containsKey('encryptionKey')) {
        encryptionKey = userData['encryptionKey'];
      } else {
        throw Exception('Encryption key not found');
      }
    } catch (e) {
      throw Exception('Failed to get encryption key: $e');
    }
    
    if (encryptionKey == null) {
      throw Exception('Failed to get encryption key');
    }
    return encryptionKey;
  }
  
  // Encrypt data with AES
  Future<Map<String, String>> _encryptData({
    required String data,
    String? encryptionKey,
  }) async {
    // Get encryption key if not provided
    final key = encryptionKey ?? await _getOrCreateEncryptionKey();
    
    // Create random IV for each encryption
    final iv = encrypt.IV.fromSecureRandom(16);
    
    // Setup encryption
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key.fromBase64(key), mode: encrypt.AESMode.cbc),
    );
    
    // Encrypt data
    final encrypted = encrypter.encrypt(data, iv: iv);
    
    // Return encrypted data and IV
    return {
      'data': encrypted.base64,
      'iv': iv.base64,
    };
  }
  
  // Decrypt data with AES
  Future<String> _decryptData({
    required String encryptedData,
    required String ivString,
    String? encryptionKey,
  }) async {
    if (ivString.isEmpty) throw Exception('IV is empty for decryption');

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

  // Add a new password
  Future<void> addPassword({
    required String accountType,
    required String accountName,
    required String username,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    // Get encryption key
    final encryptionKey = await _getOrCreateEncryptionKey();
    
    // Encrypt sensitive data
    final encryptedUsername = await _encryptData(
      data: username,
      encryptionKey: encryptionKey,
    );
    
    final encryptedPassword = await _encryptData(
      data: password,
      encryptionKey: encryptionKey,
    );
    
    // Save encrypted data to Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('passwords')
        .add({
          'accountType': accountType,
          'accountName': accountName,
          'encryptedUsername': encryptedUsername['data'],
          'usernameIv': encryptedUsername['iv'],
          'encryptedPassword': encryptedPassword['data'],
          'passwordIv': encryptedPassword['iv'],
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
  
  // Get all passwords for the current user
  Stream<List<PasswordModel>> getPasswords() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('passwords')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final encryptionKey = await _getOrCreateEncryptionKey();
          final List<PasswordModel> result = [];
          
          for (final doc in snapshot.docs) {
            final data = doc.data();
            
            try {
              // Decrypt username
              String username = '';
              if (data.containsKey('encryptedUsername') && data.containsKey('usernameIv')) {
                username = await _decryptData(
                  encryptedData: data['encryptedUsername'],
                  ivString: data['usernameIv'],
                  encryptionKey: encryptionKey,
                );
              }
              
              // Decrypt password
              String password = '';
              if (data.containsKey('encryptedPassword') && data.containsKey('passwordIv')) {
                password = await _decryptData(
                  encryptedData: data['encryptedPassword'],
                  ivString: data['passwordIv'],
                  encryptionKey: encryptionKey,
                );
              }
              
              // Create password model
              final passwordModel = PasswordModel(
                id: doc.id,
                accountType: data['accountType'] ?? 'Custom Account',
                accountName: data['accountName'] ?? data['accountType'] ?? 'Custom Account',
                username: username,
                password: password,
                createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
              );
              
              result.add(passwordModel);
            } catch (e) {
              print('Failed to decrypt password: $e');
              continue; // Skip this entry to avoid crash
            }
          }
          
          return result;
        });
  }
  
  // Delete a password
  Future<void> deletePassword(String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('passwords')
        .doc(id)
        .delete();
  }
}
