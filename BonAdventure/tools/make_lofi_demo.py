#!/usr/bin/env python3
"""Synthesises the demo lofi music loops (25 Nov 2026, user: "a lofi BGM just for the demo";
later the same day: "add a different soundtrack for loading screen", then mood tracks for the
minigames: quiz, errands, mystery, focus and outdoors; data/activities.json "music").

Original music made here from sine/noise oscillators: no samples, recordings or third-party
material. Pure Python (no numpy). Writes seamless mono 16-bit WAV loops; Godot imports them as
forward loops with QOA compression (the .wav.import files beside them).

    python3 tools/make_lofi_demo.py                  # both tracks into audio/music/
    python3 tools/make_lofi_demo.py --track loading  # one track
    python3 tools/make_lofi_demo.py --track town --out X.wav

Every track is mono 44.1 kHz; note tails, echoes and filters wrap around the loop, so the
seam is smooth. Clean on purpose (25 Nov 2026, user: the first takes sounded "grainy and fuzzy,
with some radio-like background static"): no vinyl hiss or crackle, no soft clipping, every note
fades out over FADE seconds instead of being cut off (the cut-offs clicked), and a lighter
low-pass.

Each track is one entry in TRACKS (tempo, seed, chords, instruments). Change its seed, tempo or
chords to try another take. Placeholders until licensed or commissioned music replaces them
(docs/guides/VOICE.md, "Background music").
"""
import argparse
import math
import os
import random
import struct
import wave

# 44.1 kHz since 25 Nov 2026 (user: "grainy and fuzzy"; 22.05 kHz made the drums gritty).
RATE = 44100
# Town: Fmaj7 Em7 Dm7 Cmaj7, then the same with a Dm9 G7 turnaround; boom-bap drums.
_TA = [([65, 69, 72, 76], 41), ([64, 67, 71, 74], 40), ([62, 65, 69, 72], 38), ([60, 64, 67, 71], 36)]
_TB = [([65, 69, 72, 76], 41), ([64, 67, 71, 74], 40), ([62, 65, 69, 72, 76], 38), ([67, 71, 74, 77], 43)]
# Loading: dreamier, in A: Amaj9 F#m9 Dmaj9 E6sus; music-box arpeggio, brushes and a shaker, no kick.
_LA = [([57, 61, 64, 68, 71], 45), ([54, 61, 64, 68], 42), ([62, 66, 69, 73, 76], 38), ([59, 64, 66, 69], 40)]
# Quiz (upbeat, D major): Dadd9 Bm7 Gmaj7 A7 | Gmaj7 F#m7 Em7 A7.
_QA = [([62, 64, 66, 69], 38), ([59, 62, 66, 69], 35), ([62, 66, 67, 71], 43), ([61, 64, 67, 69], 45),
       ([62, 66, 67, 71], 43), ([61, 64, 66, 69], 42), ([59, 62, 64, 67], 40), ([61, 64, 67, 69], 45)]
# Errands (cozy shopping jazz, Bb): Cm9 F13 Bbmaj9 Gm9 | Ebmaj9 D7 Gm7 F7.
_EA = [([63, 67, 70, 74], 48), ([63, 67, 69, 74], 41), ([62, 65, 69, 72], 46), ([65, 69, 70, 74], 43),
       ([62, 65, 67, 70], 39), ([60, 62, 66, 69], 38), ([62, 65, 70, 74], 43), ([63, 65, 69, 72], 41)]
# Mystery (sneaky, A minor, falling bass): Am Am/G# Am/G D/F# Fmaj7 E7 Am E7.
_MA = [([57, 60, 64], 45), ([56, 60, 64], 44), ([55, 60, 64], 43), ([54, 57, 62], 42),
       ([52, 57, 60, 64], 41), ([52, 56, 59, 62], 40), ([57, 60, 64], 45), ([56, 59, 62, 64], 40)]
# Focus (calm puzzles, D): Dmaj9 Bm9 Gmaj9 Gm6.
_FA = [([61, 64, 66, 69], 38), ([61, 62, 66, 69], 35), ([59, 62, 66, 69], 43), ([58, 62, 64, 67], 43)]
# Outdoors (playful zoo, F): F Dm Gm7 C7 | F F7 Bb C7.
_OA = [([60, 65, 69], 41), ([60, 62, 65, 69], 38), ([62, 65, 67, 70], 43), ([58, 64, 67], 36),
       ([60, 65, 69], 41), ([60, 63, 65, 69], 41), ([62, 65, 70], 46), ([58, 64, 67, 70], 36)]
# Each chord: MIDI notes of a voicing and its bass root. "style" picks the arrangement (ARRANGE);
# the town and loading tracks use the original "lofi" one.
TRACKS = {
    "town": {"file": "town_lofi_demo.wav", "bpm": 72, "seed": 7, "progression": _TA + _TB + _TA + _TB,
             "scale": [72, 74, 76, 79, 81, 84], "drums": "boom_bap", "arp": False, "cutoff": 5500},
    # 25 Nov 2026, user: "a bit slower and dreamier" (was 66 BPM, no echo, 3200 Hz, firmer keys).
    "loading": {"file": "loading_lofi_demo.wav", "bpm": 56, "seed": 23, "progression": _LA + _LA,
                "scale": [76, 78, 81, 83, 85, 88], "drums": "brushes", "arp": True, "cutoff": 4500,
                "keys": {"decay": 0.5, "wow_depth": 0.0045, "trem_rate": 2.6, "release": 2.5},
                "bell_decay": 1.5, "drum_gain": 0.6,
                "echo": {"beats": 0.75, "feedback": 0.42, "mix": 0.5, "cutoff": 1800}},
    # Minigame moods (25 Nov 2026, user: "different songs for different activity"; groups in
    # data/activities.json "music").
    "quiz": {"file": "quiz_lofi_demo.wav", "style": "quiz", "bpm": 104, "seed": 31, "progression": _QA + _QA,
             "cutoff": 8000, "drum_cutoff": 10000},
    "errands": {"file": "errands_lofi_demo.wav", "style": "errands", "bpm": 92, "seed": 41, "progression": _EA + _EA,
                "cutoff": 6500, "duck": 0.2},
    "mystery": {"file": "mystery_lofi_demo.wav", "style": "mystery", "bpm": 92, "seed": 53, "progression": _MA + _MA,
                "cutoff": 6000, "duck": 0.15,
                "echo": {"beats": 0.5, "feedback": 0.3, "mix": 0.3, "cutoff": 2200}},
    "focus": {"file": "focus_lofi_demo.wav", "style": "focus", "bpm": 60, "seed": 61, "progression": _FA * 4,
              "cutoff": 5000,
              "echo": {"beats": 1.5, "feedback": 0.35, "mix": 0.35, "cutoff": 1800}},
    "outdoors": {"file": "outdoors_lofi_demo.wav", "style": "outdoors", "bpm": 108, "seed": 71, "progression": _OA + _OA,
                 "cutoff": 8000, "drum_cutoff": 9500, "duck": 0.25},
}

def hz(note):
    return 440.0 * 2 ** ((note - 69) / 12.0)


FADE = 0.012


def add(buf, start, samples, gain=1.0):
    """Mixes `samples` into the loop at `start`, wrapping tails past the end to the start.
    The last FADE seconds fade to silence, so a note never ends with a click."""
    n = len(buf)
    count = len(samples)
    fade = min(count, int(FADE * RATE))
    for i, s in enumerate(samples):
        left = count - i
        if left <= fade:
            s *= 0.5 - 0.5 * math.cos(math.pi * left / fade)
        buf[(start + i) % n] += s * gain


def keys(note, dur, vel, wobble_phase, decay=1.1, wow_depth=0.0025, trem_rate=4.2, release=6.0, attack=0.012):
    """Electric-piano-like tone: sine with a soft bell partial, slow tremolo, gentle tape wow."""
    f = hz(note)
    count = int((dur + max(1.2, 4.0 / release)) * RATE)
    out = [0.0] * count
    phase = 0.0
    for i in range(count):
        t = i / RATE
        wow = 1.0 + wow_depth * math.sin(2 * math.pi * 0.55 * t + wobble_phase)
        phase += 2 * math.pi * f * wow / RATE
        env = math.exp(-t * decay) if t < dur else math.exp(-dur * decay) * math.exp(-(t - dur) * release)
        rise = min(1.0, t / attack)
        bell = math.sin(2 * phase) * 0.18 * math.exp(-t * 7.0) + math.sin(3 * phase) * 0.05 * math.exp(-t * 4.0)
        trem = 0.88 + 0.12 * math.sin(2 * math.pi * trem_rate * t)
        out[i] = (math.sin(phase) + bell) * env * rise * trem * vel
    return out


def bass(note, dur, vel):
    f = hz(note)
    count = int((dur + 0.15) * RATE)
    out = [0.0] * count
    for i in range(count):
        t = i / RATE
        env = min(1.0, t / 0.02) * (math.exp(-t * 0.9) if t < dur else math.exp(-dur * 0.9) * math.exp(-(t - dur) * 25.0))
        ph = 2 * math.pi * f * t
        out[i] = (math.sin(ph) + 0.25 * math.sin(2 * ph)) * env * vel
    return out


def kick(vel):
    count = int(0.35 * RATE)
    out = [0.0] * count
    phase = 0.0
    for i in range(count):
        t = i / RATE
        f = 48 + 90 * math.exp(-t * 30)
        phase += 2 * math.pi * f / RATE
        out[i] = math.sin(phase) * math.exp(-t * 9) * vel
    return out


SNARE_A = 1.0 - math.exp(-2 * math.pi * 1600 / RATE)


def snare(rng, vel):
    count = int(0.25 * RATE)
    out = [0.0] * count
    lp = 0.0
    for i in range(count):
        t = i / RATE
        lp += (rng.uniform(-1, 1) - lp) * SNARE_A       # soft noise, about 1.6 kHz
        tone = math.sin(2 * math.pi * 190 * t) * math.exp(-t * 30) * 0.5
        out[i] = (lp * math.exp(-t * 16) + tone) * vel
    return out


def band_noise(rng, count, low, high):
    """White noise kept to low..high Hz (two one-pole low-passes subtracted)."""
    a_lo = 1.0 - math.exp(-2 * math.pi * low / RATE)
    a_hi = 1.0 - math.exp(-2 * math.pi * high / RATE)
    lo = hi = 0.0
    out = [0.0] * count
    for i in range(count):
        n = rng.uniform(-1, 1)
        lo += (n - lo) * a_lo
        hi += (n - hi) * a_hi
        out[i] = hi - lo
    return out


def hat(rng, vel):
    """Hi-hat / shaker: 5-11 kHz noise (raw white noise sounded harsh and grainy)."""
    noise = band_noise(rng, int(0.06 * RATE), 5000, 11000)
    return [x * math.exp(-(i / RATE) * 70) * vel * 2.2 for i, x in enumerate(noise)]


def bell(note, vel, decay=2.6):
    """Music-box tone: a bright sine with an inharmonic partial and a quick fade."""
    f = hz(note)
    count = int(min(4.0, 4.2 / decay) * RATE)
    out = [0.0] * count
    for i in range(count):
        t = i / RATE
        ph = 2 * math.pi * f * t
        out[i] = (math.sin(ph) + 0.3 * math.sin(2.76 * ph) * math.exp(-t * 6)) * math.exp(-t * decay) * min(1.0, t / 0.004) * vel
    return out


def partials(note, vel, length, parts, attack=0.002):
    """A sum of sines: parts = [(frequency ratio, level, decay per second)]; partials above
    the Nyquist limit are left out."""
    f = hz(note)
    parts = [(r, a, d) for r, a, d in parts if f * r < 0.45 * RATE]
    count = int(length * RATE)
    out = [0.0] * count
    for i in range(count):
        t = i / RATE
        v = 0.0
        for r, a, d in parts:
            v += a * math.sin(2 * math.pi * f * r * t) * math.exp(-t * d)
        out[i] = v * min(1.0, t / attack) * vel
    return out


def marimba(note, vel):
    """Wooden bar: the fundamental, a bright 4th harmonic and a quick 10th."""
    return partials(note, vel, 1.0, [(1, 1.0, 5.0), (4, 0.35, 25.0), (10, 0.1, 60.0)])


def pluck(note, vel, decay=4.0, length=1.0):
    """A plucked string (pizzicato, ukulele): harmonics that fade faster the higher they are."""
    return partials(note, vel, length, [(h, 1.0 / h ** 1.3, decay + 2.5 * h) for h in range(1, 7)])


def clap(rng, vel):
    """Three quick bursts of 0.9-3.5 kHz noise and a short tail."""
    noise = band_noise(rng, int(0.2 * RATE), 900, 3500)
    out = [0.0] * len(noise)
    for i, x in enumerate(noise):
        t = i / RATE
        env = sum(math.exp(-(t - k) * 220) for k in (0.0, 0.009, 0.018) if t >= k) + 0.5 * math.exp(-t * 22)
        out[i] = x * env * vel * 3.0
    return out


def tock(freq, vel):
    """Woodblock."""
    count = int(0.12 * RATE)
    return [math.sin(2 * math.pi * freq * (i / RATE)) * math.exp(-(i / RATE) * 45) * vel for i in range(count)]


def third_of(chord, root):
    """The chord's third above the root (minor or major), for walking bass lines."""
    for n in chord:
        if (n - root) % 12 in (3, 4):
            return root + (n - root) % 12
    return root + 7


def echo_loop(buf, delay, feedback, mix, cutoff):
    """Soft feedback echo around the loop (its repeats wrap, so the seam stays smooth),
    darkened by a low-pass so the repeats sit behind the dry sound."""
    n = len(buf)
    d = max(1, int(delay * RATE))
    wet = [0.0] * n
    for _ in range(3):  # three laps settle the repeats that wrap past the end
        for i in range(n):
            wet[i] = feedback * (buf[(i - d) % n] + wet[(i - d) % n])
    wet = lowpass_loop(wet, cutoff)
    lows = lowpass_loop(wet, 260)  # keep the bass out of the repeats, so they stay airy
    wet = [w - l for w, l in zip(wet, lows)]
    return [x + mix * w for x, w in zip(buf, wet)]


def lowpass_loop(buf, cutoff):
    """One-pole low-pass run around the loop twice so the seam has no step."""
    a = 1.0 - math.exp(-2 * math.pi * cutoff / RATE)
    y = 0.0
    for _ in range(2):
        out = []
        for x in buf:
            y += (x - y) * a
            out.append(y)
    return out


def arrange_lofi(cfg, rng, beat_len, bar_len, length):
    """Town and loading: keys, bass, melody or music box, boom-bap or brushes."""
    progression = cfg["progression"]
    music = [0.0] * length
    drums = [0.0] * length
    kicks = []
    for bar, (chord, root) in enumerate(progression):
        bar_start = bar * bar_len
        # Chords: a slightly strummed hit on beat 1, a softer push on the "and" of 3.
        for offset, dur, vel in [(0.0, 2.4 * beat_len, 0.16), (2.5 * beat_len, 1.4 * beat_len, 0.09)]:
            for k, note in enumerate(chord):
                start = bar_start + offset + k * 0.018 + rng.uniform(0, 0.01)
                add(music, int(start * RATE), keys(note, dur, vel * rng.uniform(0.85, 1.0), rng.uniform(0, 6.28), **cfg.get("keys", {})))
        # Bass: root on 1, a fifth or octave pickup before the next bar.
        add(music, int(bar_start * RATE), bass(root, 2.6 * beat_len, 0.42))
        pick = root + (7 if bar % 2 == 0 else 12)
        add(music, int((bar_start + 3 * beat_len) * RATE), bass(pick, 0.8 * beat_len, 0.3))
        if cfg["arp"]:
            # Music box: the chord's upper notes an octave up, rising then falling in eighths.
            tones = sorted(n + 12 for n in chord[1:])
            line = tones + tones[-2:0:-1]
            for step in range(8):
                if step == 7 and bar % 2 == 1:
                    continue
                note = line[step % len(line)]
                add(music, int((bar_start + step * beat_len / 2 + rng.uniform(0, 0.012)) * RATE), bell(note, 0.06 * rng.uniform(0.8, 1.0), cfg.get("bell_decay", 2.6)))
        # Melody: a few pentatonic notes in the second and fourth bar of each phrase.
        if bar % 4 in (1, 3) and not cfg["arp"]:
            for step in sorted(rng.sample(range(8), rng.choice([2, 3]))):
                note = rng.choice(cfg["scale"])
                start = bar_start + step * beat_len / 2 + rng.uniform(0, 0.02)
                add(music, int(start * RATE), keys(note, 0.7 * beat_len, 0.07, rng.uniform(0, 6.28), **cfg.get("keys", {})))
        swing = beat_len * 0.62
        for beat in range(4):
            beat_t = bar_start + beat * beat_len
            if cfg["drums"] == "boom_bap":
                # Boom-bap with a lazy swing on the off-beat hats.
                if beat in (0, 2):
                    kicks.append(beat_t)
                    add(drums, int(beat_t * RATE), kick(0.75))
                if beat == 2 and bar % 4 == 3:
                    kicks.append(beat_t + swing)
                    add(drums, int((beat_t + swing) * RATE), kick(0.5))
                if beat in (1, 3):
                    add(drums, int((beat_t + 0.012) * RATE), snare(rng, 0.32))
                add(drums, int(beat_t * RATE), hat(rng, 0.10))
                add(drums, int((beat_t + swing) * RATE), hat(rng, 0.06 * rng.uniform(0.7, 1.0)))
            else:
                # Brushes: a soft snare swish on 2 and 4 and a swung shaker; no kick.
                if beat in (1, 3):
                    add(drums, int((beat_t + 0.015) * RATE), snare(rng, 0.14 * cfg.get("drum_gain", 1.0)))
                add(drums, int(beat_t * RATE), hat(rng, 0.05 * cfg.get("drum_gain", 1.0)))
                add(drums, int((beat_t + swing) * RATE), hat(rng, 0.035 * rng.uniform(0.7, 1.0) * cfg.get("drum_gain", 1.0)))
    return music, drums, kicks


def at(t):
    return int(t * RATE)


def arrange_quiz(cfg, rng, beat, bar_len, length):
    """Upbeat quiz: short keyboard stabs, a bouncing octave bass, a catchy marimba hook,
    four-to-the-floor-ish kick with claps."""
    music, drums, kicks = [0.0] * length, [0.0] * length, []
    hook_a = [(0, 0), (1, 1), (2, 2), (4, 3), (6, 2)]
    hook_b = [(0, 3), (2, 2), (3, 1), (4, 0)]
    turn = [(0, 3), (2, 2), (4, 1), (5, 2), (6, 3), (7, 4)]
    prog = cfg["progression"]
    for b, (chord, root) in enumerate(prog):
        t0 = b * bar_len
        for off, dur, vel in [(0.0, 0.45, 0.12), (1.5, 0.4, 0.09), (2.5, 0.4, 0.08), (3.0, 0.45, 0.1)]:
            for k, n in enumerate(chord):
                add(music, at(t0 + off * beat + k * 0.006), keys(n, dur * beat, vel * rng.uniform(0.9, 1.0), rng.uniform(0, 6.28),
                                                                 decay=2.5, release=14.0, wow_depth=0.0015, trem_rate=5.0))
        for e in range(8):
            n = root + 7 if e == 7 else root + (12 if e % 2 else 0)
            add(music, at(t0 + e * beat / 2), bass(n, 0.38 * beat, 0.3 if e % 2 == 0 else 0.22))
        tones = sorted(chord)
        hook = turn if b % 8 == 7 else (hook_a if b % 2 == 0 else hook_b)
        for step, idx in hook:
            note = tones[idx % len(tones)] + 12 + (12 if idx >= len(tones) else 0)
            add(music, at(t0 + step * beat / 2 + rng.uniform(0, 0.008)), marimba(note, 0.12))
        for e in range(8):
            tt = t0 + e * beat / 2 + (beat * 0.04 if e % 2 else 0.0)
            if e in (0, 4) or (e == 5 and b % 2 == 1):
                kicks.append(tt)
                add(drums, at(tt), kick(0.7))
            if e in (2, 6):
                add(drums, at(tt), clap(rng, 0.3))
                add(drums, at(tt), snare(rng, 0.12))
            add(drums, at(tt), hat(rng, 0.08 if e % 2 == 0 else 0.11))
        if b % 4 == 3:
            for i in range(4):
                add(drums, at(t0 + 3 * beat + i * beat / 4), hat(rng, 0.05 + 0.015 * i))
    return music, drums, kicks


def arrange_errands(cfg, rng, beat, bar_len, length):
    """Cozy shopping jazz: walking bass, Charleston comping, a few vibraphone notes, swung brushes."""
    music, drums, kicks = [0.0] * length, [0.0] * length, []
    prog = cfg["progression"]
    pent = [70, 72, 74, 77, 79, 82]
    swing = beat * 0.66
    for b, (chord, root) in enumerate(prog):
        t0 = b * bar_len
        nxt = prog[(b + 1) % len(prog)][1]
        approach = nxt + (1 if rng.random() < 0.5 else -1)
        while approach > root + 9:
            approach -= 12
        while approach < root - 5:
            approach += 12
        for k, n in enumerate([root, third_of(chord, root), root + 7, approach]):
            add(music, at(t0 + k * beat + rng.uniform(0, 0.01)), bass(n, 0.85 * beat, 0.36 if k == 0 else 0.3))
        hits = [(0.0, 1.0, 0.11), (1.5, 0.6, 0.08)] + ([(3.5, 0.5, 0.07)] if b % 2 else [])
        for off, dur, vel in hits:
            for k, n in enumerate(chord):
                add(music, at(t0 + off * beat + k * 0.012), keys(n, dur * beat, vel * rng.uniform(0.85, 1.0), rng.uniform(0, 6.28),
                                                                 decay=1.6, release=9.0))
        if b % 4 in (1, 3) or b % 8 == 6:
            for step in sorted(rng.sample(range(8), rng.choice([3, 4]))):
                tt = t0 + (step // 2) * beat + (swing if step % 2 else 0.0)
                add(music, at(tt), bell(rng.choice(pent), 0.075, 2.2))
        for k in range(4):
            tt = t0 + k * beat
            if k in (0, 2):
                kicks.append(tt)
                add(drums, at(tt), kick(0.35))
            if k in (1, 3):
                add(drums, at(tt + 0.01), snare(rng, 0.16))
            add(drums, at(tt), hat(rng, 0.07))
            if k in (1, 3):
                add(drums, at(tt + swing), hat(rng, 0.05))
    return music, drums, kicks


def arrange_mystery(cfg, rng, beat, bar_len, length):
    """Sneaky: a soft pad, tiptoeing pizzicato, woodblock ticks and a low bell now and then."""
    music, drums, kicks = [0.0] * length, [0.0] * length, []
    for b, (chord, root) in enumerate(cfg["progression"]):
        t0 = b * bar_len
        for n in chord:
            add(music, at(t0), keys(n, 3.6 * beat, 0.05, rng.uniform(0, 6.28), decay=0.3, release=3.0, attack=0.35, trem_rate=3.0))
        for k, n in enumerate([root, root + 7, root + 12, root + 7]):
            add(music, at(t0 + k * beat), pluck(n, 0.34 if k == 0 else 0.26, decay=6.0, length=0.6))
        tones = sorted(chord)
        line = [tones[0], tones[1], tones[2], tones[1]] if b % 4 != 3 else [tones[2], tones[1], tones[0], tones[0] - 12]
        for k, n in enumerate(line):
            add(music, at(t0 + (2 * k + 1) * beat / 2 + rng.uniform(0, 0.01)), pluck(n + 12, 0.13, decay=7.0, length=0.5))
        if b % 4 == 3:
            add(music, at(t0 + 2.5 * beat), bell(tones[-1] + 12, 0.06, 1.0))
        add(drums, at(t0), kick(0.4))
        kicks.append(t0)
        for k in (1, 3):
            add(drums, at(t0 + k * beat), tock(1250 if k == 1 else 950, 0.22))
        for e in range(8):
            add(drums, at(t0 + e * beat / 2 + (beat * 0.08 if e % 2 else 0.0)), hat(rng, 0.03))
    return music, drums, kicks


def arrange_focus(cfg, rng, beat, bar_len, length):
    """Calm puzzles: slow, soft chords, a long bass note, one or two bell notes a bar, a quiet shaker."""
    music, drums, kicks = [0.0] * length, [0.0] * length, []
    pent = [74, 76, 78, 81, 83, 86]
    for b, (chord, root) in enumerate(cfg["progression"]):
        t0 = b * bar_len
        for off, dur, vel in [(0.0, 2.8, 0.1), (3.0, 0.9, 0.05)]:
            for k, n in enumerate(chord):
                add(music, at(t0 + off * beat + k * 0.03), keys(n, dur * beat, vel * rng.uniform(0.85, 1.0), rng.uniform(0, 6.28),
                                                                decay=0.35, release=2.5, attack=0.2, trem_rate=2.4, wow_depth=0.0035))
        add(music, at(t0), bass(root, 3.6 * beat, 0.3))
        for step in sorted(rng.sample(range(4), rng.choice([1, 2]))):
            add(music, at(t0 + step * beat + rng.uniform(0, 0.03)), bell(rng.choice(pent), 0.05, 1.4))
        for e in range(8):
            add(drums, at(t0 + e * beat / 2 + (beat * 0.06 if e % 2 else 0.0)), hat(rng, 0.025 if e % 2 else 0.018))
        add(drums, at(t0 + 2 * beat), snare(rng, 0.05))
    return music, drums, kicks


def arrange_outdoors(cfg, rng, beat, bar_len, length):
    """Playful zoo: a ukulele strum, an oom-pah bass, a hopping marimba tune, claps and a woodblock."""
    music, drums, kicks = [0.0] * length, [0.0] * length, []
    strum = [(0.0, 1), (1.0, 1), (1.5, -1), (2.5, -1), (3.0, 1), (3.5, -1)]
    hop_a = [(0, 2), (1, 1), (2, 2), (3, 3), (4, 2)]
    hop_b = [(0, 3), (2, 2), (4, 1), (6, 0)]
    run = [0, 1, 2, 3, 4, 5, 4, 5]
    pent = [77, 79, 81, 84, 86, 89]
    for b, (chord, root) in enumerate(cfg["progression"]):
        t0 = b * bar_len
        for off, direction in strum:
            notes = [n + 12 for n in sorted(chord)][::direction]
            for k, n in enumerate(notes):
                add(music, at(t0 + off * beat + k * 0.012), pluck(n, 0.07 if direction > 0 else 0.05, decay=5.0, length=0.6))
        for off, n, dur in [(0.0, root, 0.6), (2.0, root + 7, 0.6), (3.5, root + 12, 0.35)]:
            add(music, at(t0 + off * beat), bass(n, dur * beat, 0.34))
        tones = sorted(chord)
        if b % 4 == 3:
            for step, idx in enumerate(run):
                add(music, at(t0 + step * beat / 2), marimba(pent[idx], 0.1))
        else:
            for step, idx in (hop_a if b % 2 == 0 else hop_b):
                add(music, at(t0 + step * beat / 2 + rng.uniform(0, 0.008)), marimba(tones[idx % len(tones)] + 12, 0.12))
        for e in range(8):
            tt = t0 + e * beat / 2 + (beat * 0.06 if e % 2 else 0.0)
            if e in (0, 4):
                kicks.append(tt)
                add(drums, at(tt), kick(0.6))
            if e in (2, 6):
                add(drums, at(tt), clap(rng, 0.22))
            add(drums, at(tt), hat(rng, 0.06 if e % 2 else 0.045))
        if b % 2 == 1:
            add(drums, at(t0 + 3.5 * beat), tock(1100, 0.2))
    return music, drums, kicks


ARRANGE = {"lofi": arrange_lofi, "quiz": arrange_quiz, "errands": arrange_errands, "mystery": arrange_mystery,
           "focus": arrange_focus, "outdoors": arrange_outdoors}


def render(cfg):
    rng = random.Random(cfg["seed"])
    beat_len = 60.0 / cfg["bpm"]
    bar_len = 4 * beat_len
    length = int(round(len(cfg["progression"]) * bar_len * RATE))
    music, drums, kicks = ARRANGE[cfg.get("style", "lofi")](cfg, rng, beat_len, bar_len, length)
    # Gentle sidechain: the music dips under each kick.
    duck = [1.0] * length
    for k in kicks:
        s = int(k * RATE)
        for i in range(int(0.3 * RATE)):
            t = i / RATE
            duck[(s + i) % length] = min(duck[(s + i) % length], 1.0 - cfg.get("duck", 0.35) * math.exp(-t * 9))
    music = [m * d for m, d in zip(music, duck)]
    echo = cfg.get("echo")
    if echo:
        music = echo_loop(music, echo["beats"] * beat_len, echo["feedback"], echo["mix"], echo["cutoff"])
    music = lowpass_loop(music, cfg["cutoff"])
    drums = lowpass_loop(drums, cfg.get("drum_cutoff", 9000))
    mix = [m + d for m, d in zip(music, drums)]
    # Remove any DC offset, then normalise to a peak of 0.7 (about -3 dBFS); no clipping.
    mean = sum(mix) / len(mix)
    mix = [x - mean for x in mix]
    peak = max(abs(x) for x in mix) or 1.0
    return [x / peak * 0.7 for x in mix]


def write(samples, path):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples))


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--track", choices=sorted(TRACKS), help="one track (default: all)")
    parser.add_argument("--out", help="output WAV (with --track only)")
    args = parser.parse_args()
    if args.out and not args.track:
        parser.error("--out needs --track")
    for name in [args.track] if args.track else sorted(TRACKS):
        cfg = TRACKS[name]
        out = args.out or os.path.normpath(os.path.join(here, "..", "audio", "music", cfg["file"]))
        samples = render(cfg)
        write(samples, out)
        print("%s: wrote %s: %.1f s, %d bars at %d BPM" % (name, out, len(samples) / RATE, len(cfg["progression"]), cfg["bpm"]))


if __name__ == "__main__":
    main()
