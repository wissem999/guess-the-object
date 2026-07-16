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

class RTDBDataSource {
  final FirebaseDatabase _db;

  RTDBDataSource(this._db);

  Future<void> createRoom(String code, Map<String, dynamic> data) async {
    final ref = _db.ref().child('${FirebaseConstants.roomsPath}/$code');
    await ref.set(data);
    ref.onDisconnect().remove();
  }

  Future<Map<String, dynamic>?> getRoomSnapshot(String code) async {
    final snapshot =
        await _db.ref().child('${FirebaseConstants.roomsPath}/$code').once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return null;
    return data.map((k, v) => MapEntry(k.toString(), _deepConvert(v)));
  }

  Stream<Map<String, dynamic>?> watchRoom(String code) {
    return _db
        .ref()
        .child('${FirebaseConstants.roomsPath}/$code')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return null;
      return data.map((k, v) => MapEntry(k.toString(), _deepConvert(v)));
    });
  }

  Future<void> updateRoom(String code, Map<String, dynamic> data) async {
    await _db
        .ref()
        .child('${FirebaseConstants.roomsPath}/$code')
        .update(data);
  }

  Future<void> deleteRoom(String code) async {
    await _db.ref().child('${FirebaseConstants.roomsPath}/$code').remove();
  }

  Future<Map<String, Map<String, dynamic>>> getQueueSnapshot(
      String categoryId) async {
    final snapshot = await _db
        .ref()
        .child('${FirebaseConstants.queuePath}/$categoryId')
        .once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>? ?? {};
    return data.map((k, v) {
      final entry = (v as Map<dynamic, dynamic>)
          .map((k2, v2) => MapEntry(k2.toString(), _deepConvert(v2)));
      return MapEntry(k.toString(), entry);
    });
  }

  Stream<List<Map<String, dynamic>>> watchQueue(String categoryId) {
    return _db
        .ref()
        .child('${FirebaseConstants.queuePath}/$categoryId')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.entries.map((e) {
        final entry = (e.value as Map<dynamic, dynamic>)
            .map((k, v) => MapEntry(k.toString(), _deepConvert(v)));
        return {...entry, 'id': e.key.toString()};
      }).toList();
    });
  }

  Future<void> addToQueue(String categoryId, String playerId) async {
    await _db
        .ref()
        .child('${FirebaseConstants.queuePath}/$categoryId')
        .push()
        .set({
      'playerId': playerId,
      'joinedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeFromQueue(String categoryId, String queueId) async {
    await _db
        .ref()
        .child('${FirebaseConstants.queuePath}/$categoryId/$queueId')
        .remove();
  }
}
