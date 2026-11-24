#!/usr/bin/env python3
"""One-command check runner for Vocabulary Town.

Runs a named suite of checks, each as its own process (Godot cannot easily spawn
itself per check), with an isolated HOME, VT_FOCUS=all, VT_SPAWN=none and a
per-check timeout. Parses each log for failure labels, compares them with
data/expected_check_failures.json and prints one table:

  PASS        no failures
  KNOWN       only failures listed in the expected-failures file
  NEW         failures not in the file (labels are printed)
  CRASH       exited on a signal, or no summary line was printed
  TIMEOUT     killed after the check's timeout
              (a SCRIPT ERROR raised in the check's own script, or another script under docs/,
              usually ends its coroutine and leaves Godot idle: when the log then stays quiet
              for STALL_SECONDS the run is killed early and reported as CRASH, "stalled")
  SKIPPED     marked broken in the expected-failures file (run with --include-broken)

FIXED lists expected labels that no longer fail (update the file).
Exit code: 1 when any check is NEW, CRASH or TIMEOUT; otherwise 0.

Usage (from BonAdventure/):
  python3 tools/run_checks.py                 # quick suite
  python3 tools/run_checks.py full            # full suite
  python3 tools/run_checks.py --list          # suites and checks
  python3 tools/run_checks.py --only part2,aircraft
  python3 tools/run_checks.py full --jobs 2 --out /some/scratch/folder

Logs go to a scratch folder (default: $TMPDIR/vt-checks/<timestamp>), never
into docs/. Checks that write into docs/ or overwrite PNGs are not listed.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import datetime
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from collections import Counter
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
EXPECTED_FILE = PROJECT / "data" / "expected_check_failures.json"
GODOT_DEFAULT = "/Applications/Godot.app/Contents/MacOS/Godot"

# ---------------------------------------------------------------------------
# Check table. Add a check here (see README "Verification").
#   id       short name used by --only and in the expected-failures file
#   script   res:// path of a SceneTree script, or a .py path relative to the project
#   suites   suites the check belongs to ("quick" checks also run in "full")
#   fps      pass --fixed-fps 60
#   summary  regex for the check's final line; group "n" (optional) = failure count.
#            None: no summary line on failure, so completion is judged by the exit code.
#   prefix   text stripped from the start of each failure label
#   timeout  seconds before the process group is killed
#   args     extra script arguments (passed after "--")
#   note     regex; a matching log line is shown in the check's details
# Failure labels are: printed lines "FAIL: <label>" / "FAIL <label>", push_error()
# messages raised from the check's own script (or another script under docs/), and
# "ERROR: <label>" lines of the Python checks. Lines matching the summary are not labels.
# ---------------------------------------------------------------------------
CHECKS = [
    # quick (README Verification list, first lines)
    dict(id="runtime_resources", script="res://docs/evidence/town-checks/check_runtime_resources.gd", suites=["quick"],
         summary=r"Runtime resources: \d+ checked; (?P<n>\d+) failures"),
    dict(id="language", script="res://tools/language_check.gd", suites=["quick"],
         summary=r"^(PASS|FAIL): \d+ checks, (?P<n>\d+) failed"),
    dict(id="compact_layout", script="res://docs/evidence/town-checks/check_compact_layout.gd", suites=["quick"], fps=True,
         summary=r"COMPACT LAYOUT: \d+ checks; (?P<n>\d+) failures"),
    dict(id="part2", script="res://docs/evidence/part2/verify.gd", suites=["quick"], fps=True,
         summary=r"PART 2: \d+ checks; (?P<n>\d+) failures"),
    dict(id="public_garden", script="res://docs/evidence/town-checks/check_public_garden.gd", suites=["quick"], fps=True,
         summary=r"PUBLIC GARDEN: (?P<n>\d+) failures"),
    dict(id="profiles", script="res://docs/evidence/profiles-20261112/verify.gd", suites=["quick"],
         summary=r"PROFILES: \d+ checks, (?P<n>\d+) failures"),
    dict(id="activity_lifecycle", script="res://docs/evidence/activity-lifecycle-20261112/verify.gd", suites=["quick"],
         summary=r"ACTIVITY LIFECYCLE: \d+ checks, (?P<n>\d+) failures"),
    dict(id="touch_controls", script="res://docs/evidence/touch-controls-20261112/verify.gd", suites=["full"],
         summary=r"TOUCH CONTROLS: \d+ checks, (?P<n>\d+) failures"),
    dict(id="app_flow", script="res://docs/evidence/app-flow-20261112/verify.gd", suites=["full"],
         summary=r"APP FLOW: \d+ checks, (?P<n>\d+) failures"),
    # Save and respawn (14 Nov 2026, player_place.gd): writes a test profile and place file in
    # the isolated HOME and removes them.
    dict(id="player_place", script="res://docs/evidence/player-place-20261114/verify.gd", suites=["full"],
         summary=r"PLAYER PLACE: \d+ checks, (?P<n>\d+) failures"),
    # The welcome tutorial after the user's polish list (18 Nov 2026; replaced tutorial-review-20261117).
    dict(id="tutorial", script="res://docs/evidence/tutorial-polish-20261118/verify.gd", suites=["full"],
         summary=r"TUTORIAL: \d+ checks, (?P<n>\d+) failures"),
    # The supermarket order game's carried basket (14 Nov 2026, shopping_basket.gd).
    dict(id="shop_basket", script="res://docs/evidence/shop-basket-20261114/verify.gd", suites=["full"],
         summary=r"SHOP BASKET: \d+ checks, (?P<n>\d+) failures"),
    # full: rest of the README list
    dict(id="interaction", script="res://docs/evidence/town-checks/check_interaction.gd", suites=["full"], summary=None),
    dict(id="aircraft", script="res://docs/evidence/town-checks/check_aircraft.gd", suites=["full"], fps=True,
         prefix="AIRCRAFT: ", summary=r"AIRCRAFT: \d+ checks; (?P<n>\d+) failures"),
    # The flying controls for the plane and the helicopter (easy flying 14 Nov 2026; one set with ▲ / ▼ since 23 Nov 2026, docs/guides/aircraft.md#flying-controls).
    dict(id="easy_flying", script="res://docs/evidence/town-checks/check_easy_flying.gd", suites=["full"], fps=True,
         prefix="FAIL ", summary=r"EASY FLYING CHECKS \d+ FAILURES (?P<n>\d+)"),
    dict(id="helicopter", script="res://docs/evidence/town-checks/check_helicopter_physics.gd", suites=["full"], fps=True,
         prefix="HELICOPTER: ", summary=r"HELICOPTER PHYSICS: \d+ checks; (?P<n>\d+) failures"),
    dict(id="zoo_vehicles", script="res://docs/evidence/town-checks/check_zoo_vehicles.gd", suites=["full"], fps=True,
         prefix="FAIL: ", summary=r"Zoo and vehicle regression: \d+ checks; (?P<n>\d+) failures"),
    # Parked cars/motorcycles per lot, wall slides, exit while moving, aircraft resets, map edge (14 Nov 2026).
    dict(id="vehicle_arcade", script="res://docs/evidence/town-checks/check_vehicle_arcade.gd", suites=["full"], fps=True,
         summary=r"VEHICLE ARCADE: \d+ checks; (?P<n>\d+) failures"),
    dict(id="road_physics", script="res://docs/evidence/town-checks/check_road_physics.gd", suites=["full"], fps=True,
         prefix="ROAD PHYSICS: ", summary=r"ROAD PHYSICS: \d+ checks; (?P<n>\d+) failures"),
    dict(id="hospital_remodel", script="res://docs/evidence/town-checks/check_hospital_remodel.gd", suites=["full"], fps=True,
         summary=r"HOSPITAL REMODEL: \d+ checks; (?P<n>\d+) failures", timeout=600),
    dict(id="hospital_departments", script="res://docs/evidence/town-checks/check_hospital_departments.gd", suites=["full"], fps=True,
         summary=r"HOSPITAL DEPARTMENTS: \d+ room words placed; (?P<n>\d+) failures"),
    dict(id="elevator_call_button", script="res://docs/evidence/elevator-call-button-20261109/verify.gd", suites=["full"], fps=True,
         prefix="FAIL: ", summary=r"ELEVATOR CALL BUTTON: \d+ checks, (?P<n>\d+) failures"),
    dict(id="seats_swan_boats", script="res://docs/evidence/town-checks/check_seats_and_swan_boats.gd", suites=["full"], fps=True,
         summary=r"SEATS AND SWAN BOATS: (?P<n>\d+) failures", timeout=480),
    dict(id="vocabulary_categories", script="docs/evidence/town-checks/check_vocabulary_categories.py", suites=["full"],
         summary=r"\d+ read-only checks, (?P<n>\d+) failures"),
    dict(id="vocabulary_translations", script="docs/evidence/town-checks/check_vocabulary_translations.py", suites=["full"],
         summary=r"^(FAIL: (?P<n>\d+) issues|PASS: words\.json)"),
    # Unknown word keys in game data, the loaded town's scenes and labels, aliases and phrase
    # slots (tools/vocabulary_report.gd). With --write it also refreshes
    # docs/guides/vocabulary-report/ and docs/game/words.md when the content changed (user decision, 8 Nov 2026: the report
    # follows every change); the details say "updated" when there is something to commit.
    dict(id="vocabulary_report", script="res://tools/vocabulary_report.gd", suites=["full"],
         args=["--write"], note=r"^VOCABULARY REPORT FILES: (updated|not written).*$",
         summary=r"VOCABULARY REPORT CHECK: \d+ checks, (?P<n>\d+) failures"),
    # full: checks recorded as current in docs/guides/MODULAR_TOWN.md (old pipeline removal)
    dict(id="park_terrain", script="res://docs/evidence/town-checks/check_park_terrain.gd", suites=["full"], fps=True,
         summary=r"PARK TERRAIN: (?P<n>\d+) failures"),
    dict(id="barn", script="res://docs/evidence/barn-20261101/verify.gd", suites=["full"], fps=True,
         summary=r"BARN VERIFY: \d+ checks, (?P<n>\d+) failures"),
    dict(id="police_detective", script="res://docs/evidence/police-detective-20261106/verify.gd", suites=["full"],
         summary=r"POLICE DETECTIVE: (?P<n>\d+) failures"),
    dict(id="police_interior", script="res://docs/evidence/police-interior-20261028/verify.gd", suites=["full"], fps=True,
         summary=r"police interior checks: \d+ failures: (?P<n>\d+)"),
    dict(id="police_officer", script="res://docs/evidence/police-officer-20261101/verify.gd", suites=["full"],
         summary=r"POLICE OFFICER: (?P<n>\d+) failures"),
    dict(id="map_facades", script="res://docs/evidence/town-checks/check_map_facades.gd", suites=["full"], fps=True,
         summary=r"MAP FACADES: (?P<n>\d+) failures"),
    dict(id="vehicle_boarding", script="res://docs/evidence/town-checks/check_vehicle_boarding.gd", suites=["full"], fps=True,
         prefix="VEHICLE BOARDING: ", summary=r"VEHICLE BOARDING: \d+ checks; (?P<n>\d+) failures"),
    dict(id="vehicle_doors", script="res://docs/evidence/town-checks/check_vehicle_doors.gd", suites=["full"], fps=True,
         prefix="DOORS: ", summary=r"VEHICLE DOORS: \d+ checks; (?P<n>\d+) failures"),
    # Food and shopping words: from words.json, placed in the town, ray-picked, card shows the
    # translation (rewritten for the modular town 18 Nov 2026).
    dict(id="food_shopping_vocab", script="res://docs/evidence/town-checks/check_food_shopping_vocab.gd", suites=["full"],
         summary=r"FOOD & SHOPPING GODOT RUNTIME CHECK: \d+ requested words; \d+ checks; (?P<n>\d+) failures", timeout=480),
    dict(id="building_lookup", script="res://docs/evidence/town-checks/check_building_lookup.gd", suites=["full"], fps=True,
         summary=r"BUILDING LOOKUP: \d+ checks, (?P<n>\d+) failures"),
    dict(id="warehouse", script="res://docs/evidence/warehouse-20261114/verify.gd", suites=["full"],
         summary=r"^warehouse: \d+ checks, (?P<n>\d+) failures"),
    dict(id="warehouse_game", script="res://docs/evidence/warehouse-20261114/verify_game.gd", suites=["full"],
         summary=r"^warehouse game: \d+ checks, (?P<n>\d+) failures"),
    dict(id="grammar_class", script="res://docs/evidence/grammar-class-20261106/verify.gd", suites=["full"],
         summary=r"GRAMMAR CLASS: \d+ checks, (?P<n>\d+) failures"),
    # The Mystery House and Madame Luna's Mystery Doors game (9 Nov 2026); plays a game through
    # the real session (Main saves: isolated HOME).
    dict(id="mystery_house", script="res://docs/evidence/mystery-house-20261109/verify.gd", suites=["full"],
         summary=r"MYSTERY HOUSE: \d+ checks, (?P<n>\d+) failures"),
    # The fitting room outfit picker (9 Nov 2026); writes user://settings.json (isolated HOME).
    # Headless here; with graphics the same script also renders its PNGs.
    dict(id="fitting_room", script="res://docs/evidence/fitting-room-20261109/verify.gd", suites=["full"],
         summary=r"^fitting room: \d+ checks, (?P<n>\d+) failures"),
    # The minigame test launcher and the shop, cashier and warehouse games on the shared NPC
    # host (9 Nov 2026, docs/guides/MINIGAMES.md#test-launcher); starts every game, so needs the full town.
    dict(id="minigame_launcher", script="res://docs/evidence/minigame-launcher-20261109/verify.gd", suites=["full"],
         summary=r"MINIGAME LAUNCHER: \d+ checks, (?P<n>\d+) failures"),
    # Grocery Run checkout and free shopping at the supermarket till (21 Nov 2026; Pay Up! retired into it).
    dict(id="grocery_checkout", script="res://docs/evidence/grocery-checkout-20261121/verify.gd", suites=["full"],
         summary=r"GROCERY CHECKOUT: \d+ checks, (?P<n>\d+) failures"),
    # Minigame progression: levels, stars, unlocks, Grocery Run (Pay Up! until 21 Nov 2026), picker (18 Nov 2026).
    dict(id="minigame_progression", script="res://docs/evidence/minigame-progression-20261118/verify.gd", suites=["full"],
         summary=r"MINIGAME PROGRESSION: \d+ checks, (?P<n>\d+) failures"),
    # Every world sign in every taught language; every visible Label3D covered (9 Nov 2026).
    dict(id="signs", script="res://docs/evidence/signs-20261109/verify.gd", suites=["full"],
         summary=r"SIGNS: \d+ checks, (?P<n>\d+) failures"),
    # World signs: letter height for the reading distance, fit and contrast in every language
    # (16 Nov 2026, world_sign.gd; the supermarket is migrated).
    dict(id="world_signs", script="res://docs/evidence/world-signs-20261116/verify.gd", suites=["full"],
         summary=r"WORLD SIGNS: \d+ checks, (?P<n>\d+) failures"),
    dict(id="practice_log", script="res://docs/evidence/practice-log-20261107/verify.gd", suites=["full"],
         summary=r"PRACTICE LOG: \d+ checks, (?P<n>\d+) failures"),
    # The vocabulary book (J journal table, filters, word detail; Stage C, 8 Nov 2026). Headless
    # here; with graphics the same script also renders its PNGs.
    dict(id="vocabulary_book", script="res://docs/evidence/vocabulary-book-20261108/verify.gd", suites=["full"],
         summary=r"VOCABULARY BOOK: \d+ checks, (?P<n>\d+) failures"),
    # Airport flight game logic after the board-only redesign (no town; 7 Nov 2026).
    dict(id="flight_logic", script="res://docs/evidence/flight-board-20261107/verify.gd", suites=["full"],
         summary=r"^(PASS|FAIL): \d+ checks, (?P<n>\d+) failed"),
    # Hong Kong mahjong (9 Nov 2026, docs/guides/MAHJONG.md): the rules, scoring and NPC players
    # without the town, then the table in the town (talk, mode, sit, whole hands, leave).
    # The table check is headless here; with graphics it also renders its PNGs.
    dict(id="mahjong_logic", script="res://docs/evidence/mahjong-20261109/verify.gd", suites=["full"],
         summary=r"^MAHJONG: \d+ checks, (?P<n>\d+) failures"),
    dict(id="mahjong_table", script="res://docs/evidence/mahjong-20261109/play.gd", suites=["full"],
         summary=r"^MAHJONG TABLE: \d+ checks, (?P<n>\d+) failures"),
    # Mahjong memory (23 Nov 2026): leave and carry on the same hand and scores.
    dict(id="mahjong_memory", script="res://docs/evidence/mahjong-memory-20261123/verify.gd", suites=["full"],
         summary=r"^MAHJONG MEMORY: \d+ checks, (?P<n>\d+) failures"),
    # The hand bar's hide/show button (24 Nov 2026).
    dict(id="mahjong_hand_toggle", script="res://docs/evidence/mahjong-hand-toggle-20261124/verify.gd", suites=["full"],
         summary=r"^MAHJONG HAND TOGGLE: \d+ checks, (?P<n>\d+) failures"),
    # Shared plush eyes, blinking and gestures (13 Nov 2026, docs/guides/COMPONENTS.md#plush-characters).
    dict(id="plush_life", script="res://docs/evidence/plush-rig-20261113/verify.gd", suites=["full"], fps=True,
         summary=r"^PLUSH LIFE: \d+ checks, (?P<n>\d+) failures"),
    # Radar Patrol (9 Nov 2026, docs/guides/RADAR_PATROL.md): rules, scoring and difficulty without the town.
    dict(id="radar_patrol_rules", script="res://docs/evidence/radar-patrol-20261109/rules.gd", suites=["full"],
         summary=r"^radar patrol rules: (?P<n>\d+) failure"),
    # Door registry, approved school/market dimensions, entrance walk paths and word picks: the
    # parts of the six retired October snapshot checks that nothing else covers (7 Nov 2026).
    dict(id="building_access", script="res://docs/evidence/town-checks/check_building_access.gd", suites=["full"], fps=True,
         summary=r"BUILDING ACCESS: \d+ checks, (?P<n>\d+) failures"),
    # Rooftop landings, the hospital helicopter and helipad jumps (reworked 7 Nov 2026; was broken).
    dict(id="rooftops", script="res://docs/evidence/town-checks/check_rooftops.gd", suites=["full"], fps=True,
         summary=r"ROOFTOPS & JUMPS: \d+ checks, (?P<n>\d+) failures", timeout=240),
    # Working toilets and faucets, airport restrooms (8 Nov 2026).
    dict(id="bath_fixtures", script="res://docs/evidence/bath-fixtures-20261108/verify.gd", suites=["full"],
         summary=r"BATH FIXTURES: \d+ checks, (?P<n>\d+) failed"),
    # Electrical box repair: home box, picking, E nearby, camera, wires, success, Esc (9 Nov 2026).
    dict(id="electrical_box", script="res://docs/evidence/electrical-box-20261109/verify.gd", suites=["full"],
         summary=r"ELECTRICAL BOX: \d+ checks, (?P<n>\d+) failures"),
    # Library category shelves, return shelf, 24 picture books and gaps, routes, Rosa's
    # mission dialogue (11 Nov 2026; Main saves: isolated HOME).
    dict(id="library_shelves", script="res://docs/evidence/library-shelves-20261111/verify.gd", suites=["full"],
         summary=r"LIBRARY SHELVES: \d+ checks, (?P<n>\d+) failures"),
    # Rosa's book-sorting game: new categories and titles, tracked words, gaps for every book, the
    # display at the rear wall, placing (wrong shelf back to the hand), mid-game talk, the game
    # ending by itself with a zoom on Rosa (no recap), the book close-up on pick-up, the bigger
    # burst, replenishing once the player walks away, "I'll help later", the bigger top-right
    # buttons (21 Nov 2026, replaces the 17 Nov check; headless writes no PNGs; isolated HOME).
    dict(id="library_sorting", script="res://docs/evidence/library-polish-20261121/verify.gd", suites=["full"],
         summary=r"LIBRARY SORTING: \d+ checks, (?P<n>\d+) failures"),
    # The results screen after a minigame: session words (new / practiced / struggled), the card,
    # See all, rewards, Great Practice!, Continue / Play again / Esc, Chinese text in the font
    # subset (21 Nov 2026; headless skips the fit checks and PNGs; isolated HOME).
    dict(id="results_screen", script="res://docs/evidence/results-screen-20261121/verify.gd", suites=["full"],
         summary=r"RESULTS SCREEN: \d+ checks, (?P<n>\d+) failures"),
    # The bank teller game "Next, Please!": amount stages, balances, change, the banker on the
    # shared host, window 2, the monitor, mistakes and retries, bills-only money screen, the
    # leave question, the end in the lobby (18 Nov 2026; headless writes no PNGs; isolated HOME).
    dict(id="bank_teller", script="res://docs/evidence/bank-teller-20261118/verify.gd", suites=["full"],
         summary=r"BANK TELLER: \d+ checks, (?P<n>\d+) failures"),
    # Bank rework (23 Nov 2026): the rear annex (vault room, safe-deposit room, office), the staff
    # door behind the counter, the heavy vault door, the account view (monitor and customer at
    # once), impostor payouts and the bank manager (warning, then let go). It replaced
    # bank_impostor (bank-impostor-20261121/verify.gd: its camera toggle and paid-impostor
    # warning no longer exist). Headless writes no PNGs; isolated HOME.
    dict(id="bank_rework", script="res://docs/evidence/bank-rework-20261123/verify.gd", suites=["full"],
         summary=r"BANK REWORK: \d+ checks, (?P<n>\d+) failures"),
    # NPC registry (23 Nov 2026): data/npcs.json is complete, every character in the town is in it
    # and stands at its registry spot in its costume, idle chatter and brush-offs, a host's idle
    # line when its game is not on offer, the barn farmer. Headless writes no PNGs; isolated HOME.
    dict(id="npc_registry", script="res://docs/evidence/npc-registry-20261123/verify.gd", suites=["full"],
         summary=r"NPC REGISTRY: \d+ checks, (?P<n>\d+) failures"),
    # Day-night cycle, lamp glow, indoor light and the HUD clock (9 Nov 2026).
    dict(id="day_night", script="res://docs/evidence/day-night-20261109/verify.gd", suites=["full"],
         summary=r"DAY NIGHT: \d+ checks, (?P<n>\d+) failures"),
]
# Not listed on purpose: check_animals.gd (writes docs/evidence/animals-review/measurements.json),
# capture_*/render_*/feature capture scripts (overwrite PNGs).

SUITES = {
    "quick": [c["id"] for c in CHECKS if "quick" in c["suites"]],
    "full": [c["id"] for c in CHECKS if "quick" in c["suites"] or "full" in c["suites"]],
}

FAIL_LINE = re.compile(r"^FAIL:?\s+(.+?)\s*$")
# A check stops at a SCRIPT ERROR in its own code, and Godot then waits for nothing until the
# timeout (16 Nov 2026: map_facades, bath_fixtures and electrical_box hung for minutes). After
# such an error, this many seconds without new log output end the run.
STALL_SECONDS = 30
SCRIPT_ERROR_LINE = re.compile(r"^SCRIPT ERROR: (.+?)\s*$")
ERROR_LINE = re.compile(r"^(?:USER )?ERROR: (.+?)\s*$")
FRAME0 = re.compile(r"^\s*\[0\] \S+ \((.+?):\d+\)\s*$")


def parse_log(check: dict, text: str) -> tuple[list[str], int | None, bool, int]:
    """Return (labels, summary_count, summary_found, other_error_count)."""
    summary = re.compile(check["summary"], re.M) if check.get("summary") else None
    own_script = check["script"]
    labels: list[str] = []
    other_errors = 0
    lines = text.splitlines()
    is_python = own_script.endswith(".py")
    for i, line in enumerate(lines):
        if summary and summary.search(line):
            continue
        m = ERROR_LINE.match(line)
        if m:
            if is_python:
                labels.append(m.group(1))
                continue
            # push_error() from the check: "at: push_error" then a GDScript backtrace whose
            # frame [0] is the check script (or another script under docs/).
            frame0 = None
            for follow in lines[i + 1:i + 5]:
                f = FRAME0.match(follow)
                if f:
                    frame0 = f.group(1)
                    break
                if ERROR_LINE.match(follow):
                    break
            from_push = i + 1 < len(lines) and "at: push_error" in lines[i + 1]
            if from_push and frame0 and (frame0 == own_script or frame0.startswith("res://docs/")
                                         or frame0 == own_script.replace("res://", "")):
                labels.append(m.group(1))
            else:
                other_errors += 1
            continue
        m = FAIL_LINE.match(line)
        if m and not is_python:
            labels.append(m.group(1))
    prefix = check.get("prefix")
    if prefix:
        labels = [l[len(prefix):] if l.startswith(prefix) else l for l in labels]
    found = False
    count = None
    if summary:
        for m in summary.finditer(text):
            found = True
            n = m.groupdict().get("n")
            count = int(n) if n is not None else 0
    return labels, count, found, other_errors


def matches(entry: dict, label: str) -> bool:
    if "label" in entry:
        return label == entry["label"]
    if "prefix" in entry:
        return label.startswith(entry["prefix"])
    if "regex" in entry:
        return re.search(entry["regex"], label) is not None
    return bool(entry.get("any"))


def compare(labels: list[str], known: list[dict]) -> tuple[list[str], list[str], list[str]]:
    """Return (new_labels, fixed_descriptions, notes)."""
    used = Counter()
    new: list[str] = []
    # Specific entries first, catch-all ("any") entries last.
    order = sorted(range(len(known)), key=lambda k: 1 if known[k].get("any") else 0)
    for label in labels:
        for k in order:
            entry = known[k]
            if matches(entry, label) and used[k] < entry.get("count", 1):
                used[k] += 1
                break
        else:
            new.append(label)
    fixed, notes = [], []
    for k, entry in enumerate(known):
        desc = entry.get("label") or entry.get("prefix") or entry.get("regex") or "any failure"
        want = entry.get("count", 1)
        if used[k] == 0 and not entry.get("flaky"):
            fixed.append(desc)
        elif 0 < used[k] < want and not entry.get("any"):
            notes.append(f"{desc}: {used[k]} of {want}")
    return new, fixed, notes


def run_one(check: dict, args, out_dir: Path) -> dict:
    log_path = out_dir / f"{check['id']}.log"
    home = out_dir / "home" / check["id"]
    home.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    env.update(HOME=str(home), VT_FOCUS="all", VT_SPAWN="none", VT_SCULPT_CACHE="0",
               PYTHONDONTWRITEBYTECODE="1")
    env.pop("XDG_DATA_HOME", None)
    env.pop("XDG_CONFIG_HOME", None)
    if check["script"].endswith(".py"):
        cmd = [sys.executable, check["script"]]
    else:
        cmd = [args.godot, "--headless", "--path", "."]
        if check.get("fps"):
            cmd += ["--fixed-fps", "60"]
        cmd += ["--script", check["script"]]
        if check.get("args"):
            cmd += ["--"] + check["args"]
    timeout = check.get("timeout", args.timeout)
    start = time.time()
    status = None
    stalled = ""
    rc = None
    with open(log_path, "w") as log:
        log.write("$ " + " ".join(cmd) + "\n")
        log.flush()
        proc = subprocess.Popen(cmd, cwd=PROJECT, env=env, stdout=log, stderr=subprocess.STDOUT,
                                start_new_session=True)
        offset, carry, last_growth, own_error = 0, "", time.time(), ""
        while True:
            try:
                rc = proc.wait(timeout=1)
                break
            except subprocess.TimeoutExpired:
                pass
            now = time.time()
            size = log_path.stat().st_size
            if size != offset:
                last_growth = now
                if not own_error:
                    with open(log_path, errors="replace") as f:
                        f.seek(offset)
                        chunk = carry + f.read()
                    own_error = own_script_error(check, chunk)
                    carry = chunk[-4000:]
                offset = size
            if now - start >= timeout:
                status = "TIMEOUT"
            elif own_error and now - last_growth >= STALL_SECONDS:
                status, stalled = "STALLED", own_error
            if status:
                try:
                    os.killpg(proc.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                proc.wait()
                rc = None
                break
    elapsed = time.time() - start
    if not args.keep_home:
        shutil.rmtree(home, ignore_errors=True)
    text = log_path.read_text(errors="replace")
    labels, count, found, other_errors = parse_log(check, text)
    return dict(id=check["id"], rc=rc, status=status, elapsed=elapsed, labels=labels,
                count=count, summary_found=found, other_errors=other_errors, log=str(log_path),
                stalled=stalled)


def own_script_error(check: dict, text: str) -> str:
    """The first SCRIPT ERROR in `text` raised in the check's own script (or another script
    under docs/), as "message (location)"; "" when there is none. The chunk may end inside an
    error's backtrace: that error is found again with the next chunk (run_one keeps a tail)."""
    own = check["script"]
    lines = text.splitlines()
    for i, line in enumerate(lines):
        m = SCRIPT_ERROR_LINE.match(line)
        if not m:
            continue
        for follow in lines[i + 1:i + 6]:
            f = FRAME0.match(follow)
            if f:
                if f.group(1) == own or f.group(1).startswith("res://docs/"):
                    return f"{m.group(1)} ({follow.strip()[4:]})"
                break
    return ""


def classify(result: dict, check: dict, expected: dict) -> dict:
    entry = expected.get(check["id"], {})
    known = entry.get("known", [])
    rc = result["rc"]
    notes: list[str] = []
    new, fixed, cnotes = compare(result["labels"], known)
    notes += cnotes
    if result["status"] == "TIMEOUT":
        status = "TIMEOUT"
    elif result["status"] == "STALLED":
        status = "CRASH"
        notes.append(f"stalled: killed {STALL_SECONDS} s after a SCRIPT ERROR in the check: {result['stalled']}")
    elif rc is not None and rc < 0:
        status = "CRASH"
        notes.append(f"signal {-rc}")
    elif check.get("summary") and not result["summary_found"]:
        status = "CRASH"
        notes.append(f"no summary line (exit {rc})")
    elif not check.get("summary") and rc not in (0, 1):
        status = "CRASH"
        notes.append(f"exit {rc}")
    elif new:
        status = "NEW"
    elif result["labels"]:
        status = "KNOWN"
    elif rc not in (0, None) and not check["script"].endswith(".py") and check.get("summary") \
            and (result["count"] or 0) == 0:
        status = "CRASH"
        notes.append(f"exit {rc} with no failures")
    else:
        status = "PASS"
    if check.get("note"):
        found_note = re.search(check["note"], open(result["log"], errors="replace").read(), re.M)
        if found_note:
            notes.append(found_note.group(0).strip())
    script_errors = len(re.findall(r"^SCRIPT ERROR:", open(result["log"], errors="replace").read(), re.M))
    if script_errors:
        notes.append(f"{script_errors} SCRIPT ERROR lines in the log")
    if result["count"] is not None and result["count"] != len(result["labels"]):
        notes.append(f"summary says {result['count']} failures, parsed {len(result['labels'])} labels")
    if status in ("TIMEOUT", "CRASH"):
        fixed = []  # nothing is learned about fixed labels from an unfinished run
    result.update(status=status, new=new, fixed=fixed, notes=notes,
                  known_count=len(result["labels"]) - len(new))
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("suite", nargs="?", default="quick", choices=sorted(SUITES))
    parser.add_argument("--only", help="comma-separated check ids (overrides the suite)")
    parser.add_argument("--list", action="store_true", help="list suites and checks, then exit")
    parser.add_argument("--include-broken", action="store_true", help="also run checks marked broken")
    parser.add_argument("--jobs", "-j", type=int, default=1, help="checks to run at once (default 1)")
    parser.add_argument("--timeout", type=int, default=300, help="default per-check timeout, seconds")
    parser.add_argument("--godot", default=os.environ.get("GODOT", GODOT_DEFAULT))
    parser.add_argument("--out", help="log folder (default: $TMPDIR/vt-checks/<timestamp>)")
    parser.add_argument("--keep-home", action="store_true", help="keep each check's isolated HOME")
    parser.add_argument("--json", help="also write the results as JSON to this file")
    args = parser.parse_args()

    by_id = {c["id"]: c for c in CHECKS}
    expected = json.loads(EXPECTED_FILE.read_text())["checks"]
    if args.list:
        for name, ids in SUITES.items():
            print(f"{name}: {', '.join(ids)}")
        broken = [i for i, e in expected.items() if e.get("broken")]
        print(f"broken (skipped): {', '.join(broken) or '-'}")
        return 0
    ids = args.only.split(",") if args.only else SUITES[args.suite]
    unknown = [i for i in ids if i not in by_id]
    if unknown:
        print("Unknown check ids: " + ", ".join(unknown), file=sys.stderr)
        return 2
    focus_file = PROJECT / "dev_focus.txt"
    focus_lines = [l.strip() for l in focus_file.read_text().splitlines()
                   if l.strip() and not l.strip().startswith("#")]
    if focus_lines and focus_lines != ["all"]:
        print(f"Note: dev_focus.txt lists {focus_lines}; the runner sets VT_FOCUS=all, VT_SPAWN=none.")

    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    out_dir = Path(args.out) if args.out else Path(tempfile.gettempdir()) / "vt-checks" / stamp
    out_dir = out_dir.resolve()
    if out_dir == PROJECT or PROJECT in out_dir.parents:
        print("Refusing to write logs inside the project; choose a scratch folder.", file=sys.stderr)
        return 2
    out_dir.mkdir(parents=True, exist_ok=True)

    to_run, skipped = [], []
    for i in ids:
        if expected.get(i, {}).get("broken") and not args.include_broken:
            skipped.append(i)
        else:
            to_run.append(by_id[i])
    print(f"Running {len(to_run)} checks ({args.only or args.suite}), logs in {out_dir}", flush=True)

    results: dict[str, dict] = {}

    def done(res: dict) -> None:
        res = classify(res, by_id[res["id"]], expected)
        results[res["id"]] = res
        print(f"  {res['status']:<8} {res['id']} ({res['elapsed']:.0f} s)", flush=True)

    t0 = time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
        futures = [pool.submit(run_one, c, args, out_dir) for c in to_run]
        for fut in concurrent.futures.as_completed(futures):
            done(fut.result())

    print()
    print(f"{'check':<24} {'result':<8} {'fail':>5} {'known':>5} {'time':>6}  details")
    print("-" * 100)
    for i in ids:
        if i in skipped:
            print(f"{i:<24} {'SKIPPED':<8} {'':>5} {'':>5} {'':>6}  broken: {expected[i]['broken']}")
            continue
        r = results[i]
        details = []
        if r["new"]:
            shown = r["new"][:8]
            details.append("NEW: " + " | ".join(shown) + (f" | ... +{len(r['new']) - 8}" if len(r["new"]) > 8 else ""))
        if r["fixed"]:
            details.append("FIXED: " + " | ".join(r["fixed"]))
        details += r["notes"]
        print(f"{i:<24} {r['status']:<8} {len(r['labels']):>5} {r['known_count']:>5} {r['elapsed']:>5.0f}s  "
              + "; ".join(details))
    bad = [r for r in results.values() if r["status"] in ("NEW", "CRASH", "TIMEOUT")]
    fixed = [r for r in results.values() if r["fixed"]]
    counts = Counter(r["status"] for r in results.values())
    print("-" * 100)
    print("Totals: " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items()))
          + (f", SKIPPED {len(skipped)}" if skipped else "")
          + f"; {time.time() - t0:.0f} s; logs {out_dir}")
    if fixed:
        print("Expected failures that no longer fail: update data/expected_check_failures.json "
              "(" + ", ".join(r["id"] for r in fixed) + ").")
    if args.json:
        Path(args.json).write_text(json.dumps(dict(results=results, skipped=skipped), indent=2))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
