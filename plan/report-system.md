# Report System

## Purpose

Allow players to report unfair behavior: intentional wrong answers, bad language, cheating, or any other violation. Admin can review reports with full match data (all questions + answers) and take action.

---

## Report Reasons

| Reason | Description |
|---|---|
| `intentional_wrong_answer` | Opponent deliberately answers incorrectly to make you lose |
| `bad_words` | Opponent uses offensive/hateful language in answers |
| `cheating` | Suspicious behavior, bot-like play |
| `other` | Custom description |

---

## Firestore Schema

### `/reports/{reportId}`

```json
{
  "reporterId": "uidA",
  "reportedPlayerId": "uidB",
  "matchId": "match_abc123",
  "categoryId": "animals",
  "reason": "intentional_wrong_answer",
  "description": "Player B answered 'No' to 'Is it edible?' even though it was Pizza. Clearly intentional.",
  "matchSnapshot": {
    "player1Id": "uidA",
    "player2Id": "uidB",
    "p1ObjectId": "rock",
    "p2ObjectId": "pizza",
    "turns": {
      "turn_0": {
        "playerId": "uidA",
        "question": "Is it edible?",
        "answer": "No",
        "timestamp": 1712345678901
      }
    }
  },
  "status": "pending",
  "adminNote": "",
  "createdAt": Timestamp(2026, 7, 6),
  "reviewedAt": null
}
```

**Security:** 
- Create: any authenticated user (reporterId must match auth.uid)
- Read: reporter (own reports) + admin (all)
- Update status: admin only

---

## Flow

```
Match ends → ResultScreen shows "Report Player" button
  → Player taps Report
  → Pre-filled reason picker + description field
  → Submit → Firestore write:
       - report document created
       - matchSnapshot copied from match record (all turns)
  → Admin notification (via Cloud Function or manual check)

Admin opens report list:
  → Sees: reporter, reported player, reason, date
  → Taps to expand: full match snapshot with ALL turns
  → Can see exactly who said what, in order
  → Actions: Dismiss (with note) or Ban player
```

---

## Admin Actions

| Action | Effect |
|---|---|
| **Dismiss** | Report marked `reviewed`. Reported player unaffected. |
| **Ban Player** | `player.isBanned = true` in Firestore. Auth disabled on next login. |

---

## Split Turn History (Game Page)

During the game, the turn history is split into two clear sections:

### "Your Questions" Section
Shows:
```
Q: Is it bigger than a car?   ← you asked
A: Yes                         ← opponent answered
---
Q: Is it edible?               ← you asked
A: No                          ← opponent answered
```

### "Opponent's Questions" Section
Shows:
```
Q: Is it made of metal?        ← opponent asked
A: No                          ← you answered
---
Q: Can you hold it?            ← opponent asked
A: Yes                         ← you answered
```

**Purpose:** Player can easily track what they've learned about the opponent's object, without mixing up their own questions with the opponent's.

**Implementation:** The `GamePage` filters `GameState.turns` by `playerId` to create two separate lists.

---

## Report Entity (Domain)

```dart
class Report {
  final String id;
  final String reporterId;
  final String reportedPlayerId;
  final String matchId;
  final String categoryId;
  final String reason;
  final String description;
  final Map<String, dynamic>? matchSnapshot;
  final ReportStatus status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;
}

enum ReportStatus { pending, reviewed, dismissed }
```

## ReportRepository Interface

```dart
abstract class ReportRepository {
  Future<void> submitReport(Report report);
  Future<List<Report>> getMyReports(String userId);
  // Admin only:
  Future<List<Report>> getAllReports();
  Future<void> updateReportStatus(
    String reportId, 
    ReportStatus status, 
    String? adminNote,
  );
  Future<Map<String, dynamic>> getMatchDetail(String matchId);
}
```
