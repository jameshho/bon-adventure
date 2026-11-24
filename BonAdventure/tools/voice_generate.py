#!/usr/bin/env python3
"""Makes the spoken-word clips with Amazon Polly (24 Nov 2026; guide docs/guides/VOICE.md).

What to say comes from tools/voice_manifest.gd (one SSML line per word and language, from
data/words.json and data/sounds.json "voice"); this script only sends it to Polly through the
AWS CLI (`aws polly synthesize-speech`, the profile set up with `aws sso login`) and saves
<out>/<lang>/<file>.ogg. Run it from the Godot project folder (BonAdventure/).

Nothing is written unless asked:
  python3 tools/voice_generate.py --lang es --keys apple,doctor
      dry run: prints the SSML and the Polly voice for each clip; calls nothing.
  python3 tools/voice_generate.py --lang es,zh --keys apple,doctor --out <folder outside the project>
      samples to listen to before anything goes into the game (keep them out of the project
      folder, or Godot imports them).
  python3 tools/voice_generate.py --lang es --write
      the game's clips in res://audio/voice/ (only new or changed ones; --force redoes all).
      Then import them: godot --headless --path . --import

Each output folder keeps <lang>/generated.json: per word the clip name and a fingerprint of the
voice settings and SSML, so a later run redoes only words whose text or voice changed and
lists clips whose word is gone. Polly output is used under the AWS Service Terms.
"""
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed

GODOT_DEFAULT = "/Applications/Godot.app/Contents/MacOS/Godot"
GAME_FOLDER = os.path.join("audio", "voice")
FORMAT = "ogg_vorbis"
SAMPLE_RATE = "22050"


def fail(message):
    print("ERROR: " + message, file=sys.stderr)
    sys.exit(1)


def build_manifest(godot):
    """Runs tools/voice_manifest.gd (isolated HOME, so no saves are touched) and reads its JSON."""
    work = tempfile.mkdtemp(prefix="voice_manifest_")
    try:
        out = os.path.join(work, "manifest.json")
        env = dict(os.environ, HOME=os.path.join(work, "home"))
        os.makedirs(env["HOME"])
        run = subprocess.run(
            [godot, "--headless", "--path", ".", "--script", "res://tools/voice_manifest.gd", "--", "--out", out],
            env=env, capture_output=True, text=True)
        for line in run.stdout.splitlines():
            if line.startswith(("FAIL:", "VOICE MANIFEST")):
                print(line)
        if run.returncode != 0 or not os.path.exists(out):
            fail("voice_manifest.gd failed (exit %d)" % run.returncode)
        with open(out, encoding="utf-8") as handle:
            return json.load(handle)
    finally:
        shutil.rmtree(work, ignore_errors=True)


def fingerprint(settings, ssml):
    text = "|".join([settings.get("voice", ""), settings.get("engine", ""), settings.get("language_code", ""),
                     FORMAT, SAMPLE_RATE, ssml])
    return hashlib.sha1(text.encode("utf-8")).hexdigest()


def synthesize(settings, ssml, path, aws_args):
    command = ["aws", "polly", "synthesize-speech", *aws_args,
               "--engine", settings.get("engine", "neural"),
               "--voice-id", settings["voice"],
               "--language-code", settings["language_code"],
               "--output-format", FORMAT, "--sample-rate", SAMPLE_RATE,
               "--text-type", "ssml", "--text", ssml, path]
    run = subprocess.run(command, capture_output=True, text=True)
    if run.returncode != 0:
        if os.path.exists(path):
            os.remove(path)
        return run.stderr.strip() or "aws exited %d" % run.returncode
    return ""


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--lang", required=True, help="language codes, comma separated (es,zh,en)")
    parser.add_argument("--keys", default="", help="word keys, comma separated (default: every word)")
    parser.add_argument("--limit", type=int, default=0, help="at most this many clips per language")
    parser.add_argument("--out", default="", help="write clips here (samples; outside the project folder)")
    parser.add_argument("--write", action="store_true", help="write the game's clips into audio/voice/")
    parser.add_argument("--jobs", type=int, default=4, help="Polly calls at once (default 4)")
    parser.add_argument("--force", action="store_true", help="redo clips that are already up to date")
    parser.add_argument("--profile", default="", help="AWS CLI profile (default: the CLI's default)")
    parser.add_argument("--region", default="", help="AWS region (default: data/sounds.json voice.polly_region)")
    parser.add_argument("--godot", default=os.environ.get("GODOT", GODOT_DEFAULT))
    args = parser.parse_args()

    if not os.path.exists("project.godot"):
        fail("run this from the Godot project folder (BonAdventure/)")
    if args.write and args.out:
        fail("use --write (the game's clips) or --out (samples), not both")
    out_root = os.path.abspath(GAME_FOLDER) if args.write else (os.path.abspath(args.out) if args.out else "")
    if args.out and out_root.startswith(os.path.abspath(".") + os.sep):
        fail("--out is inside the project folder, so Godot would import the samples; pick a folder outside it")
    aws_args = []
    if args.profile:
        aws_args += ["--profile", args.profile]
    # Polly's neural voices are not offered in every region (not us-east-2): the voice section's
    # "polly_region" is used unless --region says otherwise.
    with open(os.path.join("data", "sounds.json"), encoding="utf-8") as handle:
        region = args.region or json.load(handle).get("voice", {}).get("polly_region", "")
    if region:
        aws_args += ["--region", region]

    manifest = build_manifest(args.godot)
    wanted_keys = [k for k in args.keys.split(",") if k] if args.keys else []
    if out_root:
        check = subprocess.run(["aws", "sts", "get-caller-identity", *aws_args], capture_output=True, text=True)
        if check.returncode != 0:
            fail("the AWS CLI is not signed in; run `aws sso login` (then try again)")

    made = skipped = failed = 0
    for lang in [code for code in args.lang.split(",") if code]:
        section = manifest["languages"].get(lang)
        if section is None:
            fail("no voice for language '%s' in data/sounds.json" % lang)
        settings, words = section["settings"], section["words"]
        for key in wanted_keys:
            if key not in words:
                fail("'%s' is not a word key in data/words.json" % key)
        keys = wanted_keys or sorted(words)
        if args.limit:
            keys = keys[: args.limit]
        if not out_root:
            for key in keys:
                print("%s  %-24s %s (%s)  %s" % (lang, words[key]["file"] + ".ogg", settings["voice"],
                                               settings["language_code"], words[key]["ssml"]))
            continue
        folder = os.path.join(out_root, lang)
        os.makedirs(folder, exist_ok=True)
        record_path = os.path.join(folder, "generated.json")
        record = {}
        if os.path.exists(record_path):
            with open(record_path, encoding="utf-8") as handle:
                record = json.load(handle)
        todo = []
        for key in keys:
            entry = words[key]
            sha = fingerprint(settings, entry["ssml"])
            path = os.path.join(folder, entry["file"] + ".ogg")
            if not args.force and record.get(key, {}).get("sha") == sha and os.path.exists(path):
                skipped += 1
            else:
                todo.append((key, sha, path))
        # Several Polly calls at once (--jobs; Polly allows about 8 a second per account).
        with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
            jobs = {pool.submit(synthesize, settings, words[key]["ssml"], path, aws_args): (key, sha)
                    for key, sha, path in todo}
            for job in as_completed(jobs):
                key, sha = jobs[job]
                entry = words[key]
                error = job.result()
                if error:
                    failed += 1
                    print("FAIL: %s %s: %s" % (lang, key, error), flush=True)
                    continue
                record[key] = {"file": entry["file"], "text": entry["text"], "sha": sha}
                made += 1
                print("made %s/%s.ogg  (%s)" % (lang, entry["file"], entry["text"]), flush=True)
        gone = sorted(k for k in record if k not in words)
        for key in gone:
            print("NOTE: %s/%s.ogg has no word any more (%s); delete it by hand" % (lang, record[key]["file"], key))
        with open(record_path, "w", encoding="utf-8") as handle:
            json.dump(dict(sorted(record.items())), handle, ensure_ascii=False, indent=1)
            handle.write("\n")
    if out_root:
        print("VOICE CLIPS: %d made, %d up to date, %d failed -> %s" % (made, skipped, failed, out_root))
        if args.write and made:
            print("Now import them: %s --headless --path . --import" % args.godot)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
