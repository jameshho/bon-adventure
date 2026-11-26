# Spoken words

Every word in the game will be spoken in the language being learned (and the others), from clips
made once with Amazon Polly text-to-speech. Started 24 Nov 2026 (user).

## Status (24 Nov 2026)

- **Built:** the voice settings, the runtime lookup (`say_word`), the manifest of what to say,
  the Polly generator and **every word's clip**: 799 words × Spanish, Chinese and English, 2,397
  clips in `audio/voice/<lang>/`, imported (made 24 Nov 2026 after the user approved the samples).
- **Switched on** (user, 24 Nov 2026: "ok switch it on"): `data/sounds.json` `"voice":
  {"enabled": true}`. Words are said only when the player taps the speaker. Set it to false to
  silence every word: `say_word()` then plays nothing and `has_voice()` is false.
- **Where words are said** (user, 24 Nov 2026): a **speaker button** at the top left of the
  word card, opposite the star (`vocabulary_hud.gd` `speaker_button`, pastel `speaker` icon). It
  says the word in the language being learned, and shows only when spoken words are on and the
  word has a clip. Since 24 Nov 2026 (user: "there should be a speak icon on the word journal")
  the journal has one too: a speaker column at the end of every row and a speaker beside the
  star in the word's detail view (`vocabulary_book.gd` `SPEAKER_CELL`, `detail_speaker`; the
  column is left out while spoken words are off). Not on the results card yet.
  Phrases and dialogue lines are not built; words only.
- **Volume:** Settings has Main volume, Music, Sound effects and Spoken words sliders (user,
  24 Nov 2026; `game_settings.gd` `VOLUME_BUSES`, saved per profile). Spoken words sets the Voice
  bus. The Music slider sets the Music bus, which plays the demo background music (below).
- **Web audio** (user, 24 Nov 2026: the tab always showed a speaker icon). Godot keeps its
  AudioContext running and sends silence. The Web preset's head script keeps every AudioContext
  suspended and lets Godot's own `resume()` through only while `window.bonAudioWanted` is true.
  `sound.gd` sets that flag and resumes just before a sound plays, then suspends again within
  about 0.5 s of the last sound ending. Every game sound goes through `sound.gd`, so a new sound
  must too.

## Background music (25 Nov 2026)

User, 25 Nov 2026: "add a lofi BGM just for the demo for now", then "add a different soundtrack
for loading screen", then "there should be different songs for different activity" (the user
chose five mood tracks shared by the games, not one per game). **Built:** seven looping demo
tracks on the Music bus: the loading screen, the town, and one per minigame mood.

| Track | Feel | Plays | Loop |
| --- | --- | --- | --- |
| `loading` | dreamy music box, brushes, soft echo (A, 56 BPM) | loading screens | 34.3 s |
| `town` | calm lofi: electric piano, boom-bap (F, 72 BPM) | walking around | 53.3 s |
| `quiz` | upbeat: keyboard stabs, octave bass, marimba hook, claps (D, 104 BPM) | Desk Dash, Who's Who?, Flight Finder, Next, Please!, On the Menu | 36.9 s |
| `errands` | cozy shopping jazz: walking bass, vibes, swung brushes (Bb, 92 BPM) | Grocery Run, Stack & Pack, Library Helper | 41.7 s |
| `mystery` | sneaky: pizzicato, woodblock, falling bass, soft pad (A minor, 92 BPM) | Spot the Suspect, Feel the Clues, Mystery Doors | 41.7 s |
| `focus` | calm puzzles: slow soft chords, a few bells, quiet shaker (D, 60 BPM) | Wire It Up!, Radar Patrol (Mahjong Club until 25 Nov) | 64.0 s |
| `outdoors` | playful: ukulele strum, oom-pah bass, hopping marimba (F, 108 BPM) | Feeding Time! | 35.6 s |
| `mahjong` | energetic tea-house groove: off-beat stabs, driving bass, pentatonic marimba riff, four-on-the-floor kick, claps, woodblock (D pentatonic, 124 BPM; user 25 Nov: "more energizing", picked by ear: the marimba take at the slower tempo) | Mahjong Club | 31.0 s |

- **Files:** `audio/music/<track>_lofi_demo.wav`, original music synthesised by
  `tools/make_lofi_demo.py` (pure Python, no samples or third-party material; one `TRACKS` entry
  and one arrangement function per style). Mono 44.1 kHz; note tails, echoes and filters wrap
  around the loop, so the seam is smooth. Imported as QOA forward loops: about 5.5 MB in the
  pack for all seven (0.61–1.14 MB each).
- **Clean sound** (25 Nov 2026, user: "a little grainy and fuzzy, with some radio-like background
  static. fix it please"). The first takes had vinyl hiss and crackle (the "static"), notes cut
  off while still sounding (hundreds of tiny clicks: the grain), 22.05 kHz with raw white-noise
  hi-hats and claps (gritty), a tanh soft clip on the loudest hits and a heavy low-pass (muffled,
  radio-like). Now: no hiss or crackle; every note fades out over its last 12 ms (`FADE`);
  44.1 kHz; hats are 5–11 kHz and claps 0.9–3.5 kHz band noise; plain normalising to −3 dBFS
  with the DC offset removed; low-pass cutoffs about doubled (town 5.5 kHz, loading 4.5,
  quiz 8, errands 6.5, mystery 6, focus 5, outdoors 8; drums 9–10 kHz). The largest
  sample-to-sample step fell from up to 0.64 to 0.04–0.35 of full scale. The tracks' tunes,
  tempos and lengths are unchanged. To try another take, change a track's `seed`, `bpm` or
  chords, rerun the tool (`--track <name>` for one; all seven take about 50 s), then
  `godot --headless --path . --import` with your normal `HOME` (with an isolated `HOME` the editor
  has no Blender path, and on 25 Nov 2026 that error stopped a changed WAV from being reimported).
  The loading track was made slower and dreamier the same day (user: "make it a bit slower and
  dreamier"; it was 66 BPM with no echo). The town and loading tracks were approved by ear
  ("Sounds good"); the five mood tracks wait for the user's listen.
- **Loudness:** each cue's `volume_db` evens the tracks out (town −8 dB, loading −8, quiz −9.5,
  errands −10, mystery −5, focus −9, outdoors −8.5), from each file's average level (RMS
  −16.4 to −21.2 dBFS after the clean-up), so a switch neither jumps nor drops.
- **Playing:** `data/sounds.json` cues `music.<track>` (bus Music) and the `"music"` section
  (`enabled`, `tracks`, `fade_in` 4 s, `fade_out` 1.5 s). `sound.gd` `play_music(track)` fades the
  playing track out and the new one in, and a track starts from the top; `stop_music()`,
  `music_track()`, `music_playing()`. App adds the sound service when the loading screen opens
  (Main keeps it) and plays `loading`, then `town` when the screen lifts; the second loading
  screen after the tutorial (`_load_rest_now`) does the same. Main run on its own plays `town`.
  Not positional. The tutorial's title cutscene is not a loading screen and keeps the town music.
- **Record player** (25 Nov 2026, user): the home's record player
  ([component](COMPONENTS.md#record-player)) lists every track of `tracks` by its title
  (phrases `record_player.song_<track>`) and plays the one picked with `pick_record(track)`. That
  track becomes `town_track`, which `play_town()` plays wherever the town music used to be named
  (after a game, after a loading screen, Main on its own); `pick_record("")` stops the music until
  the next pick. Not saved: a new launch starts with `town`. `music_changed(track)` tells the
  turntable what is asked for ("" = stopped); `music_wanted()`, `track_names()`.
- **Minigames:** each game's `data/activities.json` `"music"` names its track. `sound.gd` listens
  to the activity board: `started(id)` plays the game's track, `ended` plays `town_track` (also while
  the results card shows). A game is "running" when its `activity_running()` is true, which for
  some games includes an open order (Grocery Run's list). Loading music is never interrupted.
  A new game only adds `"music"` ([MINIGAMES.md](MINIGAMES.md#building-a-minigame)); a favourite
  game can get its own track by adding one to `TRACKS` and `tracks` and naming it.
- **Under spoken words:** `say_word()` dips the music by 9 dB (`DUCK_DB`) for the clip's length,
  then brings it back over 0.6 s. Music players play on a bus `MusicDuck` that `sound.gd` adds at
  run time and sends to Music, so the dip never touches the Music slider.
- **Hitches** (25 Nov 2026, user: in the Godot app, the music got "stuck at a tune" when the game
  froze). Throwaway probes on the user's Mac (CoreAudio, music on, Master captured and then
  silenced at −80 dB), none reproducing it:
  - a 1.5 s block of the main thread: 1.5 s of music still mixed;
  - the whole town built by `main.tscn` (frames of 9.5 s and 2 s): 56.5 s of music in 56.5 s;
  - the loop point of the loading, town and focus tracks: each wrapped to 0:00 with no gap;
  - the app's order (loading music, town built, crossfade to town, a game's quiz music, a word
    dip, town again; a 4 s frame): 21.9 s of music in 21.9 s, no hang.
  So the music keeps playing through game freezes. A stuck or repeating sound means the audio
  thread missed its turn, which happens when the whole machine is starved: at the time, other
  sessions ran heavy Godot captures and a 52-minute town check on the MacBook Air (load average
  about 6). Mitigation: `project.godot` `audio/driver/output_latency=50` (was the default 15 ms;
  the web already uses 50), a bigger cushion before an underrun is heard. The user's runs at
  13:56 also logged errors from another session's sound-effect bindings in progress, and
  `play_music()`'s fade lookup logged "does not have any 'meta' values with the key
  'music_fade'" on every switch (fixed: has_meta first). **Not verified:** that the stuck sound
  is gone (it was never reproduced); the user should report if it comes back, with what was
  running at the time.
- **Web:** music goes through `sound.gd`, so it wakes the page's AudioContext; the tab's speaker
  icon then shows while music plays. It starts after the player has pressed Play, so browsers
  allow it. The web build has no threads and reads the town scene in one blocking load, so the
  loading music may stall or stutter for that moment (not tried).
- **Checks:** `docs/evidence/lofi-music-20261125/verify.gd` (`run_checks.py` id `lofi_music`,
  quick; headless, silent, no town): all seven cues on the Music bus as QOA forward loops of the
  right length, every game naming a track that exists, every mood used, and in a check
  `play_music()` and a game starting play nothing and add no duck bus. 25 Nov 2026: 0 failures.
  Throwaway probe scenes (Dummy audio driver, normal run) confirmed: loading then town with the
  crossfade; each mood starts with its game (Desk Dash → quiz, Grocery Run → errands, Spot the
  Suspect → mystery, Mahjong → focus (Mahjong has its own `mahjong` track since 25 Nov), Feeding
  Time! → outdoors) and town comes back when it ends;
  the duck bus sends to Music, dips to −9 dB and returns to 0; a game starting during loading
  keeps the loading music; a freed service leaves no connection on the board. Quick suite the
  same day: PASS 10, KNOWN 1 (voice_backbone, expected). **Not verified:** how the five mood
  tracks sound (the user auditions them), a real game started in the town with sound on, the web
  build and phones.
- **Open (P2):** placeholders. Replace them with licensed loops or commissioned music when the
  user chooses (fewer, better tracks cost less than one per game); maybe a title-screen track and
  place music (inside shops) through the same `tracks` list. Each new track adds to the Web pack
  (P1 below).

## Sound effects (25 Nov 2026)

User, 25 Nov 2026: sounds for the stamp coin, the doors, the chapel bell and Library Helper's
right and wrong shelf; later the same day: "each door should have different sound". The user
picked every sound by ear from 2–5 candidates each (cabinet, safe and vault took a second round).

| Cue | When | How it plays |
| --- | --- | --- |
| `coin.stamp` | A stamp coin is collected (`stamp_coin.gd` signal `collected`) | Flat, UI bus, −4 dB. Flat because the coin frees itself before a sound under it would end |
| `door.<kind>.open` / `.close` | A door is opened or closed (`door_animator.gd` `toggle()`; the teller game's staff door too). A heavy door (`seconds`, the bank vault) sounds its close when it has shut | At the door leaf, SFX bus, unit size 2–3.5 m, heard up to 16–30 m, `restart` |
| `bell.chapel` | The chapel bell is rung (`chapel_bell.gd` signal `rung`) | At the bell, SFX bus, −6 dB, unit size 8 m, heard up to 90 m, `restart` |
| `answer.correct` / `answer.wrong` | Library Helper: a book on the right shelf or a wrong one (`library_session.gd` signals `shelved_right`, `shelved_wrong`) | Flat, UI bus. Named for any game's right and wrong answers; only Library Helper uses them so far |
| `vehicle.engine`, `vehicle.truck`, `vehicle.helicopter`, `vehicle.plane` | A vehicle is driven or flown (`driveable_vehicle.gd` `update_engine_sound()` each drive step) | A loop at the vehicle, SFX bus, pitch and volume rise with speed (see Engines) |
| `ui.confirm`, `ui.decline`, `ui.tap`, `ui.select`, `ui.delete` | A button is pressed (see Buttons) | Flat, UI bus, −6 to −12 dB |
| `mahjong.shuffle`, `.draw`, `.discard`, `.call.pung` / `.chow` / `.kong` / `.sik`, `.win` | Mahjong Club (see Mahjong) | Flat, SFX bus |

- **Door kinds:** `door_animator.gd` `sound_kind()` reads the door state's `"sound"`, else a
  hinged door is `room` and a sliding door (`safe_slide`) `sliding`; drawers and curtains have
  none and stay silent, and `"none"` silences any door. Kinds set by building steps
  (`door_sounds` in police, warehouse, bank and restaurants, baked 25 Nov 2026): the holding
  cell `cell`, the two police lockers `locker`, the warehouse supply cabinet `cabinet`, the bank
  safe `safe`, the bank vault `vault` and the Pizza and Burger double door `glass`. A door scene
  (`door.gd`) has a `sound` export; a step sets other doors with
  `DoorAnimator.set_sound_kind(game, node, kind)`. Mystery House doors play the room sounds
  through their own `opened` and `slammed` signals (bindings). Not included (user, 25 Nov 2026):
  garage, vehicle doors, zoo and farm gates, lift doors.
- **Buttons** (user, 25 Nov 2026: "add sound effect when user click on confirm or decline", then
  every kind of button; picked by ear). `bon_style.gd` tags every button it styles with meta
  `bon_kind`; `sound.gd` hooks every button's `pressed` as it enters the tree and plays
  `button_cue()`: the button's meta `sound` (a cue id, `"none"` for silence), else the cue for its
  kind in `data/sounds.json` `"buttons"`. Green (`primary`: Yes / Play, Next, Start, Continue,
  Go, Done, Stay) → `ui.confirm`, two rising bubble pops; `back` (Back, Cancel) and the
  dialogue's "No / Not now" choice (icon `no`, set in `shop_order_panel.gd`) → `ui.decline`, two
  falling pops; coral `danger` (Delete, Leave) → `ui.delete`, a CC0 paper crush (user: "like
  folding paper"); cream and soft buttons (✕, HUD, Settings rows, map chips) → `ui.tap`, one
  tiny pop; tiles, choices, toggles, checkboxes and drop-downs → `ui.select`, a bell glint.
  Buttons BonStyle never styled (touch controls, money coins, mahjong tiles) stay silent. A
  dialogue choice picked with a number key is not a press and makes no sound.
- **Mahjong** (user, 25 Nov 2026: "also add sound effect to the Mahjong game", one set for
  every language, the calls in Cantonese; picked by ear). `mahjong_session.gd` emits
  argument-free signals, bound in `data/sounds.json`: `hand_dealt` → `mahjong.shuffle` (tiles
  washed, CC0 recording), `tile_drawn` (the player's own draws only, a kong's replacement too) →
  `mahjong.draw`, `tile_discarded` (every player) → `mahjong.discard` (CC0 domino recordings),
  `called_pung` / `called_chow` / `called_kong` / `called_win` (anyone) → a Cantonese voice
  saying 碰 / 上 / 槓 / 食 (Amazon Polly, Hiujin, readings pinned with Jyutping pung3, soeng5,
  gong3, sik6), and `you_won` (the result card after the player wins) → `mahjong.win`, a
  pentatonic tune climbing to a held top note (`tools/make_sfx.py` `win_a`). No sound when
  someone else wins or the wall runs out (user). `_on_game_changed()` compares the game with its
  last look (`_snapshot()`); the deal and a claimed tile leaving the discards make no sound. The
  panel's own buttons and tiles are not BonStyle buttons and stay silent. Files:
  `audio/sfx/mahjong/`. To remake a call: the SSML in its cue's `source`.
- **Engines** (user, 25 Nov 2026: a sound for driving, then the helicopter, plane and truck;
  each picked by ear from four CC0 Freesound loops). `sound.gd` `engine(vehicle, running, speed,
  kind)` starts the cue's loop under the vehicle, sets `pitch_scale` from the cue's
  `engine.pitch_idle` (stopped) to `pitch_top` (top speed) times its `types` factor for that
  kind, and the volume from `idle_db` up to the cue's `volume_db`; when the engine stops it fades
  out over 0.25 s. `engine_cue(kind)` picks the cue whose `engine.vehicles` lists the kind, else
  the `default` one (`vehicle.engine`, the car). Kinds come from `engine_kind()`: `plane` for the
  fixed-wing plane, `helicopter`, else the vehicle's word key (car, taxi, police car, ambulance and
  motorcycle → car engine; truck, bus, school bus and fire truck → truck). Level
  (`engine_level()`): road speed over top speed; the helicopter's `rotor_power`, so the rotor
  winds up on take-off and down after landing; the plane's engine power or airspeed
  (`turboprop.gd`). It runs while someone is in it and boarding is done, while the rotor or
  propeller still turns, and never after a crash. Sirens are separate cues and play on top.
- **`sound.gd`:** `play_ui(cue)` plays a cue once, flat; a bound signal plays flat when its cue
  has no `distance` or the node is not in 3D; a cue with `"restart": true` stops the same cue
  still sounding at that node first, so a door or bell used quickly does not pile up. Every play
  wakes the page's audio on the web as before. Bound signals carry no arguments.
- **Files:** `audio/sfx/doors/<kind>_open.wav` / `_close.wav`, `audio/sfx/chapel/bell.wav`,
  `audio/sfx/ui/coin_stamp.wav`, `answer_correct.wav`, `answer_wrong.wav`. Mono 22.05 kHz 16-bit,
  peak −1 dBFS, imported as QOA without a loop (about 231 KB in all once imported). Engines:
  `audio/sfx/vehicles/engine.wav`, `truck.wav`, `helicopter.wav`, `plane.wav`, 1.1–3 s seamless
  loops (an equal-power crossfade of the tail into the head, 40 Hz high-pass), imported as QOA
  forward loops (about 88 KB). Buttons: `audio/sfx/ui/button_<confirm|decline|tap|select|delete>.wav`
  (about 8 KB).
- **Sources:** the doors and the bell are CC0 Freesound recordings (HQ previews, the licence
  checked on each sound's own page), trimmed and faded; each cue's `source` and `licence` in
  `data/sounds.json` name the page and the cut. The bell is one strike made into a lower
  ding-dong. The coin and the right and wrong sounds are original, synthesised by
  `tools/make_sfx.py` (pure Python): `--out <folder outside the project>` makes every candidate,
  `--write` remakes the chosen ones (`CHOSEN`) into `audio/sfx/ui/`. The review folder
  `~/Desktop/sfx-review/` (outside the project) keeps every candidate, the downloads and the cut
  lists.
- **Check:** `docs/evidence/sfx-20261125/verify.gd` (`run_checks.py` id `sfx`, quick; headless,
  silent, no town): the 20 cues (bus, flat or positional, QOA, mono, no loop, length, source and
  licence), every cue's licence, the bindings' signals (no arguments) and cues, the door kinds
  and the kinds baked into the four unit scenes, a stamp coin bound when added, and the four
  engine loops (forward loop, QOA, mono, length, `engine_cue()` for every vehicle kind, one
  default, the hooks in `driveable_vehicle.gd` and `turboprop.gd`). 25 Nov 2026: 372 checks,
  0 failures. Town checks that open doors or flush a toilet still make players on
  the headless dummy driver, as before (the bath fixtures check counts them).
- **Not verified:** how they sound in the game (levels against the music, distances, the vault's
  timing, the engines' pitch range at real speeds and with several vehicles running), the web
  build (whether `pitch_scale` changes on the web's sample playback) and phones.
- **Open (P3):** drawers, curtains, garage, gates, vehicle and lift doors; a rattle for the
  Mystery House's locked doors (`rattled` is unbound); the right and wrong sounds in other games.

## Decisions (user, 24 Nov 2026)

- Generated with **Amazon Polly** (neural voices), not taken from the web, with no live calls
  from the game. Clips are made ahead of time and shipped with the game, so it works offline
  and on the web.
- **Latin American Spanish:** `es-MX`, voice **Mia** (male alternative: Andrés). This matches
  `data/words.json`, which uses Mexican Spanish.
- English `en-US` Joanna. Mandarin `cmn-CN` Zhiyu, made to say the game's own pinyin (below).
- The user listens to samples before any clip goes into the game. Mia and Zhiyu were approved
  from the first samples on 24 Nov 2026. Making the game's clips and switching `enabled` on
  still each wait for the user's word.

## How it fits together

| Part | Owns |
| --- | --- |
| `data/sounds.json` `"voice"` | Master switch `enabled`, folder `res://audio/voice`, bus `Voice`, volume, and the Polly voice per language |
| `scripts/core/sound.gd` | `voice_file(key)` (clip name: `apple pie` → `apple_pie`), `voice_path()`, `has_voice()`, `say_word(key, lang)`. Plays one word at a time on the Voice bus, not positional |
| `tools/voice_manifest.gd` | What to say: one SSML line per word and language. It reads `data/words.json` through the Lexicon and fails on clashing clip names, missing text or pinyin it cannot split |
| `tools/voice_generate.py` | Sends the manifest to Polly with the AWS CLI. Writes `<out>/<lang>/<file>.ogg` (Ogg Vorbis, 22.05 kHz) and `<lang>/generated.json` (a fingerprint per clip, so only changed words are redone) |

What is said:

- **Spanish:** the word with its article (`la manzana`). Two forms are said with a 0.4 s pause
  between them (`el médico / la médica`). Every `/` in any language is that pause.
- **Notes in brackets** that tell two meanings apart on screen are left out:
  `el banco (dinero)` is said as `el banco`.
- **Chinese:** each character goes in an SSML `<phoneme alphabet="x-amazon-pinyin">` with its
  pinyin as tone numbers, taken from the reading the game shows (`Lexicon.reading_tokens()`,
  `data/pinyin_zh.json`). For example 蘋果 → `ping2 guo3`, 綠色 → `lv4 se4`, 爺爺 → `ye2 ye5`.
  Polly therefore says the same pinyin the game shows and does not guess readings of the
  Traditional characters. If the pinyin data is wrong, fix it there; the voice follows.

## Making clips

Run these from `BonAdventure/`. The AWS CLI must be signed in (`aws sso login`).

1. Dry run. This calls nothing and prints the SSML and voice for each clip:
   `python3 tools/voice_generate.py --lang es,zh --keys apple,doctor,aunt`
2. Samples to listen to. Write them to a folder **outside** the project, otherwise Godot imports
   them; the tool refuses a folder inside it:
   `python3 tools/voice_generate.py --lang es,zh --keys apple,doctor,aunt --out ~/Desktop/voice-samples`
3. After the user approves, make the game's clips. This only redoes new or changed words;
   `--force` redoes all of them. Then import the clips:
   `python3 tools/voice_generate.py --lang es --write`, then `godot --headless --path . --import`
4. Set `"enabled": true` in `data/sounds.json` **only when the user says so**.

Options: `--limit N`, `--profile`, and `--region`. By default the tool uses
`"polly_region": "us-east-1"` from the voice settings. The CLI's default region, us-east-2, has no
neural voices: it refused with "The selected engine is not supported in this region" on
24 Nov 2026. About 800 words × 3 languages
cost cents and fit the Polly free tier. `--jobs N` (default 4) makes N clips at once; all
2,397 took a few minutes on 24 Nov 2026. The Web export leaves out the `generated.json` records
(`export_presets.cfg` `exclude_filter`).

## Checks

- `tools/voice_manifest.gd` with no arguments only checks. It prints `FAIL:` lines and
  `VOICE MANIFEST: N clips in M languages; K problems`. It is not in `run_checks.py` yet.
- `docs/evidence/voice-backbone-20261124/verify.gd`, headless and silent: clip names and paths,
  the switch is off, `say_word()` stays silent while off and when a clip is missing, and every
  word has a clip in every voice language that loads as non-looping Ogg Vorbis. It never calls
  `say_word()` on a real clip.
- 24 Nov 2026: manifest 2,397 clips in 3 languages, 0 problems; backbone check 18 checks,
  0 failures; `language_check` PASS 5342.
- 24 Nov 2026, later: first samples for the user to review, in `~/Desktop/voice-samples/`
  (outside the project, not imported). Eleven words in Spanish and Chinese: apple, doctor, bank,
  avocado, green, apple pie, at what time, grandfather, daughter, aunt, behind. All 22 were
  made: Ogg Vorbis, mono, 22.05 kHz, about 6–11 KB and 0.6–1.9 s each. The exception is
  Chinese "aunt" (seven forms), at 27 KB and 7.7 s. That points to about 6 MB per language for
  every word. **The user listened and approved Mia and Zhiyu ("Sound good", 24 Nov 2026).**
- 24 Nov 2026, later: every clip made with `--lang es,zh,en --write` (2,397 made, 0 failed),
  then `godot --headless --path . --import` (exit 0, `.import` loop=false). Backbone check:
  22 checks, 0 failures. Files: about 7 MB per language on disk. Only the Spanish and Chinese
  samples above have been listened to; English (Joanna) has not been reviewed.

## Open items

- Done 24 Nov 2026: the user listened to the Spanish and Chinese samples and approved them,
  including Zhiyu with `x-amazon-pinyin` on Traditional characters.
- Done 24 Nov 2026: the game's clips are made and imported (user: "Yes, make all clips").
- Done 24 Nov 2026: `enabled` switched on (user).
- Done 24 Nov 2026: the speaker button on the word card and the volume sliders in Settings
  (`docs/evidence/sound-ui-20261124/verify.gd`: 30 checks, 0 failures, with views).
- 24 Nov 2026, web check: a Web export (`tools/deploy_web.py --out`, not published) served on
  localhost in the app's built-in Chromium. The one AudioContext stayed `suspended` on the title
  screen and after clicking Play (Godot's own resume was held back). Resuming with
  `bonAudioWanted` true gave `running`, and a Godot-style resume while it was false stayed
  `suspended`. The console showed no errors. **Not tried:** a real sound playing on the web
  (nothing may play yet), Safari, and a phone. `index.pck` is now 91.4 MB, of which about 20 MB
  is the clips; GitHub's limit is 100 MB per file.
- **P1:** the Web pack is near GitHub's 100 MB file limit. Ship only the language being learned,
  or split the clips out of `index.pck`, before adding more audio or music. Since 25 Nov 2026
  (commit 5525310a) the pack is 65.5 MB; the sound effects add about 0.32 MB (engines included) and the five mood
  tracks more (not measured here).
- **P2:** decide whether to also say words on the results card, and whether
  the card should say the word by itself when it opens.
- **P2:** web size. All three languages are in the Web export (about 20 MB in total). Consider
  shipping or downloading only the language being learned.
- **P3:** review the English clips by ear. The Spanish and Chinese ones were only spot-checked
  through the 22 samples.
- **P3:** phrases and NPC lines, and the credits entry for Polly.
