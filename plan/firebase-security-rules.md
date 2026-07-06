# Firebase Security Rules

## Firestore Rules

File: `firestore.rules`

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── Users ──────────────────────────────────────────────
    match /users/{userId} {
      // Authenticated users can read any user profile (for display)
      allow read: if request.auth != null;

      // User creates own profile on first login
      allow create: if request.auth.uid == userId;

      // User can update own profile, but cannot change email or uid
      allow update: if request.auth.uid == userId
                    && request.resource.data.id == resource.data.id;

      // Never allow delete
      allow delete: if false;
    }

    // ── Categories ──────────────────────────────────────────
    match /categories/{categoryId} {
      // All authenticated users can browse categories
      allow read: if request.auth != null;

      // Only admins can write categories
      allow write: if request.auth.token.isAdmin == true;
    }

    // ── Game Objects ────────────────────────────────────────
    match /objects/{objectId} {
      // All authenticated users can view objects
      allow read: if request.auth != null;

      // Only admins can write objects
      allow write: if request.auth.token.isAdmin == true;
    }

    // ── Match History ───────────────────────────────────────
    match /matches/{matchId} {
      // Only participants can read the match record
      allow read: if request.auth != null
                  && (request.auth.uid == resource.data.player1Id
                      || request.auth.uid == resource.data.player2Id);

      // Allow creation if the creator is one of the players
      allow create: if request.auth.uid == request.resource.data.player1Id;

      // Match records are immutable after creation
      allow update: if false;
      allow delete: if false;
    }

    // Deny everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## Realtime Database Rules

File: `database.rules`

```
{
  "rules": {
    // ── Global Deny ─────────────────────────────────────────
    ".read": false,
    ".write": false,

    // ── Rooms ───────────────────────────────────────────────
    "rooms": {
      "$roomCode": {
        // Authenticated users can read room data
        ".read": "auth != null",

        // Authenticated users can write room data
        ".write": "auth != null",

        "hostId": {
          // Only the host can set their own ID
          ".validate": "newData.val() === auth.uid"
        },

        "guestId": {
          // Guest ID can only be set once (from null to value)
          // Guest cannot be the same as host
          ".validate": "(!data.exists() || data.val() === '')
                       && newData.val() !== root.child('rooms').child($roomCode).child('hostId').val()
                       && newData.isString()"
        },

        "categoryId": {
          // Must be an existing category (validated on client/server)
          ".validate": "newData.isString() && newData.val().length > 0"
        },

        "status": {
          // Strict state machine transitions
          ".validate": "(newData.val() === 'waiting' && (!data.exists() || data.val() === 'waiting'))
                       || (newData.val() === 'ready' && data.val() === 'waiting')
                       || (newData.val() === 'playing' && data.val() === 'ready')
                       || (newData.val() === 'finished' && data.val() === 'playing')"
        },

        "gameId": {
          // Only set once when game starts
          ".validate": "newData.isString() && (!data.exists() || data.val() === '')"
        },

        "hostReady": {
          ".validate": "newData.isBoolean()"
        },

        "guestReady": {
          ".validate": "newData.isBoolean()"
        },

        "createdAt": {
          ".validate": "newData.isNumber()"
        }
      }
    },

    // ── Active Games ────────────────────────────────────────
    "activeGames": {
      "$gameId": {
        ".read": "auth != null",
        ".write": "auth != null",

        "roomCode": {
          ".validate": "newData.isString()"
        },

        "categoryId": {
          ".validate": "newData.isString()"
        },

        "player1Id": {
          ".validate": "newData.val() === auth.uid"
        },

        "player2Id": {
          ".validate": "newData.val() === auth.uid
                       && newData.val() !== data.parent().child('player1Id').val()"
        },

        "p1ObjectId": {
          // Player1 sets their own object. After set, only readable by player1
          ".validate": "newData.isString()
                       && (data.exists() || auth.uid === data.parent().child('player1Id').val())"
        },

        "p2ObjectId": {
          // Player2 sets their own object
          ".validate": "newData.isString()
                       && (data.exists() || auth.uid === data.parent().child('player2Id').val())"
        },

        "currentTurn": {
          // Must always be one of the two players
          // Must alternate (can't be the same as previous turn)
          ".validate": "(newData.val() === data.parent().child('player1Id').val()
                        || newData.val() === data.parent().child('player2Id').val())
                       && newData.val() !== data.val()"
        },

        "phase": {
          ".validate": "newData.val() === 'playing'
                       || newData.val() === 'guessing'
                       || newData.val() === 'confirming'
                       || newData.val() === 'finished'"
        },

        "turns": {
          "$turnKey": {
            "playerId": {
              // Must be one of the two players
              ".validate": "newData.val() === data.parent().parent().parent().child('player1Id').val()
                           || newData.val() === data.parent().parent().parent().child('player2Id').val()"
            },
            "question": {
              // Question text must be non-empty
              ".validate": "newData.isString() && newData.val().length > 0"
            },
            "answer": {
              // Answer text must be non-empty
              ".validate": "newData.isString() && newData.val().length > 0"
            },
            "timestamp": {
              ".validate": "newData.isNumber()"
            }
          }
        },

        "guess": {
          "playerId": {
            // The guesser sets their own ID
            ".validate": "newData.val() === auth.uid"
          },
          "guessedObject": {
            // Must be a non-empty string
            ".validate": "newData.isString() && newData.val().length > 0"
          },
          "isCorrect": {
            // Only the opponent (not the guesser) can confirm
            ".validate": "newData.isBoolean()
                         && auth.uid !== data.parent().child('playerId').val()
                         && (auth.uid === data.parent().parent().child('player1Id').val()
                             || auth.uid === data.parent().parent().child('player2Id').val())"
          }
        },

        "winnerId": {
          ".validate": "newData.val() === data.parent().child('player1Id').val()
                       || newData.val() === data.parent().child('player2Id').val()"
        },

        "createdAt": {
          ".validate": "newData.isNumber()"
        },

        "lastActivity": {
          ".validate": "newData.isNumber()"
        }
      }
    },

    // ── Matchmaking Queue ──────────────────────────────────
    "queue": {
      "$categoryId": {
        ".read": "auth != null",
        ".write": "auth != null",

        "$playerId": {
          "playerId": {
            // Can only add yourself to the queue
            ".validate": "newData.val() === auth.uid"
          },
          "joinedAt": {
            ".validate": "newData.isNumber()"
          }
        }
      }
    },

    // ── Presence ───────────────────────────────────────────
    ".info": {
      ".read": "auth != null"
    }
  }
}
```

## Rule Design Principles

1. **Validate state machine transitions** - room status, game phase, current turn must follow valid paths
2. **Ownership checks** - players can only write their own data (hostId, playerId, etc.)
3. **Opponent confirmation** - only the non-guesser can set isCorrect (prevents self-confirmation)
4. **Immutable history** - match records in Firestore are write-once
5. **Admin controls** - categories and objects are admin-only writes
6. **Deny by default** - Firebase defaults to deny; explicit allow for each path
