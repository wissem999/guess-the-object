import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/lobby/presentation/pages/lobby_page.dart';
import '../../features/game/presentation/pages/game_page.dart';
import '../../features/game/presentation/pages/result_page.dart';
import '../../features/room/presentation/pages/create_room_page.dart';
import '../../features/room/presentation/pages/join_room_page.dart';
import '../../features/room/presentation/pages/waiting_room_page.dart';
import '../../features/game/presentation/pages/pick_object_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/ranking/presentation/pages/leaderboard_page.dart';
import '../../features/ranking/presentation/pages/friends_page.dart';
import '../../features/ranking/presentation/pages/add_friend_page.dart';
import '../../features/report/presentation/pages/report_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/lobby',
    redirect: (context, state) {
      final user = ref.read(authStateProvider).valueOrNull;
      final onLogin = state.matchedLocation == '/login';
      if (user == null && !onLogin) return '/login';
      if (user != null && onLogin) return '/lobby';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/lobby', builder: (_, _) => const LobbyPage()),
      GoRoute(path: '/create-room', builder: (_, _) => const CreateRoomPage()),
      GoRoute(path: '/join-room', builder: (_, _) => const JoinRoomPage()),
      GoRoute(path: '/waiting-room/:code', builder: (_, state) => WaitingRoomPage(roomCode: state.pathParameters['code']!)),
      GoRoute(path: '/pick-object/:code', builder: (_, state) => PickObjectPage(roomCode: state.pathParameters['code']!)),
      GoRoute(path: '/game/:gameId', builder: (_, state) => GamePage(gameId: state.pathParameters['gameId']!)),
      GoRoute(path: '/result/:gameId', builder: (_, state) => ResultPage(gameId: state.pathParameters['gameId']!)),
      GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
      GoRoute(path: '/leaderboard', builder: (_, _) => const LeaderboardPage()),
      GoRoute(path: '/friends', builder: (_, _) => const FriendsPage()),
      GoRoute(path: '/add-friend', builder: (_, _) => const AddFriendPage()),
      GoRoute(path: '/report/:matchId', builder: (_, state) => ReportPage(matchId: state.pathParameters['matchId']!)),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Force-navigate to /login after sign-out. Called from app.dart listener.
void goLogin() => _rootNavigatorKey.currentContext?.go('/login');
