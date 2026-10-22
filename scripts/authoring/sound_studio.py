#!/usr/bin/env python3
"""Open the profile-bound Alien Soldier Sound Studio workstation."""

from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.content_workspace import (  # noqa: E402
    ContentError,
    artifact_path,
    checked_path,
    load_manifest,
    stage_tree,
)
from authoring.sound_envelope_model import (  # noqa: E402
    apply_document as apply_envelopes,
    atomic_write_json as write_envelopes,
    load_document as load_envelopes,
    validate_document as validate_envelopes,
)
from authoring.sound_instrument_model import (  # noqa: E402
    apply_document as apply_instruments,
    atomic_write_json as write_instruments,
    load_document as load_instruments,
    validate_document as validate_instruments,
)
from authoring.sound_pcm_codec import (  # noqa: E402
    decode_dpcm,
    load_tables,
    ordinary_dac_event_offsets,
    ordinary_dac_timing_contract,
)
from authoring.sound_pcm_model import (  # noqa: E402
    apply_document as apply_pcm,
    atomic_write_json as write_pcm,
    load_document as load_pcm,
    music_sample_ids,
    validate_document as validate_pcm,
)
from authoring.sound_pcm_preview import export_path, wav_bytes  # noqa: E402
from authoring.sound_sequence_model import (  # noqa: E402
    apply_document as apply_sequences,
    atomic_write_json as write_sequences,
    load_document as load_sequences,
    validate_document as validate_sequences,
)
from authoring.sound_studio_state import Workspace  # noqa: E402
from authoring.sound_audition import launch as launch_audition  # noqa: E402
from authoring.sound_audition_model import request_for_payload  # noqa: E402
from authoring.sound_semantic_model import channel_owners, source_channels  # noqa: E402
from authoring.stage_tilemap_model import labelled_blocks, parsed_operation  # noqa: E402


MANIFEST = "config/authoring/content_studios.json"
HANDLERS = {
    "sound_envelope_document": (load_envelopes, validate_envelopes, write_envelopes, apply_envelopes),
    "sound_instrument_document": (load_instruments, validate_instruments, write_instruments, apply_instruments),
    "sound_pcm_document": (load_pcm, validate_pcm, write_pcm, apply_pcm),
    "sound_sequence_document": (load_sequences, validate_sequences, write_sequences, apply_sequences),
}


def load_context(project: Path, profile: str) -> dict[str, dict]:
    with parsed_operation(project):
        return _load_context(project, profile)


def _load_context(project: Path, profile: str) -> dict[str, dict]:
    manifest = load_manifest(checked_path(project, MANIFEST), project)
    studio = next(item for item in manifest["studios"] if item["id"] == "sound")
    artifacts = {item["id"]: item for item in manifest["artifacts"]}
    context = {}
    for identifier in studio["artifacts"]:
        artifact = artifacts[identifier]
        try:
            loader, validator, writer, apply = HANDLERS[artifact["kind"]]
        except KeyError as error:
            raise ValueError("Sound Studio has no handler for %s" % artifact["kind"]) from error
        path = artifact_path(project, manifest, profile, artifact)
        document = loader(path)
        validator(document, project, profile)
        context[identifier] = {
            "artifact": artifact,
            "path": path,
            "document": document,
            "load": loader,
            "validate": validator,
            "write": writer,
            "apply": apply,
        }
    return context


def parse_value(text: str) -> int:
    text = text.strip()
    if text.startswith("$"):
        return int(text[1:], 16)
    return int(text, 0)


def replacement_for(value: int, bounds: tuple[int, int]) -> int:
    minimum, maximum = bounds
    if value < maximum:
        return value + 1
    if value > minimum:
        return value - 1
    raise ValueError("selected sound value has no alternate representation")


class Window:
    """Tk widgets only; the tested Workspace owns editable values."""

    def __init__(self, project, profile, context, tk, ttk, messagebox, simpledialog, filedialog, gens=None):
        self.project = project
        self.profile = profile
        self.context = context
        self.tk = tk
        self.ttk = ttk
        self.messagebox = messagebox
        self.simpledialog = simpledialog
        self.filedialog = filedialog
        self.gens = gens or project.parent / "gens_automation/Output/Gens.exe"
        self.audition = None
        self.audition_timer = None
        self.state = Workspace({identifier: record["document"] for identifier, record in context.items()})
        self.high_dpcm, self.low_dpcm = load_tables(project)
        self.dac_timing = ordinary_dac_timing_contract(project)
        self._semantic_source = None
        self._semantic_bindings = {}
        self._semantic_owners = ()
        self._semantic_samples = None
        self._semantic_controls = ()
        self.window = tk.Tk()
        self.window.title("Alien Soldier Sound Studio (%s)" % profile.upper())
        self.window.geometry("1040x740")
        self.window.protocol("WM_DELETE_WINDOW", self.close)
        self._build_toolbar()
        self._build_editor()
        self.select_artifact(0)

    def _build_toolbar(self):
        bar = self.ttk.Frame(self.window, padding=(8, 6))
        bar.pack(side="top", fill="x")
        self.ttk.Label(bar, text="Artifact").pack(side="left")
        self.artifact_choice = self.tk.StringVar()
        self.artifact_box = self.ttk.Combobox(
            bar,
            values=self.state.artifact_ids,
            textvariable=self.artifact_choice,
            state="readonly",
            width=30,
        )
        self.artifact_box.pack(side="left", padx=8)
        self.artifact_box.bind(
            "<<ComboboxSelected>>",
            lambda _: self.select_artifact(self.artifact_box.current()),
        )
        self.save_button = self.ttk.Button(bar, text="Save", command=self.save)
        self.save_button.pack(side="left", padx=2)
        self.reload_button = self.ttk.Button(bar, text="Reload", command=self.reload)
        self.reload_button.pack(side="left", padx=2)
        self.build_button = self.ttk.Button(bar, text="Build ROM", command=self.build_rom)
        self.build_button.pack(side="left", padx=2)
        self.preview_button = self.ttk.Button(bar, text="Export PCM WAV", command=self.export_pcm_preview)
        self.preview_button.pack(side="left", padx=2)
        self.status = self.ttk.Label(bar, text="")
        self.status.pack(side="left", padx=10)
        audition = self.ttk.Frame(self.window, padding=(8, 4))
        audition.pack(side="top", fill="x")
        self.ttk.Label(audition, text="Original-driver audition").pack(side="left")
        payloads = []
        for payload in self.context.get("sound_sequences", {}).get("document", {}).get("payloads", []):
            try:
                request_for_payload(payload["name"])
            except (KeyError, ValueError):
                continue
            payloads.append(payload["name"])
        self.audition_choice = self.tk.StringVar(value=payloads[0] if payloads else "")
        self.audition_box = self.ttk.Combobox(
            audition, values=payloads, textvariable=self.audition_choice, state="readonly", width=23
        )
        self.audition_box.pack(side="left", padx=8)
        self.play_button = self.ttk.Button(
            audition, text="Play", command=self.play_audition, state="normal" if payloads else "disabled"
        )
        self.play_button.pack(side="left", padx=2)
        self.stop_button = self.ttk.Button(audition, text="Stop", command=self.stop_audition, state="disabled")
        self.stop_button.pack(side="left", padx=2)
        self.ttk.Label(audition, text="Plays the saved workspace").pack(side="left", padx=10)

    def _build_editor(self):
        panel = self.ttk.Frame(self.window, padding=(14, 12))
        panel.pack(fill="both", expand=True)
        self.ttk.Label(panel, text="Payload / editable field").grid(row=0, column=0, sticky="w")
        self.field_choice = self.tk.StringVar()
        self.field_box = self.ttk.Combobox(panel, textvariable=self.field_choice, state="readonly", width=98)
        self.field_box.grid(row=1, column=0, columnspan=5, sticky="ew", pady=(2, 12))
        self.field_box.bind("<<ComboboxSelected>>", lambda _: self.select_field(self.field_box.current()))

        self.ttk.Button(panel, text="Previous", command=lambda: self.step_value(-1)).grid(row=2, column=0, sticky="w")
        self.ttk.Button(panel, text="Next", command=lambda: self.step_value(1)).grid(
            row=2, column=1, sticky="w", padx=(4, 18)
        )
        self.ttk.Label(panel, text="Index").grid(row=2, column=2, sticky="e")
        self.index_text = self.tk.StringVar(value="0")
        index = self.ttk.Entry(panel, textvariable=self.index_text, width=10)
        index.grid(row=2, column=3, sticky="w", padx=5)
        index.bind("<Return>", lambda _: self.go_to_value())
        self.ttk.Button(panel, text="Go", command=self.go_to_value).grid(row=2, column=4, sticky="w")

        self.position = self.ttk.Label(panel, text="")
        self.position.grid(row=3, column=0, columnspan=5, sticky="w", pady=(12, 2))
        self.sequence = self.ttk.Label(panel, text="", justify="left", wraplength=960, font=("TkFixedFont", 10))
        self.sequence.grid(row=4, column=0, columnspan=5, sticky="ew", pady=(0, 10))
        self.decoded = self.ttk.Label(panel, text="", justify="left", wraplength=960, font=("TkFixedFont", 10))
        self.decoded.grid(row=5, column=0, columnspan=5, sticky="ew", pady=(0, 18))

        self.ttk.Label(panel, text="Numeric value ($hex, 0xhex, or decimal)").grid(
            row=6, column=0, columnspan=2, sticky="w"
        )
        self.value_text = self.tk.StringVar()
        value = self.ttk.Entry(panel, textvariable=self.value_text, width=18)
        value.grid(row=7, column=0, sticky="w", pady=(2, 8))
        value.bind("<Return>", lambda _: self.apply_value())
        self.ttk.Button(panel, text="Apply value", command=self.apply_value).grid(row=7, column=1, sticky="w", padx=4)
        self.semantic_description = self.ttk.Label(panel, text="", justify="left", wraplength=960)
        self.semantic_description.grid(row=8, column=0, columnspan=5, sticky="w", pady=(8, 4))
        self.semantic_box = self.ttk.Combobox(panel, state="disabled", width=55)
        self.semantic_box.grid(row=9, column=0, columnspan=2, sticky="w")
        self.semantic_box.bind("<<ComboboxSelected>>", lambda _: self.show_semantic_value())
        self.semantic_text = self.tk.StringVar()
        self.semantic_entry = self.ttk.Entry(panel, textvariable=self.semantic_text, width=12)
        self.semantic_entry.grid(row=9, column=2, sticky="w")
        self.semantic_entry.bind("<Return>", lambda _: self.apply_semantic())
        self.semantic_button = self.ttk.Button(panel, text="Apply semantic value", command=self.apply_semantic)
        self.semantic_button.grid(row=9, column=3, columnspan=2, sticky="w", padx=4)
        self.help = self.ttk.Label(
            panel,
            text=(
                "Fixed-capacity values only. Sequence opcodes and branch targets, "
                "envelope commands, PCM headers, descriptors, and padding stay protected. "
                "DPCM preview shows exact decoded levels without claiming an unproved rate."
            ),
            wraplength=960,
        )
        self.help.grid(row=10, column=0, columnspan=5, sticky="w", pady=(18, 0))
        panel.columnconfigure(0, weight=1)

    def select_artifact(self, index):
        try:
            self.state.select_artifact(index)
        except ValueError as error:
            self.messagebox.showerror("Sound Studio", str(error))
            return
        self.artifact_box.current(index)
        self.preview_button.configure(state="normal" if self.state.artifact_id == "sound_pcm_samples" else "disabled")
        self.field_box.configure(values=[field.label for field in self.state.artifact_fields])
        self.select_field(0)

    def select_field(self, index):
        try:
            self.state.select_field(index)
        except ValueError as error:
            self.messagebox.showerror("Sound Studio", str(error))
            return
        self.field_box.current(index)
        self.index_text.set("0")
        parts = self.state.field.label.split(" / ")
        payload = (
            parts[1]
            if self.state.artifact_id == "sound_sequences" and len(parts) > 1
            else parts[0]
            if self.state.artifact_id == "sound_instruments"
            else None
        )
        if payload is not None and payload in self.audition_box["values"]:
            self.audition_choice.set(payload)
        self.show_value()

    def go_to_value(self):
        try:
            self.state.select_value(int(self.index_text.get(), 0))
        except ValueError as error:
            self.messagebox.showerror("Sound Studio", str(error))
            return
        self.show_value()

    def step_value(self, delta):
        index = max(0, min(self.state.field.length - 1, self.state.value_index + delta))
        self.state.select_value(index)
        self.index_text.set(str(index))
        self.show_value()

    def _dpcm_preview(self) -> str:
        if self.state.field.representation != "dpcm":
            return ""
        sample = self.state.field.values[0].container
        decoded = decode_dpcm(bytes.fromhex(sample["data"]), self.high_dpcm, self.low_dpcm)
        centre = self.state.value_index * 2
        start = max(0, centre - 16)
        end = min(len(decoded), centre + 18)
        first, second = ordinary_dac_event_offsets(self.dac_timing, self.state.value_index)
        return (
            "Decoded DPCM levels %d..%d: %s\n"
            "Selected pair: %02X at +%d, %02X at +%d Z80 T-states "
            "(CPU-only uninterrupted path; not an audio rate)"
        ) % (
            start,
            end - 1,
            " ".join("%02X" % value for value in decoded[start:end]),
            decoded[centre],
            first,
            decoded[centre + 1],
            second,
        )

    def show_value(self):
        field = self.state.field
        minimum, maximum = self.state.bounds
        if field.representation == "signed":
            self.value_text.set(str(self.state.value))
        else:
            self.value_text.set("$%02X" % self.state.value)
        self.position.configure(
            text=(
                "%s — value %d of %d; allowed %d..%d"
                % (field.label, self.state.value_index + 1, field.length, minimum, maximum)
            )
        )
        start, values = self.state.visible_values()
        formatter = str if field.representation == "signed" else lambda value: "%02X" % value
        self.sequence.configure(
            text=(
                "Values %d..%d: %s" % (start, start + len(values) - 1, " ".join(formatter(value) for value in values))
            )
        )
        self.decoded.configure(text=self._dpcm_preview())
        self.show_semantic_context()

    def show_semantic_context(self):
        previous = self.semantic_box.current()
        previous_name = self._semantic_controls[previous].name if 0 <= previous < len(self._semantic_controls) else None
        self._semantic_owners, self._semantic_samples = (), None
        try:
            payload = self.state.field.payload
            if self.state.artifact_id == "sound_sequences" and payload and "entry_offsets" in payload:
                name = payload["name"]
                if name not in self._semantic_bindings:
                    if self._semantic_source is None:
                        self._semantic_source = labelled_blocks(self.project)
                    data, bodies = self._semantic_source
                    channels = source_channels(payload, data[name])
                    self._semantic_bindings[name] = (channel_owners(payload, channels), music_sample_ids(bodies))
                owner_map, self._semantic_samples = self._semantic_bindings[name]
                instruction = self.state.field.values[self.state.value_index].container
                self._semantic_owners = owner_map.get(instruction.get("offset"), ())
            description, self._semantic_controls = self.state.semantic_context(
                self._semantic_owners, self._semantic_samples
            )
        except (KeyError, OSError, ValueError) as error:
            description, self._semantic_controls = "Source channel binding unavailable: " + str(error), ()
        self.semantic_description.configure(text=description)
        self.semantic_box.configure(
            values=["%s (%d..%d)" % (item.label, item.minimum, item.maximum) for item in self._semantic_controls],
            state="readonly" if self._semantic_controls else "disabled",
        )
        if self._semantic_controls:
            selected = next(
                (index for index, control in enumerate(self._semantic_controls) if control.name == previous_name), 0
            )
            self.semantic_box.current(selected)
        else:
            self.semantic_box.set("")
        self.show_semantic_value()

    def show_semantic_value(self):
        index = self.semantic_box.current()
        enabled = 0 <= index < len(self._semantic_controls)
        self.semantic_text.set(str(self._semantic_controls[index].read(self.state.value)) if enabled else "")
        for widget in (self.semantic_entry, self.semantic_button):
            widget.configure(state="normal" if enabled else "disabled")

    def apply_semantic(self):
        index = self.semantic_box.current()
        if not 0 <= index < len(self._semantic_controls):
            return
        record = self.context[self.state.artifact_id]
        try:
            self.state.set_semantic(
                self._semantic_controls[index],
                parse_value(self.semantic_text.get()),
                lambda document: record["validate"](document, self.project, self.profile),
                owners=self._semantic_owners,
                sample_ids=self._semantic_samples,
            )
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Sound Studio", str(error))
            self.show_value()
            return
        self.show_value()
        self.status.configure(text="Validated semantic edit: " + self.state.artifact_id)

    def apply_value(self):
        artifact = self.state.artifact_id
        old_value = self.state.value
        dirty_before = set(self.state.dirty)
        try:
            self.state.set_value(parse_value(self.value_text.get()))
            record = self.context[artifact]
            record["validate"](record["document"], self.project, self.profile)
        except Exception as error:
            self.state.field.set_value(self.state.value_index, old_value)
            self.state.dirty = dirty_before
            self.messagebox.showerror("Sound Studio", str(error))
            self.show_value()
            return
        self.show_value()
        self.status.configure(text="Edited %s" % artifact)

    def save(self):
        try:
            for record in self.context.values():
                record["validate"](record["document"], self.project, self.profile)
            for identifier in self.state.dirty:
                record = self.context[identifier]
                record["write"](record["path"], record["document"])
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Sound Studio", str(error))
            return False
        self.state.dirty.clear()
        self.status.configure(text="Saved")
        return True

    def reload(self):
        if self.state.dirty and not self.messagebox.askyesno("Sound Studio", "Discard unsaved sound edits?"):
            return
        try:
            self.context = load_context(self.project, self.profile)
            self.state = Workspace({identifier: record["document"] for identifier, record in self.context.items()})
            self._semantic_source = None
            self._semantic_bindings = {}
            self.select_artifact(0)
        except (OSError, ValueError, ContentError) as error:
            self.messagebox.showerror("Sound Studio", str(error))

    def build_rom(self):
        if self.state.dirty:
            self.messagebox.showerror("Sound Studio", "Save sound edits before building.")
            return
        command = [
            "make",
            "--no-print-directory",
            "build-content",
            "CONTENT_PROFILE=%s" % self.profile,
        ]
        if self.gens.is_file():
            command.append("GENS_DIR=" + str(self.gens.resolve().parent.parent))
        try:
            result = subprocess.run(command, cwd=self.project, check=False)
        except OSError as error:
            self.messagebox.showerror("Sound Studio", "Cannot launch content build: " + str(error))
            self.status.configure(text="Content build could not be launched.")
            return
        if result.returncode:
            self.messagebox.showerror("Sound Studio", "Content build failed with code %d." % result.returncode)

    def play_audition(self):
        try:
            request = request_for_payload(self.audition_choice.get())
            # Save must succeed before either rebuilding or replacing playback.
            if self.state.dirty and not self.save():
                return
            if self.stop_audition() is not None:
                return
            parent = checked_path(self.project, "build/content/%s/audition" % self.profile)
            parent.mkdir(parents=True, exist_ok=True)
            directory = Path(tempfile.mkdtemp(prefix="build-", dir=parent))
            listing = directory / "sound.lst"
            self.status.configure(text="Building saved %s workspace for audition..." % self.profile.upper())
            self.window.update_idletasks()
            result = subprocess.run(
                [
                    "make",
                    "--no-print-directory",
                    "build-content",
                    "CONTENT_PROFILE=%s" % self.profile,
                    "AS_ARGS=-q -maxerrors 2",
                    "CONTENT_LISTING=" + str(listing),
                    "GENS_DIR=" + str(self.gens.resolve().parent.parent),
                ],
                cwd=self.project,
                check=False,
            )
            if result.returncode:
                raise ValueError("audition content build failed with code %d" % result.returncode)
            self.audition = launch_audition(
                self.project,
                self.profile,
                request,
                checked_path(self.project, "build/content/%s/alien_soldier.bin" % self.profile),
                listing,
                self.gens,
            )
            self.stop_button.configure(state="normal")
            self.status.configure(text="Waiting for request $%02X loader state..." % request)
            self.audition_timer = self.window.after(200, self._poll_audition)
        except (OSError, RuntimeError, ValueError, ContentError) as error:
            self.messagebox.showerror("Sound Studio", str(error))

    def _poll_audition(self):
        self.audition_timer = None
        if self.audition is None:
            return
        try:
            live = self.audition.poll()
            if self.audition.ready is not None:
                self.status.configure(
                    text="Request $%02X loaded; original-driver audition" % self.audition.contract["request_id"]
                )
            if live:
                self.audition_timer = self.window.after(200, self._poll_audition)
            else:
                self.status.configure(text="Audition finished")
                self.audition = None
                self.stop_button.configure(state="disabled")
        except (OSError, RuntimeError, ValueError) as error:
            cleanup_error = self.stop_audition(report_error=False)
            detail = str(error)
            if cleanup_error is not None and str(cleanup_error) != detail:
                detail += "\nStop also failed: " + str(cleanup_error)
            self.messagebox.showerror("Sound Studio", detail)

    def stop_audition(self, *, report_error=True):
        if self.audition_timer is not None:
            self.window.after_cancel(self.audition_timer)
            self.audition_timer = None
        if self.audition is not None:
            session = self.audition
            try:
                session.stop()
                if session.process.poll() is None:
                    raise RuntimeError("audition stop returned with its process still running")
            except (OSError, RuntimeError, ValueError, subprocess.TimeoutExpired) as error:
                # Validation can fail after reaping; termination/wait can also
                # fail before it. Never discard an alive or unverified owner.
                try:
                    stopped = session.process.poll() is not None
                except (OSError, RuntimeError):
                    stopped = False
                if stopped:
                    self.audition = None
                self.stop_button.configure(state="disabled" if stopped else "normal")
                self.status.configure(
                    text="Audition stopped; validation failed"
                    if stopped
                    else "Audition stop failed; process remains owned"
                )
                if report_error:
                    self.messagebox.showerror("Sound Studio", str(error))
                return error
            self.audition = None
            self.status.configure(text="Audition stopped")
        self.stop_button.configure(state="disabled")
        return None

    def export_pcm_preview(self):
        if self.state.artifact_id != "sound_pcm_samples":
            return
        try:
            record = self.context["sound_pcm_samples"]
            record["validate"](record["document"], self.project, self.profile)
            sample = self.state.field.values[0].container
            label = self.state.field.label
            bank = label.split(" / ", 1)[0]
            rate = self.simpledialog.askinteger(
                "Sound Studio",
                "Audition sample rate in Hz (the cartridge rate is not yet proved):",
                parent=self.window,
                minvalue=1000,
                maxvalue=48000,
            )
            if rate is None:
                return
            destination = self.filedialog.asksaveasfilename(
                parent=self.window,
                title="Export PCM audition WAV",
                defaultextension=".wav",
                filetypes=[("WAV audio", "*.wav")],
                initialfile="%s_sample_%02d.wav" % (bank, sample["index"]),
            )
            if not destination:
                return
            path = export_path(self.project, self.project / "content/workspace", Path(destination))
            payload = wav_bytes(sample, rate, self.high_dpcm, self.low_dpcm)
            from authoring.atomic_output import atomic_write_bytes as _write_bytes

            _write_bytes(path, payload)
            self.status.configure(text="Exported %s at selected %d Hz" % (path.name, rate))
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Sound Studio", str(error))

    def close(self):
        if self.state.dirty and not self.messagebox.askyesno("Sound Studio", "Close with unsaved sound edits?"):
            return
        self.stop_audition()
        if self.audition is None:
            self.window.destroy()


def check(project: Path, profile: str) -> None:
    with parsed_operation(project):
        _check(project, profile)


def _check(project: Path, profile: str) -> None:
    context = load_context(project, profile)
    state = Workspace({identifier: record["document"] for identifier, record in context.items()})
    destination = project / "build/content/sound-smoke" / profile / "tree"
    stage_tree(project, destination)
    for identifier in state.artifact_ids:
        state.select_artifact(identifier)
        original = state.value
        state.set_value(replacement_for(original, state.bounds))
        record = context[identifier]
        record["validate"](record["document"], project, profile)
        changed = record["apply"](record["document"], destination, profile, validation_root=project)
        if not changed:
            raise ValueError("Sound Studio smoke edit changed no source: %s" % identifier)
        state.field.set_value(0, original)
        record["validate"](record["document"], project, profile)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=("jp", "eu"), default="jp")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--gens", default="../gens_automation/Output/Gens.exe")
    args = parser.parse_args()
    project = Path(args.root).resolve()
    try:
        if args.check:
            check(project, args.profile)
            print("[OK] %s Sound Studio workstation smoke" % args.profile)
            return 0
        context = load_context(project, args.profile)
        import tkinter as tk
        from tkinter import filedialog, messagebox, simpledialog, ttk

        window = Window(
            project, args.profile, context, tk, ttk, messagebox, simpledialog, filedialog, Path(args.gens).resolve()
        )
        window.window.mainloop()
        return 0
    except (OSError, ValueError, ContentError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
