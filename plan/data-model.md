# Firebase Data Model

## Firestore Collections

### `/users/{userId}`

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "photoUrl": "https://...",
  "wins": 12,
  "losses": 5,
  "rating": 1245,
  "peakRating": 1320,
  "tier": "Silver",
  "seasonWins": 4,
  "seasonLosses": 2,
  "createdAt": Timestamp(2026, 7, 1)
}
```

**Security:** Owner read/write. Admin write only.

### `/categories/{categoryId}`

```json
{
  "name": "Animals",
  "iconUrl": "assets/icons/animals.png",
  "description": "From pets to wild beasts",
  "order": 1
}
```

**Security:** All authenticated users read. Admin write.

### `/objects/{objectId}`

```json
{
  "name": "Elephant",
  "categoryId": "animals",
  "hints": ["Very large", "Has a trunk", "Grey color"]
}
```

**Security:** All authenticated users read. Admin write.

### `/matches/{matchId}`

```json
{
  "player1Id": "uid1",
  "player2Id": "uid2",
  "categoryId": "animals",
  "winnerId": "uid1",
  "loserId": "uid2",
  "totalTurns": 8,
  "player1RatingBefore": 1200,
  "player2RatingBefore": 1100,
  "player1RatingAfter": 1208,
  "player2RatingAfter": 1092,
  "allTurns": [
    {
      "playerId": "uid1",
      "question": "Is it bigger than a car?",
      "answer": "Yes",
      "timestamp": 1712345678901
    }
  ],
  "createdAt": Timestamp(2026, 7, 6),
  "endedAt": Timestamp(2026, 7, 6)
}
```

**Security:** Participants only read. Created by participants. Immutable after creation.
**Note:** `allTurns` is copied from RTDB game data when match ends, so admins can review reported games even after RTDB cleanup.

---

### `/friendRequests/{requestId}`

```json
{
  "fromId": "uidA",
  "toId": "uidB",
  "status": "pending | accepted | rejected",
  "createdAt": Timestamp(2026, 7, 6)
}
```

### `/friendships/{userId}`

```json
{
  "friendIds": {
    "uidB": true,
    "uidC": true
  }
}
```

### `/reports/{reportId}`

```json
{
  "reporterId": "uidA",
  "reportedPlayerId": "uidB",
  "matchId": "match123",
  "categoryId": "animals",
  "reason": "intentional_wrong_answer | bad_words | cheating | other",
  "description": "Player B kept answering 'Yes' to everything even when wrong",
  "matchSnapshot": { ... },     // copy of match data + all turns
  "status": "pending | reviewed | dismissed",
  "adminNote": "",
  "createdAt": Timestamp(2026, 7, 6),
  "reviewedAt": null
}
```

**Security:** All authenticated users can create. Admins only can read/update status.

---

### `/seasons/{seasonId}`

```json
{
  "seasonNumber": 42,
  "startDate": Timestamp(2026, 7, 6),
  "endDate": Timestamp(2026, 7, 13),
  "participants": {
    "uid1": {
      "peakRating": 1850,
      "finalRating": 1720,
      "peakTier": "Platinum",
      "gamesPlayed": 47,
      "wins": 28,
      "losses": 19
    }
  }
}
```

---

## Realtime Database Paths

### `/rooms/{roomCode}`

```json
{
  "hostId": "uid1",
  "guestId": "uid2",
  "categoryId": "animals",
  "status": "waiting | ready | playing | finished",
  "gameId": "gameIdValue",
  "hostReady": false,
  "guestReady": false,
  "createdAt": 1712345678901
}
```

**Path:** 6-char alphanumeric code (16M+ combinations).

### `/activeGames/{gameId}`

```json
{
  "roomCode": "ABC123",
  "categoryId": "animals",
  "player1Id": "uid1",
  "player2Id": "uid2",
  "p1ObjectId": "elephant",
  "p2ObjectId": "pizza",
  "currentTurn": "uid1",
  "phase": "playing | guessing | confirming | finished",
  "turns": {
    "turn_0": {
      "playerId": "uid1",
      "question": "Is it bigger than a car?",
      "answer": "Yes",
      "timestamp": 1712345678901
    }
  },
  "guess": {
    "playerId": "uid2",
    "guessedObject": "Elephant",
    "isCorrect": true
  },
  "winnerId": "uid2",
  "createdAt": 1712345678901,
  "lastActivity": 1712345678901
}
```

### `/queue/{categoryId}`

```json
{
  "queueId1": {
    "playerId": "uid1",
    "joinedAt": 1712345678901
  }
}
```

Used for quick play matchmaking. Player A adds entry → listens for match via `onChildAdded`. Player B added → both notified, room created, queue entries removed.
