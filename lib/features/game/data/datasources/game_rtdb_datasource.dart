import 'package:firebase_database/firebase_database.dart';
import '../../../../core/constants/firebase_constants.dart';

dynamic _deepConvert(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), _deepConvert(v)));
  }
  if (value is List) {
    return value.map(_deepConvert).toList();
  }
  return value;
}

class GameRTDBDataSource {
  final FirebaseDatabase _db;

  GameRTDBDataSource(this._db);

  Future<String> createActiveGame(Map<String, dynamic> data) async {
    final ref = _db.ref().child(FirebaseConstants.activeGamesPath).push();
    final gameData = {...data, 'status': 'active'};
    await ref.set(gameData);
    ref.onDisconnect().update({
      'status': 'disconnected',
      'disconnectedAt': ServerValue.timestamp,
    });
    return ref.key!;
  }

  Future<void> cancelGameOnDisconnect(String gameId) async {
    final ref = _db.ref().child('${FirebaseConstants.activeGamesPath}/$gameId');
    ref.onDisconnect().cancel();
  }

  Future<void> setGameActive(String gameId) async {
    final ref = _db.ref().child('${FirebaseConstants.activeGamesPath}/$gameId');
    ref.onDisconnect().update({
      'status': 'disconnected',
      'disconnectedAt': ServerValue.timestamp,
    });
    await ref.update({'status': 'active'});
  }

  Stream<Map<String, dynamic>?> watchGame(String gameId) {
    return _db
        .ref()
        .child('${FirebaseConstants.activeGamesPath}/$gameId')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return data.map((k, v) => MapEntry(k.toString(), _deepConvert(v)));
    });
  }

  Future<void> updateGame(String gameId, Map<String, dynamic> data) async {
    await _db
        .ref()
        .child('${FirebaseConstants.activeGamesPath}/$gameId')
        .update(data);
  }

  Future<void> pushTurn(String gameId, Map<String, dynamic> turnData) async {
    final turnsRef = _db
        .ref()
        .child('${FirebaseConstants.activeGamesPath}/$gameId/turns');
    final snapshot = await turnsRef.once();
    final existing = snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
    final turnCount = existing.length;
    await turnsRef.child('turn_$turnCount').set(turnData);
  }

  Future<void> setGuess(String gameId, Map<String, dynamic> guessData) async {
    await _db
        .ref()
        .child('${FirebaseConstants.activeGamesPath}/$gameId/guess')
        .set(guessData);
  }

  Future<Map<String, dynamic>?> getGameSnapshot(String gameId) async {
    final snapshot = await _db
        .ref()
        .child('${FirebaseConstants.activeGamesPath}/$gameId')
        .once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return null;
    return data.map((k, v) => MapEntry(k.toString(), _deepConvert(v)));
  }

  Future<void> deleteGame(String gameId) async {
    await _db
        .ref()
        .child('${FirebaseConstants.activeGamesPath}/$gameId')
        .remove();
  }
}
