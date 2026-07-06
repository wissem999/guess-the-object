# Game Flow

## State Machine

```
                    ┌──────────┐
                    │  LOGIN   │
                    └────┬─────┘
                         ▼
                    ┌──────────┐
                    │  LOBBY   │
                    │(category │
                    │  pick)   │
                    └────┬─────┘
                         │
              ┌──────────┼───────────┐
              ▼          ▼           ▼
        ┌─────────┐ ┌────────┐ ┌──────────┐
        │QUICK    │ │CREATE  │ │ JOIN     │
        │PLAY     │ │ROOM    │ │ ROOM     │
        └────┬────┘ └───┬────┘ └────┬─────┘
             │          │           │
             └──────────┼───────────┘
                        ▼
                  ┌─────────────┐
                  │ WAITING     │
                  │ ROOM        │
                  │ (both ready)│
                  └──────┬──────┘
                         ▼
                  ┌─────────────┐
                  │ PICK OBJECT │
                  │ (secret)    │
                  └──────┬──────┘
                         ▼
                  ┌─────────────┐
                  │  GAME PLAY  │◄──────────┐
                  │             │           │
                  │ Ask →      │           │
                  │ Answer →   ├───────────┘
                  │ Switch turn│  (next turn)
                  └──────┬─────┘
                         │ (player guesses)
                         ▼
                  ┌─────────────┐
                  │  CONFIRM    │
                  │  GUESS      │
                  └──────┬──────┘
                    ┌────┴────┐
                    ▼         ▼
              ┌─────────┐ ┌─────────┐
              │CORRECT  │ │ WRONG   │
              │= WIN    │ │= LOSE   │
              └────┬────┘ └────┬────┘
                   │           │
                   ▼           ▼
              ┌──────────────────────┐
              │      RESULT SCREEN    │
              │   (Win / Lose)        │
              │   [Rematch] [Lobby]   │
              └──────────────────────┘
```

## Complete Turn Sequence

```
Step 1: Player A's turn
  - A sees:
    - **My Questions** section: all questions A asked + B's answers
    - **Opponent's Questions** section: all questions B asked + A's answers
    - Text input field + yes/no quick buttons
  - A types question: "Is it bigger than a car?"
  - A submits → RTDB write → stream updates

Step 2: Player B answers
  - B sees: incoming question, text input + yes/no buttons
  - B sees same split turn history (filtered for B's perspective)
  - B answers: "No"
  - B submits → RTDB write → stream updates

Step 3: Turn switches to Player B
  - B's turn to ask
  - Same loop...

**At any point during own turn, player can "Make a Guess"**

**Split Turn History Design:**
- The game page shows two visually separate sections
- Section 1 "Your Questions": shows only turns where current user asked (helps remember gathered intel)
- Section 2 "Their Questions": shows only turns where opponent asked (helps track what they know)
- Each card shows question and its answer together
```

## Guess Flow

```
Step 1: Player A clicks "Make a Guess"
  - Dialog opens: "Type the object you think B has"
  - A types "Pizza" and confirms
  - Phase changes to "guessing"

Step 2: Player B notified
  - B sees: "A thinks your object is Pizza"
  - Two buttons: "Correct ✓" or "Wrong ✗"

Step 3a: B clicks Correct
  - Winner = A, Loser = B
  - Phase → "finished"

Step 3b: B clicks Wrong
  - Winner = B, Loser = A
  - Phase → "finished"
```

## Edge Cases

| Scenario | Handling |
|---|---|
| **Player disconnects mid-game** | RTDB presence detects. Show "opponent disconnected" dialog. Game saved, can resume if reconnect within 60s. |
| **Both guess simultaneously** | First guess in RTDB wins. Second guess rejected (phase already changed). |
| **Turn timeout (30s inactivity)** | Countdown timer per turn. Timeout → current player auto-passes turn. 3 timeouts = forfeit. |
| **Player leaves result screen** | Match history saved in Firestore. Result screen shows from history on re-open. |
| **Room code invalid** | Show error "Room not found". Return to lobby. |
| **Room full (guest already joined)** | Show error "Room is full". |
| **Matchmaking no opponent found** | Show estimated wait time. Optional "Cancel" button. |
