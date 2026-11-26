#!/usr/bin/env python3
"""Builds the web app (PWA) and, with --publish, puts it on the repository's `gh-pages` branch.

GitHub Pages hosting (user, 13 Nov 2026: ONE public repository; this replaces the separate
build repository of 12 Nov): https://github.com/jameshho/bon-adventure, served at
https://jameshho.github.io/bon-adventure/ (a fresh repository since 16 Nov 2026; the earlier one is private).
Since 16 Nov 2026 (user) the custom domain is https://boomingpodcast.com/ (Route 53 DNS points at
Pages); the build carries a CNAME file (CUSTOM_DOMAIN) because a gh-pages commit without one
removes the domain from Pages. Source lives on `main`; the exported files live on `gh-pages`,
which GitHub Pages serves (Settings > Pages > Deploy from a branch, branch "gh-pages",
folder "/"). The script:

  1. exports the "Web" preset (export_presets.cfg) into --out (default: a temporary folder);
  2. adds .nojekyll (Pages then serves every file as it is) and sets the game's display name:
     the manifest's "name" (DISPLAY_NAME) and "short_name" (SHORT_NAME, the label under the
     installed icon) and the page <title>. Godot would write config/name there, the short
     "Bon Adventure" (desktop saves, user://, are keyed to it);
  3. writes the spoken-word packs into <out>/voice/ (tools/voice_packs.gd: one pack per
     language plus index.json; PERF-04, decision D7, 25 Nov 2026). The preset leaves audio/voice/
     out of index.pck, so a player downloads only the language being learned (sound.gd
     ensure_voice(), docs/guides/VOICE.md "Web packs");
  4. refuses files over GitHub's 100 MB limit and prints the sizes;
     before exporting, it refuses a build when a scene still names a file the preset leaves out
     (the clay zoo animals, scenes/animals/*_clay.*: base.scn stores them as plain nodes since
     13 Nov 2026, base step `clay_animals_unpacked`, saving 33 MB of download; since 16 Nov 2026
     their meshes are separate compressed files in scenes/animals/clay_meshes/, which the pack
     includes and base.scn names);
  5. with --publish: makes `gh-pages` ONE new commit holding only the build (no parent, so old
     builds do not pile up in history). It never pushes and never touches the checked-out
     branch or the working tree: check the build, then
       git push --force origin gh-pages

Usage (from BonAdventure/):
  python3 tools/deploy_web.py [--out <folder>] [--publish] [--godot <binary>]

The build works from any sub-path (https://<user>.github.io/<repo>/): every path in it is
relative. Pages cannot send COOP/COEP headers, so the preset is single-threaded.
"""
import argparse
import fnmatch
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

GODOT_DEFAULT = "/Applications/Godot.app/Contents/MacOS/Godot"
LIMIT = 100 * 1000 * 1000
# The game's name (user, 16 Nov 2026): the manifest's name and the page title; SHORT_NAME is the
# installed app's label under its icon.
DISPLAY_NAME = "Bon Adventure: Little Town of Words"
SHORT_NAME = "Bon Adventure"
# Left out of the web pack by export_presets.cfg's exclude_filter; no scene may name them.
EXCLUDED_SCENE = re.compile(rb"res://scenes/animals/[A-Za-z0-9_]+_clay\.t?scn")
# Any res:// path under scenes/animals/ a scene names; checked against the preset's exclude_filter
# (since 25 Nov 2026 the static clay mesh folders the town no longer uses are left out too).
ANIMAL_PATH = re.compile(rb"res://(scenes/animals/[A-Za-z0-9_./-]+)")
BRANCH = "gh-pages"
# Pages custom domain (user, 16 Nov 2026), written to the build's CNAME file.
CUSTOM_DOMAIN = "boomingpodcast.com"


def git(repo, *args, **kwargs):
    return subprocess.run(["git", "-C", repo, *args], check=True, text=True, capture_output=True, **kwargs).stdout.strip()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", help="folder for the exported files (emptied first; default: a temporary folder)")
    parser.add_argument("--publish", action="store_true", help="commit the build as the gh-pages branch (no push)")
    parser.add_argument("--godot", default=os.environ.get("GODOT", GODOT_DEFAULT))
    args = parser.parse_args()
    project = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    repo = os.path.dirname(project)
    with open(os.path.join(project, "dev_focus.txt")) as focus:
        lines = [line.strip() for line in focus if line.strip() and not line.startswith("#")]
    if lines != ["all"]:
        print("deploy_web: dev_focus.txt must read 'all' for a release build")
        return 1
    named = excluded_references(project)
    if named:
        print("deploy_web: these scenes name clay animal files the web build leaves out "
              "(call base.gd unpack_clay_animals() in the step that placed them, and re-bake):")
        for line in named:
            print("  " + line)
        return 1
    out = os.path.abspath(args.out) if args.out else tempfile.mkdtemp(prefix="bon-adventure-web-")
    if os.path.commonpath([out, repo]) == repo:
        print("deploy_web: --out must be outside the repository")
        return 1
    if os.path.isdir(out):
        shutil.rmtree(out)
    os.makedirs(out)
    result = subprocess.run([args.godot, "--headless", "--path", project, "--export-release", "Web",
                             os.path.join(out, "index.html")])
    if result.returncode != 0 or not os.path.exists(os.path.join(out, "index.pck")):
        print("deploy_web: export failed (are the 4.x web export templates installed?)")
        return 1
    open(os.path.join(out, ".nojekyll"), "w").close()
    with open(os.path.join(out, "CNAME"), "w") as f:
        f.write(CUSTOM_DOMAIN + "\n")
    manifest_path = os.path.join(out, "index.manifest.json")
    with open(manifest_path) as f:
        manifest = json.load(f)
    manifest["name"] = DISPLAY_NAME
    manifest["short_name"] = SHORT_NAME
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, ensure_ascii=False, separators=(",", ":"))
    page_path = os.path.join(out, "index.html")
    with open(page_path, encoding="utf-8") as f:
        page = f.read()
    page, titles = re.subn(r"<title>[^<]*</title>", "<title>" + DISPLAY_NAME + "</title>", page, count=1)
    if titles != 1:
        print("deploy_web: no <title> in index.html")
        return 1
    with open(page_path, "w", encoding="utf-8") as f:
        f.write(page)
    result = subprocess.run([args.godot, "--headless", "--path", project, "--script", "res://tools/voice_packs.gd",
                             "--", "--out", os.path.join(out, "voice")])
    if result.returncode != 0 or not os.path.exists(os.path.join(out, "voice", "index.json")):
        print("deploy_web: the spoken-word packs failed (tools/voice_packs.gd)")
        return 1
    too_big = []
    for folder, _dirs, names in sorted(os.walk(out)):
        for name in sorted(names):
            path = os.path.join(folder, name)
            rel = os.path.relpath(path, out)
            size = os.path.getsize(path)
            print(f"{size / 1e6:9.2f} MB  {rel}")
            if size > LIMIT:
                too_big.append(rel)
    if too_big:
        print("deploy_web: over GitHub's 100 MB file limit: " + ", ".join(too_big))
        return 1
    print(f"deploy_web: build in {out}")
    if not args.publish:
        print("deploy_web: not published (run again with --publish to make the gh-pages commit)")
        return 0
    # One parentless commit made from the folder with a private index: the working tree, the
    # real index and the checked-out branch are untouched.
    source = git(repo, "rev-parse", "--short", "HEAD")
    env = dict(os.environ, GIT_INDEX_FILE=os.path.join(tempfile.mkdtemp(prefix="bon-adventure-index-"), "index"), GIT_WORK_TREE=out)
    subprocess.run(["git", "-C", repo, "add", "-A", "-f", "."], check=True, env=env, cwd=out)
    tree = subprocess.run(["git", "-C", repo, "write-tree"], check=True, env=env, text=True, capture_output=True).stdout.strip()
    shutil.rmtree(os.path.dirname(env["GIT_INDEX_FILE"]))
    commit = git(repo, "commit-tree", tree, "-m", f"Web build of {source}")
    git(repo, "update-ref", f"refs/heads/{BRANCH}", commit)
    print(f"deploy_web: {BRANCH} is now {commit[:7]} (build of {source}); push it with: git push --force origin {BRANCH}")
    return 0


def animal_excludes(project):
    """The Web preset's exclude_filter patterns under scenes/animals/."""
    with open(os.path.join(project, "export_presets.cfg")) as presets:
        m = re.search(r'^exclude_filter="([^"]*)"', presets.read(), re.M)
    return [p.strip() for p in (m.group(1).split(",") if m else []) if p.strip().startswith("scenes/animals/")]


def excluded_references(project):
    """Scenes (other than the excluded files themselves) that name an excluded clay animal, or
    any file under scenes/animals/ that the preset's exclude_filter leaves out."""
    patterns = animal_excludes(project)
    found = []
    for folder, _dirs, files in os.walk(os.path.join(project, "scenes")):
        for name in files:
            if not name.endswith((".scn", ".tscn")) or re.search(r"_clay\.t?scn$", name):
                continue
            path = os.path.join(folder, name)
            if "clay_meshes" in os.path.relpath(path, project).split(os.sep) and \
                    any(fnmatch.fnmatch(os.path.relpath(path, project), p) for p in patterns):
                continue
            with open(path, "rb") as scene:
                data = scene.read()
            hits = set(EXCLUDED_SCENE.findall(data))
            hits |= {b"res://" + m for m in ANIMAL_PATH.findall(data)
                     if any(fnmatch.fnmatch(m.decode(errors="replace"), p) for p in patterns)}
            hits = sorted(hits)
            if hits:
                found.append(os.path.relpath(path, project) + ": " + ", ".join(h.decode() for h in hits))
    return found


if __name__ == "__main__":
    sys.exit(main())
