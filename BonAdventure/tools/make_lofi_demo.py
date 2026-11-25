#!/usr/bin/env python3
"""Synthesises the demo lofi music loops (25 Nov 2026, user: "a lofi BGM just for the demo";
later the same day: "add a different soundtrack for loading screen").

Original music made here from sine/noise oscillators: no samples, recordings or third-party
material. Pure Python (no numpy). Writes seamless mono 16-bit WAV loops; Godot imports them as
forward loops with QOA compression (the .wav.import files beside them).

    python3 tools/make_lofi_demo.py                  # both tracks into audio/music/
    python3 tools/make_lofi_demo.py --track loading  # one track
    python3 tools/make_lofi_demo.py --track town --out X.wav

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

RATE = 22050
# Town: Fmaj7 Em7 Dm7 Cmaj7, then the same with a Dm9 G7 turnaround; boom-bap drums.
_TA = [([65, 69, 72, 76], 41), ([64, 67, 71, 74], 40), ([62, 65, 69, 72], 38), ([60, 64, 67, 71], 36)]
_TB = [([65, 69, 72, 76], 41), ([64, 67, 71, 74], 40), ([62, 65, 69, 72, 76], 38), ([67, 71, 74, 77], 43)]
# Loading: dreamier, in A: Amaj9 F#m9 Dmaj9 E6sus; music-box arpeggio, brushes and a shaker, no kick.
_LA = [([57, 61, 64, 68, 71], 45), ([54, 61, 64, 68], 42), ([62, 66, 69, 73, 76], 38), ([59, 64, 66, 69], 40)]
# Each chord: MIDI notes of a voicing and its bass root.
TRACKS = {
    "town": {"file": "town_lofi_demo.wav", "bpm": 72, "seed": 7, "progression": _TA + _TB + _TA + _TB,
             "scale": [72, 74, 76, 79, 81, 84], "drums": "boom_bap", "arp": False, "cutoff": 2600},
    # 25 Nov 2026, user: "a bit slower and dreamier" (was 66 BPM, no echo, 3200 Hz, firmer keys).
    "loading": {"file": "loading_lofi_demo.wav", "bpm": 56, "seed": 23, "progression": _LA + _LA,
                "scale": [76, 78, 81, 83, 85, 88], "drums": "brushes", "arp": True, "cutoff": 2300,
                "keys": {"decay": 0.5, "wow_depth": 0.0045, "trem_rate": 2.6, "release": 2.5},
                "bell_decay": 1.5, "drum_gain": 0.6,
                "echo": {"beats": 0.75, "feedback": 0.42, "mix": 0.5, "cutoff": 1800}},
}

def hz(note):
    return 440.0 * 2 ** ((note - 69) / 12.0)


def add(buf, start, samples, gain=1.0):
    """Mixes `samples` into the loop at `start`, wrapping tails past the end to the start."""
    n = len(buf)
    for i, s in enumerate(samples):
        buf[(start + i) % n] += s * gain


def keys(note, dur, vel, wobble_phase, decay=1.1, wow_depth=0.0025, trem_rate=4.2, release=6.0):
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
        attack = min(1.0, t / 0.012)
        bell = math.sin(2 * phase) * 0.18 * math.exp(-t * 7.0) + math.sin(3 * phase) * 0.05 * math.exp(-t * 4.0)
        trem = 0.88 + 0.12 * math.sin(2 * math.pi * trem_rate * t)
        out[i] = (math.sin(phase) + bell) * env * attack * trem * vel
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


def snare(rng, vel):
    count = int(0.25 * RATE)
    out = [0.0] * count
    lp = 0.0
    for i in range(count):
        t = i / RATE
        lp += (rng.uniform(-1, 1) - lp) * 0.35          # soft, dusty noise
        tone = math.sin(2 * math.pi * 190 * t) * math.exp(-t * 30) * 0.5
        out[i] = (lp * math.exp(-t * 16) + tone) * vel
    return out


def hat(rng, vel):
    count = int(0.06 * RATE)
    out = [0.0] * count
    prev = 0.0
    for i in range(count):
        t = i / RATE
        n = rng.uniform(-1, 1)
        out[i] = (n - prev) * math.exp(-t * 70) * vel  # crude high-pass
        prev = n
    return out


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


def render(cfg):
    rng = random.Random(cfg["seed"])
    beat_len = 60.0 / cfg["bpm"]
    bar_len = 4 * beat_len
    progression = cfg["progression"]
    length = int(round(len(progression) * bar_len * RATE))
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
    # Gentle sidechain: the music dips under each kick.
    duck = [1.0] * length
    for k in kicks:
        s = int(k * RATE)
        for i in range(int(0.3 * RATE)):
            t = i / RATE
            duck[(s + i) % length] = min(duck[(s + i) % length], 1.0 - 0.35 * math.exp(-t * 9))
    music = [m * d for m, d in zip(music, duck)]
    echo = cfg.get("echo")
    if echo:
        music = echo_loop(music, echo["beats"] * beat_len, echo["feedback"], echo["mix"], echo["cutoff"])
    music = lowpass_loop(music, cfg["cutoff"])
    drums = lowpass_loop(drums, 5200)
    # Vinyl: soft hiss plus sparse crackles.
    vinyl = [0.0] * length
    hiss = 0.0
    for i in range(length):
        hiss += (rng.uniform(-1, 1) - hiss) * 0.2
        vinyl[i] = hiss * 0.012
        if rng.random() < 0.0009:
            vinyl[i] += rng.uniform(-1, 1) * rng.uniform(0.03, 0.12)
    mix = [m + d + v for m, d, v in zip(music, drums, vinyl)]
    peak = max(abs(x) for x in mix) or 1.0
    # Normalise to about -3 dBFS with a soft clip.
    return [math.tanh(x / peak * 1.1) * 0.7 for x in mix]


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
