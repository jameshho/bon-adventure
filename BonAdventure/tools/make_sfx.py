#!/usr/bin/env python3
"""Synthesises the game's cartoony sound effects (25 Nov 2026, user: coin and right/wrong sounds;
later the same day the button sounds).

Original sounds made here from sine and noise oscillators: no samples, recordings or third-party
material. Pure Python (no numpy). Writes short mono 16-bit 22.05 kHz WAV files, peak -1 dBFS,
with a few milliseconds of fade at each end.

    python3 tools/make_sfx.py --out ~/Desktop/sfx-review   # every candidate, to listen to
    python3 tools/make_sfx.py --list                       # names and one-line descriptions
    python3 tools/make_sfx.py --write                      # the chosen ones into audio/sfx/

Candidates go to <out>/<cue>/<name>.wav. --out refuses a folder inside the project (Godot would
import them). CHOSEN names the candidate each cue uses in the game and where it goes; empty
until the user picks by ear. Guide: docs/guides/VOICE.md ("Sound effects").
"""
import argparse
import math
import os
import random
import struct
import wave

RATE = 22050
PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# cue -> (candidate name, project path): the user's picks by ear (25 Nov 2026); --write makes these.
CHOSEN = {
    "coin.stamp": ("coin_b", "res://audio/sfx/ui/coin_stamp.wav"),
    "answer.correct": ("correct_a", "res://audio/sfx/ui/answer_correct.wav"),
    "answer.wrong": ("wrong_a", "res://audio/sfx/ui/answer_wrong.wav"),
    "ui.confirm": ("confirm_b", "res://audio/sfx/ui/button_confirm.wav"),
    "ui.decline": ("decline_b", "res://audio/sfx/ui/button_decline.wav"),
    "ui.tap": ("tap_b", "res://audio/sfx/ui/button_tap.wav"),
    "ui.select": ("select_c", "res://audio/sfx/ui/button_select.wav"),
    "mahjong.win": ("win_a", "res://audio/sfx/mahjong/win.wav"),
}


def hz(note):
    return 440.0 * 2 ** ((note - 69) / 12.0)


def silence(seconds):
    return [0.0] * int(seconds * RATE)


def mix(buf, start, samples, gain=1.0):
    """Adds `samples` into `buf` from `start` seconds, growing it when needed."""
    at = int(start * RATE)
    if at + len(samples) > len(buf):
        buf.extend([0.0] * (at + len(samples) - len(buf)))
    for i, s in enumerate(samples):
        buf[at + i] += s * gain
    return buf


def partials(freq, seconds, parts, attack=0.003):
    """A struck tone: each part is (ratio, gain, decay seconds); exponential decays."""
    count = int(seconds * RATE)
    out = [0.0] * count
    for ratio, gain, decay in parts:
        f = freq * ratio
        if f >= RATE * 0.45:
            continue
        step = 2 * math.pi * f / RATE
        k = math.exp(-1.0 / (decay * RATE))
        env = gain
        for i in range(count):
            a = min(1.0, i / (attack * RATE)) if attack > 0 else 1.0
            out[i] += math.sin(step * i) * env * a
            env *= k
    return out


def bell(freq, seconds, decay=0.5):
    """A small bright metal bell: slightly inharmonic partials, the high ones dying first."""
    return partials(freq, seconds, [(1.0, 1.0, decay), (2.0, 0.55, decay * 0.6), (2.76, 0.35, decay * 0.4),
                                    (5.4, 0.22, decay * 0.18), (8.93, 0.12, decay * 0.1)])


def marimba(freq, seconds, decay=0.28):
    """A wooden bar: fundamental, the bar's 4x overtone, a soft mallet click."""
    out = partials(freq, seconds, [(1.0, 1.0, decay), (3.93, 0.32, decay * 0.25), (9.2, 0.08, 0.012)], attack=0.002)
    return out


def wood_block(freq, seconds=0.18, seed=1):
    """A hollow wooden knock: two damped partials and a puff of filtered noise."""
    rng = random.Random(seed)
    out = partials(freq, seconds, [(1.0, 1.0, 0.035), (2.45, 0.5, 0.02), (4.1, 0.2, 0.01)], attack=0.0008)
    low = 0.0
    for i in range(min(len(out), int(0.02 * RATE))):
        low += 0.35 * (rng.uniform(-1, 1) - low)
        out[i] += low * 0.6 * (1.0 - i / (0.02 * RATE))
    return out


def glide(f0, f1, seconds, decay, shape=0.5):
    """A sine sliding from f0 to f1 (a soft "boop"), with a short rise and an exponential fall."""
    count = int(seconds * RATE)
    out = [0.0] * count
    phase = 0.0
    for i in range(count):
        t = i / count
        f = f0 + (f1 - f0) * (t ** shape)
        phase += 2 * math.pi * f / RATE
        env = min(1.0, i / (0.006 * RATE), (count - i) / (0.012 * RATE)) * math.exp(-i / (decay * RATE))
        out[i] = (math.sin(phase) + 0.18 * math.sin(2 * phase)) * env
    return out


def sparkle(seconds, start_hz, end_hz, count, seed, gain=0.18):
    """A shower of tiny high pings sweeping from start_hz to end_hz."""
    rng = random.Random(seed)
    out = silence(seconds)
    for n in range(count):
        t = seconds * 0.8 * n / count + rng.uniform(0, 0.02)
        f = start_hz + (end_hz - start_hz) * n / max(1, count - 1)
        ping = partials(f * rng.uniform(0.97, 1.03), 0.12, [(1.0, 1.0, 0.03)], attack=0.001)
        mix(out, t, ping, gain * (1.0 - 0.5 * n / count))
    return out[:int(seconds * RATE)]


def lowpass(samples, cutoff):
    a = 1.0 - math.exp(-2 * math.pi * cutoff / RATE)
    out = []
    y = 0.0
    for s in samples:
        y += a * (s - y)
        out.append(y)
    return out


# --- The candidates -----------------------------------------------------------------------------

def coin_a():
    out = silence(0.0)
    mix(out, 0.0, bell(hz(91), 0.9, 0.22), 0.8)   # G6
    mix(out, 0.07, bell(hz(98), 0.9, 0.3), 1.0)    # D7
    return out


def coin_b():
    out = silence(0.0)
    for k, note in enumerate([84, 88, 91, 96]):    # C7 E7 G7 C8, quick arpeggio
        mix(out, k * 0.055, bell(hz(note - 12), 0.9, 0.16 + 0.05 * k), 0.75)
    mix(out, 0.12, sparkle(0.7, 2600, 5200, 9, 3), 1.0)
    return out


def coin_c():
    out = silence(0.0)
    mix(out, 0.0, partials(hz(88), 0.95, [(1.0, 1.0, 0.25), (2.0, 0.6, 0.18), (3.0, 0.4, 0.12), (4.2, 0.25, 0.06)]), 0.9)
    mix(out, 0.0, glide(1400, 2600, 0.16, 0.08, 0.6), 0.35)
    mix(out, 0.09, sparkle(0.8, 3400, 2200, 8, 7), 1.0)
    return out


def correct_a():
    out = silence(0.0)
    mix(out, 0.0, marimba(hz(76), 0.9), 0.9)      # E5
    mix(out, 0.11, marimba(hz(81), 0.9), 1.0)     # A5
    return out


def correct_b():
    out = silence(0.0)
    for k, note in enumerate([72, 76, 79]):         # C5 E5 G5
        mix(out, k * 0.075, marimba(hz(note), 0.9, 0.22 + 0.04 * k), 0.85)
    mix(out, 0.15, bell(hz(91), 0.8, 0.2), 0.25)    # a little glint on top
    return out


def correct_c():
    out = silence(0.0)
    mix(out, 0.0, glide(500, 1250, 0.09, 0.05, 0.4), 0.6)   # a soft "pop"
    mix(out, 0.07, bell(hz(84), 0.9, 0.26), 0.8)              # C7 ding
    mix(out, 0.07, bell(hz(79), 0.9, 0.26), 0.45)             # G6 underneath
    return out


def wrong_a():
    out = silence(0.0)
    mix(out, 0.0, marimba(hz(57), 0.8, 0.18), 1.0)   # A3
    mix(out, 0.16, marimba(hz(53), 0.8, 0.22), 0.9) # F3
    return lowpass(out, 2400)


def wrong_b():
    out = silence(0.0)
    mix(out, 0.0, glide(330, 290, 0.17, 0.09), 0.9)
    mix(out, 0.2, glide(270, 200, 0.45, 0.12), 0.9)
    return lowpass(out, 1800)


def wrong_c():
    out = silence(0.0)
    mix(out, 0.0, wood_block(520, seed=1), 1.0)
    mix(out, 0.14, wood_block(430, seed=2), 0.9)
    return out


def engine(f0, cycles, parts, noise, cutoff, seed):
    """A seamless engine loop: `cycles` firing cycles at f0 Hz (so the loop wraps exactly), each
    cycle a little louder or softer (a fixed random pattern), plus noise pulsed by the firing.
    parts: (harmonic, gain). Filters run over the loop twice so their state wraps too."""
    rng = random.Random(seed)
    count = int(round(cycles / f0 * RATE))
    beat = [rng.uniform(0.75, 1.0) for _ in range(cycles)]
    noise_src = [rng.uniform(-1, 1) for _ in range(count)]
    out = [0.0] * count
    for i in range(count):
        phase = cycles * i / count            # in cycles, exact over the loop
        k = int(phase) % cycles
        frac = phase - int(phase)
        pulse = math.exp(-frac * 5.0) * beat[k]   # each firing's punch
        tone = sum(g * math.sin(2 * math.pi * h * phase) for h, g in parts)
        out[i] = tone * (0.55 + 0.45 * pulse) + noise_src[i] * noise * pulse
    # One-pole low-pass, run twice round the loop so the seam has no step.
    a = 1.0 - math.exp(-2 * math.pi * cutoff / RATE)
    y = 0.0
    for _ in range(2):
        for i in range(count):
            y += a * (out[i] - y)
            out[i] = y if _ == 1 else out[i]
    return out


def engine_e():
    # Cartoony "brum-brum": 24 firings a second, strong low harmonics, a puff of noise each.
    return engine(24.0, 72, [(1, 1.0), (2, 0.7), (3, 0.45), (4, 0.25), (6, 0.12)], 0.35, 900, 11)


def engine_f():
    # Smoother, buzzier hum: 32 firings a second, more upper harmonics, less noise.
    return engine(32.0, 96, [(1, 0.8), (2, 1.0), (3, 0.6), (4, 0.45), (5, 0.3), (7, 0.15)], 0.15, 1400, 5)


## Candidates that loop: normalised only (no trim or fades, which would break the seam).
# --- Buttons (25 Nov 2026, user: a sound for confirm and decline, then every kind of button) ---
# Four matching families: a wooden marimba (like the right / wrong sounds), bubble pops, small
# bells and soft plucks. Confirm rises, decline falls, tap and select are tiny, delete is low.

def pluck(freq, seconds, decay=0.12):
    """A soft plucked string: harmonic partials, the upper ones dying first."""
    return partials(freq, seconds, [(1.0, 1.0, decay), (2.0, 0.45, decay * 0.5), (3.0, 0.2, decay * 0.3),
                                    (4.0, 0.08, decay * 0.2)], attack=0.0015)


def pop(f0, f1, seconds=0.07):
    """A bubble pop: a quick sine slide with a fast decay."""
    return glide(f0, f1, seconds, seconds * 0.35, shape=0.35)


def notes(make, plan):
    """`plan`: [(start seconds, note, gain)], each made with make(freq)."""
    out = silence(0.0)
    for start, note, gain in plan:
        mix(out, start, make(hz(note)), gain)
    return out


def confirm_a():
    return notes(lambda f: marimba(f, 0.35, 0.16), [(0.0, 79, 0.75), (0.07, 84, 1.0)])     # G5 C6


def confirm_b():
    out = silence(0.0)
    mix(out, 0.0, pop(480, 820, 0.07), 0.8)
    mix(out, 0.06, pop(700, 1250, 0.08), 1.0)
    return out


def confirm_c():
    return notes(lambda f: bell(f, 0.4, 0.14), [(0.0, 88, 0.7), (0.06, 95, 1.0)])          # E6 B6


def confirm_d():
    return notes(lambda f: pluck(f, 0.35, 0.14), [(0.0, 72, 0.75), (0.07, 79, 1.0)])       # C5 G5


def decline_a():
    return notes(lambda f: marimba(f, 0.32, 0.14), [(0.0, 79, 0.9), (0.08, 74, 0.8)])      # G5 D5


def decline_b():
    out = silence(0.0)
    mix(out, 0.0, pop(820, 560, 0.07), 0.9)
    mix(out, 0.07, pop(560, 360, 0.08), 0.8)
    return out


def decline_c():
    return notes(lambda f: bell(f, 0.35, 0.1), [(0.0, 83, 0.8), (0.07, 76, 0.7)])          # B5 E5


def decline_d():
    return notes(lambda f: pluck(f, 0.32, 0.12), [(0.0, 67, 0.9), (0.08, 62, 0.8)])        # G4 D4


def tap_a():
    return marimba(hz(81), 0.12, 0.05)                                                     # A5


def tap_b():
    return pop(560, 900, 0.05)


def tap_c():
    return bell(hz(93), 0.1, 0.035)                                                        # A6


def tap_d():
    return pluck(hz(74), 0.12, 0.05)                                                       # D5


def select_a():
    return notes(lambda f: marimba(f, 0.18, 0.07), [(0.0, 86, 1.0), (0.0, 74, 0.35)])      # D6 + D5


def select_b():
    out = silence(0.0)
    mix(out, 0.0, pop(700, 1000, 0.045), 0.8)
    mix(out, 0.035, pop(950, 1350, 0.05), 1.0)
    return out


def select_c():
    return bell(hz(91), 0.18, 0.06)                                                        # G6


def select_d():
    return notes(lambda f: pluck(f, 0.16, 0.07), [(0.0, 76, 0.7), (0.035, 83, 1.0)])       # E5 B5


def delete_a():
    return notes(lambda f: marimba(f, 0.45, 0.2), [(0.0, 62, 0.9), (0.1, 55, 1.0)])        # D4 G3


def delete_b():
    return pop(420, 140, 0.28)


def delete_c():
    """A soft downward swish: noise through a falling low-pass, with a low thump under it."""
    rng = random.Random(7)
    seconds = 0.32
    count = int(seconds * RATE)
    out = [0.0] * count
    y = 0.0
    for i in range(count):
        t = i / count
        cutoff = 2400 * (1 - t) + 250 * t
        a = 1.0 - math.exp(-2 * math.pi * cutoff / RATE)
        y += a * (rng.uniform(-1, 1) - y)
        out[i] = y * math.sin(math.pi * min(1.0, t * 1.6)) * 0.9
    mix(out, 0.17, partials(hz(43), 0.15, [(1.0, 1.0, 0.04)], attack=0.002), 0.7)
    return out


def delete_d():
    out = silence(0.0)
    mix(out, 0.0, wood_block(330, 0.2, seed=3), 0.9)
    mix(out, 0.09, wood_block(220, 0.24, seed=4), 1.0)
    return out


def paper_fold():
    """Folding a sheet of paper (user: "like folding paper"): two crinkly bursts, a crease then the
    fold pressed flat, each a cloud of tiny high crackles over a soft swish."""
    rng = random.Random(11)
    out = silence(0.34)
    for start, length, density, gain in [(0.0, 0.13, 260, 1.0), (0.16, 0.12, 180, 0.75)]:
        count = int(length * RATE)
        swish = 0.0
        for i in range(count):
            t = i / count
            env = math.sin(math.pi * min(1.0, t * 1.4)) * gain
            swish += 0.25 * (rng.uniform(-1, 1) - swish)
            out[int(start * RATE) + i] += swish * env * 0.35
        for _n in range(int(density * length)):
            at = start + rng.uniform(0, length)
            f = rng.uniform(2200, 6500)
            crackle = partials(f, 0.012, [(1.0, 1.0, 0.0025)], attack=0.0002)
            mix(out, at, crackle, gain * rng.uniform(0.15, 0.5) * math.sin(math.pi * (at - start) / length))
    return out


# --- Mahjong (25 Nov 2026, user: "also add sound effect to the Mahjong game"; one set for every
# language). The tile sounds are CC0 recordings (the review folder's cut list); these are the
# calls and the end of a hand. Pentatonic in D, like a table game in a tea house.

def gong(freq, seconds, decay=0.9, bend=0.015):
    """A small gong: inharmonic partials that sag a little in pitch, the high ones dying first."""
    count = int(seconds * RATE)
    out = [0.0] * count
    for ratio, gain, d in [(1.0, 1.0, decay), (1.48, 0.55, decay * 0.7), (2.02, 0.4, decay * 0.5),
                           (2.74, 0.28, decay * 0.35), (3.91, 0.16, decay * 0.2), (5.3, 0.08, decay * 0.12)]:
        phase = 0.0
        for i in range(count):
            t = i / RATE
            f = freq * ratio * (1.0 + bend * math.exp(-t * 6.0))
            phase += 2 * math.pi * f / RATE
            out[i] += math.sin(phase) * gain * math.exp(-t / d) * min(1.0, i / (0.004 * RATE))
    return out


PENTA = [62, 64, 66, 69, 71, 74, 76, 78, 81, 83, 86, 88, 90, 93]   # D major pentatonic, D4 up


def call_a():
    return notes(lambda f: marimba(f, 0.4, 0.14), [(0.0, 86, 0.8), (0.08, 93, 1.0)])    # D6 A6 "ta-da"


def call_b():
    return gong(hz(69), 0.8, 0.35)                                                      # small gong A4


def call_c():
    out = silence(0.0)
    mix(out, 0.0, wood_block(900, 0.15, seed=5), 0.8)
    mix(out, 0.07, wood_block(1200, 0.15, seed=6), 0.9)
    mix(out, 0.12, bell(hz(91), 0.4, 0.12), 0.5)
    return out


def mellow(freq, seconds, decay=0.25):
    """A soft, round wooden note: the fundamental and a quiet octave, no bright overtone or
    mallet click (those rang like a bell at the end of the win tune)."""
    return partials(freq, seconds, [(1.0, 1.0, decay), (2.0, 0.12, decay * 0.3)], attack=0.004)


def win_a():
    """A pentatonic tune climbing two octaves that ends on its top note, held, with a soft chord
    under it; soft wooden notes all the way (user, 25 Nov 2026: no "sharp bell sound" at the
    end, a longer melody, "the note should go up and end there")."""
    out = silence(0.0)
    tune = [62, 64, 66, 69, 71, 74, 76, 78, 81, 83]
    step = 0.07
    for k, note in enumerate(tune):
        mix(out, k * step, mellow(hz(note), 0.5, 0.18), 0.7)
    top = len(tune) * step
    for note, gain in [(86, 0.85), (78, 0.35), (74, 0.4), (62, 0.4)]:
        mix(out, top, mellow(hz(note), 1.2, 0.5), gain)
    return out


def win_b():
    out = silence(0.0)
    mix(out, 0.0, gong(hz(50), 1.6, 0.9), 1.0)                                          # D3 gong
    for k, note in enumerate([81, 83, 86, 88, 90, 93]):
        mix(out, 0.12 + k * 0.07, bell(hz(note), 0.8, 0.3), 0.35)
    return out


def win_c():
    """A zither sweep up two octaves of the pentatonic, then the top note rings."""
    out = silence(0.0)
    for k, note in enumerate(PENTA[:11]):
        mix(out, k * 0.035, pluck(hz(note), 1.0, 0.35 if k < 10 else 0.9), 0.55)
    mix(out, 0.4, pluck(hz(86), 1.2, 0.9), 0.8)
    return out


def over_a():
    return notes(lambda f: marimba(f, 0.6, 0.22), [(0.0, 81, 0.9), (0.14, 78, 0.85), (0.28, 74, 0.8)])   # A5 F#5 D5


def over_b():
    return gong(hz(50), 1.2, 0.6, bend=0.01)                                            # soft low gong D3


def over_c():
    out = silence(0.0)
    for k, note in enumerate(reversed(PENTA[3:10])):
        mix(out, k * 0.05, pluck(hz(note), 0.8, 0.3), 0.5)
    return out

LOOPED = {"engine_e", "engine_f"}
# Candidates allowed past finish()'s 0.95 s (the win and end-of-hand sounds ring out).
LONGEST = {"win_a": 2.0, "win_b": 2.0, "win_c": 2.0, "over_a": 1.2, "over_b": 1.6, "over_c": 1.4, "call_b": 1.0}

CANDIDATES = {
    "coin.stamp": [
        ("coin_a", coin_a, "two quick bright bell pings, G6 then D7 (a classic gold 'ching-ching')"),
        ("coin_b", coin_b, "fast four-note rising bell arpeggio with a shimmer of sparkles"),
        ("coin_c", coin_c, "one rich golden 'kling' with a whoosh up and a falling sparkle tail"),
    ],
    "answer.correct": [
        ("correct_a", correct_a, "two-note rising marimba, E5 then A5 (warm wooden 'da-ding')"),
        ("correct_b", correct_b, "three-note rising marimba C-E-G with a small bell glint"),
        ("correct_c", correct_c, "soft bubble pop then a bright bell 'ding'"),
    ],
    "answer.wrong": [
        ("wrong_a", wrong_a, "two soft falling marimba notes, A3 then F3 ('uh-oh', gentle)"),
        ("wrong_b", wrong_b, "two low sine 'boop-boop' sliding down, muffled"),
        ("wrong_c", wrong_c, "two hollow wood-block knocks, the second lower (matches the wobble)"),
    ],
    "ui.confirm": [
        ("confirm_a", confirm_a, "marimba, two notes up (G5 C6), like the right-shelf chime"),
        ("confirm_b", confirm_b, "two bubble pops sliding up"),
        ("confirm_c", confirm_c, "two small bells up (E6 B6)"),
        ("confirm_d", confirm_d, "soft plucked string, two notes up (C5 G5)"),
    ],
    "ui.decline": [
        ("decline_a", decline_a, "marimba, two notes down (G5 D5), gentle"),
        ("decline_b", decline_b, "two bubble pops sliding down"),
        ("decline_c", decline_c, "two small bells down (B5 E5)"),
        ("decline_d", decline_d, "soft plucked string, two notes down (G4 D4)"),
    ],
    "ui.tap": [
        ("tap_a", tap_a, "one tiny marimba knock (A5)"),
        ("tap_b", tap_b, "one tiny bubble pop"),
        ("tap_c", tap_c, "one tiny bell tick (A6)"),
        ("tap_d", tap_d, "one tiny pluck (D5)"),
    ],
    "ui.select": [
        ("select_a", select_a, "a bright marimba knock with its octave (D6 + D5)"),
        ("select_b", select_b, "two quick rising pops"),
        ("select_c", select_c, "a bell glint (G6)"),
        ("select_d", select_d, "a quick two-note pluck up (E5 B5)"),
    ],
    "ui.delete": [
        ("delete_a", delete_a, "marimba, two low notes down (D4 G3)"),
        ("delete_b", delete_b, "one deep pop sliding down"),
        ("delete_c", delete_c, "a soft downward swish with a low thump"),
        ("delete_d", delete_d, "two hollow wood knocks, the second lower"),
        ("paper_fold", paper_fold, "folding paper: a crinkly crease, then the fold pressed flat"),
    ],
    "mahjong.call": [
        ("call_a", call_a, "two quick bright marimba notes, 'ta-da' (D6 A6)"),
        ("call_b", call_b, "a small gong (A4)"),
        ("call_c", call_c, "two wood knocks and a bell glint"),
    ],
    "mahjong.win": [
        ("win_a", win_a, "a pentatonic marimba run up and a bell chord"),
        ("win_b", win_b, "a low gong and rising bells"),
        ("win_c", win_c, "a zither sweep up two octaves, the top note ringing"),
    ],
    "mahjong.over": [
        ("over_a", over_a, "three soft falling marimba notes (someone else won, or a draw)"),
        ("over_b", over_b, "a soft low gong"),
        ("over_c", over_c, "a soft zither sweep down"),
    ],
    "vehicle.engine": [
        ("engine_e", engine_e, "cartoony 'brum-brum' engine loop, 24 firings a second (3 s loop)"),
        ("engine_f", engine_f, "smoother, buzzier engine hum, 32 firings a second (3 s loop)"),
    ],
}


def normalise(samples, peak_db=-1.0):
    peak = max(abs(s) for s in samples) or 1.0
    return [s * 10 ** (peak_db / 20.0) / peak for s in samples]


def finish(samples, peak_db=-1.0, fade_in=0.002, fade_out=0.15, longest=0.95):
    """Trims trailing near-silence (and anything past `longest` seconds), fades both ends and
    normalises the peak."""
    floor = max(abs(s) for s in samples) * 0.001
    end = min(len(samples), int(longest * RATE))
    while end > 1 and abs(samples[end - 1]) < floor:
        end -= 1
    out = samples[:end]
    n_in = max(1, int(fade_in * RATE))
    n_out = max(1, min(len(out) // 2, int(fade_out * RATE)))
    for i in range(n_in):
        out[i] *= i / n_in
    for i in range(n_out):
        out[-1 - i] *= (i / n_out) ** 2
    peak = max(abs(s) for s in out) or 1.0
    gain = 10 ** (peak_db / 20.0) / peak
    return [s * gain for s in out]


def write(samples, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", help="folder for every candidate (<out>/<cue>/<name>.wav), outside the project")
    parser.add_argument("--list", action="store_true", help="print the candidates")
    parser.add_argument("--write", action="store_true", help="write the CHOSEN candidates into the project")
    args = parser.parse_args()
    if args.list or not (args.out or args.write):
        for cue, items in CANDIDATES.items():
            for name, _make, about in items:
                print("%-15s %-10s %s" % (cue, name, about))
    if args.out:
        out = os.path.abspath(os.path.expanduser(args.out))
        if out == PROJECT or out.startswith(PROJECT + os.sep):
            parser.error("--out must be outside the project, or Godot imports the candidates")
        for cue, items in CANDIDATES.items():
            for name, make, _about in items:
                samples = normalise(make()) if name in LOOPED else finish(make(), longest=LONGEST.get(name, 0.95))
                path = os.path.join(out, cue, name + ".wav")
                write(samples, path)
                print("%s  %.2f s" % (path, len(samples) / RATE))
    if args.write:
        if not CHOSEN:
            print("Nothing chosen yet (CHOSEN is empty).")
        for cue, (name, target) in CHOSEN.items():
            make = {n: m for n, m, _a in CANDIDATES[cue]}[name]
            path = os.path.join(PROJECT, target.replace("res://", ""))
            write(normalise(make()) if name in LOOPED else finish(make(), longest=LONGEST.get(name, 0.95)), path)
            print(path)


if __name__ == "__main__":
    main()
