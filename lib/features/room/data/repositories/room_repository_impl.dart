import 'dart:math';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/room_repository.dart';
import '../datasources/room_rtdb_datasource.dart';
import '../models/room_dto.dart';

final _random = Random();

String generateRoomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
}

class RoomRepositoryImpl implements RoomRepository {
  final RTDBDataSource _rtdb;

  RoomRepositoryImpl(this._rtdb);

  @override
  Future<Room> createRoom(String hostId, String categoryId) async {
    try {
      String code;
      int attempts = 0;
      do {
        code = generateRoomCode();
        attempts++;
        if (attempts > 10) {
          throw ServerException('Failed to generate unique room code');
        }
      } while (await _roomExists(code));

      final now = DateTime.now().millisecondsSinceEpoch;
      final dto = RoomDto(
        hostId: hostId,
        categoryId: categoryId,
        createdAt: now,
      );
      await _rtdb.createRoom(code, dto.toJson());
      return _toEntity(code, dto);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to create room: $e');
    }
  }

  Future<bool> _roomExists(String code) async {
    try {
      final data = await _rtdb.getRoomSnapshot(code);
      return data != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Room> joinRoom(String code, String guestId) async {
    try {
      final data = await _rtdb.getRoomSnapshot(code);
      if (data == null) {
        throw ServerException('Room not found');
      }
      final dto = RoomDto.fromJson(data);
      if (dto.guestId != null && dto.guestId != guestId) {
        throw ServerException('Room is full');
      }
      if (dto.hostId == guestId) {
        throw ServerException('Cannot join your own room');
      }
      await _rtdb.updateRoom(code, {
        'guestId': guestId,
        'status': 'ready',
      });
      final updated = await _rtdb.getRoomSnapshot(code);
      return _toEntity(code, RoomDto.fromJson(updated!));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to join room: $e');
    }
  }

  @override
  Stream<Room> watchRoom(String code) {
    return _rtdb.watchRoom(code).map((data) {
      if (data == null) {
        throw ServerException('Room deleted');
      }
      return _toEntity(code, RoomDto.fromJson(data));
    });
  }

  @override
  Future<void> setPlayerReady(
      String code, String playerId, bool ready) async {
    final isHost = await _isHost(code, playerId);
    final field = isHost ? 'hostReady' : 'guestReady';
    await _rtdb.updateRoom(code, {field: ready});
  }

  Future<bool> _isHost(String code, String playerId) async {
    final data = await _rtdb.getRoomSnapshot(code);
    if (data == null) return false;
    return data['hostId'] == playerId;
  }

  @override
  Future<void> cancelRoom(String code) async {
    await _rtdb.deleteRoom(code);
  }

  @override
  Stream<String> watchQueue(String categoryId) {
    return _rtdb.watchQueue(categoryId).map((entries) {
      return entries.isNotEmpty ? entries.last['playerId'] as String : '';
    });
  }

  @override
  Future<String> findQuickMatch(String playerId, String categoryId) async {
    try {
      final queueSnapshot = await _rtdb.getQueueSnapshot(categoryId);
      final entries = queueSnapshot.entries.toList();

      if (entries.isNotEmpty) {
        final firstEntry = entries.first;
        final opponentId = firstEntry.value['playerId'] as String;
        if (opponentId == playerId) {
          final match = await _createMatchFromQueue(
              playerId, playerId, categoryId);
          return match.code;
        }
        final match = await _createMatchFromQueue(
            opponentId, playerId, categoryId);
        await _rtdb.removeFromQueue(firstEntry.key, categoryId);
        return match.code;
      } else {
        await _rtdb.addToQueue(categoryId, playerId);
        return '';
      }
    } catch (e) {
      throw ServerException('Quick match failed: $e');
    }
  }

  Future<Room> _createMatchFromQueue(
      String player1Id, String player2Id, String categoryId) async {
    final code = generateRoomCode();
    final now = DateTime.now().millisecondsSinceEpoch;
    final dto = RoomDto(
      hostId: player1Id,
      guestId: player2Id,
      categoryId: categoryId,
      status: 'ready',
      createdAt: now,
    );
    await _rtdb.createRoom(code, dto.toJson());
    return _toEntity(code, dto);
  }

  Room _toEntity(String code, RoomDto dto) {
    return Room(
      code: code,
      hostId: dto.hostId,
      guestId: dto.guestId,
      categoryId: dto.categoryId,
      status: _parseStatus(dto.status),
      gameId: dto.gameId,
      hostReady: dto.hostReady,
      guestReady: dto.guestReady,
      p1ObjectId: dto.p1ObjectId,
      p2ObjectId: dto.p2ObjectId,
      createdAt: dto.createdAt,
    );
  }

  RoomStatus _parseStatus(String status) {
    switch (status) {
      case 'waiting':
        return RoomStatus.waiting;
      case 'ready':
        return RoomStatus.ready;
      case 'playing':
        return RoomStatus.playing;
      case 'finished':
        return RoomStatus.finished;
      default:
        return RoomStatus.waiting;
    }
  }
}
