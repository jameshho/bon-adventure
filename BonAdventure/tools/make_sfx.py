#!/usr/bin/env python3
"""Synthesises the game's cartoony sound effects (25 Nov 2026, user: coin and right/wrong sounds).

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
LOOPED = {"engine_e", "engine_f"}

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
                samples = normalise(make()) if name in LOOPED else finish(make())
                path = os.path.join(out, cue, name + ".wav")
                write(samples, path)
                print("%s  %.2f s" % (path, len(samples) / RATE))
    if args.write:
        if not CHOSEN:
            print("Nothing chosen yet (CHOSEN is empty).")
        for cue, (name, target) in CHOSEN.items():
            make = {n: m for n, m, _a in CANDIDATES[cue]}[name]
            path = os.path.join(PROJECT, target.replace("res://", ""))
            write(normalise(make()) if name in LOOPED else finish(make()), path)
            print(path)


if __name__ == "__main__":
    main()
