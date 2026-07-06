import '../entities/player.dart';

abstract class AuthRepository {
  Stream<Player?> get currentUser;
  Future<Player> signInWithGoogle();
  Future<Player> signInWithEmail(String email, String password);
  Future<Player> registerWithEmail(String email, String password, String name);
  Future<void> signOut();
  Future<void> createProfile(Player player);
}
