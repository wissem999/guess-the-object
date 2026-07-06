# Audio & Haptic Feedback

## Service Interface

```dart
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> init() async {
    // Pre-load all sound assets into cache
  }

  // ── Game Events ──────────────────────────────────────
  void playTurnChange();        // Your turn now
  void playQuestionReceived();  // Opponent asked
  void playAnswerReceived();    // Opponent answered
  void playGuessMade();         // Someone made a guess
  void playWin();               // You won!
  void playLose();              // You lost
  void playMatchFound();        // Quick match paired

  // ── UI Events ────────────────────────────────────────
  void playButtonTap();         // Generic button press
  void playRoomCreated();       // Room code generated

  // ── Haptics ──────────────────────────────────────────
  void vibrate(HapticType type);
}

enum HapticType { light, medium, heavy, selection }
```

## Trigger Points

| Event | Sound | Haptic | Trigger Provider |
|---|---|---|---|
| Turn changes to you | `turn_change.mp3` | Medium | `gameStreamWithAudioProvider` |
| New question from opponent | `question_received.mp3` | Light | `gameStreamWithAudioProvider` |
| Answer received | `answer_received.mp3` | Selection | `gameStreamWithAudioProvider` |
| Opponent makes a guess | `guess_made.mp3` | Medium | `gameStreamWithAudioProvider` |
| You win | `win.mp3` | Heavy | `gameStreamWithAudioProvider` |
| You lose | `lose.mp3` | Light | `gameStreamWithAudioProvider` |
| Match found | `match_found.mp3` | Medium | `matchmakingQueueProvider` |
| Button tap | `button_tap.mp3` | None | Via widget `onTap` wrapper |
| Room created | `room_created.mp3` | Selection | `createRoomProvider` |

## Sound Assets

Path: `assets/sounds/`

| File | Duration | Format |
|---|---|---|
| `turn_change.mp3` | ~0.5s | MP3 128kbps |
| `question_received.mp3` | ~0.3s | MP3 128kbps |
| `answer_received.mp3` | ~0.3s | MP3 128kbps |
| `guess_made.mp3` | ~0.4s | MP3 128kbps |
| `win.mp3` | ~1.5s | MP3 128kbps |
| `lose.mp3` | ~1.0s | MP3 128kbps |
| `match_found.mp3` | ~0.5s | MP3 128kbps |
| `button_tap.mp3` | ~0.1s | MP3 128kbps |

## Dependencies

```yaml
dependencies:
  audioplayers: ^6.1.0
  vibration: ^2.0.0    # or flutter_vibrate
```

## Implementation Notes

- `AudioService` is a singleton (only one player needed)
- Sound volumes: UI sounds 0.3, game event sounds 0.7
- User can mute sounds in settings (persisted with SharedPreferences)
- Vibration only on game events, not on UI interactions (except guess)
- Android: Vibration requires `<uses-permission android:name="android.permission.VIBRATE" />`
- iOS: Haptics work natively without special permissions
