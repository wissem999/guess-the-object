import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/room_rtdb_datasource.dart';
import '../../data/repositories/room_repository_impl.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/room_repository.dart';

final rtdbDataSourceProvider = Provider<RTDBDataSource>((ref) {
  return RTDBDataSource(ref.watch(firebaseDatabaseProvider));
});

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepositoryImpl(
    ref.watch(rtdbDataSourceProvider),
  );
});

final roomStreamProvider = StreamProvider.family<Room, String>((ref, code) {
  return ref.watch(roomRepositoryProvider).watchRoom(code);
});

final roomActionsProvider = Provider<RoomActions>((ref) {
  return RoomActions(ref.watch(roomRepositoryProvider));
});

class RoomActions {
  final RoomRepository _repo;
  RoomActions(this._repo);

  Future<String> createRoom(String hostId, String categoryId) async {
    try {
      final room = await _repo.createRoom(hostId, categoryId);
      return room.code;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<Room> joinRoom(String code, String guestId) async {
    try {
      return await _repo.joinRoom(code, guestId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  Future<void> setReady(String code, String playerId, bool ready) async {
    await _repo.setPlayerReady(code, playerId, ready);
  }

  Future<void> cancelRoom(String code) async {
    await _repo.cancelRoom(code);
  }

  Future<String> findQuickMatch(String playerId, String categoryId) async {
    try {
      return await _repo.findQuickMatch(playerId, categoryId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}
