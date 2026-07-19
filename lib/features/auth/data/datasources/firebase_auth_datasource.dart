import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  static const _isWeb = kIsWeb;

  Stream<firebase_auth.User?> authStateChanges() => _auth.authStateChanges();

  firebase_auth.User? get currentUser => _auth.currentUser;

  Future<firebase_auth.UserCredential> signInWithGoogle() async {
    if (_isWeb) {
      final provider = firebase_auth.GoogleAuthProvider();
      return await _auth.signInWithPopup(provider);
    }
    try {
      final account = await GoogleSignIn.instance.authenticate();
      if (account == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Sign-in was cancelled',
        );
      }
      final authentication = await account.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: authentication.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: e.toString(),
      );
    }
  }

  Future<firebase_auth.UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<firebase_auth.UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (_isWeb) {
      await _auth.signOut();
      return;
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
