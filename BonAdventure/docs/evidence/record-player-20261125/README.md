# Record player — 25 November 2026

User request: a record player on a stand next to the TV that plays the game's background
music, lets the player choose any song and switch songs, shows a turning disc, and can be left.
Built as the [record player component](../../guides/COMPONENTS.md#record-player) and placed in
the home's living room (home step `record_player`).

| File | What |
| --- | --- |
| `verify.gd` | Placement beside the media console, the interactable, the panel (every song, play, ◀ / ▶, stop and play again, ✕), the disc turning and stopping, the arm on and off the record, the card fitting a 1200 × 800 and an 844 × 390 window. Renders the views below. |
| `room.png` | The stand beside the TV console |
| `closeup.png` | The close-up just after picking Mystery Night (green row, purple label) |
| `closeup_stopped.png` | After the green button: stopped, arm at rest, "Pick a song" |
| `phone.png` | The same at 844 × 390 (landscape phone) |

Run (window, isolated HOME, home unit loaded):

```
HOME=<scratch>/home VT_FOCUS=home VT_SPAWN=none godot --path . --resolution 1200x800 --script res://docs/evidence/record-player-20261125/verify.gd
```

Music never plays in a check (`sound.gd`), so the check covers the panel, `sound.gd`
`town_track` and the turntable, not the audio itself. Not play-tested by hand.

Result 25 Nov 2026: 46 PASS, 0 FAIL (`RECORD PLAYER: 0 failures`), home unit only (VT_FOCUS=home,
not the full town). Godot's own exit code was 137 after the check had printed its result and
called quit(); other Godot runs were sharing the machine. An earlier run hung waiting for a
frame to draw, so `shot()` no longer waits on `frame_post_draw`.
