import 'dart:math';
import '../entities/room.dart';

abstract class RoomRepository {
  Future<Room> createRoom(String hostId, String categoryId);
  Future<Room> joinRoom(String code, String guestId);
  Stream<Room> watchRoom(String code);
  Future<void> setPlayerReady(String code, String playerId, bool ready);
  Future<void> cancelRoom(String code);
  Stream<String> watchQueue(String categoryId);
  Future<String> findQuickMatch(String playerId, String categoryId);
}

final _random = Random();

String generateRoomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
}
