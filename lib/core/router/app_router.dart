import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/email_auth_page.dart';
import '../../features/lobby/presentation/pages/lobby_page.dart';
import '../../features/game/presentation/pages/game_page.dart';
import '../../features/game/presentation/pages/result_page.dart';
import '../../features/room/presentation/pages/create_room_page.dart';
import '../../features/room/presentation/pages/join_room_page.dart';
import '../../features/room/presentation/pages/waiting_room_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/ranking/presentation/pages/leaderboard_page.dart';
import '../../features/ranking/presentation/pages/friends_page.dart';
import '../../features/ranking/presentation/pages/add_friend_page.dart';
import '../../features/report/presentation/pages/report_page.dart';
import '../../features/store/presentation/pages/store_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final _authRefreshNotifier = ValueNotifier(0);

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/lobby',
    refreshListenable: _authRefreshNotifier,
    redirect: (context, state) {
      final user = ref.read(authStateProvider).valueOrNull;
      final onLogin = state.matchedLocation == '/login';
      final onEmailAuth = state.matchedLocation == '/email-auth';
      final isPublicRoute = onLogin || onEmailAuth;
      if (user == null && !isPublicRoute) return '/login';
      if (user != null && (onLogin || onEmailAuth)) return '/lobby';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/email-auth', builder: (_, _) => const EmailAuthPage()),
      GoRoute(path: '/lobby', builder: (_, _) => const MainShell()),
      GoRoute(path: '/host', builder: (_, _) => const CreateRoomPage()),
      GoRoute(path: '/join-room', builder: (_, _) => const JoinRoomPage()),
      GoRoute(path: '/waiting-room/:code', builder: (_, state) => WaitingRoomPage(roomCode: state.pathParameters['code']!)),
      GoRoute(path: '/game/:gameId', builder: (_, state) => GamePage(gameId: state.pathParameters['gameId']!)),
      GoRoute(path: '/result/:gameId', builder: (_, state) => ResultPage(gameId: state.pathParameters['gameId']!)),
      GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
      GoRoute(path: '/leaderboard', builder: (_, _) => const LeaderboardPage()),
      GoRoute(path: '/friends', builder: (_, _) => const FriendsPage()),
      GoRoute(path: '/add-friend', builder: (_, _) => const AddFriendPage()),
      GoRoute(path: '/report/:matchId/:reportedPlayerId/:categoryId', builder: (_, state) => ReportPage(
        matchId: state.pathParameters['matchId']!,
        reportedPlayerId: state.pathParameters['reportedPlayerId']!,
        categoryId: state.pathParameters['categoryId']!,
      )),
      GoRoute(path: '/store', builder: (_, _) => const StorePage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

void goLogin() => rootNavigatorKey.currentContext?.go('/login');
void goLobby() => rootNavigatorKey.currentContext?.go('/lobby');

/// Notify GoRouter to re-evaluate redirects on auth change.
void refreshAuthRedirect() => _authRefreshNotifier.value++;
