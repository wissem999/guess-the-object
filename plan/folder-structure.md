# Folder Structure

## Complete File Tree

```
guess-the-object/
│
├── lib/
│   ├── main.dart                              # Entry point, ProviderScope, runApp
│   ├── app.dart                               # MaterialApp.router, theme setup
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart             # Timeouts (30s turn), limits (6-char code)
│   │   │   └── firebase_constants.dart        # Collection names, RTDB paths as constants
│   │   ├── errors/
│   │   │   ├── exceptions.dart                # ServerException, CacheException, AuthException
│   │   │   └── failures.dart                  # Failure sealed class (Server, Cache, Auth)
│   │   ├── theme/
│   │   │   └── app_theme.dart                 # Colors, text styles, button themes
│   │   ├── utils/
│   │   │   ├── validators.dart                # Email validator, room code validator
│   │   │   └── date_helpers.dart              # Relative time formatting
│   │   └── router/
│   │       └── app_router.dart                # GoRouter with auth redirect + deep links
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── firebase_auth_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── player_dto.dart        # @freezed, fromJson/toJson
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── player.dart            # Pure Dart class
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository.dart   # Abstract interface
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── auth_providers.dart     # Provider wiring
│   │   │       │   └── auth_state_provider.dart # Stream auth state
│   │   │       └── pages/
│   │   │           ├── login_page.dart         # Google + Email buttons
│   │   │           └── register_page.dart      # Email registration form
│   │   │
│   │   ├── lobby/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── category_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── category_dto.dart
│   │   │   │   │   └── game_object_dto.dart
│   │   │   │   └── repositories/
│   │   │   │       └── category_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── category.dart
│   │   │   │   │   └── game_object.dart
│   │   │   │   └── repositories/
│   │   │   │       └── category_repository.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── lobby_providers.dart
│   │   │       └── pages/
│   │   │           └── lobby_page.dart
│   │   │
│   │   ├── room/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── room_firestore_datasource.dart
│   │   │   │   │   └── room_rtdb_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── room_dto.dart
│   │   │   │   └── repositories/
│   │   │   │       └── room_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── room.dart
│   │   │   │   └── repositories/
│   │   │   │       └── room_repository.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── room_providers.dart
│   │   │       │   └── matchmaking_providers.dart
│   │   │       └── pages/
│   │   │           ├── create_room_page.dart
│   │   │           ├── join_room_page.dart
│   │   │           └── waiting_room_page.dart
│   │   │
│   │   ├── game/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── game_rtdb_datasource.dart
│   │   │   │   │   └── game_firestore_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── game_state_dto.dart
│   │   │   │   │   └── turn_dto.dart
│   │   │   │   └── repositories/
│   │   │   │       └── game_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── game_state.dart
│   │   │   │   │   └── turn.dart
│   │   │   │   └── repositories/
│   │   │   │       └── game_repository.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── game_providers.dart
│   │   │       └── pages/
│   │   │           ├── pick_object_page.dart
│   │   │           ├── game_page.dart
│   │   │           └── result_page.dart
│   │   │
│   │   ├── ranking/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── ranking_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── friend_request_dto.dart
│   │   │   │   │   └── season_data_dto.dart
│   │   │   │   └── repositories/
│   │   │   │       └── ranking_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── friend.dart
│   │   │   │   │   ├── friend_request.dart
│   │   │   │   │   ├── season_data.dart
│   │   │   │   │   └── elo_calculator.dart
│   │   │   │   └── repositories/
│   │   │   │       └── ranking_repository.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── ranking_providers.dart
│   │   │       └── pages/
│   │   │           ├── leaderboard_page.dart
│   │   │           ├── friends_page.dart
│   │   │           └── add_friend_page.dart
│   │   │
│   │   └── profile/
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   │   └── profile_datasource.dart
│   │       │   ├── models/
│   │       │   │   └── match_record_dto.dart
│   │       │   └── repositories/
│   │       │       └── profile_repository_impl.dart
│   │       ├── domain/
│   │       │   ├── entities/
│   │       │   │   └── match_record.dart
│   │       │   └── repositories/
│   │       │       └── profile_repository.dart
│   │       └── presentation/
│   │           ├── providers/
│   │           │   └── profile_providers.dart
│   │           └── pages/
│   │               └── profile_page.dart
│   │
│   └── shared/
│       └── widgets/
│           ├── app_button.dart
│           ├── loading_overlay.dart
│           ├── category_card.dart
│           ├── question_bubble.dart
│           ├── answer_bubble.dart
│           ├── turn_timer.dart
│           ├── yes_no_quick_buttons.dart
│           ├── opponent_info_card.dart
│           ├── guess_dialog.dart
│           ├── turn_history_list.dart
│           ├── tier_badge.dart
│           ├── rating_change_indicator.dart
│           ├── friend_tile.dart
│           ├── report_button.dart
│           ├── my_question_card.dart
│           └── opponent_question_card.dart
│
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   └── google_logo.png
│   └── sounds/
│       ├── turn_change.mp3
│       ├── question_received.mp3
│       ├── answer_received.mp3
│       ├── guess_made.mp3
│       ├── win.mp3
│       ├── lose.mp3
│       ├── match_found.mp3
│       └── button_tap.mp3
│
├── test/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── datasources/
│   │   │   │   └── firebase_auth_datasource_test.dart
│   │   │   ├── domain/
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_test.dart
│   │   │   └── presentation/
│   │   │       └── providers/
│   │   │           └── auth_providers_test.dart
│   │   ├── lobby/
│   │   ├── room/
│   │   └── game/
│   └── shared/
│       └── widgets/
│           └── widgets_test.dart
│
├── firebase.json
├── firestore.rules
├── database.rules
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

## File Count Summary

| Layer | File Count |
|---|---|
| Core | 8 |
| Auth feature | 9 |
| Lobby feature | 9 |
| Room feature | 12 |
| Game feature | 14 |
| Report feature | 8 |
| Ranking feature | 12 |
| Profile feature | 8 |
| Shared widgets | 16 |
| Assets | 11 |
| Tests | 12+ |
| Config | 5 |
| **Total** | **~115** |
