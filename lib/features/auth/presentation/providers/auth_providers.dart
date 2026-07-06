import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../lobby/data/datasources/category_datasource.dart';

// ── Data Source Provider ──────────────────────────────────
final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

final firestoreDataSourceProvider = Provider<FirestoreDataSource>((ref) {
  return FirestoreDataSource();
});

// ── Repository Provider ───────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(firebaseAuthDataSourceProvider),
    ref.watch(firestoreDataSourceProvider),
  );
});

// ── Auth State Stream ─────────────────────────────────────
final authStateProvider = StreamProvider<Player?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});

// ── Auth Actions ──────────────────────────────────────────
final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref.watch(authRepositoryProvider));
});

class AuthActions {
  final AuthRepository _repository;
  AuthActions(this._repository);

  Future<Player> signInWithGoogle() async {
    try {
      return await _repository.signInWithGoogle();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<Player> signInWithEmail(String email, String password) async {
    try {
      return await _repository.signInWithEmail(email, password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<Player> registerWithEmail(
      String email, String password, String name) async {
    try {
      return await _repository.registerWithEmail(email, password, name);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }
}

// Simple provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.id;
});
