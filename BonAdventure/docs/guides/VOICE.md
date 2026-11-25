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
for loading screen". **Built:** two looping demo tracks on the Music bus: one while the loading
screen shows, one in the town.

- **Tracks** (`audio/music/`), original music synthesised by `tools/make_lofi_demo.py` (pure
  Python, no samples or third-party material; one `TRACKS` entry each). Both are mono 22.05 kHz,
  wrap their note tails so the loop seam is smooth, and are imported as QOA forward loops.
  - `town_lofi_demo.wav`: Fmaj7–Em7–Dm7–Cmaj7 electric-piano chords (Dm9–G7 turnaround), bass,
    a sparse pentatonic melody, swung boom-bap drums, a soft sidechain dip, low-pass and vinyl
    crackle. 16 bars at 72 BPM, 53.3 s, about 0.48 MB in the pack.
  - `loading_lofi_demo.wav`: dreamy, in A (Amaj9–F#m9–Dmaj9–E6sus), a music-box arpeggio,
    soft brushes and a shaker with no kick, long-ringing keys with a slow, wide wobble, a dark
    dotted-eighth echo on the keys and music box (not the bass), the same bass and vinyl.
    8 bars at 56 BPM, 34.3 s, about 0.31 MB. Made slower and dreamier the same day (user: "make
    it a bit slower and dreamier"; it was 66 BPM with no echo).
  To try another take, change a track's `seed`, `bpm` or chords, rerun the tool
  (`--track town|loading` for one), then `godot --headless --path . --import` with your normal
  `HOME` (with an isolated `HOME` the editor has no Blender path, and on 25 Nov 2026 that error
  stopped a changed WAV from being reimported).
- **Playing:** `data/sounds.json` cues `music.town` and `music.loading` (bus Music, −8 dB) and the
  `"music"` section (`enabled`, `tracks`, `fade_in` 4 s, `fade_out` 1.5 s). `sound.gd`
  `play_music(track)` fades the playing track out and the new one in; `stop_music()`,
  `music_track()`, `music_playing()`. App adds the sound service when the loading screen opens
  (Main keeps it) and plays `loading`, then `town` when the screen lifts; the second loading
  screen after the tutorial (`_load_rest_now`) does the same. Main run on its own plays `town`.
  Never plays when the tree runs a script, so checks stay silent. Not positional; the town track
  keeps playing through minigames and buildings. The tutorial's title cutscene is not a loading
  screen and keeps the town music.
- **Web:** music goes through `sound.gd`, so it wakes the page's AudioContext; the tab's speaker
  icon then shows while music plays. It starts after the player has pressed Play, so browsers
  allow it. The web build has no threads and reads the town scene in one blocking load, so the
  loading music may stall or stutter for that moment (not tried).
- **Check:** `docs/evidence/lofi-music-20261125/verify.gd` (`run_checks.py` id `lofi_music`,
  quick; headless, silent, no town): both cues, Music bus, QOA forward loops of the right length,
  and `play_music()` refuses in a check. 25 Nov 2026: 0 failures. A throwaway probe scene (Dummy
  audio driver) confirmed in a normal run: loading plays, `town` fades it out and fades in
  (−24 dB halfway), and `stop_music()` stops it; app.gd and main.gd parse. Quick suite the same
  day: PASS 9, KNOWN 1 (voice_backbone, expected). **Not verified:** how they sound (Claude
  cannot listen; the user auditions them), a real start-up through the loading screen with
  sound, the web build and phones.
- **Open (P2):** placeholders. Replace them with licensed loops or commissioned music when the
  user chooses; maybe a title-screen track, per-place music or a quieter mix during minigames.
  Each new track adds to the Web pack (P1 below).

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
  or split the clips out of `index.pck`, before adding more audio or music.
- **P2:** decide whether to also say words on the results card, and whether
  the card should say the word by itself when it opens.
- **P2:** web size. All three languages are in the Web export (about 20 MB in total). Consider
  shipping or downloading only the language being learned.
- **P3:** review the English clips by ear. The Spanish and Chinese ones were only spot-checked
  through the 22 samples.
- **P3:** phrases and NPC lines, and the credits entry for Polly.
