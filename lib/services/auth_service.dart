import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'totp_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
    Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      await TOTPService().forceCreateEncryptionKey();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
  
  Future<String?> signUp({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Buat dokumen user baru di Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}