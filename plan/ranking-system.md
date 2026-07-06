# Ranking System

## ELO Calculation

Standard ELO with K-factor for fair rating adjustments.

### Formula

```
Expected Score:  Ea = 1 / (1 + 10^((Rb - Ra) / 400))
New Rating:      Ra' = Ra + K * (Sa - Ea)

Where:
  Ra = current rating of player A
  Rb = current rating of player B
  Sa = 1 if A wins, 0 if A loses
  K  = 32 (K-factor)
```

### Example

- Player A rating: 1200, Player B rating: 1000
- Ea = 1 / (1 + 10^((1000 - 1200) / 400)) = 1 / (1 + 10^(-0.5)) = 0.76
- If A wins: A = 1200 + 32 * (1 - 0.76) = 1208 (+8), B = 1000 + 32 * (0 - 0.24) = 992 (-8)
- If B wins: A = 1200 + 32 * (0 - 0.76) = 1176 (-24), B = 1000 + 32 * (1 - 0.24) = 1024 (+24)

Lower-rated player gains more for upset win. Higher-rated player gains less for expected win.

---

## Tiers

| Tier | Rating Range | Badge |
|---|---|---|
| Bronze | 0 – 999 | 🥉 Bronze |
| Silver | 1000 – 1399 | 🥈 Silver |
| Gold | 1400 – 1699 | 🥇 Gold |
| Platinum | 1700 – 1999 | 💎 Platinum |
| Diamond | 2000 – 2299 | 👑 Diamond |
| Legend | 2300+ | 🏆 Legend |

---

## Weekly Seasons

- **Start:** Monday 00:00 UTC
- **End:** Sunday 23:59 UTC
- **Season reset:** Rating = 1000 + (peakRating - 1000) * 0.3  (30% of gains retained)
- **Season history:** Stored in Firestore `/seasons/{seasonId}`
- **Season rewards:** Badge based on highest tier achieved that season

### Season Document Structure

```
/seasons/{seasonId}/
├── startDate: Timestamp
├── endDate: Timestamp
├── seasonNumber: 42
├── participants: {
│     "userId": {
│       "peakRating": 1850,
│       "finalRating": 1720,
│       "peakTier": "Platinum",
│       "gamesPlayed": 47,
│       "wins": 28,
│       "losses": 19
│     }
│   }
```

---

## Friends System

### Friend Request Flow

```
Player A searches for Player B by name/email
  → A sends friend request
  → B receives notification
  → B accepts → both added to friends list
  → B rejects → request deleted
```

### Firestore Structure

```
/friendRequests/{requestId}/
├── fromId: "uidA"
├── toId: "uidB"
├── status: "pending" | "accepted" | "rejected"
├── createdAt: Timestamp

/ friendships/{userId}/
  └── friendIds: { "uidB": true, "uidC": true }
```

### Friends-Only Leaderboard

Leaderboard shows ranking of the current player's friends. Queried by:
1. Get current user's friend IDs from `/friendships/{userId}/friendIds`
2. Query `/users/{id}` for each friend to get name + rating + tier
3. Sort by rating descending

---

## ELO Update Flow (Server-side)

ELO must be calculated **server-side** via Firebase Cloud Function to prevent cheating:

```
Match ends → Cloud Function trigger onCreate(/matches/{matchId})
  → Read match data (player1Id, player2Id, winnerId)
  → Read both players' current ratings from /users/{id}.rating
  → Calculate new ratings with ELO formula
  → Update both players' ratings in Firestore
  → Update season participant data
  → Check for tier promotion → trigger notification
```

During development/MVP, ELO can be calculated on the client with Firestore security rules preventing manual rating edits. Cloud Function is added later for production.

---

## Ranking Display in UI

| Screen | What Shows |
|---|---|
| **Lobby** | Current rating + tier badge next to avatar |
| **Result** | Rating change (+12 / -24) with tier badge animation |
| **Opponent Card** | Opponent's tier badge + rating during game |
| **Leaderboard** | Friends sorting: rating, name, tier, win rate |
| **Profile** | Season peak tier, current rating, tier history |
| **Match History** | Old rating → new rating, tier change indicator |
