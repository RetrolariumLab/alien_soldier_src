#!/usr/bin/env python3
"""Generate an offline, untracked evidence worksheet for ROM font glyphs."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import sys
import tempfile
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.credits_text_model import glyph_art  # noqa: E402
from authoring.japanese_glyph_model import ART_PATH as JAPANESE_ART_PATH  # noqa: E402
from authoring.shared_font_preview import FONT_PATH as SHARED_FONT_PATH  # noqa: E402


DEFAULT_OUTPUT = Path("reference/text_glyph_review_shared_font.html")
EVIDENCE = {"visual", "in_game", "source", "unknown_or_unused"}


def inventory(root: Path) -> dict:
    """Read the two fonts and credits' use of the shared font."""
    shared = (root / SHARED_FONT_PATH).read_bytes()
    japanese = (root / JAPANESE_ART_PATH).read_bytes()
    credits = glyph_art(root)
    if not shared or len(shared) % 64:
        raise ValueError("shared font has incomplete 64-byte records")
    if not japanese or len(japanese) % 128:
        raise ValueError("Japanese font has incomplete 128-byte records")
    if credits != shared:
        raise ValueError("credits glyphs no longer use the shared font")
    assets = (
        ("shared", shared, 0, len(shared) // 64),
        ("japanese", japanese, 0x20, len(japanese) // 128),
        ("credits", credits, 0, len(credits) // 64),
    )
    return {
        name: {
            "first": first,
            "count": count,
            "sha256": hashlib.sha256(body).hexdigest(),
            "base64": base64.b64encode(body).decode("ascii"),
        }
        for name, body, first, count in assets
    }


HTML = r"""<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Alien Soldier Source 2.0 — ROM glyph review</title>
<style>
  :root { color-scheme: dark; font-family: system-ui, sans-serif; }
  body { margin: 0 auto; max-width: 1300px; padding: 24px; background: #11151c; color: #e6ebf2; }
  h1 { margin: 0 0 8px; font-size: 1.6rem; }
  p { line-height: 1.5; color: #bec9d6; }
  .controls { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; margin: 18px 0; }
  button, select, input, textarea { font: inherit; color: inherit; background: #202b38; border: 1px solid #52657b; border-radius: 5px; padding: 7px; }
  button { cursor: pointer; }
  button:hover { background: #314158; }
  .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(290px, 1fr)); gap: 12px; }
  .card { background: #1a2430; border: 1px solid #3f5064; border-radius: 8px; padding: 14px; }
  .card h2 { font-size: 1rem; margin: 0 0 8px; }
  .card canvas { display: block; image-rendering: pixelated; background: #202020; margin: 8px 0 14px; }
  .card label { display: block; font-size: .85rem; margin-top: 9px; color: #c9d5e1; }
  .card input, .card select, .card textarea { display: block; box-sizing: border-box; width: 100%; margin-top: 4px; }
  .card textarea { min-height: 54px; resize: vertical; }
  .note { font-size: .85rem; }
  .status { font-variant-numeric: tabular-nums; }
</style>
<h1>Alien Soldier Source 2.0 — ROM glyph evidence</h1>
<p>These are raw source pixels, not a character map. Shared and credits records are the same SharedFontTileArt bytes; credits IDs index that font, with ID 0 reserved as a blank slot. Their two tiles appear in <em>source order</em>, separated by a gap; screen arrangement is not asserted. Japanese glyphs use the four-tile arrangement proved by the story-font reader. Enter a transcription only when you can identify it; otherwise choose unknown/unused or leave it unreviewed.</p>
<p class="note">Answers stay in this browser's local storage until you export JSON. The downloaded JSON includes art hashes so it can be matched to the exact ROM assets. This page uses no network service.</p>
<div class="controls">
  <label>Font <select id="set"></select></label>
  <button id="prev" type="button">Previous 24</button>
  <span id="page" class="status"></span>
  <button id="next" type="button">Next 24</button>
  <span id="progress" class="status"></span>
  <button id="save" type="button">Save answers JSON</button>
  <label>Restore JSON <input id="restore" type="file" accept=".json,application/json"></label>
</div>
<div id="cards" class="cards"></div>
<script>
"use strict";
const assets = __GLYPH_DATA__;
const sourceHashes = Object.fromEntries(Object.entries(assets).map(
  ([name, asset]) => [name, asset.sha256]));
const storageKey = "alien-soldier-source-2.0-glyph-review:" +
  Object.values(sourceHashes).join(":");
const bodies = Object.fromEntries(Object.entries(assets).map(
  ([name, asset]) => [name, Uint8Array.from(atob(asset.base64), ch => ch.charCodeAt(0))]));
const names = {shared: "Shared font", japanese: "Japanese story font", credits: "Animated credits"};
const pageSize = 24;
const setBox = document.getElementById("set");
const cards = document.getElementById("cards");
let page = 0;
let answers = {};
try { answers = JSON.parse(localStorage.getItem(storageKey) || "{}"); }
catch (_) { answers = {}; }

for (const [name, asset] of Object.entries(assets)) {
  const option = document.createElement("option");
  option.value = name;
  option.textContent = names[name] + " (" + asset.count + ")";
  setBox.append(option);
}

function key(name, index) { return name + ":" + index; }
function hex(index) { return "$" + index.toString(16).toUpperCase().padStart(3, "0"); }
function persist() {
  try { localStorage.setItem(storageKey, JSON.stringify(answers)); }
  catch (_) { /* Export still works when local storage is unavailable. */ }
  updateProgress();
}
function updateProgress() {
  const total = Object.values(assets).reduce((sum, asset) => sum + asset.count, 0);
  document.getElementById("progress").textContent =
    Object.keys(answers).length + " / " + total + " answered";
}
function drawTile(ctx, body, offset, left, top) {
  for (let p = 0; p < 64; p++) {
    const value = body[offset + (p >> 1)];
    const nibble = p % 2 ? value & 15 : value >> 4;
    const shade = 32 + nibble * 14;
    ctx.fillStyle = "rgb(" + shade + "," + shade + "," + shade + ")";
    ctx.fillRect(left + p % 8, top + Math.floor(p / 8), 1, 1);
  }
}
function drawGlyph(canvas, name, index) {
  if (name === "credits" && index === 0) return;
  const ctx = canvas.getContext("2d");
  const body = bodies[name];
  if (name === "japanese") {
    const base = (index - 0x20) * 128;
    [[0, 0], [0, 8], [8, 0], [8, 8]].forEach(([x, y], tile) =>
      drawTile(ctx, body, base + tile * 32, x, y));
  } else {
    const base = index * 64;
    drawTile(ctx, body, base, 0, 0);
    drawTile(ctx, body, base + 32, 9, 0);
  }
}
function field(card, label, control, answer, property, name, index) {
  const wrapper = document.createElement("label");
  wrapper.textContent = label;
  control.value = answer[property] || "";
  control.addEventListener("input", () => {
    const entry = answers[key(name, index)] || {
      set: name, index: index, transcription: "", evidence: "", notes: ""};
    entry[property] = control.value;
    if (entry.transcription || entry.evidence || entry.notes) {
      answers[key(name, index)] = entry;
    } else {
      delete answers[key(name, index)];
    }
    persist();
  });
  wrapper.append(control);
  card.append(wrapper);
}
function render() {
  const name = setBox.value;
  const asset = assets[name];
  const pages = Math.ceil(asset.count / pageSize);
  page = Math.max(0, Math.min(page, pages - 1));
  document.getElementById("page").textContent = (page + 1) + " / " + pages;
  document.getElementById("prev").disabled = page === 0;
  document.getElementById("next").disabled = page === pages - 1;
  cards.replaceChildren();
  const end = Math.min(asset.count, (page + 1) * pageSize);
  for (let ordinal = page * pageSize; ordinal < end; ordinal++) {
    const index = asset.first + ordinal;
    const answer = answers[key(name, index)] || {};
    const card = document.createElement("section");
    card.className = "card";
    const title = document.createElement("h2");
    title.textContent = names[name] + " " + hex(index) +
      (name === "credits" && index === 0 ? " — blank slot" : "");
    card.append(title);
    const canvas = document.createElement("canvas");
    canvas.width = name === "japanese" ? 16 : 17;
    canvas.height = name === "japanese" ? 16 : 8;
    canvas.style.width = (canvas.width * 8) + "px";
    canvas.style.height = (canvas.height * 8) + "px";
    card.append(canvas);
    drawGlyph(canvas, name, index);
    const transcription = document.createElement("input");
    transcription.maxLength = 32;
    field(card, "Transcription (leave blank if uncertain)",
      transcription, answer, "transcription", name, index);
    const evidence = document.createElement("select");
    for (const [value, label] of [
      ["", "Unreviewed"], ["visual", "Visual identification"],
      ["in_game", "Observed in game"], ["source", "Source-proven"],
      ["unknown_or_unused", "Unknown / possibly unused"]]) {
      const option = document.createElement("option");
      option.value = value;
      option.textContent = label;
      evidence.append(option);
    }
    field(card, "Evidence level", evidence, answer, "evidence", name, index);
    const notes = document.createElement("textarea");
    field(card, "Notes / screenshot frame", notes, answer, "notes", name, index);
    cards.append(card);
  }
  updateProgress();
}
setBox.addEventListener("change", () => { page = 0; render(); });
document.getElementById("prev").addEventListener("click", () => { page--; render(); });
document.getElementById("next").addEventListener("click", () => { page++; render(); });
document.getElementById("save").addEventListener("click", () => {
  for (const answer of Object.values(answers)) {
    const label = answer.set + " " + hex(answer.index);
    if (!["visual", "in_game", "source", "unknown_or_unused"].includes(answer.evidence)) {
      alert(label + ": choose an evidence level before exporting.");
      return;
    }
    if (answer.evidence === "unknown_or_unused" && answer.transcription) {
      alert(label + ": an unknown glyph cannot also claim a transcription.");
      return;
    }
    if (["in_game", "source"].includes(answer.evidence) && !answer.notes.trim()) {
      alert(label + ": add a frame or source note for this evidence level.");
      return;
    }
  }
  const output = {
    schema_version: 1,
    source_hashes: sourceHashes,
    answers: Object.values(answers).sort(
      (a, b) => a.set.localeCompare(b.set) || a.index - b.index),
  };
  const blob = new Blob([JSON.stringify(output, null, 2) + "\n"],
    {type: "application/json"});
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = "alien_soldier_source_2_0_glyph_answers.json";
  anchor.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
});
document.getElementById("restore").addEventListener("change", async event => {
  const file = event.target.files[0];
  if (!file) return;
  try {
    const documentData = JSON.parse(await file.text());
    if (documentData.schema_version !== 1 ||
        JSON.stringify(documentData.source_hashes) !== JSON.stringify(sourceHashes) ||
        !Array.isArray(documentData.answers)) {
      throw new Error("Answer schema or source-art hashes differ.");
    }
    const imported = {};
    for (const answer of documentData.answers) {
      const asset = assets[answer.set];
      if (!asset || !Number.isInteger(answer.index) ||
          answer.index < asset.first || answer.index >= asset.first + asset.count ||
          typeof answer.transcription !== "string" ||
          typeof answer.evidence !== "string" ||
          typeof answer.notes !== "string") {
        throw new Error("Invalid glyph answer record.");
      }
      imported[key(answer.set, answer.index)] = answer;
    }
    answers = imported;
    persist();
    render();
  } catch (error) {
    alert("Could not restore answers: " + error.message);
  }
  event.target.value = "";
});
render();
</script>
</html>
"""


def render_html(root: Path) -> str:
    return HTML.replace("__GLYPH_DATA__", json.dumps(inventory(root), separators=(",", ":")))


def validate_answers(document: dict, assets: dict) -> int:
    """Validate a returned worksheet against these exact source-art bytes."""
    if not isinstance(document, dict) or document.get("schema_version") != 1:
        raise ValueError("glyph answers have an unsupported schema")
    expected_hashes = {name: asset["sha256"] for name, asset in assets.items()}
    if document.get("source_hashes") != expected_hashes:
        raise ValueError("glyph answers do not match the current source-art hashes")
    answers = document.get("answers")
    if not isinstance(answers, list):
        raise ValueError("glyph answers must be a list")
    seen = set()
    for answer in answers:
        if not isinstance(answer, dict) or set(answer) != {"set", "index", "transcription", "evidence", "notes"}:
            raise ValueError("glyph answer fields differ from the worksheet schema")
        name, index = answer["set"], answer["index"]
        if not isinstance(name, str) or name not in assets or isinstance(index, bool) or not isinstance(index, int):
            raise ValueError("glyph answer has an invalid set or index")
        asset = assets[name]
        if not asset["first"] <= index < asset["first"] + asset["count"]:
            raise ValueError("glyph answer index is outside source art")
        key = name, index
        if key in seen:
            raise ValueError("duplicate glyph answer: %s %d" % key)
        seen.add(key)
        transcription, evidence, notes = (answer["transcription"], answer["evidence"], answer["notes"])
        if (
            not isinstance(transcription, str)
            or len(transcription) > 32
            or not isinstance(evidence, str)
            or evidence not in EVIDENCE
            or not isinstance(notes, str)
            or len(notes) > 2000
        ):
            raise ValueError("glyph answer has invalid transcription or evidence")
        if evidence == "unknown_or_unused" and transcription:
            raise ValueError("unknown glyph answer cannot claim a transcription")
        if evidence in {"in_game", "source"} and not notes.strip():
            raise ValueError("in-game and source evidence needs a frame or source note")
    return len(seen)


def write_page(path: Path, body: str, force: bool) -> None:
    if path.exists() and not force:
        raise ValueError("review page already exists; pass --force to replace it")
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            newline="\n",
            dir=path.parent,
            prefix=path.name + ".",
            suffix=".tmp",
            delete=False,
        ) as stream:
            temporary = Path(stream.name)
            stream.write(body)
        os.replace(temporary, path)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--validate-answers")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    try:
        assets = inventory(root)
        if args.validate_answers:
            path = Path(args.validate_answers)
            document = json.loads(path.read_text(encoding="utf-8"))
            count = validate_answers(document, assets)
            print("[OK] %d glyph answers match the current source art" % count)
            return 0
        if args.check:
            print("[OK] glyph review: " + ", ".join("%s %d" % (name, asset["count"]) for name, asset in assets.items()))
            return 0
        output = (root / args.output).resolve()
        if not output.is_relative_to(root / "reference"):
            raise ValueError("glyph review output must be inside the ignored reference/")
        page = HTML.replace("__GLYPH_DATA__", json.dumps(assets, separators=(",", ":")))
        write_page(output, page, args.force)
        print("[OK] wrote %s" % output)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
