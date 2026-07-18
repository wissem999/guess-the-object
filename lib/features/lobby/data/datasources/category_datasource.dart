import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../auth/data/models/player_dto.dart';

class FirestoreDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ── Player Profile ──────────────────────────────────────
  Future<PlayerDto?> getPlayer(String userId) async {
    final doc = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return PlayerDto.fromJson({...doc.data()!, 'id': doc.id});
  }

  Stream<PlayerDto?> watchPlayer(String userId) {
    return _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) =>
            doc.exists ? PlayerDto.fromJson({...doc.data()!, 'id': doc.id}) : null);
  }

  Future<void> createUserProfile(PlayerDto dto) async {
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(dto.id)
        .set(dto.toJson());
  }

  Future<void> updatePlayerRating(
    String userId,
    int newRating,
    int peakRating,
    String tier,
  ) async {
    await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .update({
      FirebaseConstants.fieldRating: newRating,
      FirebaseConstants.fieldPeakRating: peakRating,
      FirebaseConstants.fieldTier: tier,
    });
  }

  // ── Categories ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCategories() async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.categoriesCollection)
        .orderBy('order')
        .get();
    return snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<List<Map<String, dynamic>>> getObjectsByCategory(
      String categoryId) async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.objectsCollection)
        .where('categoryId', isEqualTo: categoryId)
        .get();
    return snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<Map<String, dynamic>?> getObjectById(String objectId) async {
    final doc = await _firestore
        .collection(FirebaseConstants.objectsCollection)
        .doc(objectId)
        .get();
    if (!doc.exists) return null;
    return {...doc.data()!, 'id': doc.id};
  }

  // ── Match History ────────────────────────────────────────
  Future<void> saveMatchRecord(Map<String, dynamic> data) async {
    await _firestore
        .collection(FirebaseConstants.matchesCollection)
        .add(data);
  }

  Future<Map<String, dynamic>?> getMatchDocument(String matchId) async {
    final doc = await _firestore
        .collection(FirebaseConstants.matchesCollection)
        .doc(matchId)
        .get();
    if (!doc.exists) return null;
    return {...doc.data()!, 'id': doc.id};
  }

  Future<List<Map<String, dynamic>>> getMatchHistory(String userId) async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.matchesCollection)
        .where('player1Id', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  // ── Friends ──────────────────────────────────────────────
  Future<List<String>> getFriendIds(String userId) async {
    final doc = await _firestore
        .collection(FirebaseConstants.friendshipsCollection)
        .doc(userId)
        .get();
    if (!doc.exists) return [];
    final data = doc.data()!;
    return (data[FirebaseConstants.fieldFriendIds] as Map<String, dynamic>)
        .keys
        .toList();
  }

  Future<List<Map<String, dynamic>>> getPlayersByIds(
      List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final snapshot = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .where(FieldPath.documentId, whereIn: userIds)
        .get();
    return snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<void> sendFriendRequest(String fromId, String toId, {String? fromName}) async {
    await _firestore
        .collection(FirebaseConstants.friendRequestsCollection)
        .add({
      'fromId': fromId,
      'toId': toId,
      'fromName': fromName ?? '',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest(
      String requestId, String userId, String friendId) async {
    await _firestore.runTransaction((transaction) async {
      transaction.update(
        _firestore
            .collection(FirebaseConstants.friendRequestsCollection)
            .doc(requestId),
        {'status': 'accepted'},
      );
      transaction.set(
        _firestore
            .collection(FirebaseConstants.friendshipsCollection)
            .doc(userId),
        {FirebaseConstants.fieldFriendIds: {friendId: true}},
        SetOptions(merge: true),
      );
      transaction.set(
        _firestore
            .collection(FirebaseConstants.friendshipsCollection)
            .doc(friendId),
        {FirebaseConstants.fieldFriendIds: {userId: true}},
        SetOptions(merge: true),
      );
    });
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore
        .collection(FirebaseConstants.friendRequestsCollection)
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  Stream<List<Map<String, dynamic>>> watchFriendRequests(String userId) {
    return _firestore
        .collection(FirebaseConstants.friendRequestsCollection)
        .where('toId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<List<Map<String, dynamic>>> searchUsers(
      String query, String currentUserId) async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();
    return snapshot.docs
        .where((d) => d.id != currentUserId)
        .map((d) => {...d.data(), 'id': d.id})
        .toList();
  }

  // ── Username Check ──────────────────────────────────────
  Future<bool> isUsernameTaken(String name, {String? excludeUserId}) async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return false;
    if (excludeUserId != null) {
      return !snapshot.docs.any((d) => d.id == excludeUserId);
    }
    return true;
  }

  // ── Reports ──────────────────────────────────────────────
  Future<void> submitReport(Map<String, dynamic> data) async {
    await _firestore
        .collection(FirebaseConstants.reportsCollection)
        .add(data);
  }

  Future<List<Map<String, dynamic>>> getMyReports(String userId) async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.reportsCollection)
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  // ── Seasons ──────────────────────────────────────────────
  Future<Map<String, dynamic>?> getCurrentSeasonData(String userId) async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.seasonsCollection)
        .orderBy('seasonNumber', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final season = snapshot.docs.first;
    final participants =
        Map<String, dynamic>.from(season.data()['participants'] ?? {});
    return participants[userId] as Map<String, dynamic>?;
  }
}
