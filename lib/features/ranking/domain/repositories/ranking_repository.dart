import '../entities/friend.dart';

abstract class RankingRepository {
  Future<List<Friend>> getFriendsLeaderboard(String userId);
  Future<void> sendFriendRequest(String fromId, String toId);
  Future<void> acceptFriendRequest(String requestId, String userId, String friendId);
  Future<void> rejectFriendRequest(String requestId);
  Stream<List<FriendRequest>> watchFriendRequests(String userId);
  Future<List<Friend>> searchUsers(String query, String currentUserId);
  Future<SeasonData?> getCurrentSeasonData(String userId);
}
