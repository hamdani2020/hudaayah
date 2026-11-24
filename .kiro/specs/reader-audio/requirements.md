# Requirements — Reader Audio (follow recitation, word highlighting, reciters)

Release: 1.2.0 (after 1.1.0). Fixes tester bug 8 and adds tester features 1 and 3.
All audio and timing data comes from Quran Foundation through the backend adapter,
cached at most one week.

## R1 The reader follows the recitation (bug 8)
- During play-all, the ayah being recited stays visible: the list scrolls smoothly so
  that ayah is on screen as each new ayah starts.
- If the learner scrolls by hand during playback, following stops and a
  **Follow recitation** button appears; tapping it scrolls back to the current ayah and
  resumes following. Following also resumes when play-all is started again.
- The audio strip's progress bar shows real progress through the lesson's audio
  (position / duration), replacing the static bar.
- Single-ayah play scrolls to that ayah only if it is off screen.

## R2 Word-by-word highlighting as the reciter speaks (feature 1)
- While audio plays (single ayah or play-all), the word being recited is highlighted in
  the Arabic line and, in the Full reading view, in its word chip.
- Highlighting follows pause, resume and loop.
- The Arabic text is rendered word by word in Quran Foundation's order with Quran
  Foundation's text; nothing is added, removed, reordered or changed.
- When the selected reciter has no word timings, audio plays normally with ayah-level
  highlighting only (the current orange outline), and a small note says "Word
  highlighting isn't available for this reciter."

## R3 Choose a reciter (feature 3)
- Profile → Settings → **Reciter** opens a list of every reciter Quran Foundation
  provides audio for (name and style, e.g. Murattal), with the current one ticked.
- Reciters with word timings are marked (so learners know which support highlighting).
- The choice is saved to the learner's account and used on any device.
- The reader shows the chosen reciter's name (no hardcoded reciter label) and the lesson
  attribution credits the reciter.
- Listening exercises use the chosen reciter as well.
- If a reciter's audio is unavailable for a lesson, the app falls back to the default
  reciter and says so.
