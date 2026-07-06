import '../entities/match_record.dart';

abstract class ProfileRepository {
  Future<List<MatchRecord>> getMatchHistory(String userId);
  Future<int> getTotalGames(String userId);
  Future<int> getTotalWins(String userId);
}
