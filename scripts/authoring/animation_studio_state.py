#!/usr/bin/env python3
"""Display-free editing state for Graphics Studio animation timelines."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class AnimationWorkspace:
    document: dict
    script_index: int = 0
    frame_index: int = 0
    dirty: bool = False

    @property
    def scripts(self) -> list[dict]:
        return self.document["scripts"]

    @property
    def script(self) -> dict:
        return self.scripts[self.script_index]

    @property
    def frames(self) -> list[dict]:
        return self.script["frames"]

    @property
    def frame(self) -> dict:
        return self.frames[self.frame_index]

    @property
    def target_options(self) -> list[str]:
        if self.frame["jump"]:
            return [record["name"] for record in self.scripts]
        return self.document["frame_targets"]

    def select_script(self, index: int) -> None:
        if not 0 <= index < len(self.scripts):
            raise ValueError("animation script index is outside the document")
        self.script_index = index
        self.frame_index = 0

    def select_frame(self, index: int) -> None:
        if not 0 <= index < len(self.frames):
            raise ValueError("animation frame index is outside the script")
        self.frame_index = index

    def set_frame(self, target: str, duration: int) -> None:
        if target not in self.target_options:
            raise ValueError("target is not valid for this frame role")
        if isinstance(duration, bool) or not isinstance(duration, int):
            raise ValueError("frame duration must be an integer")
        if not 0 <= duration <= 0xFFFF:
            raise ValueError("frame duration must fit an unsigned word")
        if bool(duration == 0) != self.frame["jump"]:
            raise ValueError("zero-duration jump role is source-owned")
        if self.frame["target"] == target and self.frame["duration"] == duration:
            return
        self.frame["target"] = target
        self.frame["duration"] = duration
        self.dirty = True
