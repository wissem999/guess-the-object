import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';

class ProfileDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getMatchHistory(String userId) async {
    final snapshot = await _firestore
        .collection(FirebaseConstants.matchesCollection)
        .where('player1Id', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<Map<String, dynamic>?> getPlayerStats(String userId) async {
    final doc = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return {...doc.data()!, 'id': doc.id};
  }
}
