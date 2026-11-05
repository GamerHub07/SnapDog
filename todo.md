Fix the Streak statistics in SnapDog.

CURRENT BUG:
The streak currently increases for every completed game. For example, completing 40 games on the same day displays a 40-day streak.

EXPECTED BEHAVIOR:
A streak must count consecutive calendar days on which the player completed at least one puzzle.

### 1. Correct streak calculation

- Track unique local calendar dates on which at least one level was completed.
- Completing multiple levels on the same date must count as only ONE active day.
- Completing 40 puzzles today must result in a 1-day streak if no previous consecutive days exist.
- Completing puzzles on three consecutive dates must result in a 3-day streak.

### 2. Streak rules

Calculate the current streak using these rules:

- If the player completed at least one puzzle today, count consecutive completed dates backwards starting from today.
- If the player has not completed a puzzle today but completed one yesterday, count backwards starting from yesterday.
- If the player completed neither today nor yesterday, the current streak is 0.
- Missing a calendar day breaks the streak.
- Multiple completions on the same date never increase the streak more than once.

### 3. Date handling

- Use the device's local calendar date.
- Normalize completion timestamps to calendar dates before comparison.
- Handle month changes, year changes, leap years, and timezone changes safely.
- Do not calculate streaks using a simple difference between completion timestamps in hours.

### 4. Fix historical data

Inspect the existing persistence model.

- Derive unique completion dates from existing completion records wherever possible.
- Deduplicate multiple game completions from the same calendar date.
- Migrate existing streak data safely.
- Do not treat the old inflated streak number as a valid historical streak.
- Preserve completed-level records, puzzle progress, and other statistics.
- Do not delete game history.

### 5. Statistics consistency

Ensure all streak-related UI reads from the corrected streak calculation.

If there are separate values for:
- Current streak
- Best streak
- Completed games
- Total completed levels

Keep their meanings separate.

Best streak must also be calculated from consecutive unique completion dates, not the number of games played.

### 6. Automated tests

Add tests for:

1. One game completed today → 1-day streak.
2. 40 games completed today → 1-day streak.
3. Games completed on three consecutive days → 3-day streak.
4. Multiple games on each of three consecutive days → 3-day streak.
5. Today and yesterday completed → 2-day streak.
6. Today skipped but yesterday completed → streak calculated from yesterday.
7. Both today and yesterday skipped → 0-day current streak.
8. A missing day breaks the streak.
9. Month and year boundaries.
10. Leap-year dates.
11. Multiple timestamps on the same calendar date.
12. Best streak calculated correctly.
13. Existing historical records migrated without losing completed levels.
14. App restart preserves the correct streak.

### 7. Scope restrictions

Do not:
- Change the Home screen layout.
- Change gameplay.
- Change level progression.
- Change puzzle generation.
- Change the visual design of the statistics card.

Only fix streak calculation, persistence, migration, and related tests.

After implementation, report the files changed, migration behavior, and test results.