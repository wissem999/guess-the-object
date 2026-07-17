import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/models/player_dto.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../lobby/data/datasources/category_datasource.dart';

// ── Data Source Provider ──────────────────────────────────
final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

final firebaseDatabaseProvider = Provider<FirebaseDatabase>((ref) {
  return FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: dotenv.env['FIREBASE_DATABASE_URL'],
  );
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
    } catch (e) {
      throw AuthFailure('Google sign-in failed: $e');
    }
  }

  Future<Player> signInWithEmail(String email, String password) async {
    try {
      return await _repository.signInWithEmail(email, password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure('Sign-in failed: $e');
    }
  }

  Future<Player> registerWithEmail(
      String email, String password, String name) async {
    try {
      return await _repository.registerWithEmail(email, password, name);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure('Registration failed: $e');
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

// Watch any player by ID (name, photo, rating, etc.)
final playerDtoStreamProvider = StreamProvider.family<PlayerDto?, String>((ref, userId) {
  return ref.watch(firestoreDataSourceProvider).watchPlayer(userId);
});
