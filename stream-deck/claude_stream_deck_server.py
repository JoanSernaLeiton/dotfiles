#!/usr/bin/env python3
import base64
import hashlib
import io
import json
import math
import re
import threading
import time
import traceback
import urllib.parse
import urllib.request
import uuid
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from functools import lru_cache
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

LISTEN_HOST = "0.0.0.0"
LISTEN_PORT = 8791
LOCAL_CLIENT_ADDRESSES = {"127.0.0.1", "::1", "::ffff:127.0.0.1"}
COMPANION_BASE_URL = "http://127.0.0.1:8000"
COMPANION_TIMEOUT_SECONDS = 2.5
STREAM_DECK_PAGE_VARIABLE_PATH = "/api/variable/internal/surface_streamdeck_A00SA5222LSBSF_page/value"
JUMP_TARGET_VARIABLE_NAME = "claude_deck_target_page"
CLAUDE_PAGE_NUMBER = 26
JUMP_CONTROL_PAGE_NUMBER = 27
JUMP_CONTROL_ROW = 0
JUMP_CONTROL_COLUMN = 0
FALLBACK_RETURN_PAGE_NUMBER = 1
MAIN_PAGE_NUMBER = 1
MAIN_PAGE_CLAUDE_KEY_ROW = 1
MAIN_PAGE_CLAUDE_KEY_COLUMN = 3
DECK_ROW_COUNT = 3
DECK_COLUMN_COUNT = 5
KEY_PIXEL_SIZE = 72
TEXT_HORIZONTAL_PADDING = 3
LABEL_HORIZONTAL_PADDING = 4
STATE_FILE_PATH = Path(__file__).resolve().parent / "state.json"
REQUEST_ABANDON_AFTER_SECONDS = 30
FINISHED_REQUEST_RETENTION_SECONDS = 120
WAITING_SESSION_RETENTION_SECONDS = 12 * 3600
LONG_POLL_DEFAULT_SECONDS = 10
LONG_POLL_MAXIMUM_SECONDS = 15
SENT_SCREEN_DISPLAY_SECONDS = 1.2
USER_BROWSING_GRACE_SECONDS = 15
RENDER_LOOP_INTERVAL_SECONDS = 0.25
TIME_LABEL_REFRESH_SECONDS = 30
FULL_REPUSH_INTERVAL_SECONDS = 600
COMPANION_HEALTH_PROBE_SECONDS = 30
FAILED_PUSH_RETRY_SECONDS = 3
MAXIMUM_REQUEST_BODY_BYTES = 512 * 1024
MAXIMUM_LAST_MESSAGE_CHARACTERS = 6000
MAXIMUM_DETAIL_CHARACTERS = 4000
MAXIMUM_PROJECT_CHARACTERS = 40
MAXIMUM_SESSION_LABEL_CHARACTERS = 28
MAXIMUM_AGENT_LABEL_CHARACTERS = 24
MAXIMUM_READING_PAGES = 40
MAXIMUM_QUESTIONS_PER_REQUEST = 4
MAXIMUM_OPTIONS_PER_QUESTION = 4
MAXIMUM_CHUNK_CHARACTERS = 40
PNG_PALETTE_COLOR_COUNT = 64
PUSH_WORKER_COUNT = 4
MAIN_KEY_BLINK_INTERVAL_SECONDS = 0.8
MAIN_KEY_BLINK_DURATION_SECONDS = 60
MAIN_KEY_ICON_DIAMETER = 40
MAIN_KEY_ICON_TOP = 7
MAIN_KEY_BADGE_RADIUS = 12
MAIN_KEY_BORDER_WIDTH = 3
MAIN_KEY_LABEL_FONT_SIZE = 12
ICON_SUPERSAMPLING_FACTOR = 4
MAIN_KEY_IDLE_ICON_DIAMETER = 50
ICON_GRID_SIZE = 24
ICON_STROKE_WIDTH_IN_GRID = 2.0
ICON_ARC_SEGMENT_COUNT = 48
ICON_KEY_ICON_SIZE = 30
ICON_KEY_ICON_TOP = 11
ICON_KEY_COMPACT_ICON_SIZE = 24
ICON_KEY_COMPACT_ICON_TOP = 20
ICON_KEY_CAPTION_TOP = 5
ICON_KEY_LABEL_TOP = 50
ICON_KEY_LABEL_FONT_SIZE = 12
ICON_KEY_CAPTION_FONT_SIZE = 11
SPARK_RAY_LENGTH_RATIOS = (1.0, 0.8, 0.94, 0.76, 1.0, 0.84, 0.9, 0.78, 0.97, 0.82, 0.9)
SPARK_RAY_BASE_WIDTH_RATIO = 0.11
SPARK_RAY_TIP_WIDTH_RATIO = 0.055
SPARK_ROTATION_RADIANS = -math.pi / 2
LABEL_CAPTION_FONT_SIZE = 12
LABEL_STRIP_HEIGHT = 6
LABEL_EDGE_MARGIN = 4
PREVIEW_KEY_GAP = 12
PREVIEW_MARGIN = 16

REGULAR_FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD_FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
NARROW_REGULAR_FONT_PATH = "/usr/share/fonts/truetype/liberation/LiberationSansNarrow-Regular.ttf"
NARROW_BOLD_FONT_PATH = "/usr/share/fonts/truetype/liberation/LiberationSansNarrow-Bold.ttf"
SYMBOL_CHARACTERS = frozenset("▶▼★☐☑✓↺↩")

PANEL_BACKGROUND_COLOR = (16, 16, 20)
BODY_TEXT_COLOR = (238, 238, 238)
MUTED_TEXT_COLOR = (150, 150, 162)
MUTED_BODY_COLOR = (190, 190, 200)
DARK_TEXT_COLOR = (24, 24, 24)
CLAUDE_ACCENT_COLOR = (217, 119, 87)
ALLOW_COLOR = (46, 125, 50)
ALLOW_TEXT_COLOR = (102, 187, 106)
ALLOW_ALWAYS_COLOR = (21, 101, 192)
ALLOW_ALWAYS_TEXT_COLOR = (100, 170, 255)
REJECT_COLOR = (198, 40, 40)
REJECT_TEXT_COLOR = (239, 110, 110)
NAVIGATION_COLOR = (44, 44, 50)
ICON_COLOR = (240, 240, 244)
NAVIGATION_LABEL_COLOR = (168, 168, 180)
ACCENT_LABEL_COLOR = (245, 245, 245)
ACCENT_CAPTION_COLOR = (225, 225, 230)
TERMINAL_KEY_COLOR = (38, 50, 56)
DISABLED_KEY_COLOR = (48, 48, 48)
OPTION_BACKGROUND_COLOR = (38, 50, 56)
OPTION_CHOSEN_COLOR = (0, 121, 107)
RECOMMENDED_STRIP_COLOR = (102, 187, 106)
PENDING_ALERT_COLOR = (198, 40, 40)
WAITING_ALERT_COLOR = (255, 179, 0)
IDLE_MAIN_KEY_COLOR = (32, 32, 36)
MAIN_KEY_PENDING_BACKGROUND_COLOR = (96, 22, 22)
MAIN_KEY_WAITING_BACKGROUND_COLOR = (54, 44, 18)
PAUSED_MACHINE_COLOR = (60, 60, 64)
WAITING_SESSION_BACKGROUND_COLOR = (34, 40, 46)
PENDING_LIST_BACKGROUND_COLOR = (110, 28, 28)
SENT_BACKGROUND_COLOR = (27, 94, 32)
RELEASED_BACKGROUND_COLOR = (55, 71, 79)
EMPTY_KEY_COLOR = (0, 0, 0)
UNKNOWN_MACHINE_COLOR = (120, 120, 120)
PREVIEW_BACKGROUND_COLOR = (70, 70, 74)
BANNER_MACHINE_TINT_WEIGHT = 0.16

MACHINE_NAME_PATTERN = re.compile(r"[a-z0-9-]{1,20}")
REQUEST_IDENTIFIER_PATTERN = r"([0-9a-f]{32})"
WAIT_PATH_PATTERN = re.compile(rf"/api/requests/{REQUEST_IDENTIFIER_PATTERN}/wait")
REQUEST_PATH_PATTERN = re.compile(rf"/api/requests/{REQUEST_IDENTIFIER_PATTERN}")
PRESS_PATH_PATTERN = re.compile(r"/deck/press/([0-2])/([0-4])")
RECOMMENDED_SUFFIX_PATTERN = re.compile(r"\s*\((recomendad[oa]|recommended)\)\s*$", re.IGNORECASE)
HOME_DIRECTORY_PATTERN = re.compile(r"/(?:Users|home)/[^/\s]+")
MARKDOWN_LINK_PATTERN = re.compile(r"\[([^\]]+)\]\([^)]+\)")
MARKDOWN_HEADING_PATTERN = re.compile(r"^#{1,6}\s*")
MARKDOWN_BULLET_PATTERN = re.compile(r"^[-*+]\s+")
CODE_LIKE_CHARACTERS = "/\\._:=@"


def log_event(message):
    print(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {message}", flush=True)


@dataclass(frozen=True)
class MachineDisplay:
    label: str
    color: tuple


KNOWN_MACHINE_DISPLAYS = {
    "personal": MachineDisplay("PERSONAL", (126, 87, 194)),
    "trabajo": MachineDisplay("TRABAJO", (2, 136, 209)),
}


def machine_display_for(machine):
    return KNOWN_MACHINE_DISPLAYS.get(machine) or MachineDisplay(machine.upper(), UNKNOWN_MACHINE_COLOR)


@dataclass(frozen=True)
class PanelTypography:
    regular_font_path: str
    bold_font_path: str
    font_size: int
    line_height: int
    lines_per_key: int


PANEL_TYPOGRAPHY = PanelTypography(NARROW_REGULAR_FONT_PATH, NARROW_BOLD_FONT_PATH, 15, 17, 4)

ALL_COLUMNS = tuple(range(DECK_COLUMN_COUNT))
TEXT_COLUMNS_BESIDE_IDENTITY = (1, 2, 3, 4)
IDENTITY_KEY_LOCATION = (0, 0)
BANNER_KEY_ROWS = ((0, TEXT_COLUMNS_BESIDE_IDENTITY),)
FULL_TEXT_KEY_ROWS = ((0, TEXT_COLUMNS_BESIDE_IDENTITY), (1, ALL_COLUMNS), (2, (1, 2, 3)))
WAITING_READING_KEY_ROWS = ((0, TEXT_COLUMNS_BESIDE_IDENTITY), (1, ALL_COLUMNS), (2, (1, 2)))
EMPTY_HOME_MESSAGE_KEY_ROWS = ((1, (1, 2, 3)),)
HOME_LIST_LOCATIONS = tuple((row, column) for row in (1, 2) for column in ALL_COLUMNS)
REQUEST_KIND_LABELS = {"question": "pregunta", "permission": "permiso"}


@lru_cache(maxsize=64)
def load_font(font_path, font_size):
    return ImageFont.truetype(font_path, font_size)


def typography_font(typography, bold):
    return load_font(typography.bold_font_path if bold else typography.regular_font_path, typography.font_size)


def label_font_path(text, bold):
    if any(character in SYMBOL_CHARACTERS for character in text):
        return BOLD_FONT_PATH if bold else REGULAR_FONT_PATH
    return NARROW_BOLD_FONT_PATH if bold else NARROW_REGULAR_FONT_PATH


def blend_colors(foreground_color, background_color, foreground_weight):
    return tuple(
        round(foreground_channel * foreground_weight + background_channel * (1 - foreground_weight))
        for foreground_channel, background_channel in zip(foreground_color, background_color)
    )


def banner_background_for(machine_display):
    return blend_colors(machine_display.color, PANEL_BACKGROUND_COLOR, BANNER_MACHINE_TINT_WEIGHT)


def shorten_home_paths(text):
    return HOME_DIRECTORY_PATTERN.sub("~", text)


def truncate_text(text, maximum_characters):
    if len(text) <= maximum_characters:
        return text
    return text[: maximum_characters - 1] + "…"


def compact_json(value, maximum_characters):
    return truncate_text(json.dumps(value, ensure_ascii=False, separators=(", ", ": ")), maximum_characters)


def first_meaningful_line(text):
    for line in text.splitlines():
        if line.strip():
            return line.strip()
    return ""


def simplify_markdown_for_deck(text):
    simplified_lines = []
    for line in text.splitlines():
        stripped_line = line.strip()
        if stripped_line.startswith("```"):
            continue
        stripped_line = MARKDOWN_HEADING_PATTERN.sub("", stripped_line)
        stripped_line = MARKDOWN_BULLET_PATTERN.sub("• ", stripped_line)
        stripped_line = MARKDOWN_LINK_PATTERN.sub(r"\1", stripped_line)
        stripped_line = stripped_line.replace("**", "").replace("`", "")
        simplified_lines.append(stripped_line)
    return "\n".join(simplified_lines)


def describe_elapsed_time(elapsed_seconds):
    if elapsed_seconds < 60:
        return "ahora"
    if elapsed_seconds < 3600:
        return f"{int(elapsed_seconds // 60)} min"
    return f"{int(elapsed_seconds // 3600)} h"


def is_code_like_word(word):
    return any(character in word for character in CODE_LIKE_CHARACTERS)


def split_word_into_fitting_chunks(word, font, maximum_width):
    if len(word) <= MAXIMUM_CHUNK_CHARACTERS and font.getlength(word) <= maximum_width:
        return [word]
    continuation_marker = "" if is_code_like_word(word) else "-"
    chunks = []
    remaining_text = word
    while len(remaining_text) > MAXIMUM_CHUNK_CHARACTERS or font.getlength(remaining_text) > maximum_width:
        cut_length = min(len(remaining_text) - 1, MAXIMUM_CHUNK_CHARACTERS)
        while cut_length > 1 and font.getlength(remaining_text[:cut_length] + continuation_marker) > maximum_width:
            cut_length -= 1
        chunks.append(remaining_text[:cut_length] + continuation_marker)
        remaining_text = remaining_text[cut_length:]
    if remaining_text:
        chunks.append(remaining_text)
    return chunks


def ellipsize_to_width(text, font, maximum_width):
    trimmed_text = text
    while trimmed_text and font.getlength(trimmed_text + "…") > maximum_width:
        trimmed_text = trimmed_text[:-1]
    return trimmed_text.rstrip() + "…"


@dataclass(frozen=True)
class TextParagraph:
    text: str
    color: tuple
    bold: bool = False
    starts_new_key: bool = False


@dataclass(frozen=True)
class WordToken:
    text: str
    color: tuple
    bold: bool
    starts_new_line: bool
    starts_new_key: bool


@dataclass
class PlacedTextLine:
    line_index_in_key: int
    text: str
    color: tuple
    bold: bool


@dataclass
class PanelLayout:
    lines_by_key: dict
    next_token_index: int
    overflowed: bool


@lru_cache(maxsize=64)
def tokenize_paragraphs(paragraphs, typography):
    maximum_width = KEY_PIXEL_SIZE - 2 * TEXT_HORIZONTAL_PADDING
    tokens = []
    for paragraph in paragraphs:
        font = typography_font(typography, paragraph.bold)
        paragraph_has_tokens = False
        for line_text in paragraph.text.split("\n"):
            line_has_tokens = False
            for word in line_text.split():
                for chunk in split_word_into_fitting_chunks(word, font, maximum_width):
                    tokens.append(
                        WordToken(
                            text=chunk,
                            color=paragraph.color,
                            bold=paragraph.bold,
                            starts_new_line=not line_has_tokens,
                            starts_new_key=paragraph.starts_new_key and not paragraph_has_tokens,
                        )
                    )
                    line_has_tokens = True
                    paragraph_has_tokens = True
    return tuple(tokens)


class KeyByKeyTextComposer:
    def __init__(self, key_rows, typography):
        self.typography = typography
        self.key_sequence = [(row, column) for row, columns in key_rows for column in columns]
        self.key_position = 0
        self.line_index = 0
        self.line_words = []
        self.line_color = BODY_TEXT_COLOR
        self.line_bold = False
        self.lines_by_key = {}
        self.placed_lines_in_reading_order = []
        self.maximum_line_width = KEY_PIXEL_SIZE - 2 * TEXT_HORIZONTAL_PADDING

    def has_free_line(self):
        return self.key_position < len(self.key_sequence)

    def current_key_has_content(self):
        return self.line_index > 0 or bool(self.line_words)

    def commit_line(self):
        if not self.line_words:
            return
        placed_line = PlacedTextLine(self.line_index, " ".join(self.line_words), self.line_color, self.line_bold)
        self.lines_by_key.setdefault(self.key_sequence[self.key_position], []).append(placed_line)
        self.placed_lines_in_reading_order.append(placed_line)
        self.line_words = []

    def move_to_next_key(self):
        self.commit_line()
        self.key_position += 1
        self.line_index = 0

    def move_to_next_line(self):
        self.commit_line()
        self.line_index += 1
        if self.line_index >= self.typography.lines_per_key:
            self.key_position += 1
            self.line_index = 0

    def line_accepts(self, token):
        if not self.line_words:
            return True
        if self.line_color != token.color or self.line_bold != token.bold:
            return False
        candidate_text = " ".join(self.line_words + [token.text])
        return typography_font(self.typography, token.bold).getlength(candidate_text) <= self.maximum_line_width

    def place_token(self, token):
        if not self.has_free_line():
            return False
        if token.starts_new_key and self.current_key_has_content():
            self.move_to_next_key()
        elif token.starts_new_line and self.line_words:
            self.move_to_next_line()
        while self.has_free_line():
            if self.line_accepts(token):
                self.line_words.append(token.text)
                self.line_color = token.color
                self.line_bold = token.bold
                return True
            self.move_to_next_line()
        return False

    def finish(self, append_ellipsis):
        if self.has_free_line():
            self.commit_line()
        if append_ellipsis and self.placed_lines_in_reading_order:
            last_line = self.placed_lines_in_reading_order[-1]
            font = typography_font(self.typography, last_line.bold)
            last_line.text = ellipsize_to_width(last_line.text, font, self.maximum_line_width)


def compose_text_panel(tokens, start_token_index, key_rows, typography, ellipsize_on_overflow):
    composer = KeyByKeyTextComposer(key_rows, typography)
    token_index = start_token_index
    while token_index < len(tokens):
        if not composer.place_token(tokens[token_index]):
            break
        token_index += 1
    overflowed = token_index < len(tokens)
    composer.finish(overflowed and ellipsize_on_overflow)
    return PanelLayout(composer.lines_by_key, token_index, overflowed)


@lru_cache(maxsize=32)
def paginate_text_panel(tokens, key_rows, typography):
    page_start_indexes = [0]
    while len(page_start_indexes) < MAXIMUM_READING_PAGES:
        layout = compose_text_panel(tokens, page_start_indexes[-1], key_rows, typography, False)
        if not layout.overflowed or layout.next_token_index <= page_start_indexes[-1]:
            break
        page_start_indexes.append(layout.next_token_index)
    return tuple(page_start_indexes)


def render_text_panel_key(placed_lines, typography, background_color):
    image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), background_color)
    drawing = ImageDraw.Draw(image)
    text_block_height = typography.lines_per_key * typography.line_height
    top_offset = (KEY_PIXEL_SIZE - text_block_height) // 2
    for placed_line in placed_lines:
        drawing.text(
            (TEXT_HORIZONTAL_PADDING, top_offset + placed_line.line_index_in_key * typography.line_height),
            placed_line.text,
            font=typography_font(typography, placed_line.bold),
            fill=placed_line.color,
        )
    return image


def render_text_panel(paragraphs, key_rows, background_color, start_token_index=0, ellipsize=True):
    tokens = tokenize_paragraphs(tuple(paragraphs), PANEL_TYPOGRAPHY)
    layout = compose_text_panel(tokens, start_token_index, key_rows, PANEL_TYPOGRAPHY, ellipsize)
    key_images = {}
    for row, columns in key_rows:
        for column in columns:
            key_images[(row, column)] = render_text_panel_key(
                layout.lines_by_key.get((row, column), []), PANEL_TYPOGRAPHY, background_color
            )
    return key_images


def wrap_text_to_width(text, font, maximum_width, allow_word_splitting):
    wrapped_lines = []
    for raw_line in text.split("\n"):
        current_words = []
        for word in raw_line.split():
            if not allow_word_splitting and font.getlength(word) > maximum_width:
                return None
            for chunk in split_word_into_fitting_chunks(word, font, maximum_width):
                candidate_line = " ".join(current_words + [chunk])
                if current_words and font.getlength(candidate_line) > maximum_width:
                    wrapped_lines.append(" ".join(current_words))
                    current_words = [chunk]
                else:
                    current_words.append(chunk)
        if current_words:
            wrapped_lines.append(" ".join(current_words))
    return wrapped_lines


@dataclass(frozen=True)
class LabelKeyDesign:
    primary_text: str
    background_color: tuple
    primary_color: tuple = BODY_TEXT_COLOR
    caption_text: str = ""
    caption_color: tuple = BODY_TEXT_COLOR
    footer_text: str = ""
    footer_color: tuple = BODY_TEXT_COLOR
    top_strip_color: tuple = None
    maximum_font_size: int = 16
    minimum_font_size: int = 10


def draw_centered_single_line(drawing, text, font, vertical_position, color):
    available_width = KEY_PIXEL_SIZE - 2 * LABEL_HORIZONTAL_PADDING
    fitted_text = text if font.getlength(text) <= available_width else ellipsize_to_width(text, font, available_width)
    horizontal_position = (KEY_PIXEL_SIZE - font.getlength(fitted_text)) / 2
    drawing.text((horizontal_position, vertical_position), fitted_text, font=font, fill=color)


def choose_primary_text_layout(design, available_width, available_height):
    primary_font_path = label_font_path(design.primary_text, True)
    for allow_word_splitting in (False, True):
        for font_size in range(design.maximum_font_size, design.minimum_font_size - 1, -1):
            font = load_font(primary_font_path, font_size)
            line_height = font_size + 2
            wrapped_lines = wrap_text_to_width(design.primary_text, font, available_width, allow_word_splitting)
            if wrapped_lines is not None and len(wrapped_lines) * line_height <= available_height:
                return font, line_height, wrapped_lines
    font = load_font(primary_font_path, design.minimum_font_size)
    line_height = design.minimum_font_size + 2
    wrapped_lines = wrap_text_to_width(design.primary_text, font, available_width, True)
    maximum_line_count = max(1, available_height // line_height)
    if len(wrapped_lines) > maximum_line_count:
        wrapped_lines = wrapped_lines[:maximum_line_count]
        wrapped_lines[-1] = ellipsize_to_width(wrapped_lines[-1], font, available_width)
    return font, line_height, wrapped_lines


@lru_cache(maxsize=512)
def render_label_key(design):
    image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), design.background_color)
    drawing = ImageDraw.Draw(image)
    top_reserved = LABEL_EDGE_MARGIN
    bottom_reserved = LABEL_EDGE_MARGIN
    if design.top_strip_color is not None:
        drawing.rectangle([0, 0, KEY_PIXEL_SIZE - 1, LABEL_STRIP_HEIGHT - 1], fill=design.top_strip_color)
        top_reserved = LABEL_STRIP_HEIGHT + 2
    if design.caption_text:
        caption_font = load_font(label_font_path(design.caption_text, True), LABEL_CAPTION_FONT_SIZE)
        draw_centered_single_line(drawing, design.caption_text, caption_font, top_reserved, design.caption_color)
        top_reserved += LABEL_CAPTION_FONT_SIZE + 3
    if design.footer_text:
        footer_font = load_font(label_font_path(design.footer_text, False), LABEL_CAPTION_FONT_SIZE)
        footer_vertical_position = KEY_PIXEL_SIZE - LABEL_EDGE_MARGIN - LABEL_CAPTION_FONT_SIZE - 1
        draw_centered_single_line(drawing, design.footer_text, footer_font, footer_vertical_position, design.footer_color)
        bottom_reserved += LABEL_CAPTION_FONT_SIZE + 3
    if not design.primary_text:
        return image
    available_width = KEY_PIXEL_SIZE - 2 * LABEL_HORIZONTAL_PADDING
    available_height = KEY_PIXEL_SIZE - top_reserved - bottom_reserved
    font, line_height, wrapped_lines = choose_primary_text_layout(design, available_width, available_height)
    first_line_position = top_reserved + (available_height - len(wrapped_lines) * line_height) // 2
    for line_position, line_text in enumerate(wrapped_lines):
        horizontal_position = (KEY_PIXEL_SIZE - font.getlength(line_text)) / 2
        drawing.text(
            (horizontal_position, first_line_position + line_position * line_height),
            line_text,
            font=font,
            fill=design.primary_color,
        )
    return image


LINE_ICON_SHAPES = {
    "home": (
        ("polygon", ((3, 10), (12, 3), (21, 10), (21, 21), (3, 21))),
        ("polyline", ((9.5, 21), (9.5, 14.5), (14.5, 14.5), (14.5, 21))),
    ),
    "back": (("polyline", ((19, 12), (5, 12))), ("polyline", ((12, 19), (5, 12), (12, 5)))),
    "exit": (
        ("polyline", ((9, 21), (4, 21), (4, 3), (9, 3))),
        ("polyline", ((16, 17), (21, 12), (16, 7))),
        ("polyline", ((21, 12), (9, 12))),
    ),
    "full_text": (
        ("polyline", ((4, 6), (20, 6))),
        ("polyline", ((4, 12), (20, 12))),
        ("polyline", ((4, 18), (14, 18))),
    ),
    "terminal": (("polyline", ((4, 17), (10, 11), (4, 5))), ("polyline", ((12, 19), (20, 19)))),
    "check": (("polyline", ((20, 6), (9, 17), (4, 12))),),
    "check_double": (("polyline", ((18, 6), (7, 17), (2, 12))), ("polyline", ((22, 10), (14.5, 17.5), (13, 16)))),
    "cross": (("polyline", ((18, 6), (6, 18))), ("polyline", ((6, 6), (18, 18)))),
    "chevron_right": (("polyline", ((9, 18), (15, 12), (9, 6))),),
    "chevron_down": (("polyline", ((6, 9), (12, 15), (18, 9))),),
    "restart": (
        ("arc", (12, 12, 9, 180, -135)),
        ("polyline", ((5.64, 5.64), (3, 8))),
        ("polyline", ((3, 3), (3, 8), (8, 8))),
    ),
    "dismiss": (("circle", (12, 12, 10)), ("polyline", ((15, 9), (9, 15))), ("polyline", ((9, 9), (15, 15)))),
    "send": (("polygon", ((22, 2), (15, 22), (11, 13), (2, 9))), ("polyline", ((22, 2), (11, 13)))),
    "skip_forward": (("polygon", ((5, 4), (15, 12), (5, 20))), ("polyline", ((19, 5), (19, 19)))),
}


def arc_grid_points(center_x, center_y, radius, start_degrees, end_degrees):
    sweep_degrees = end_degrees - start_degrees
    angles = (
        math.radians(start_degrees + sweep_degrees * step / ICON_ARC_SEGMENT_COUNT)
        for step in range(ICON_ARC_SEGMENT_COUNT + 1)
    )
    return tuple((center_x + radius * math.cos(angle), center_y + radius * math.sin(angle)) for angle in angles)


def draw_round_cap(drawing, point, stroke_width, color):
    cap_radius = stroke_width / 2
    drawing.ellipse(
        [point[0] - cap_radius, point[1] - cap_radius, point[0] + cap_radius, point[1] + cap_radius], fill=color
    )


def draw_stroked_path(drawing, canvas_points, stroke_width, color, closed):
    path_points = list(canvas_points) + ([canvas_points[0], canvas_points[1]] if closed else [])
    drawing.line(path_points, fill=color, width=round(stroke_width), joint="curve")
    for corner_point in canvas_points if closed else (canvas_points[0], canvas_points[-1]):
        draw_round_cap(drawing, corner_point, stroke_width, color)


@lru_cache(maxsize=64)
def render_line_icon(icon_name, icon_size, color):
    canvas_size = icon_size * ICON_SUPERSAMPLING_FACTOR
    grid_scale = canvas_size / ICON_GRID_SIZE
    stroke_width = ICON_STROKE_WIDTH_IN_GRID * grid_scale
    icon_image = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    drawing = ImageDraw.Draw(icon_image)
    for shape_kind, shape_geometry in LINE_ICON_SHAPES[icon_name]:
        if shape_kind == "circle":
            center_x, center_y, radius = (value * grid_scale for value in shape_geometry)
            drawing.ellipse(
                [center_x - radius, center_y - radius, center_x + radius, center_y + radius],
                outline=color,
                width=round(stroke_width),
            )
            continue
        grid_points = arc_grid_points(*shape_geometry) if shape_kind == "arc" else shape_geometry
        canvas_points = [(grid_x * grid_scale, grid_y * grid_scale) for grid_x, grid_y in grid_points]
        draw_stroked_path(drawing, canvas_points, stroke_width, color, shape_kind == "polygon")
    return icon_image.resize((icon_size, icon_size), Image.LANCZOS)


@dataclass(frozen=True)
class IconKeyDesign:
    icon_name: str
    label_text: str
    background_color: tuple
    icon_color: tuple = ICON_COLOR
    label_color: tuple = NAVIGATION_LABEL_COLOR
    caption_text: str = ""
    caption_color: tuple = MUTED_TEXT_COLOR


@lru_cache(maxsize=128)
def render_icon_key(design):
    image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), design.background_color)
    drawing = ImageDraw.Draw(image)
    icon_size, icon_top = ICON_KEY_ICON_SIZE, ICON_KEY_ICON_TOP
    if design.caption_text:
        caption_font = load_font(label_font_path(design.caption_text, True), ICON_KEY_CAPTION_FONT_SIZE)
        draw_centered_single_line(drawing, design.caption_text, caption_font, ICON_KEY_CAPTION_TOP, design.caption_color)
        icon_size, icon_top = ICON_KEY_COMPACT_ICON_SIZE, ICON_KEY_COMPACT_ICON_TOP
    icon_image = render_line_icon(design.icon_name, icon_size, design.icon_color)
    image.paste(icon_image, ((KEY_PIXEL_SIZE - icon_size) // 2, icon_top), icon_image)
    label_font = load_font(NARROW_BOLD_FONT_PATH, ICON_KEY_LABEL_FONT_SIZE)
    draw_centered_single_line(drawing, design.label_text, label_font, ICON_KEY_LABEL_TOP, design.label_color)
    return image


def navigation_key_image(icon_name, label, caption="", background_color=NAVIGATION_COLOR):
    return render_icon_key(
        IconKeyDesign(icon_name=icon_name, label_text=label, background_color=background_color, caption_text=caption)
    )


def accent_key_image(icon_name, label, background_color, caption=""):
    return render_icon_key(
        IconKeyDesign(
            icon_name=icon_name,
            label_text=label,
            background_color=background_color,
            label_color=ACCENT_LABEL_COLOR,
            caption_text=caption,
            caption_color=ACCENT_CAPTION_COLOR,
        )
    )


def empty_key_image():
    return render_label_key(LabelKeyDesign(primary_text="", background_color=EMPTY_KEY_COLOR))


def join_non_empty_lines(*line_texts):
    return "\n".join(line_text for line_text in line_texts if line_text)


def render_identity_key(machine, project, session_label, footer_text):
    display = machine_display_for(machine)
    return render_label_key(
        LabelKeyDesign(
            primary_text=join_non_empty_lines(project, session_label),
            background_color=display.color,
            caption_text=display.label,
            footer_text=footer_text,
            maximum_font_size=15,
        )
    )


def option_key_design(option_index, label, multi_select, chosen):
    recommended = RECOMMENDED_SUFFIX_PATTERN.search(label) is not None
    clean_label = RECOMMENDED_SUFFIX_PATTERN.sub("", label).strip() or label
    caption_parts = []
    if multi_select:
        caption_parts.append("☑" if chosen else "☐")
    caption_parts.append(str(option_index + 1))
    if recommended:
        caption_parts.append("★")
    return LabelKeyDesign(
        primary_text=clean_label,
        background_color=OPTION_CHOSEN_COLOR if chosen else OPTION_BACKGROUND_COLOR,
        caption_text=" ".join(caption_parts),
        caption_color=BODY_TEXT_COLOR if chosen else CLAUDE_ACCENT_COLOR,
        top_strip_color=RECOMMENDED_STRIP_COLOR if recommended else None,
        maximum_font_size=16,
    )


def offset_point(origin_x, origin_y, direction, distance):
    return (origin_x + direction[0] * distance, origin_y + direction[1] * distance)


@lru_cache(maxsize=4)
def render_claude_spark_icon(diameter, color):
    canvas_size = diameter * ICON_SUPERSAMPLING_FACTOR
    icon_image = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    drawing = ImageDraw.Draw(icon_image)
    center = canvas_size / 2
    base_half_width = canvas_size * SPARK_RAY_BASE_WIDTH_RATIO / 2
    tip_half_width = canvas_size * SPARK_RAY_TIP_WIDTH_RATIO / 2
    for ray_position, length_ratio in enumerate(SPARK_RAY_LENGTH_RATIOS):
        angle = SPARK_ROTATION_RADIANS + 2 * math.pi * ray_position / len(SPARK_RAY_LENGTH_RATIOS)
        direction = (math.cos(angle), math.sin(angle))
        perpendicular = (-direction[1], direction[0])
        tip_x, tip_y = offset_point(center, center, direction, (center - tip_half_width) * length_ratio)
        drawing.polygon(
            [
                offset_point(center, center, perpendicular, base_half_width),
                offset_point(tip_x, tip_y, perpendicular, tip_half_width),
                offset_point(tip_x, tip_y, perpendicular, -tip_half_width),
                offset_point(center, center, perpendicular, -base_half_width),
            ],
            fill=color,
        )
        drawing.ellipse(
            [tip_x - tip_half_width, tip_y - tip_half_width, tip_x + tip_half_width, tip_y + tip_half_width], fill=color
        )
    hub_radius = base_half_width * 1.6
    drawing.ellipse([center - hub_radius, center - hub_radius, center + hub_radius, center + hub_radius], fill=color)
    return icon_image.resize((diameter, diameter), Image.LANCZOS)


def draw_count_badge(drawing, count, badge_color, text_color):
    badge_center_x = KEY_PIXEL_SIZE - MAIN_KEY_BADGE_RADIUS - 2
    badge_center_y = MAIN_KEY_BADGE_RADIUS + 2
    drawing.ellipse(
        [
            badge_center_x - MAIN_KEY_BADGE_RADIUS,
            badge_center_y - MAIN_KEY_BADGE_RADIUS,
            badge_center_x + MAIN_KEY_BADGE_RADIUS,
            badge_center_y + MAIN_KEY_BADGE_RADIUS,
        ],
        fill=badge_color,
        outline=(16, 16, 16),
        width=2,
    )
    badge_text = str(count) if count < 10 else "9+"
    badge_font = load_font(BOLD_FONT_PATH, 14 if count < 10 else 11)
    drawing.text((badge_center_x, badge_center_y), badge_text, font=badge_font, fill=text_color, anchor="mm")


@lru_cache(maxsize=64)
def render_main_page_claude_key(pending_count, waiting_count, highlight_on):
    if pending_count and highlight_on:
        background_color = MAIN_KEY_PENDING_BACKGROUND_COLOR
    elif waiting_count and not pending_count:
        background_color = MAIN_KEY_WAITING_BACKGROUND_COLOR
    else:
        background_color = IDLE_MAIN_KEY_COLOR
    image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), background_color)
    drawing = ImageDraw.Draw(image)
    if pending_count and highlight_on:
        drawing.rectangle(
            [0, 0, KEY_PIXEL_SIZE - 1, KEY_PIXEL_SIZE - 1], outline=PENDING_ALERT_COLOR, width=MAIN_KEY_BORDER_WIDTH
        )
    if not pending_count and not waiting_count:
        idle_icon = render_claude_spark_icon(MAIN_KEY_IDLE_ICON_DIAMETER, CLAUDE_ACCENT_COLOR)
        idle_icon_offset = (KEY_PIXEL_SIZE - MAIN_KEY_IDLE_ICON_DIAMETER) // 2
        image.paste(idle_icon, (idle_icon_offset, idle_icon_offset), idle_icon)
        return image
    spark_icon = render_claude_spark_icon(MAIN_KEY_ICON_DIAMETER, CLAUDE_ACCENT_COLOR)
    image.paste(spark_icon, ((KEY_PIXEL_SIZE - MAIN_KEY_ICON_DIAMETER) // 2, MAIN_KEY_ICON_TOP), spark_icon)
    if pending_count:
        label_text, label_color = "RESPONDER", BODY_TEXT_COLOR
        draw_count_badge(drawing, pending_count, PENDING_ALERT_COLOR, BODY_TEXT_COLOR)
    else:
        label_text, label_color = "ESPERANDO", WAITING_ALERT_COLOR
        draw_count_badge(drawing, waiting_count, WAITING_ALERT_COLOR, DARK_TEXT_COLOR)
    label_font = load_font(NARROW_BOLD_FONT_PATH, MAIN_KEY_LABEL_FONT_SIZE)
    label_vertical_position = KEY_PIXEL_SIZE - MAIN_KEY_LABEL_FONT_SIZE - 9
    draw_centered_single_line(drawing, label_text, label_font, label_vertical_position, label_color)
    return image


def encode_key_image_as_data_url(image):
    palette_image = image.convert("P", palette=Image.Palette.ADAPTIVE, colors=PNG_PALETTE_COLOR_COUNT)
    png_buffer = io.BytesIO()
    palette_image.save(png_buffer, format="PNG", optimize=True)
    return "data:image/png;base64," + base64.b64encode(png_buffer.getvalue()).decode("ascii")


def render_deck_preview_image(frame):
    deck_width = DECK_COLUMN_COUNT * KEY_PIXEL_SIZE + (DECK_COLUMN_COUNT - 1) * PREVIEW_KEY_GAP
    deck_height = DECK_ROW_COUNT * KEY_PIXEL_SIZE + (DECK_ROW_COUNT - 1) * PREVIEW_KEY_GAP
    preview_width = deck_width + KEY_PIXEL_SIZE + 4 * PREVIEW_MARGIN
    preview_height = deck_height + 2 * PREVIEW_MARGIN
    preview_image = Image.new("RGB", (preview_width, preview_height), PREVIEW_BACKGROUND_COLOR)
    for (row, column), key_image in frame.key_images.items():
        horizontal_position = PREVIEW_MARGIN + column * (KEY_PIXEL_SIZE + PREVIEW_KEY_GAP)
        vertical_position = PREVIEW_MARGIN + row * (KEY_PIXEL_SIZE + PREVIEW_KEY_GAP)
        preview_image.paste(key_image, (horizontal_position, vertical_position))
    preview_image.paste(frame.main_page_key_image, (deck_width + 3 * PREVIEW_MARGIN, PREVIEW_MARGIN))
    return preview_image


@dataclass(frozen=True)
class PermissionDescription:
    title: str
    summary: str
    detail: str


def string_field(tool_input, field_name):
    value = tool_input.get(field_name)
    return value if isinstance(value, str) else ""


def describe_permission_request(tool_name, tool_input):
    if tool_name == "Bash":
        command = string_field(tool_input, "command")
        description = string_field(tool_input, "description")
        detail = command + (f"\n({description})" if description else "")
        return PermissionDescription("Comando", first_meaningful_line(command), detail)
    if tool_name in ("Edit", "MultiEdit"):
        file_path = shorten_home_paths(string_field(tool_input, "file_path"))
        old_text = truncate_text(string_field(tool_input, "old_string"), 600)
        new_text = truncate_text(string_field(tool_input, "new_string"), 600)
        detail = f"{file_path}\nCambia:\n{old_text}\nPor:\n{new_text}" if old_text or new_text else file_path
        return PermissionDescription("Editar", file_path, detail)
    if tool_name == "Write":
        file_path = shorten_home_paths(string_field(tool_input, "file_path"))
        content = truncate_text(string_field(tool_input, "content"), 1200)
        return PermissionDescription("Escribir", file_path, f"{file_path}\n{content}")
    if tool_name == "NotebookEdit":
        notebook_path = shorten_home_paths(string_field(tool_input, "notebook_path"))
        return PermissionDescription("Notebook", notebook_path, notebook_path)
    if tool_name in ("Read", "Glob", "Grep"):
        target = string_field(tool_input, "file_path") or string_field(tool_input, "pattern") or string_field(tool_input, "path")
        return PermissionDescription("Leer", shorten_home_paths(target), compact_json(tool_input, MAXIMUM_DETAIL_CHARACTERS))
    if tool_name == "WebFetch":
        url = string_field(tool_input, "url")
        return PermissionDescription("Abrir web", url, f"{url}\n{string_field(tool_input, 'prompt')}")
    if tool_name == "WebSearch":
        query = string_field(tool_input, "query")
        return PermissionDescription("Buscar en web", query, query)
    if tool_name == "ExitPlanMode":
        plan = simplify_markdown_for_deck(string_field(tool_input, "plan"))
        return PermissionDescription("Aprobar plan", first_meaningful_line(plan), plan)
    if tool_name.startswith("mcp__"):
        name_parts = tool_name.split("__")
        server_name = name_parts[1] if len(name_parts) > 1 else "mcp"
        mcp_tool_name = name_parts[-1]
        return PermissionDescription(
            f"MCP {server_name}", mcp_tool_name, f"{mcp_tool_name}\n{compact_json(tool_input, MAXIMUM_DETAIL_CHARACTERS)}"
        )
    return PermissionDescription(tool_name, compact_json(tool_input, 200), compact_json(tool_input, MAXIMUM_DETAIL_CHARACTERS))


def describe_permission_suggestions(permission_suggestions):
    descriptions = []
    for suggestion in permission_suggestions:
        if not isinstance(suggestion, dict):
            continue
        suggestion_type = suggestion.get("type")
        if suggestion_type in ("addRules", "replaceRules"):
            for rule in suggestion.get("rules") or []:
                if not isinstance(rule, dict):
                    continue
                tool_name = str(rule.get("toolName") or "?")
                rule_content = rule.get("ruleContent")
                descriptions.append(shorten_home_paths(f"{tool_name}({rule_content})" if rule_content else tool_name))
        elif suggestion_type == "addDirectories":
            descriptions.extend(
                f"Carpeta {shorten_home_paths(str(directory))}" for directory in suggestion.get("directories") or []
            )
        elif suggestion_type == "setMode":
            descriptions.append(f"Modo {suggestion.get('mode')}")
        else:
            descriptions.append(compact_json(suggestion, 200))
    return descriptions


def normalize_machine_name(raw_machine):
    if isinstance(raw_machine, str) and MACHINE_NAME_PATTERN.fullmatch(raw_machine):
        return raw_machine
    return None


def normalize_project_label(raw_project):
    project = raw_project if isinstance(raw_project, str) and raw_project.strip() else "?"
    return truncate_text(project.strip(), MAXIMUM_PROJECT_CHARACTERS)


def normalize_optional_label(raw_label, maximum_characters):
    if not isinstance(raw_label, str):
        return ""
    return truncate_text(" ".join(raw_label.split()), maximum_characters)


def normalize_question_payload(raw_payload):
    questions = raw_payload.get("questions") if isinstance(raw_payload, dict) else None
    if not isinstance(questions, list) or not 0 < len(questions) <= MAXIMUM_QUESTIONS_PER_REQUEST:
        return None
    normalized_questions = []
    for raw_question in questions:
        if not isinstance(raw_question, dict):
            return None
        question_text = raw_question.get("question")
        options = raw_question.get("options")
        if not isinstance(question_text, str) or not isinstance(options, list):
            return None
        if not 0 < len(options) <= MAXIMUM_OPTIONS_PER_QUESTION:
            return None
        normalized_options = []
        for raw_option in options:
            if not isinstance(raw_option, dict) or not isinstance(raw_option.get("label"), str):
                return None
            normalized_options.append(
                {"label": raw_option["label"], "description": str(raw_option.get("description") or "")}
            )
        normalized_questions.append(
            {
                "question": question_text,
                "header": str(raw_question.get("header") or ""),
                "multiSelect": bool(raw_question.get("multiSelect")),
                "options": normalized_options,
            }
        )
    return {"questions": normalized_questions}


def normalize_permission_payload(raw_payload):
    if not isinstance(raw_payload, dict) or not isinstance(raw_payload.get("tool_name"), str):
        return None
    tool_input = raw_payload.get("tool_input")
    permission_suggestions = raw_payload.get("permission_suggestions")
    return {
        "tool_name": raw_payload["tool_name"],
        "tool_input": tool_input if isinstance(tool_input, dict) else {},
        "permission_suggestions": permission_suggestions if isinstance(permission_suggestions, list) else [],
    }


@dataclass
class PendingRequest:
    request_id: str
    machine: str
    session_id: str
    project: str
    session_label: str
    agent_label: str
    kind: str
    payload: dict
    created_at: float
    last_polled_at: float
    status: str = "pending"
    answer: dict = None
    finished_at: float = 0.0
    current_question_index: int = 0
    question_answers: dict = field(default_factory=dict)
    multi_select_choices: set = field(default_factory=set)


@dataclass
class WaitingSession:
    machine: str
    session_id: str
    project: str
    session_label: str
    last_message: str
    waiting_since: float


@dataclass
class ReadingContext:
    source_kind: str
    source_key: object
    page_index: int
    return_screen: str


@dataclass
class DeckFrame:
    key_images: dict
    key_actions: dict
    main_page_key_image: Image.Image
    view_token: int
    state_version: int


class InvalidRequestBody(Exception):
    pass


DECISION_PRESENTATION = {
    "allow": ("Vas a PERMITIR", "PERMITIR", ALLOW_COLOR, ALLOW_TEXT_COLOR),
    "allow_always": ("Vas a PERMITIR SIEMPRE", "SIEMPRE", ALLOW_ALWAYS_COLOR, ALLOW_ALWAYS_TEXT_COLOR),
    "deny": ("Vas a RECHAZAR", "RECHAZAR", REJECT_COLOR, REJECT_TEXT_COLOR),
}


class ClaudeDeckCoordinator:
    def __init__(self, state_file_path):
        self.state_file_path = state_file_path
        self.condition = threading.Condition(threading.RLock())
        self.render_wakeup_event = threading.Event()
        self.requests_by_id = {}
        self.queued_request_ids = []
        self.waiting_sessions_by_key = {}
        self.routing_enabled_by_machine, self.auto_open_enabled = self.load_preferences()
        self.screen = "home"
        self.view_token = 0
        self.state_version = 0
        self.focused_request_id = None
        self.reading_context = None
        self.confirm_choice = None
        self.sent_screen_style = "answered"
        self.sent_screen_machine = ""
        self.sent_screen_visible_until = 0.0
        self.pending_page_jumps = []
        self.displayed_key_actions = {}
        self.displayed_view_token = -1
        self.last_displayed_frame = None
        self.companion_is_reachable = True
        self.last_time_label_refresh_at = time.monotonic()
        self.last_user_press_at = 0.0
        self.home_list_page_index = 0
        self.press_handlers = {
            "open_request_reading": self.press_open_request_reading,
            "focus_request_by_id": self.press_focus_request_by_id,
            "home_next_list_page": self.press_home_next_list_page,
            "choose_option": self.press_choose_option,
            "submit_multi_select": self.press_submit_multi_select,
            "choose_permission": self.press_choose_permission,
            "confirm_send": self.press_confirm_send,
            "confirm_back": self.press_confirm_back,
            "reading_next_page": self.press_reading_next_page,
            "reading_back": self.press_reading_back,
            "leave_deck": self.press_leave_deck,
            "cycle_request": self.press_cycle_request,
            "show_home": self.press_show_home,
            "focus_first_request": self.press_focus_first_request,
            "release_to_terminal": self.press_release_to_terminal,
            "toggle_machine_routing": self.press_toggle_machine_routing,
            "toggle_auto_open": self.press_toggle_auto_open,
            "open_waiting_reading": self.press_open_waiting_reading,
            "dismiss_waiting_session": self.press_dismiss_waiting_session,
        }

    def load_preferences(self):
        routing_enabled_by_machine = {machine: True for machine in KNOWN_MACHINE_DISPLAYS}
        auto_open_enabled = True
        try:
            stored_state = json.loads(self.state_file_path.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            return routing_enabled_by_machine, auto_open_enabled
        stored_routing = stored_state.get("routing_enabled_by_machine")
        if isinstance(stored_routing, dict):
            for machine, enabled in stored_routing.items():
                if normalize_machine_name(machine) and isinstance(enabled, bool):
                    routing_enabled_by_machine[machine] = enabled
        if isinstance(stored_state.get("auto_open_enabled"), bool):
            auto_open_enabled = stored_state["auto_open_enabled"]
        return routing_enabled_by_machine, auto_open_enabled

    def save_preferences(self):
        temporary_state_path = self.state_file_path.with_suffix(".json.partial")
        stored_state = {
            "routing_enabled_by_machine": self.routing_enabled_by_machine,
            "auto_open_enabled": self.auto_open_enabled,
        }
        try:
            temporary_state_path.write_text(json.dumps(stored_state), encoding="utf-8")
            temporary_state_path.replace(self.state_file_path)
        except OSError as save_error:
            log_event(f"could not save preferences: {save_error}")

    def mark_state_changed(self):
        self.state_version += 1
        self.condition.notify_all()
        self.render_wakeup_event.set()

    def transition_to_screen(self, screen):
        self.screen = screen
        self.view_token += 1
        self.mark_state_changed()

    def is_showing_request_flow(self):
        if self.screen in ("request", "confirm"):
            return True
        return (
            self.screen == "reading"
            and self.reading_context is not None
            and self.reading_context.source_kind == "request"
        )

    def focused_request(self):
        if self.focused_request_id is None:
            return None
        request = self.requests_by_id.get(self.focused_request_id)
        if request is None or request.status != "pending":
            return None
        return request

    def current_question(self, request):
        return request.payload["questions"][request.current_question_index]

    def focus_request(self, request_id):
        self.focused_request_id = request_id
        self.confirm_choice = None
        self.reading_context = None
        self.transition_to_screen("request")

    def focus_next_request_or_return_home(self):
        if self.queued_request_ids:
            self.focus_request(self.queued_request_ids[0])
            return
        self.focused_request_id = None
        self.confirm_choice = None
        self.reading_context = None
        self.home_list_page_index = 0
        self.transition_to_screen("home")
        self.pending_page_jumps.append("return_from_claude_page")

    def finish_request(self, request, status, answer=None):
        request.status = status
        request.answer = answer
        request.finished_at = time.monotonic()
        if request.request_id in self.queued_request_ids:
            self.queued_request_ids.remove(request.request_id)
        self.condition.notify_all()

    def withdraw_request_from_deck(self, request, status):
        was_focused_in_request_flow = (
            self.focused_request_id == request.request_id and self.is_showing_request_flow()
        )
        self.finish_request(request, status)
        if self.focused_request_id == request.request_id:
            if was_focused_in_request_flow:
                self.focus_next_request_or_return_home()
            else:
                self.focused_request_id = None
        self.mark_state_changed()

    def show_sent_screen(self, request, style):
        self.sent_screen_style = style
        self.sent_screen_machine = request.machine
        self.sent_screen_visible_until = time.monotonic() + SENT_SCREEN_DISPLAY_SECONDS
        self.focused_request_id = None
        self.confirm_choice = None
        self.reading_context = None
        self.transition_to_screen("sent")

    def remove_waiting_session(self, session_key):
        if self.waiting_sessions_by_key.pop(session_key, None) is None:
            return
        reading_this_session = (
            self.screen == "reading"
            and self.reading_context is not None
            and self.reading_context.source_kind == "waiting"
            and self.reading_context.source_key == session_key
        )
        if reading_this_session:
            self.reading_context = None
            self.transition_to_screen("home")
        else:
            self.mark_state_changed()

    def create_request(self, request_body):
        machine = normalize_machine_name(request_body.get("machine"))
        kind = request_body.get("kind")
        session_id = request_body.get("session_id")
        if machine is None or kind not in ("question", "permission") or not isinstance(session_id, str):
            raise InvalidRequestBody("machine, kind and session_id are required")
        if kind == "question":
            payload = normalize_question_payload(request_body.get("payload"))
        else:
            payload = normalize_permission_payload(request_body.get("payload"))
        if payload is None:
            return {"status": "released", "reason": "unsupported_payload"}
        with self.condition:
            if not self.routing_enabled_by_machine.get(machine, True):
                return {"status": "released", "reason": "machine_paused"}
            if not self.companion_is_reachable:
                return {"status": "released", "reason": "companion_unreachable"}
            now = time.monotonic()
            request = PendingRequest(
                request_id=uuid.uuid4().hex,
                machine=machine,
                session_id=session_id,
                project=normalize_project_label(request_body.get("project")),
                session_label=normalize_optional_label(request_body.get("session_label"), MAXIMUM_SESSION_LABEL_CHARACTERS),
                agent_label=normalize_optional_label(request_body.get("agent_label"), MAXIMUM_AGENT_LABEL_CHARACTERS),
                kind=kind,
                payload=payload,
                created_at=now,
                last_polled_at=now,
            )
            self.requests_by_id[request.request_id] = request
            self.queued_request_ids.append(request.request_id)
            self.remove_waiting_session((machine, session_id))
            user_is_browsing_deck = now - self.last_user_press_at < USER_BROWSING_GRACE_SECONDS
            if not self.is_showing_request_flow() and self.screen != "sent" and not user_is_browsing_deck:
                self.focus_request(self.queued_request_ids[0])
            if self.auto_open_enabled:
                self.pending_page_jumps.append("show_claude_page")
            self.mark_state_changed()
            log_event(f"request {request.request_id[:8]} {kind} from {machine}/{request.project}")
            return {"status": "pending", "request_id": request.request_id}

    def wait_for_request(self, request_id, requested_timeout_seconds):
        timeout_seconds = max(0.0, min(requested_timeout_seconds, LONG_POLL_MAXIMUM_SECONDS))
        with self.condition:
            request = self.requests_by_id.get(request_id)
            if request is None:
                return 404, {"status": "unknown"}
            deadline = time.monotonic() + timeout_seconds
            request.last_polled_at = time.monotonic()
            while request.status == "pending":
                remaining_seconds = deadline - time.monotonic()
                if remaining_seconds <= 0:
                    break
                self.condition.wait(remaining_seconds)
            request.last_polled_at = time.monotonic()
            if request.status == "pending":
                return 200, {"status": "pending"}
            self.requests_by_id.pop(request_id, None)
            if request.status == "answered":
                return 200, {"status": "answered", "answer": request.answer}
            return 200, {"status": request.status}

    def cancel_request(self, request_id):
        with self.condition:
            request = self.requests_by_id.pop(request_id, None)
            if request is None:
                return False
            if request.status == "pending":
                self.withdraw_request_from_deck(request, "cancelled")
                log_event(f"request {request_id[:8]} cancelled by {request.machine}")
            return True

    def withdraw_requests_resolved_in_terminal(self, machine, session_id):
        stale_requests = [
            request
            for request in self.requests_by_id.values()
            if request.status == "pending"
            and request.machine == machine
            and request.session_id == session_id
            and not request.agent_label
        ]
        for stale_request in stale_requests:
            self.withdraw_request_from_deck(stale_request, "resolved_in_terminal")
            log_event(f"request {stale_request.request_id[:8]} resolved in terminal by {machine}")

    def mark_session_waiting(self, request_body):
        machine = normalize_machine_name(request_body.get("machine"))
        session_id = request_body.get("session_id")
        if machine is None or not isinstance(session_id, str):
            raise InvalidRequestBody("machine and session_id are required")
        last_message = request_body.get("last_message")
        with self.condition:
            self.withdraw_requests_resolved_in_terminal(machine, session_id)
            self.waiting_sessions_by_key[(machine, session_id)] = WaitingSession(
                machine=machine,
                session_id=session_id,
                project=normalize_project_label(request_body.get("project")),
                session_label=normalize_optional_label(request_body.get("session_label"), MAXIMUM_SESSION_LABEL_CHARACTERS),
                last_message=truncate_text(last_message, MAXIMUM_LAST_MESSAGE_CHARACTERS)
                if isinstance(last_message, str)
                else "",
                waiting_since=time.monotonic(),
            )
            self.mark_state_changed()

    def mark_session_active(self, request_body):
        machine = normalize_machine_name(request_body.get("machine"))
        session_id = request_body.get("session_id")
        if machine is None or not isinstance(session_id, str):
            raise InvalidRequestBody("machine and session_id are required")
        with self.condition:
            self.withdraw_requests_resolved_in_terminal(machine, session_id)
            self.remove_waiting_session((machine, session_id))

    def health_summary(self):
        with self.condition:
            return {
                "ok": True,
                "companion_reachable": self.companion_is_reachable,
                "pending_requests": len(self.queued_request_ids),
                "waiting_sessions": len(self.waiting_sessions_by_key),
                "screen": self.screen,
                "routing_enabled_by_machine": self.routing_enabled_by_machine,
                "auto_open_enabled": self.auto_open_enabled,
            }

    def open_from_main_page(self):
        with self.condition:
            self.last_user_press_at = 0.0
            self.home_list_page_index = 0
            if self.queued_request_ids and not self.is_showing_request_flow():
                self.focus_request(self.queued_request_ids[0])
            elif not self.queued_request_ids and self.screen != "home":
                self.confirm_choice = None
                self.reading_context = None
                self.transition_to_screen("home")
            self.pending_page_jumps.append("opened_from_main_page")
            self.mark_state_changed()

    def handle_key_press(self, row, column):
        with self.condition:
            if self.displayed_view_token != self.view_token:
                return "stale_view"
            action = self.displayed_key_actions.get((row, column))
            if action is None:
                return "no_action"
            self.last_user_press_at = time.monotonic()
            action_name, action_argument = action
            self.press_handlers[action_name](action_argument)
            return action_name

    def press_focus_request_by_id(self, request_id):
        if request_id in self.queued_request_ids:
            self.focus_request(request_id)

    def press_home_next_list_page(self, unused_argument):
        self.home_list_page_index += 1
        self.mark_state_changed()

    def press_open_request_reading(self, unused_argument):
        request = self.focused_request()
        if request is None:
            return
        self.reading_context = ReadingContext("request", request.request_id, 0, "request")
        self.transition_to_screen("reading")

    def press_choose_option(self, option_index):
        request = self.focused_request()
        if request is None or request.kind != "question":
            return
        question = self.current_question(request)
        if option_index >= len(question["options"]):
            return
        if question["multiSelect"]:
            if option_index in request.multi_select_choices:
                request.multi_select_choices.remove(option_index)
            else:
                request.multi_select_choices.add(option_index)
            self.mark_state_changed()
            return
        self.confirm_choice = {"kind": "option", "index": option_index}
        self.transition_to_screen("confirm")

    def press_submit_multi_select(self, unused_argument):
        request = self.focused_request()
        if request is None or not request.multi_select_choices:
            return
        self.confirm_choice = {"kind": "multi"}
        self.transition_to_screen("confirm")

    def press_choose_permission(self, decision):
        request = self.focused_request()
        if request is None or request.kind != "permission":
            return
        if decision == "allow_always" and not request.payload["permission_suggestions"]:
            return
        self.confirm_choice = {"kind": "permission", "decision": decision}
        self.transition_to_screen("confirm")

    def press_confirm_send(self, unused_argument):
        request = self.focused_request()
        choice = self.confirm_choice
        if request is None or choice is None or self.screen != "confirm":
            return
        if choice["kind"] == "permission":
            self.finish_request(request, "answered", {"type": "permission", "decision": choice["decision"]})
            log_event(f"request {request.request_id[:8]} answered {choice['decision']}")
            self.show_sent_screen(request, "answered")
            return
        question = self.current_question(request)
        if choice["kind"] == "option":
            answer_label = question["options"][choice["index"]]["label"]
        else:
            answer_label = ", ".join(
                question["options"][option_index]["label"] for option_index in sorted(request.multi_select_choices)
            )
        request.question_answers[question["question"]] = answer_label
        if request.current_question_index + 1 < len(request.payload["questions"]):
            request.current_question_index += 1
            request.multi_select_choices = set()
            self.confirm_choice = None
            self.transition_to_screen("request")
            return
        self.finish_request(request, "answered", {"type": "question_answers", "answers": dict(request.question_answers)})
        log_event(f"request {request.request_id[:8]} answered question")
        self.show_sent_screen(request, "answered")

    def press_confirm_back(self, unused_argument):
        self.confirm_choice = None
        self.transition_to_screen("request" if self.focused_request() else "home")

    def press_reading_next_page(self, unused_argument):
        if self.reading_context is None:
            return
        self.reading_context.page_index += 1
        self.mark_state_changed()

    def press_reading_back(self, unused_argument):
        return_screen = self.reading_context.return_screen if self.reading_context else "home"
        self.reading_context = None
        if return_screen == "request" and self.focused_request() is None:
            return_screen = "home"
        self.transition_to_screen(return_screen)

    def press_leave_deck(self, unused_argument):
        if self.screen in ("confirm", "reading"):
            self.confirm_choice = None
            self.reading_context = None
            self.transition_to_screen("request" if self.focused_request() else "home")
        self.last_user_press_at = 0.0
        self.pending_page_jumps.append("leave_claude_page")
        self.mark_state_changed()

    def press_cycle_request(self, unused_argument):
        if len(self.queued_request_ids) < 2:
            return
        if self.focused_request_id in self.queued_request_ids:
            next_position = (self.queued_request_ids.index(self.focused_request_id) + 1) % len(self.queued_request_ids)
        else:
            next_position = 0
        self.focus_request(self.queued_request_ids[next_position])

    def press_show_home(self, unused_argument):
        self.confirm_choice = None
        self.reading_context = None
        self.home_list_page_index = 0
        self.transition_to_screen("home")

    def press_focus_first_request(self, unused_argument):
        if not self.queued_request_ids:
            return
        if self.focused_request_id in self.queued_request_ids:
            self.focus_request(self.focused_request_id)
        else:
            self.focus_request(self.queued_request_ids[0])

    def press_release_to_terminal(self, unused_argument):
        request = self.focused_request()
        if request is None:
            return
        self.finish_request(request, "released")
        log_event(f"request {request.request_id[:8]} released to terminal")
        self.show_sent_screen(request, "released")

    def press_toggle_machine_routing(self, machine):
        routing_enabled = not self.routing_enabled_by_machine.get(machine, True)
        self.routing_enabled_by_machine[machine] = routing_enabled
        self.save_preferences()
        if not routing_enabled:
            for request_id in list(self.queued_request_ids):
                request = self.requests_by_id.get(request_id)
                if request is not None and request.machine == machine:
                    self.withdraw_request_from_deck(request, "released")
        log_event(f"routing for {machine} {'enabled' if routing_enabled else 'paused'}")
        self.mark_state_changed()

    def press_toggle_auto_open(self, unused_argument):
        self.auto_open_enabled = not self.auto_open_enabled
        self.save_preferences()
        log_event(f"auto open {'enabled' if self.auto_open_enabled else 'disabled'}")
        self.mark_state_changed()

    def press_open_waiting_reading(self, session_key):
        if session_key not in self.waiting_sessions_by_key:
            return
        self.reading_context = ReadingContext("waiting", session_key, 0, "home")
        self.transition_to_screen("reading")

    def press_dismiss_waiting_session(self, session_key):
        self.waiting_sessions_by_key.pop(session_key, None)
        self.reading_context = None
        self.transition_to_screen("home")

    def run_periodic_maintenance(self):
        with self.condition:
            now = time.monotonic()
            for request in list(self.requests_by_id.values()):
                if request.status == "pending" and now - request.last_polled_at > REQUEST_ABANDON_AFTER_SECONDS:
                    log_event(f"request {request.request_id[:8]} abandoned by {request.machine}")
                    self.withdraw_request_from_deck(request, "cancelled")
                    self.requests_by_id.pop(request.request_id, None)
                elif request.status != "pending" and now - request.finished_at > FINISHED_REQUEST_RETENTION_SECONDS:
                    self.requests_by_id.pop(request.request_id, None)
            for session_key, session in list(self.waiting_sessions_by_key.items()):
                if now - session.waiting_since > WAITING_SESSION_RETENTION_SECONDS:
                    self.remove_waiting_session(session_key)
            if self.screen == "sent" and now >= self.sent_screen_visible_until:
                self.focus_next_request_or_return_home()
            if now - self.last_time_label_refresh_at >= TIME_LABEL_REFRESH_SECONDS:
                self.last_time_label_refresh_at = now
                self.mark_state_changed()

    def take_pending_page_jumps(self):
        with self.condition:
            page_jumps = self.pending_page_jumps
            self.pending_page_jumps = []
            return page_jumps

    def set_companion_reachability(self, reachable):
        with self.condition:
            if self.companion_is_reachable != reachable:
                log_event(f"companion {'reachable' if reachable else 'unreachable'}")
            self.companion_is_reachable = reachable

    def record_displayed_frame(self, frame):
        with self.condition:
            self.displayed_key_actions = frame.key_actions
            self.displayed_view_token = frame.view_token
            self.last_displayed_frame = frame

    def main_page_key_alert_state(self):
        with self.condition:
            pending_count = len(self.queued_request_ids)
            waiting_count = len(self.waiting_sessions_by_key)
            newest_request_created_at = max(
                (self.requests_by_id[request_id].created_at for request_id in self.queued_request_ids), default=None
            )
            should_blink = (
                newest_request_created_at is not None
                and time.monotonic() - newest_request_created_at < MAIN_KEY_BLINK_DURATION_SECONDS
            )
            return pending_count, waiting_count, should_blink

    def build_main_page_key_image(self, blink_phase_on=True):
        pending_count, waiting_count, should_blink = self.main_page_key_alert_state()
        highlight_on = pending_count > 0 and (blink_phase_on or not should_blink)
        return render_main_page_claude_key(pending_count, waiting_count, highlight_on)

    def build_deck_frame(self, main_key_blink_phase_on=True):
        with self.condition:
            frame_builder = self.select_frame_builder()
            key_images, key_actions = frame_builder()
            for row in range(DECK_ROW_COUNT):
                for column in range(DECK_COLUMN_COUNT):
                    key_images.setdefault((row, column), empty_key_image())
            return DeckFrame(
                key_images=key_images,
                key_actions=key_actions,
                main_page_key_image=self.build_main_page_key_image(main_key_blink_phase_on),
                view_token=self.view_token,
                state_version=self.state_version,
            )

    def reading_source_is_available(self):
        if self.reading_context is None:
            return False
        if self.reading_context.source_kind == "request":
            request = self.requests_by_id.get(self.reading_context.source_key)
            return request is not None and request.status == "pending"
        return self.reading_context.source_key in self.waiting_sessions_by_key

    def select_frame_builder(self):
        if self.screen == "sent":
            return self.build_sent_frame
        request = self.focused_request()
        if self.screen == "request" and request is not None:
            return self.build_question_frame if request.kind == "question" else self.build_permission_frame
        if self.screen == "confirm" and request is not None and self.confirm_choice is not None:
            return self.build_confirm_frame
        if self.screen == "reading" and self.reading_source_is_available():
            return self.build_reading_frame
        return self.build_home_frame

    def request_identity_footer(self, request):
        if request.agent_label:
            return request.agent_label
        question_count = len(request.payload["questions"]) if request.kind == "question" else 1
        if question_count > 1:
            return f"{request.current_question_index + 1}/{question_count}"
        return REQUEST_KIND_LABELS[request.kind]

    def request_identity_key_image(self, request):
        return render_identity_key(
            request.machine, request.project, request.session_label, self.request_identity_footer(request)
        )

    def build_home_list_entries(self, now):
        list_entries = []
        for request_id in self.queued_request_ids:
            request = self.requests_by_id[request_id]
            display = machine_display_for(request.machine)
            list_entries.append(
                (
                    LabelKeyDesign(
                        primary_text=join_non_empty_lines(request.project, request.session_label),
                        background_color=PENDING_LIST_BACKGROUND_COLOR,
                        caption_text=display.label,
                        footer_text=REQUEST_KIND_LABELS[request.kind],
                        top_strip_color=display.color,
                        maximum_font_size=14,
                    ),
                    ("focus_request_by_id", request_id),
                )
            )
        waiting_sessions = sorted(
            self.waiting_sessions_by_key.values(), key=lambda session: session.waiting_since, reverse=True
        )
        for session in waiting_sessions:
            display = machine_display_for(session.machine)
            list_entries.append(
                (
                    LabelKeyDesign(
                        primary_text=join_non_empty_lines(session.project, session.session_label),
                        background_color=WAITING_SESSION_BACKGROUND_COLOR,
                        caption_text=display.label,
                        caption_color=MUTED_BODY_COLOR,
                        footer_text=describe_elapsed_time(now - session.waiting_since),
                        footer_color=MUTED_BODY_COLOR,
                        top_strip_color=display.color,
                        maximum_font_size=14,
                    ),
                    ("open_waiting_reading", (session.machine, session.session_id)),
                )
            )
        return list_entries

    def place_home_list(self, key_images, key_actions, list_entries):
        if len(list_entries) <= len(HOME_LIST_LOCATIONS):
            visible_entries = list_entries
        else:
            entries_per_page = len(HOME_LIST_LOCATIONS) - 1
            page_count = math.ceil(len(list_entries) / entries_per_page)
            page_number = self.home_list_page_index % page_count
            first_entry_position = page_number * entries_per_page
            visible_entries = list_entries[first_entry_position : first_entry_position + entries_per_page]
            more_location = HOME_LIST_LOCATIONS[-1]
            key_images[more_location] = navigation_key_image(
                "chevron_right", "MÁS", caption=f"{page_number + 1}/{page_count}"
            )
            key_actions[more_location] = ("home_next_list_page", None)
        for location, (design, action) in zip(HOME_LIST_LOCATIONS, visible_entries):
            key_images[location] = render_label_key(design)
            key_actions[location] = action

    def build_home_frame(self):
        key_images = {}
        key_actions = {}
        now = time.monotonic()
        for column, machine in enumerate(KNOWN_MACHINE_DISPLAYS):
            display = machine_display_for(machine)
            routing_enabled = self.routing_enabled_by_machine.get(machine, True)
            pending_count = sum(
                1 for request_id in self.queued_request_ids if self.requests_by_id[request_id].machine == machine
            )
            waiting_count = sum(1 for session in self.waiting_sessions_by_key.values() if session.machine == machine)
            if pending_count:
                footer_text = f"{pending_count} pendientes"
            elif waiting_count:
                footer_text = f"{waiting_count} esperando"
            else:
                footer_text = ""
            key_images[(0, column)] = render_label_key(
                LabelKeyDesign(
                    primary_text="ACTIVO" if routing_enabled else "EN PAUSA",
                    background_color=display.color if routing_enabled else PAUSED_MACHINE_COLOR,
                    caption_text=display.label,
                    footer_text=footer_text,
                    maximum_font_size=15,
                )
            )
            key_actions[(0, column)] = ("toggle_machine_routing", machine)
        pending_count, waiting_count, unused_should_blink = self.main_page_key_alert_state()
        key_images[(0, 2)] = render_main_page_claude_key(pending_count, waiting_count, True)
        if pending_count:
            key_actions[(0, 2)] = ("focus_first_request", None)
        key_images[(0, 3)] = render_label_key(
            LabelKeyDesign(
                primary_text="SÍ" if self.auto_open_enabled else "NO",
                background_color=ALLOW_COLOR if self.auto_open_enabled else PAUSED_MACHINE_COLOR,
                caption_text="AUTO-ABRIR",
                footer_text="esta página",
                maximum_font_size=18,
            )
        )
        key_actions[(0, 3)] = ("toggle_auto_open", None)
        key_images[(0, 4)] = navigation_key_image("exit", "SALIR")
        key_actions[(0, 4)] = ("leave_deck", None)
        list_entries = self.build_home_list_entries(now)
        if not list_entries:
            key_images.update(
                render_text_panel(
                    (TextParagraph("Ninguna sesión te está esperando", MUTED_TEXT_COLOR),),
                    EMPTY_HOME_MESSAGE_KEY_ROWS,
                    EMPTY_KEY_COLOR,
                )
            )
            return key_images, key_actions
        self.place_home_list(key_images, key_actions, list_entries)
        return key_images, key_actions

    def add_request_navigation_row(self, key_images, key_actions):
        key_images[(2, 0)] = navigation_key_image("exit", "SALIR")
        key_actions[(2, 0)] = ("leave_deck", None)
        key_images[(2, 1)] = navigation_key_image("full_text", "VER TODO")
        key_actions[(2, 1)] = ("open_request_reading", None)
        other_request_count = len(self.queued_request_ids) - 1
        if other_request_count > 0:
            key_images[(2, 2)] = accent_key_image(
                "skip_forward", "SIGUIENTE", PENDING_ALERT_COLOR, caption=f"+{other_request_count} EN COLA"
            )
            key_actions[(2, 2)] = ("cycle_request", None)
        key_images[(2, 3)] = navigation_key_image("home", "INICIO")
        key_actions[(2, 3)] = ("show_home", None)
        key_images[(2, 4)] = navigation_key_image("terminal", "TERMINAL", background_color=TERMINAL_KEY_COLOR)
        key_actions[(2, 4)] = ("release_to_terminal", None)

    def build_banner(self, request, body_paragraphs):
        display = machine_display_for(request.machine)
        key_images = render_text_panel(tuple(body_paragraphs), BANNER_KEY_ROWS, banner_background_for(display))
        key_images[IDENTITY_KEY_LOCATION] = self.request_identity_key_image(request)
        key_actions = {(0, column): ("open_request_reading", None) for column in ALL_COLUMNS}
        return key_images, key_actions

    def build_question_frame(self):
        request = self.focused_request()
        question = self.current_question(request)
        key_images, key_actions = self.build_banner(request, (TextParagraph(question["question"], BODY_TEXT_COLOR),))
        for option_index, option in enumerate(question["options"]):
            location = (1, option_index)
            key_images[location] = render_label_key(
                option_key_design(
                    option_index,
                    option["label"],
                    question["multiSelect"],
                    option_index in request.multi_select_choices,
                )
            )
            key_actions[location] = ("choose_option", option_index)
        if question["multiSelect"]:
            chosen_count = len(request.multi_select_choices)
            key_images[(1, 4)] = accent_key_image(
                "check",
                "LISTO",
                ALLOW_COLOR if chosen_count else DISABLED_KEY_COLOR,
                caption=f"{chosen_count} elegidas",
            )
            key_actions[(1, 4)] = ("submit_multi_select", None)
        self.add_request_navigation_row(key_images, key_actions)
        return key_images, key_actions

    def build_permission_frame(self):
        request = self.focused_request()
        description = describe_permission_request(request.payload["tool_name"], request.payload["tool_input"])
        key_images, key_actions = self.build_banner(
            request,
            (
                TextParagraph(description.title, CLAUDE_ACCENT_COLOR, True),
                TextParagraph(shorten_home_paths(description.summary), BODY_TEXT_COLOR),
            ),
        )
        key_images[(1, 0)] = accent_key_image("check", "PERMITIR", ALLOW_COLOR)
        key_actions[(1, 0)] = ("choose_permission", "allow")
        if request.payload["permission_suggestions"]:
            key_images[(1, 1)] = accent_key_image("check_double", "SIEMPRE", ALLOW_ALWAYS_COLOR)
            key_actions[(1, 1)] = ("choose_permission", "allow_always")
        key_images[(1, 2)] = accent_key_image("cross", "RECHAZAR", REJECT_COLOR)
        key_actions[(1, 2)] = ("choose_permission", "deny")
        self.add_request_navigation_row(key_images, key_actions)
        return key_images, key_actions

    def build_request_reading_paragraphs(self, request):
        if request.kind == "question":
            question = self.current_question(request)
            paragraphs = [TextParagraph(question["question"], BODY_TEXT_COLOR)]
            for option_index, option in enumerate(question["options"]):
                paragraphs.append(
                    TextParagraph(f"{option_index + 1}. {option['label']}", CLAUDE_ACCENT_COLOR, True, starts_new_key=True)
                )
                if option["description"]:
                    paragraphs.append(TextParagraph(option["description"], MUTED_BODY_COLOR))
            return paragraphs
        description = describe_permission_request(request.payload["tool_name"], request.payload["tool_input"])
        paragraphs = [
            TextParagraph(description.title, CLAUDE_ACCENT_COLOR, True),
            TextParagraph(truncate_text(description.detail, MAXIMUM_DETAIL_CHARACTERS), BODY_TEXT_COLOR),
        ]
        rule_descriptions = describe_permission_suggestions(request.payload["permission_suggestions"])
        if rule_descriptions:
            paragraphs.append(TextParagraph("SIEMPRE agrega:", MUTED_TEXT_COLOR, True, starts_new_key=True))
            paragraphs.append(TextParagraph("\n".join(rule_descriptions), BODY_TEXT_COLOR))
        return paragraphs

    def build_confirm_paragraphs(self, request):
        choice = self.confirm_choice
        if choice["kind"] == "option":
            option = self.current_question(request)["options"][choice["index"]]
            paragraphs = [
                TextParagraph("Vas a responder:", MUTED_TEXT_COLOR),
                TextParagraph(option["label"], BODY_TEXT_COLOR, True),
            ]
            if option["description"]:
                paragraphs.append(TextParagraph(option["description"], MUTED_BODY_COLOR))
            return paragraphs
        if choice["kind"] == "multi":
            options = self.current_question(request)["options"]
            chosen_labels = [options[option_index]["label"] for option_index in sorted(request.multi_select_choices)]
            return [
                TextParagraph("Vas a responder:", MUTED_TEXT_COLOR),
                TextParagraph("\n".join(f"• {label}" for label in chosen_labels), BODY_TEXT_COLOR, True),
            ]
        decision_title, unused_send_caption, unused_key_color, decision_text_color = DECISION_PRESENTATION[
            choice["decision"]
        ]
        description = describe_permission_request(request.payload["tool_name"], request.payload["tool_input"])
        paragraphs = [
            TextParagraph(decision_title, decision_text_color, True),
            TextParagraph(description.title, CLAUDE_ACCENT_COLOR, True),
            TextParagraph(truncate_text(description.detail, 900), BODY_TEXT_COLOR),
        ]
        if choice["decision"] == "allow_always":
            rule_descriptions = describe_permission_suggestions(request.payload["permission_suggestions"])
            paragraphs.append(TextParagraph("Regla nueva:", MUTED_TEXT_COLOR, starts_new_key=True))
            paragraphs.append(TextParagraph("\n".join(rule_descriptions), BODY_TEXT_COLOR, True))
        return paragraphs

    def build_confirm_frame(self):
        request = self.focused_request()
        key_images = render_text_panel(
            tuple(self.build_confirm_paragraphs(request)), FULL_TEXT_KEY_ROWS, PANEL_BACKGROUND_COLOR
        )
        key_images[IDENTITY_KEY_LOCATION] = self.request_identity_key_image(request)
        key_actions = {}
        key_images[(2, 0)] = navigation_key_image("back", "ATRÁS")
        key_actions[(2, 0)] = ("confirm_back", None)
        choice = self.confirm_choice
        if choice["kind"] == "permission":
            unused_title, send_caption, send_color, unused_text_color = DECISION_PRESENTATION[choice["decision"]]
        else:
            send_caption, send_color = "RESPUESTA", ALLOW_COLOR
        key_images[(2, 4)] = accent_key_image("send", "ENVIAR", send_color, caption=send_caption)
        key_actions[(2, 4)] = ("confirm_send", None)
        return key_images, key_actions

    def build_reading_frame(self):
        context = self.reading_context
        if context.source_kind == "request":
            request = self.requests_by_id[context.source_key]
            paragraphs = self.build_request_reading_paragraphs(request)
            key_rows = FULL_TEXT_KEY_ROWS
            identity_image = self.request_identity_key_image(request)
        else:
            session = self.waiting_sessions_by_key[context.source_key]
            message_text = simplify_markdown_for_deck(session.last_message) or "(sin mensaje)"
            paragraphs = [TextParagraph(message_text, BODY_TEXT_COLOR)]
            key_rows = WAITING_READING_KEY_ROWS
            identity_image = render_identity_key(
                session.machine,
                session.project,
                session.session_label,
                describe_elapsed_time(time.monotonic() - session.waiting_since),
            )
        tokens = tokenize_paragraphs(tuple(paragraphs), PANEL_TYPOGRAPHY)
        page_start_indexes = paginate_text_panel(tokens, key_rows, PANEL_TYPOGRAPHY)
        page_count = len(page_start_indexes)
        page_number = context.page_index % page_count
        key_images = render_text_panel(
            tuple(paragraphs),
            key_rows,
            PANEL_BACKGROUND_COLOR,
            start_token_index=page_start_indexes[page_number],
            ellipsize=False,
        )
        key_images[IDENTITY_KEY_LOCATION] = identity_image
        key_actions = {}
        if page_count > 1:
            for row, columns in key_rows:
                for column in columns:
                    key_actions[(row, column)] = ("reading_next_page", None)
            is_last_page = page_number == page_count - 1
            page_caption = f"{page_number + 1}/{page_count}"
            if is_last_page:
                key_images[(2, 4)] = navigation_key_image("restart", "INICIO", caption=page_caption)
            else:
                key_images[(2, 4)] = navigation_key_image("chevron_down", "MÁS", caption=page_caption)
            key_actions[(2, 4)] = ("reading_next_page", None)
        key_images[(2, 0)] = navigation_key_image("back", "ATRÁS")
        key_actions[(2, 0)] = ("reading_back", None)
        if context.source_kind == "waiting":
            key_images[(2, 3)] = navigation_key_image("dismiss", "DESCARTAR", background_color=TERMINAL_KEY_COLOR)
            key_actions[(2, 3)] = ("dismiss_waiting_session", context.source_key)
        return key_images, key_actions

    def build_sent_frame(self):
        display = machine_display_for(self.sent_screen_machine or "?")
        answered = self.sent_screen_style == "answered"
        background_color = SENT_BACKGROUND_COLOR if answered else RELEASED_BACKGROUND_COLOR
        blank_image = render_label_key(LabelKeyDesign(primary_text="", background_color=background_color))
        key_images = {(row, column): blank_image for row in range(DECK_ROW_COUNT) for column in ALL_COLUMNS}
        key_images[(1, 1)] = render_label_key(
            LabelKeyDesign(primary_text="✓" if answered else "↩", background_color=background_color, maximum_font_size=40)
        )
        key_images[(1, 2)] = render_label_key(
            LabelKeyDesign(
                primary_text="ENVIADO" if answered else "EN LA TERMINAL",
                background_color=background_color,
                maximum_font_size=16,
            )
        )
        key_images[(1, 3)] = render_label_key(
            LabelKeyDesign(primary_text=display.label, background_color=display.color, maximum_font_size=15)
        )
        return key_images, {}


class CompanionClient:
    def send(self, method, path, query_parameters=None):
        url = COMPANION_BASE_URL + path
        if query_parameters:
            url += "?" + urllib.parse.urlencode(query_parameters)
        http_request = urllib.request.Request(url, data=b"" if method == "POST" else None, method=method)
        with urllib.request.urlopen(http_request, timeout=COMPANION_TIMEOUT_SECONDS) as http_response:
            return http_response.read().decode("utf-8", errors="replace")

    def set_key_image(self, page, row, column, data_url):
        self.send("POST", f"/api/location/{page}/{row}/{column}/style", {"png64": data_url})

    def read_stream_deck_page(self):
        try:
            return int(self.send("GET", STREAM_DECK_PAGE_VARIABLE_PATH).strip().strip('"'))
        except (OSError, ValueError):
            return None

    def set_custom_variable(self, variable_name, value):
        self.send("POST", f"/api/custom-variable/{variable_name}/value", {"value": value})

    def press_key(self, page, row, column):
        self.send("POST", f"/api/location/{page}/{row}/{column}/press")


class DeckRenderer:
    def __init__(self, coordinator, companion_client):
        self.coordinator = coordinator
        self.companion_client = companion_client
        self.pushed_digest_by_location = {}
        self.remembered_return_page = None
        self.last_rendered_state_version = -1
        self.retry_not_before = 0.0
        self.last_full_repush_at = time.monotonic()
        self.last_health_probe_at = 0.0
        self.main_key_blink_phase_on = True
        self.last_blink_toggle_at = 0.0
        self.push_executor = ThreadPoolExecutor(max_workers=PUSH_WORKER_COUNT)

    def run_forever(self):
        while True:
            self.coordinator.render_wakeup_event.wait(timeout=RENDER_LOOP_INTERVAL_SECONDS)
            self.coordinator.render_wakeup_event.clear()
            try:
                self.coordinator.run_periodic_maintenance()
                self.probe_companion_health_when_due()
                self.render_when_needed()
                self.refresh_main_key_blink()
                self.execute_pending_page_jumps()
            except Exception:
                log_event("renderer error:\n" + traceback.format_exc())
                time.sleep(1)

    def probe_companion_health_when_due(self):
        now = time.monotonic()
        if now - self.last_health_probe_at < COMPANION_HEALTH_PROBE_SECONDS:
            return
        self.last_health_probe_at = now
        reachable = self.companion_client.read_stream_deck_page() is not None
        was_reachable = self.coordinator.companion_is_reachable
        self.coordinator.set_companion_reachability(reachable)
        if reachable and not was_reachable:
            self.pushed_digest_by_location.clear()
            self.last_rendered_state_version = -1

    def push_key_image(self, location, data_url):
        page, row, column = location
        try:
            self.companion_client.set_key_image(page, row, column, data_url)
            return True
        except (OSError, ValueError) as push_error:
            log_event(f"push to {location} failed: {push_error}")
            return False

    def refresh_main_key_blink(self):
        now = time.monotonic()
        if now - self.last_blink_toggle_at < MAIN_KEY_BLINK_INTERVAL_SECONDS:
            return
        self.last_blink_toggle_at = now
        unused_pending_count, unused_waiting_count, should_blink = self.coordinator.main_page_key_alert_state()
        self.main_key_blink_phase_on = (not self.main_key_blink_phase_on) if should_blink else True
        main_key_location = (MAIN_PAGE_NUMBER, MAIN_PAGE_CLAUDE_KEY_ROW, MAIN_PAGE_CLAUDE_KEY_COLUMN)
        data_url = encode_key_image_as_data_url(self.coordinator.build_main_page_key_image(self.main_key_blink_phase_on))
        digest = hashlib.sha256(data_url.encode("ascii")).hexdigest()
        if self.pushed_digest_by_location.get(main_key_location) == digest:
            return
        if self.push_key_image(main_key_location, data_url):
            self.pushed_digest_by_location[main_key_location] = digest

    def render_when_needed(self):
        now = time.monotonic()
        if now - self.last_full_repush_at >= FULL_REPUSH_INTERVAL_SECONDS:
            self.last_full_repush_at = now
            self.pushed_digest_by_location.clear()
            self.last_rendered_state_version = -1
        if self.coordinator.state_version == self.last_rendered_state_version:
            return
        if self.last_rendered_state_version == -1 and now < self.retry_not_before:
            return
        frame = self.coordinator.build_deck_frame(self.main_key_blink_phase_on)
        images_by_location = {
            (CLAUDE_PAGE_NUMBER, row, column): key_image for (row, column), key_image in frame.key_images.items()
        }
        images_by_location[(MAIN_PAGE_NUMBER, MAIN_PAGE_CLAUDE_KEY_ROW, MAIN_PAGE_CLAUDE_KEY_COLUMN)] = (
            frame.main_page_key_image
        )
        changed_data_urls = {}
        for location, key_image in images_by_location.items():
            data_url = encode_key_image_as_data_url(key_image)
            digest = hashlib.sha256(data_url.encode("ascii")).hexdigest()
            if self.pushed_digest_by_location.get(location) != digest:
                changed_data_urls[location] = (data_url, digest)
        changed_locations = list(changed_data_urls)
        push_results = list(
            self.push_executor.map(
                lambda location: self.push_key_image(location, changed_data_urls[location][0]), changed_locations
            )
        )
        for location, pushed in zip(changed_locations, push_results):
            if pushed:
                self.pushed_digest_by_location[location] = changed_data_urls[location][1]
        all_pushed = all(push_results)
        if changed_locations:
            self.coordinator.set_companion_reachability(all_pushed)
        if all_pushed:
            self.coordinator.record_displayed_frame(frame)
            self.last_rendered_state_version = frame.state_version
        else:
            self.last_rendered_state_version = -1
            self.retry_not_before = now + FAILED_PUSH_RETRY_SECONDS

    def jump_to_page(self, page_number):
        try:
            self.companion_client.set_custom_variable(JUMP_TARGET_VARIABLE_NAME, str(page_number))
            self.companion_client.press_key(JUMP_CONTROL_PAGE_NUMBER, JUMP_CONTROL_ROW, JUMP_CONTROL_COLUMN)
        except (OSError, ValueError) as jump_error:
            log_event(f"jump to page {page_number} failed: {jump_error}")

    def execute_pending_page_jumps(self):
        for page_jump in self.coordinator.take_pending_page_jumps():
            if page_jump == "opened_from_main_page":
                self.remembered_return_page = MAIN_PAGE_NUMBER
                continue
            current_page = self.companion_client.read_stream_deck_page()
            if page_jump == "show_claude_page":
                if current_page != CLAUDE_PAGE_NUMBER:
                    if current_page is not None:
                        self.remembered_return_page = current_page
                    self.jump_to_page(CLAUDE_PAGE_NUMBER)
            elif page_jump == "return_from_claude_page":
                if current_page == CLAUDE_PAGE_NUMBER and self.remembered_return_page is not None:
                    self.jump_to_page(self.remembered_return_page)
                self.remembered_return_page = None
            elif page_jump == "leave_claude_page":
                self.jump_to_page(self.remembered_return_page or FALLBACK_RETURN_PAGE_NUMBER)
                self.remembered_return_page = None


class ClaudeDeckRequestHandler(BaseHTTPRequestHandler):
    coordinator = None
    server_version = "ClaudeStreamDeck/1.0"

    def log_message(self, format_text, *format_arguments):
        return

    def client_is_local(self):
        return self.client_address[0] in LOCAL_CLIENT_ADDRESSES

    def send_bytes_response(self, status_code, content_type, response_bytes):
        try:
            self.send_response(status_code)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(response_bytes)))
            self.end_headers()
            self.wfile.write(response_bytes)
        except (BrokenPipeError, ConnectionResetError):
            return

    def send_json_response(self, status_code, body):
        self.send_bytes_response(
            status_code, "application/json; charset=utf-8", json.dumps(body, ensure_ascii=False).encode("utf-8")
        )

    def read_json_body(self):
        content_length = int(self.headers.get("Content-Length") or 0)
        if content_length <= 0 or content_length > MAXIMUM_REQUEST_BODY_BYTES:
            raise InvalidRequestBody("missing or oversized body")
        try:
            parsed_body = json.loads(self.rfile.read(content_length).decode("utf-8"))
        except (UnicodeDecodeError, ValueError) as parse_error:
            raise InvalidRequestBody(f"invalid JSON: {parse_error}") from parse_error
        if not isinstance(parsed_body, dict):
            raise InvalidRequestBody("body must be a JSON object")
        return parsed_body

    def run_safely(self, route_handler):
        try:
            route_handler()
        except InvalidRequestBody as invalid_body_error:
            self.send_json_response(400, {"error": str(invalid_body_error)})
        except Exception:
            log_event("handler error:\n" + traceback.format_exc())
            self.send_json_response(500, {"error": "internal"})

    def do_GET(self):
        self.run_safely(self.route_get)

    def do_POST(self):
        self.run_safely(self.route_post)

    def do_DELETE(self):
        self.run_safely(self.route_delete)

    def reject_unless_local(self):
        if self.client_is_local():
            return False
        self.send_json_response(403, {"error": "local_only"})
        return True

    def route_get(self):
        parsed_url = urllib.parse.urlsplit(self.path)
        if parsed_url.path == "/health":
            self.send_json_response(200, self.coordinator.health_summary())
            return
        wait_match = WAIT_PATH_PATTERN.fullmatch(parsed_url.path)
        if wait_match:
            query_values = urllib.parse.parse_qs(parsed_url.query)
            try:
                timeout_seconds = float(query_values.get("timeout", [LONG_POLL_DEFAULT_SECONDS])[0])
            except ValueError:
                timeout_seconds = LONG_POLL_DEFAULT_SECONDS
            status_code, body = self.coordinator.wait_for_request(wait_match.group(1), timeout_seconds)
            self.send_json_response(status_code, body)
            return
        if parsed_url.path == "/deck/preview.png":
            if self.reject_unless_local():
                return
            frame = self.coordinator.last_displayed_frame or self.coordinator.build_deck_frame()
            png_buffer = io.BytesIO()
            render_deck_preview_image(frame).save(png_buffer, format="PNG")
            self.send_bytes_response(200, "image/png", png_buffer.getvalue())
            return
        self.send_json_response(404, {"error": "not_found"})

    def route_post(self):
        parsed_url = urllib.parse.urlsplit(self.path)
        press_match = PRESS_PATH_PATTERN.fullmatch(parsed_url.path)
        if press_match:
            if self.reject_unless_local():
                return
            press_result = self.coordinator.handle_key_press(int(press_match.group(1)), int(press_match.group(2)))
            self.send_json_response(200, {"result": press_result})
            return
        if parsed_url.path == "/deck/open":
            if self.reject_unless_local():
                return
            self.coordinator.open_from_main_page()
            self.send_json_response(200, {"ok": True})
            return
        if parsed_url.path == "/api/requests":
            self.send_json_response(200, self.coordinator.create_request(self.read_json_body()))
            return
        if parsed_url.path == "/api/sessions/waiting":
            self.coordinator.mark_session_waiting(self.read_json_body())
            self.send_json_response(200, {"ok": True})
            return
        if parsed_url.path == "/api/sessions/active":
            self.coordinator.mark_session_active(self.read_json_body())
            self.send_json_response(200, {"ok": True})
            return
        self.send_json_response(404, {"error": "not_found"})

    def route_delete(self):
        parsed_url = urllib.parse.urlsplit(self.path)
        request_match = REQUEST_PATH_PATTERN.fullmatch(parsed_url.path)
        if request_match and self.coordinator.cancel_request(request_match.group(1)):
            self.send_json_response(200, {"ok": True})
            return
        self.send_json_response(404, {"error": "not_found"})


def main():
    coordinator = ClaudeDeckCoordinator(STATE_FILE_PATH)
    renderer = DeckRenderer(coordinator, CompanionClient())
    threading.Thread(target=renderer.run_forever, name="deck-renderer", daemon=True).start()
    ClaudeDeckRequestHandler.coordinator = coordinator
    http_server = ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), ClaudeDeckRequestHandler)
    http_server.daemon_threads = True
    log_event(f"claude stream deck coordinator listening on {LISTEN_HOST}:{LISTEN_PORT}")
    http_server.serve_forever()


if __name__ == "__main__":
    main()
