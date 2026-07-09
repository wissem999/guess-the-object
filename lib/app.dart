import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

class GuessTheObjectApp extends ConsumerStatefulWidget {
  const GuessTheObjectApp({super.key});
  @override
  ConsumerState<GuessTheObjectApp> createState() => _GuessTheObjectAppState();
}

class _GuessTheObjectAppState extends ConsumerState<GuessTheObjectApp> {
  bool _wasLoggedIn = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    ref.listen<AsyncValue>(authStateProvider, (_, next) {
      if (next is AsyncData) {
        final loggedIn = next.value != null;
        if (!_initialized) {
          _initialized = true;
          _wasLoggedIn = loggedIn;
          return;
        }
        if (_wasLoggedIn != loggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (loggedIn) {
              goLobby();
            } else {
              goLogin();
            }
          });
        }
        _wasLoggedIn = loggedIn;
      }
    });

    return MaterialApp.router(
      title: 'Guess The Object',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
