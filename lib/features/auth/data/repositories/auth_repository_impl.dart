import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../models/player_dto.dart';
import '../../../lobby/data/datasources/category_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _authDataSource;
  final FirestoreDataSource _firestoreDataSource;

  AuthRepositoryImpl(this._authDataSource, this._firestoreDataSource);

  @override
  Stream<Player?> get currentUser {
    return _authDataSource.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final dto = await _firestoreDataSource.getPlayer(firebaseUser.uid);
        if (dto != null) return _toEntity(dto);
      } catch (_) {}
      return Player(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Player',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );
    });
  }

  @override
  Future<Player> signInWithGoogle() async {
    try {
      final credential = await _authDataSource.signInWithGoogle();
      return await _handleSignIn(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Google sign-in failed', code: e.code);
    } catch (e) {
      throw AuthException('Google sign-in failed: ${e.toString()}');
    }
  }

  @override
  Future<Player> signInWithEmail(String email, String password) async {
    try {
      final credential = await _authDataSource.signInWithEmail(email, password);
      return await _handleSignIn(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign-in failed', code: e.code);
    }
  }

  @override
  Future<Player> registerWithEmail(
      String email, String password, String name) async {
    try {
      final credential =
          await _authDataSource.registerWithEmail(email, password);
      await credential.user!.updateDisplayName(name);
      return await _handleSignIn(credential.user!, name: name);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Registration failed', code: e.code);
    }
  }

  @override
  Future<void> signOut() async {
    await _authDataSource.signOut();
  }

  @override
  Future<void> createProfile(Player player) async {
    final dto = PlayerDto(
      id: player.id,
      name: player.name,
      email: player.email,
      photoUrl: player.photoUrl,
      createdAt: player.createdAt,
    );
    await _firestoreDataSource.createUserProfile(dto);
  }

  Future<Player> _handleSignIn(User firebaseUser, {String? name}) async {
    final dto = await _firestoreDataSource.getPlayer(firebaseUser.uid);
    if (dto != null) return _toEntity(dto);
    final newPlayer = Player(
      id: firebaseUser.uid,
      name: name ?? firebaseUser.displayName ?? 'Player',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );
    await createProfile(newPlayer);
    return newPlayer;
  }

  Player _toEntity(PlayerDto dto) {
    return Player(
      id: dto.id,
      name: dto.name,
      email: dto.email,
      photoUrl: dto.photoUrl,
      wins: dto.wins,
      losses: dto.losses,
      rating: dto.rating,
      peakRating: dto.peakRating,
      tier: dto.tier,
      brainPoints: dto.brainPoints,
      seasonWins: dto.seasonWins,
      seasonLosses: dto.seasonLosses,
      createdAt: dto.createdAt,
    );
  }
}
