# SudoSodoku v2.0.0

```
$ sudo solve
> root access granted.
```

**sudo solve — root access for logical purists.**

v2.0.0 is the release where SudoSodoku becomes what it always wanted to be: a full terminal fantasy with a real competitive ladder.

## The Ladder goes live 🏆

- **Game Center leaderboards**: a global ELO ranking plus fastest-time boards for every difficulty. Scores are performance — solve time and rating — never spending.
- **Twelve achievements**, from `HELLO_WORLD` to `THE_ARCHITECT`, including one secret. Unlocks are celebrated inside the victory sequence with glowing badges.

## Every puzzle now reads as hand-crafted ✍️

- Clue patterns follow varied aesthetic styles — rotational, mirror, diagonal, or deliberately free — like a well-edited puzzle book.
- Every difficulty has a technique identity: EASY always offers parallel simple moves and can never dead-end you; HARD is designed around a fair intermediate "aha" and never requires guessing; MASTER resists intermediate techniques entirely.
- Generation stays instant (≤10ms) behind the new breach-log loading screen.

## The feel pass 🎛️

- A semantic haptic vocabulary: mechanical key-press placements, error notifications, unit-completion pulses, and a custom victory rumble.
- Signature moments: the typewriter breach log, a three-act victory sequence with real matrix rain and an ELO ticker, phosphor pulses on completed units, a quiet streak counter — and a one-time surprise for your first MASTER game.
- An optional play clock that only counts active time; personal bests and archives show durations.
- Every animation respects Reduce Motion. Sounds are never forced on.

## Fixed

- EASY boards can no longer stall you: the grader now understands column/box logic, clue distribution is guaranteed, and every step offers at least two ways forward.
- Profile statistics stay in lockstep with your archive (previously they lagged by one change).

---

**Requirements:** iOS 17.0+, iPhone only. Internet optional (Game Center).
Full details in [CHANGELOG.md](CHANGELOG.md).
