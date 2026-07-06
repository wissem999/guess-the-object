# Use Case Diagram

## Actors

| Actor | Type | Description |
|---|---|---|
| **Player** | Primary | Human user of the mobile app |
| **Admin** | Primary | App moderator who reviews player reports |
| **Google Auth Provider** | Secondary | External auth system for Google sign-in |
| **Game Timer** | Secondary | System actor that enforces turn timeouts |

---

## Use Cases by Package

### 1. Auth Feature

| UC# | Name | Description |
|---|---|---|
| UC-01 | **Login with Google** | Player taps Google button → OAuth flow → Firebase Auth → profile created if new |
| UC-02 | **Login with Email/Password** | Player enters email + password → Firebase Auth Email/Password |
| UC-03 | **Register with Email** | Player creates account with email + password |
| UC-04 | **Logout** | Player signs out → redirect to login screen |
| UC-05 | **View Profile** | Player views their name, photo, stats |

**Includes:** UC-01 and UC-02 both include "Authenticate with Firebase"
**Extends:** UC-04 extends UC-01/02 (must be logged in to log out)

### 2. Lobby Feature

| UC# | Name | Description |
|---|---|---|
| UC-06 | **Browse Categories** | Player sees list of available game categories |
| UC-07 | **Select Category** | Player taps a category to enter room creation/joining flow |
| UC-08 | **Quick Play** | Player enters matchmaking queue; auto-matched with waiting opponent |
| UC-09 | **Create Room** | Player generates a 6-char room code to share with a friend |
| UC-10 | **Join Room** | Player enters a 6-char code to join a friend's room |

**Includes:** UC-07 is included by UC-08, UC-09, UC-10 (all need category selected first)

### 3. Room Feature

| UC# | Name | Description |
|---|---|---|
| UC-11 | **Wait for Opponent** | Player sees waiting screen until opponent joins |
| UC-12 | **Share Room Code** | Player copies code and shares via system share sheet |
| UC-13 | **Cancel Room** | Host cancels the room before game starts |
| UC-14 | **Pick Secret Object** | Each player selects their object from category pool (hidden from opponent) |
| UC-15 | **Confirm Ready** | Player confirms they've picked their object → both ready starts game |

**Extends:** UC-11 is extended by UC-13 (can cancel while waiting)

### 4. Game Feature

| UC# | Name | Description |
|---|---|---|
| UC-16 | **Ask Question** | Current turn player types a question about opponent's object |
| UC-17 | **Quick Yes/No Answer** | Answerer taps Yes or No button instead of typing |
| UC-18 | **Type Free-Text Answer** | Answerer types a custom response |
| UC-19 | **View My Turn History** | Player sees own questions + opponent's answers in one section, opponent's questions + own answers in another |
| UC-20 | **Make a Guess** | Player announces what they think opponent's object is |
| UC-21 | **Confirm Guess (Correct)** | Opponent confirms guess is correct → guesser wins |
| UC-22 | **Deny Guess (Wrong)** | Opponent says guess is wrong → guesser loses |
| UC-23 | **View Result** | Both players see win/lose screen with stats |

**Includes:** UC-20 includes UC-21/22 (guess triggers confirmation)
**Extends:** UC-16 extends "View My Turn History" (can see split history while asking)

### 7. Report Feature

| UC# | Name | Description |
|---|---|---|
| UC-34 | **Report Player** | Player submits a report against opponent after match with reason + description |
| UC-35 | **View My Reports** | Player sees status of reports they submitted |
| UC-36 | **Review Reports (Admin)** | Admin views all pending reports with full match data |
| UC-37 | **Dismiss Report (Admin)** | Admin marks report as dismissed with optional note |
| UC-38 | **Ban Player (Admin)** | Admin bans a player for repeated violations |

**Extends:** UC-34 extends UC-23 (report button on result screen)

### 5. Post-Game Feature

| UC# | Name | Description |
|---|---|---|
| UC-24 | **Rematch** | Both players play again with same opponent, new objects same category |
| UC-25 | **Return to Lobby** | Player goes back to category selection |
| UC-26 | **View Match History** | Player sees past matches in their profile |

### 6. Ranking Feature

| UC# | Name | Description |
|---|---|---|
| UC-27 | **View Friends Leaderboard** | Player sees friends sorted by ELO rating |
| UC-28 | **Search for Friend** | Player searches other users by name/email |
| UC-29 | **Send Friend Request** | Player sends a friend request to another user |
| UC-30 | **Accept Friend Request** | Player accepts incoming friend request |
| UC-31 | **Reject Friend Request** | Player rejects incoming friend request |
| UC-32 | **View Current Season Stats** | Player sees their weekly season performance |
| UC-33 | **View Rating Change** | Player sees ELO change (+/-) after each match |

**Includes:** UC-33 is included by UC-23 (View Result always shows rating change)

---

## Relationships Summary

```
                    ┌──────────┐
                    │  Player  │
                    └────┬─────┘
                         │
         ┌───────────────┼───────────────────┐
         │               │                   │
    ┌────▼────┐   ┌──────▼──────┐   ┌───────▼────────┐
    │ UC-01   │   │ UC-02       │   │ UC-08          │
    │ Google  │   │ Email Login │   │ Quick Play     │
    │ Login   │   │             │   │                │
    └────┬────┘   └──────┬──────┘   └───────┬────────┘
         │               │                  │
         └───────┬───────┘                  │
                 │ <<include>>              │
           ┌─────▼──────┐          ┌────────▼────────┐
           │UC-Auth     │          │ UC-07           │
           │Authenticate │          │ Select Category │
           └────────────┘          └────────┬────────┘
                                            │
                           ┌────────────────┼────────────────┐
                           │                │                │
                    ┌──────▼──────┐  ┌──────▼──────┐  ┌─────▼──────┐
                    │ UC-09       │  │ UC-10       │  │ UC-08      │
                    │ Create Room │  │ Join Room   │  │ Quick Play │
                    └──────┬──────┘  └──────┬──────┘  └─────┬──────┘
                           │                │                │
                           └────────────────┼────────────────┘
                                            │
                                     ┌──────▼──────┐
                                     │ UC-11       │
                                     │ Wait for    │
                                     │ Opponent    │
                                     └──────┬──────┘
                                            │
                                     ┌──────▼──────┐
                                     │ UC-14       │
                                     │ Pick Object │
                                     └──────┬──────┘
                                            │
                                     ┌──────▼──────┐
                                     │ UC-15       │
                                     │ Ready       │
                                     └──────┬──────┘
                                            │
                                     ┌──────▼──────────────────┐
                                     │ ┌──────────────────────┐ │
                                     │ │    GAME LOOP         │ │
                                     │ │                      │ │
                                     │ │  UC-16 → UC-18      │ │
                                     │ │  Ask → Answer →     │ │
                                     │ │  Switch Turn        │ │
                                     │ │                      │ │
                                     │ │  UC-20 → UC-21/22   │ │
                                     │ │  Guess → Confirm    │ │
                                     │ └──────────────────────┘ │
                                     └──────────┬───────────────┘
                                                │
                                         ┌──────▼──────┐
                                         │ UC-23       │
                                         │ View Result │
                                         └──────┬──────┘
                                     ┌──────────┴──────────┐
                                     │                     │
                              ┌──────▼──────┐      ┌──────▼──────┐
                              │ UC-24       │      │ UC-25       │
                              │ Rematch     │      │ Go to Lobby │
                               └─────────────┘      └─────────────┘
                                                │
                                         ┌──────▼──────┐
                                         │ UC-27       │
                                         │ Leaderboard │
                                         └──────┬──────┘
                                                │
                                         ┌──────▼──────┐
                                         │ UC-28/29/30 │
                                         │ Friend Mgmt │
                                         └──────┬──────┘
                                                │
                                         ┌──────▼──────┐
                                         │ UC-32       │
                                         │ Season Stats│
                                         └─────────────┘
```
