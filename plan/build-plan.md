# Build Plan

## Phase 1 — Firebase Project Setup

**Goal:** Firebase project configured and linked to Flutter

| Task | Files | Est. Time |
|---|---|---|
| Create Firebase project in Firebase Console | — | 15min |
| Enable Auth (Google + Email/Password) | — | 5min |
| Create Firestore database | — | 5min |
| Create RTDB database | — | 5min |
| Create Android + iOS apps in Firebase Console | — | 10min |
| Download `google-services.json` + `GoogleService-Info.plist` | — | 5min |
| Run `flutterfire configure` | `firebase_options.dart` | 10min |
| Set up `pubspec.yaml` with all dependencies | `pubspec.yaml` | 10min |
| **Total** | | **~1h** |

---

## Phase 2 — Core Layer

**Goal:** Constants, errors, theme, router ready

| Task | Files | Est. Time |
|---|---|---|
| Define app constants (timeouts, limits) | `core/constants/app_constants.dart` | 15min |
| Define Firebase path constants | `core/constants/firebase_constants.dart` | 15min |
| Create exception classes | `core/errors/exceptions.dart` | 10min |
| Create Failure sealed class | `core/errors/failures.dart` | 10min |
| Build app theme | `core/theme/app_theme.dart` | 20min |
| Build GoRouter with auth redirect | `core/router/app_router.dart` | 30min |
| Create validators | `core/utils/validators.dart` | 15min |
| **Total** | | **~2h** |

---

## Phase 3 — Auth Feature

**Goal:** Login/signup working with Google + Email

| Task | Files | Est. Time |
|---|---|---|
| Create Player entity | `features/auth/domain/entities/player.dart` | 15min |
| Create AuthRepository interface | `features/auth/domain/repositories/auth_repository.dart` | 15min |
| Create FirebaseAuthDataSource | `features/auth/data/datasources/firebase_auth_datasource.dart` | 30min |
| Create PlayerDto | `features/auth/data/models/player_dto.dart` | 15min |
| Create AuthRepositoryImpl | `features/auth/data/repositories/auth_repository_impl.dart` | 30min |
| Create auth providers | `features/auth/presentation/providers/auth_providers.dart` | 20min |
| Create auth state provider | `features/auth/presentation/providers/auth_state_provider.dart` | 15min |
| Build LoginPage UI | `features/auth/presentation/pages/login_page.dart` | 1h |
| Build RegisterPage UI | `features/auth/presentation/pages/register_page.dart` | 30min |
| **Total** | | **~3h** |

---

## Phase 4 — Lobby Feature

**Goal:** Player can see categories and pick one

| Task | Files | Est. Time |
|---|---|---|
| Create Category + GameObject entities | `features/lobby/domain/entities/` | 20min |
| Create CategoryRepository interface | `features/lobby/domain/repositories/category_repository.dart` | 15min |
| Create CategoryDataSource | `features/lobby/data/datasources/category_datasource.dart` | 20min |
| Create DTOs | `features/lobby/data/models/` | 20min |
| Create CategoryRepositoryImpl | `features/lobby/data/repositories/` | 20min |
| Seed Firestore with categories + objects | Script or manual | 30min |
| Create lobby providers | `features/lobby/presentation/providers/` | 20min |
| Build LobbyPage (category grid) | `features/lobby/presentation/pages/lobby_page.dart` | 1h |
| **Total** | | **~3h** |

---

## Phase 5 — Room Feature

**Goal:** Create room, join room, quick play matchmaking

| Task | Files | Est. Time |
|---|---|---|
| Create Room entity + enum | `features/room/domain/entities/room.dart` | 15min |
| Create RoomRepository interface | `features/room/domain/repositories/room_repository.dart` | 20min |
| Create RTDB RoomDataSource | `features/room/data/datasources/room_rtdb_datasource.dart` | 1h |
| Create Firestore RoomDataSource | `features/room/data/datasources/room_firestore_datasource.dart` | 30min |
| Create RoomDto | `features/room/data/models/room_dto.dart` | 15min |
| Create RoomRepositoryImpl | `features/room/data/repositories/room_repository_impl.dart` | 1h |
| Create room + matchmaking providers | `features/room/presentation/providers/` | 30min |
| Build CreateRoomPage | `features/room/presentation/pages/create_room_page.dart` | 45min |
| Build JoinRoomPage | `features/room/presentation/pages/join_room_page.dart` | 45min |
| Build WaitingRoomPage | `features/room/presentation/pages/waiting_room_page.dart` | 45min |
| **Total** | | **~5h** |

---

## Phase 6 — Game Feature

**Goal:** Full game loop — pick object, ask/answer, guess, result

| Task | Files | Est. Time |
|---|---|---|
| Create GameState + Turn entities | `features/game/domain/entities/` | 30min |
| Create GameRepository interface | `features/game/domain/repositories/game_repository.dart` | 20min |
| Create RTDB GameDataSource | `features/game/data/datasources/game_rtdb_datasource.dart` | 1.5h |
| Create Firestore GameDataSource | `features/game/data/datasources/game_firestore_datasource.dart` | 30min |
| Create GameStateDto + TurnDto | `features/game/data/models/` | 30min |
| Create GameRepositoryImpl | `features/game/data/repositories/game_repository_impl.dart` | 1.5h |
| Create game providers (stream, turn, guess) | `features/game/presentation/providers/` | 1h |
| Build PickObjectPage | `features/game/presentation/pages/pick_object_page.dart` | 1h |
| Build GamePage (main game screen) | `features/game/presentation/pages/game_page.dart` | 2h |
| Build ResultPage | `features/game/presentation/pages/result_page.dart` | 45min |
| **Total** | | **~9h** |

---

## Phase 7 — Report Feature

**Goal:** Player can report unfair play, admin can review with full match data

| Task | Files | Est. Time |
|---|---|---|
| Create Report entity + enum | `features/report/domain/entities/report.dart` | 15min |
| Create ReportRepository interface | `features/report/domain/repositories/report_repository.dart` | 15min |
| Create ReportDataSource | `features/report/data/datasources/report_datasource.dart` | 30min |
| Create ReportDto | `features/report/data/models/report_dto.dart` | 15min |
| Create ReportRepositoryImpl | `features/report/data/repositories/report_repository_impl.dart` | 30min |
| Create report providers | `features/report/presentation/providers/report_providers.dart` | 20min |
| Build ReportPage + report form | `features/report/presentation/pages/report_page.dart` | 1h |
| Add ReportButton to ResultPage | `features/game/presentation/pages/result_page.dart` | 15min |
| Update GamePage for split turn history | `features/game/presentation/pages/game_page.dart` | 30min |
| Update MatchRecord to store allTurns snapshot | `features/profile/domain/entities/match_record.dart` | 15min |
| **Total** | | **~4h** |

---

## Phase 8 — Ranking Feature

**Goal:** ELO system, tiers, friends leaderboard, seasonal resets

| Task | Files | Est. Time |
|---|---|---|
| Create ELO calculator (pure Dart) | `features/ranking/domain/entities/elo_calculator.dart` | 30min |
| Create Friend + FriendRequest + SeasonData entities | `features/ranking/domain/entities/` | 20min |
| Create RankingRepository interface | `features/ranking/domain/repositories/ranking_repository.dart` | 15min |
| Create RankingDataSource | `features/ranking/data/datasources/ranking_datasource.dart` | 1h |
| Create DTOs (FriendRequestDto, SeasonDataDto) | `features/ranking/data/models/` | 20min |
| Create RankingRepositoryImpl | `features/ranking/data/repositories/ranking_repository_impl.dart` | 45min |
| Create ranking providers | `features/ranking/presentation/providers/ranking_providers.dart` | 30min |
| Build LeaderboardPage | `features/ranking/presentation/pages/leaderboard_page.dart` | 1h |
| Build FriendsPage | `features/ranking/presentation/pages/friends_page.dart` | 1h |
| Build AddFriendPage | `features/ranking/presentation/pages/add_friend_page.dart` | 45min |
| Update ResultPage to show ELO change | `features/game/presentation/pages/result_page.dart` | 20min |
| Update Player entity with tier/rating fields | `features/auth/domain/entities/player.dart` | 10min |
| Update MatchRecord entity with rating change | `features/profile/domain/entities/match_record.dart` | 10min |
| **Total** | | **~6h** |

---

## Phase 9 — Profile Feature

**Goal:** Player stats and match history

| Task | Files | Est. Time |
|---|---|---|
| Create MatchRecord entity | `features/profile/domain/entities/` | 10min |
| Create ProfileRepository | `features/profile/domain/repositories/` | 10min |
| Create ProfileDataSource | `features/profile/data/datasources/` | 15min |
| Create MatchRecordDto | `features/profile/data/models/` | 10min |
| Create ProfileRepositoryImpl | `features/profile/data/repositories/` | 15min |
| Create profile providers | `features/profile/presentation/providers/` | 15min |
| Build ProfilePage | `features/profile/presentation/pages/profile_page.dart` | 1h |
| **Total** | | **~2h** |

---

## Phase 10 — Shared Widgets

**Goal:** Reusable UI components

| Widget | Est. Time |
|---|---|
| `AppButton` | 15min |
| `LoadingOverlay` | 15min |
| `CategoryCard` | 20min |
| `QuestionBubble` | 15min |
| `AnswerBubble` | 15min |
| `TurnTimer` | 20min |
| `YesNoQuickButtons` | 20min |
| `OpponentInfoCard` | 15min |
| `GuessDialog` | 20min |
| `TurnHistoryList` | 20min |
| `TierBadge` | 15min |
| `RatingChangeIndicator` | 15min |
| `FriendTile` | 15min |
| `ReportButton` | 10min |
| `MyQuestionCard` | 15min |
| `OpponentQuestionCard` | 15min |
| **Total** | **~4h** |

---

## Phase 11 — Audio & Haptics

**Goal:** Sound effects and haptic feedback

| Task | Est. Time |
|---|---|
| Source or generate 8 sound effect files | 30min |
| Create AudioService singleton | 1h |
| Wire audio triggers via Riverpod provider | 30min |
| Add settings toggle (mute) | 30min |
| **Total** | **~2.5h** |

---

## Phase 12 — Firebase Security Rules

**Goal:** Production-ready security

| Task | Est. Time |
|---|---|
| Write Firestore rules | 30min |
| Write RTDB rules | 1h |
| Test rules in Firebase Console simulator | 30min |
| **Total** | **~2h** |

---

## Phase 13 — Testing

**Goal:** Unit, widget, and integration tests

| Area | Est. Time |
|---|---|
| Auth feature tests | 1h |
| Room feature tests | 1h |
| Game feature tests (core logic) | 2h |
| Widget tests for shared widgets | 1h |
| Integration test (full game flow) | 2h |
| **Total** | **~7h** |

---

## Summary

| Phase | Hours |
|---|---|---|
| 1. Firebase Setup | 1h |
| 2. Core Layer | 2h |
| 3. Auth Feature | 3h |
| 4. Lobby Feature | 3h |
| 5. Room Feature | 5h |
| 6. Game Feature | 9h |
| 7. Report Feature | 4h |
| 8. Ranking Feature | 6h |
| 9. Profile Feature | 2h |
| 10. Shared Widgets | 3h |
| 11. Audio & Haptics | 2.5h |
| 12. Security Rules | 2h |
| 13. Testing | 7h |
| **Total** | **~50h** |
