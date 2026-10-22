"""A bounded source-art palette; glyph IDs carry no inferred transcription."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from authoring.credits_text_model import glyph_tiles as credits_glyph_tiles
from authoring.japanese_glyph_model import glyph_pixels
from authoring.shared_font_preview import glyph_tiles


PAGE_SIZE = 64
COLUMNS = 16
CELL_WIDTH = 40
CELL_HEIGHT = 56
ROWS = PAGE_SIZE // COLUMNS


@dataclass(frozen=True)
class GlyphRange:
    family: str
    minimum: int
    maximum: int

    @property
    def page_count(self) -> int:
        return (self.maximum - self.minimum) // PAGE_SIZE + 1

    def page_for(self, value: int) -> int:
        if type(value) is not int or not self.minimum <= value <= self.maximum:
            raise ValueError("glyph is outside the selected font range")
        return (value - self.minimum) // PAGE_SIZE

    def values(self, page: int) -> range:
        if type(page) is not int or not 0 <= page < self.page_count:
            raise ValueError("glyph page is outside the selected font range")
        start = self.minimum + page * PAGE_SIZE
        return range(start, min(start + PAGE_SIZE, self.maximum + 1))

    def value_at(self, page: int, x: int, y: int) -> int | None:
        if not 0 <= x < COLUMNS * CELL_WIDTH or not 0 <= y < ROWS * CELL_HEIGHT:
            return None
        index = (y // CELL_HEIGHT) * COLUMNS + x // CELL_WIDTH
        values = self.values(page)
        return values[index] if index < len(values) else None


def source_pixels(root: Path, family: str, value: int) -> list[list[int]]:
    """Use the editor's proved decoders, separating a shared font's two tiles."""
    if family == "japanese":
        return glyph_pixels(root, value)
    if family == "credits":
        tiles = credits_glyph_tiles(root, value)
        if tiles is None:
            return [[0] * 17 for _ in range(8)]
    elif family == "shared":
        tiles = glyph_tiles(root, value)
    else:
        raise ValueError("unknown source glyph family")
    return [left + [0] + right for left, right in zip(*tiles)]


class GlyphPicker:
    """One compact modeless palette, refreshed when its editor selects a slot."""

    def __init__(self, owner):
        self.owner = owner
        self.font_range = None
        self.page = 0
        self.photo = None
        self.window = owner.tk.Toplevel(owner.window)
        self.window.title("Choose source glyph (%s)" % owner.profile.upper())
        self.window.transient(owner.window)
        self.window.resizable(False, False)
        self.window.protocol("WM_DELETE_WINDOW", self.close)
        bar = owner.ttk.Frame(self.window, padding=8)
        bar.pack(fill="x")
        self.previous = owner.ttk.Button(bar, text="Previous page", command=lambda: self.step_page(-1))
        self.previous.pack(side="left")
        self.next = owner.ttk.Button(bar, text="Next page", command=lambda: self.step_page(1))
        self.next.pack(side="left", padx=6)
        self.caption = owner.ttk.Label(bar, text="")
        self.caption.pack(side="left", padx=8)
        self.canvas = owner.tk.Canvas(
            self.window,
            width=COLUMNS * CELL_WIDTH,
            height=ROWS * CELL_HEIGHT,
            highlightthickness=0,
            background="#202020",
        )
        self.canvas.pack(padx=8)
        self.canvas.bind("<Button-1>", self.choose)
        self.hint = owner.ttk.Label(self.window, text="Click a glyph to replace the selected slot.", padding=8)
        self.hint.pack(fill="x")
        self.sync()

    def sync(self):
        self.font_range = self.owner.state.glyph_range
        self.page = self.font_range.page_for(self.owner.state.value) if self.font_range is not None else 0
        self.draw()

    def step_page(self, delta):
        if self.font_range is None:
            return
        self.page = max(0, min(self.page + delta, self.font_range.page_count - 1))
        self.draw()

    def draw(self):
        self.canvas.delete("all")
        self.photo = None
        if self.font_range is None:
            self.previous.configure(state="disabled")
            self.next.configure(state="disabled")
            self.caption.configure(text="No editable glyph selected")
            self.hint.configure(text="Timing values and protected boundaries have no glyph palette.")
            return
        self.previous.configure(state="normal" if self.page else "disabled")
        self.next.configure(state=("normal" if self.page + 1 < self.font_range.page_count else "disabled"))
        values = self.font_range.values(self.page)
        self.caption.configure(
            text="%s  $%02X..$%02X  (%d/%d)"
            % (self.font_range.family, values[0], values[-1], self.page + 1, self.font_range.page_count)
        )
        self.hint.configure(
            text=(
                "Source palette indices; shared tiles shown separately. Credits $00 is a blank slot."
                if self.font_range.family == "credits"
                else "Source palette indices; click replaces one slot. No character transcription."
            )
        )
        self.photo = self.owner.tk.PhotoImage(master=self.window, width=COLUMNS * CELL_WIDTH, height=ROWS * CELL_HEIGHT)
        self.photo.put("#202020", to=(0, 0, COLUMNS * CELL_WIDTH, ROWS * CELL_HEIGHT))
        for index, value in enumerate(values):
            left = (index % COLUMNS) * CELL_WIDTH
            top = (index // COLUMNS) * CELL_HEIGHT
            pixels = source_pixels(self.owner.project, self.font_range.family, value)
            for y, row in enumerate(pixels):
                colours = ["#%02x%02x%02x" % ((32 + pixel * 14,) * 3) for pixel in row for _ in range(2)]
                line = "{" + " ".join(colours) + "}"
                self.photo.put(line, to=(left + 3, top + y * 2 + 3))
                self.photo.put(line, to=(left + 3, top + y * 2 + 4))
        self.canvas.create_image(0, 0, anchor="nw", image=self.photo)
        for index, value in enumerate(values):
            left = (index % COLUMNS) * CELL_WIDTH
            top = (index // COLUMNS) * CELL_HEIGHT
            self.canvas.create_text(
                left + CELL_WIDTH // 2, top + 44, text="$%02X" % value, fill="#eeeeee", font=("TkFixedFont", 9)
            )
            if value == self.owner.state.value:
                self.canvas.create_rectangle(
                    left + 1, top + 1, left + CELL_WIDTH - 1, top + CELL_HEIGHT - 1, outline="#ff40ff", width=2
                )

    def choose(self, event):
        if self.font_range is None:
            return
        value = self.font_range.value_at(self.page, event.x, event.y)
        if value is not None:
            self.owner.apply_value(glyph=value)

    def close(self):
        self.owner.picker = None
        self.window.destroy()
