import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import 'dart:async';

class RTDBDataSource {
  // Note: Firebase Realtime Database will be configured here.
  // For now, this uses Cloud Firestore for room/game state.
  // In production, migrate to RTDB for sub-10ms latency.

  // ── Rooms ────────────────────────────────────────────────
  Future<void> createRoom(String code, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.roomsPath)
        .doc(code)
        .set(data);
  }

  Stream<Map<String, dynamic>?> watchRoom(String code) {
    return FirebaseFirestore.instance
        .collection(FirebaseConstants.roomsPath)
        .doc(code)
        .snapshots()
        .map((snap) => snap.exists ? {...snap.data()!, 'id': snap.id} : null);
  }

  Future<void> updateRoom(String code, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.roomsPath)
        .doc(code)
        .update(data);
  }

  Future<void> deleteRoom(String code) async {
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.roomsPath)
        .doc(code)
        .delete();
  }

  // ── Active Games ─────────────────────────────────────────
  Future<String> createActiveGame(Map<String, dynamic> data) async {
    final doc = await FirebaseFirestore.instance
        .collection(FirebaseConstants.activeGamesPath)
        .add(data);
    return doc.id;
  }

  Stream<Map<String, dynamic>?> watchGame(String gameId) {
    return FirebaseFirestore.instance
        .collection(FirebaseConstants.activeGamesPath)
        .doc(gameId)
        .snapshots()
        .map((snap) => snap.exists ? {...snap.data()!, 'id': snap.id} : null);
  }

  Future<void> updateGame(String gameId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.activeGamesPath)
        .doc(gameId)
        .update(data);
  }

  // ── Queue ────────────────────────────────────────────────
  Future<String> addToQueue(String categoryId, String playerId) async {
    final doc = await FirebaseFirestore.instance
        .collection(FirebaseConstants.queuePath)
        .doc(categoryId)
        .collection('entries')
        .add({
      'playerId': playerId,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<List<Map<String, dynamic>>> watchQueue(String categoryId) {
    return FirebaseFirestore.instance
        .collection(FirebaseConstants.queuePath)
        .doc(categoryId)
        .collection('entries')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> removeFromQueue(String queueId, String categoryId) async {
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.queuePath)
        .doc(categoryId)
        .collection('entries')
        .doc(queueId)
        .delete();
  }
}
