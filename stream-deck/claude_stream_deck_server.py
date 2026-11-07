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
KNOWN_SESSION_RETENTION_SECONDS = 12 * 3600
SESSION_DECK_OVERRIDE_RETENTION_SECONDS = 7 * 24 * 3600
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
MAXIMUM_SESSION_LABEL_CHARACTERS = 48
MAXIMUM_AGENT_LABEL_CHARACTERS = 24
MAXIMUM_READING_PAGES = 40
MAXIMUM_QUESTIONS_PER_REQUEST = 4
MAXIMUM_OPTIONS_PER_QUESTION = 4
MAXIMUM_CHUNK_CHARACTERS = 40
PNG_PALETTE_COLOR_COUNT = 64
PUSH_WORKER_COUNT = 4
MAIN_KEY_ANIMATION_FRAME_SECONDS = 0.12
MAIN_KEY_ANIMATION_DURATION_SECONDS = 60
MAIN_KEY_REMINDER_JUMP_INTERVAL_SECONDS = 15
MAIN_KEY_BADGE_RADIUS = 10
MAIN_KEY_BADGE_EDGE_MARGIN = 2
MAIN_KEY_BADGE_SINGLE_DIGIT_FONT_SIZE = 13
MAIN_KEY_BADGE_OVERFLOW_FONT_SIZE = 10
MAIN_KEY_BADGE_MAXIMUM_EXACT_COUNT = 9
MAIN_KEY_BADGE_OUTLINE_WIDTH = 2
MAIN_KEY_BORDER_WIDTH = 3
MAIN_KEY_LABEL_FONT_SIZE = 12
MAIN_KEY_LABEL_TOP = 55
MAIN_KEY_ALERT_MASCOT_PIXEL_UNIT = 3
MAIN_KEY_ALERT_MASCOT_GROUND_TOP = 50
MAIN_KEY_ALERT_MASCOT_HORIZONTAL_CENTER = 31
MAIN_KEY_IDLE_MASCOT_PIXEL_UNIT = 4
MASCOT_CANVAS_WIDTH_UNITS = 18
MASCOT_STANDING_HEIGHT_UNITS = 10
MASCOT_HEADROOM_UNITS = 1
MASCOT_CANVAS_HEIGHT_UNITS = MASCOT_STANDING_HEIGHT_UNITS + MASCOT_HEADROOM_UNITS
MASCOT_BODY_LEFT_UNIT = 3
MASCOT_BODY_WIDTH_UNITS = 12
MASCOT_BODY_HEIGHT_UNITS = 8
MASCOT_LEG_HEIGHT_UNITS = 2
MASCOT_LEG_COLUMN_UNITS = (4, 6, 11, 13)
MASCOT_EYE_COLUMN_UNITS = (5, 12)
MASCOT_EYE_TOP_OFFSET_UNITS = 2
MASCOT_OPEN_EYE_HEIGHT_UNITS = 2
MASCOT_CLOSED_EYE_HEIGHT_UNITS = 1
MASCOT_ARM_WIDTH_UNITS = 2
MASCOT_ARM_HEIGHT_UNITS = 2
MASCOT_RESTING_ARM_TOP_OFFSET_UNITS = 4
MASCOT_RAISED_ARM_TOP_OFFSET_UNITS = -1
MASCOT_RAISED_ARM_HEIGHT_UNITS = 3
MASCOT_SHADOW_HEIGHT = 4
MASCOT_SHADOW_WEIGHT = 0.5
MASCOT_SHADOW_SHRINK_PER_LIFT_UNIT = 0.09
MASCOT_KEY_PIXEL_UNIT = 3
MASCOT_KEY_GROUND_TOP = 44
MASCOT_KEY_UNCAPTIONED_GROUND_TOP = 52
MASCOT_KEY_CAPTION_TOP = 52
MASCOT_KEY_CAPTION_MAXIMUM_FONT_SIZE = 12
MASCOT_KEY_CAPTION_MINIMUM_FONT_SIZE = 9
SESSIONS_TITLE_MASCOT_PIXEL_UNIT = 2
SESSIONS_TITLE_MASCOT_GROUND_TOP = 30
SESSIONS_TITLE_LABEL_TOP = 37
SESSIONS_TITLE_FONT_SIZE = 14
SESSIONS_TITLE_MACHINE_TOP = 54
SLEEPING_MARK_PLACEMENTS = ((9, 55, 9), (12, 61, 0))
ICON_SUPERSAMPLING_FACTOR = 4
ICON_GRID_SIZE = 24
ICON_STROKE_WIDTH_IN_GRID = 2.6
ICON_ARC_SEGMENT_COUNT = 48
ICON_KEY_ICON_SIZE = 34
ICON_KEY_ICON_TOP = 9
ICON_KEY_COMPACT_ICON_SIZE = 26
ICON_KEY_COMPACT_ICON_TOP = 20
ICON_KEY_SOLO_ICON_SIZE = 40
ICON_KEY_CAPTION_TOP = 4
ICON_KEY_LABEL_TOP = 52
ICON_KEY_LABEL_FONT_SIZE = 12
ICON_KEY_CAPTION_FONT_SIZE = 11
OPTION_KEY_MARGIN = 5
OPTION_NUMBER_CHIP_DIAMETER = 18
OPTION_NUMBER_FONT_SIZE = 12
OPTION_CHECKBOX_SIZE = 16
OPTION_CHECKBOX_OUTLINE_WIDTH = 2
OPTION_CHECKBOX_CORNER_RADIUS = 4
OPTION_CHECKBOX_CHECK_INSET = 2
OPTION_MARKER_GAP = 4
OPTION_RECOMMENDED_FONT_SIZE = 15
RECOMMENDED_MARK_TEXT = "★"
OPTION_LABEL_LINE_SPACING = 2
OPTION_LABEL_AREA_TOP = 26
OPTION_LABEL_FONT_SIZE_AND_LINE_COUNT_ATTEMPTS = ((16, 2), (14, 2), (13, 3), (12, 3), (11, 3))
LEGEND_SWITCH_WIDTH = 30
LEGEND_SWITCH_HEIGHT = 16
LEGEND_SWITCH_TOP = 9
LEGEND_TEXT_AREA_TOP = 31
LEGEND_TEXT_FONT_SIZE_AND_LINE_COUNT_ATTEMPTS = ((13, 2), (12, 2), (11, 3))
LABEL_CAPTION_FONT_SIZE = 12
LABEL_STRIP_HEIGHT = 6
LABEL_EDGE_MARGIN = 4
PREVIEW_KEY_GAP = 12
PREVIEW_MARGIN = 16
SESSION_KEY_MARGIN = 5
SESSION_KEY_BORDER_WIDTH = 2
SESSION_KEY_TOP_ROW_TOP = 5
SESSION_KEY_TOP_ROW_GAP = 4
SESSION_KEY_SMALL_FONT_SIZE = 11
SESSION_SWITCH_WIDTH = 22
SESSION_SWITCH_HEIGHT = 12
SESSION_TITLE_AREA_TOP = 19
SESSION_TITLE_AREA_HEIGHT = 35
SESSION_TITLE_FONT_SIZE_AND_LINE_COUNT_ATTEMPTS = ((14, 2), (13, 2), (12, 2), (11, 3))
SESSION_TITLE_LINE_SPACING_UP_TO_TWO_LINES = 1
TEAMMATE_STRIPE_WIDTH = 3
TOGGLE_SWITCH_KNOB_INSET = 2
STATUS_DOT_DIAMETER = 6
STATUS_DOT_OUTLINE_WIDTH = 1.25
STATUS_DOT_TEXT_GAP = 3
MACHINE_SUMMARY_CAPTION_TOP = 5
MACHINE_SUMMARY_HEADLINE_TOP = 21
MACHINE_SUMMARY_HEADLINE_MAXIMUM_FONT_SIZE = 16
MACHINE_SUMMARY_HEADLINE_MINIMUM_FONT_SIZE = 12
MACHINE_KEY_FOOTER_MAXIMUM_FONT_SIZE = 12
MACHINE_KEY_FOOTER_MINIMUM_FONT_SIZE = 10
MACHINE_SUMMARY_DOTS_TOP = 43
MACHINE_SESSION_DOT_DIAMETER = 6
MACHINE_SESSION_DOT_GAP = 3
MAXIMUM_MACHINE_SESSION_DOTS = 7
SESSION_DOT_KIND_DISPLAY_ORDER = {"alert": 0, "on": 1, "off": 2}
MACHINE_SWITCH_WIDTH = 38
MACHINE_SWITCH_HEIGHT = 20
MACHINE_SWITCH_TOP = 25

REGULAR_FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD_FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
NARROW_REGULAR_FONT_PATH = "/usr/share/fonts/truetype/liberation/LiberationSansNarrow-Regular.ttf"
NARROW_BOLD_FONT_PATH = "/usr/share/fonts/truetype/liberation/LiberationSansNarrow-Bold.ttf"
SYMBOL_CHARACTERS = frozenset("▶▼★☐☑✓↺↩")

CLAUDE_CLAY_COLOR = (217, 119, 87)
CLAUDE_CRAIL_COLOR = (193, 95, 60)
CLAUDE_KRAFT_COLOR = (212, 162, 127)
CLAUDE_MANILLA_COLOR = (235, 219, 188)
CLAUDE_IVORY_COLOR = (250, 249, 245)
CLAUDE_IVORY_MEDIUM_COLOR = (240, 240, 235)
CLAUDE_SLATE_DARKEST_COLOR = (20, 20, 19)
CLAUDE_SLATE_DARK_COLOR = (25, 25, 25)
CLAUDE_SLATE_MEDIUM_COLOR = (38, 38, 37)
CLAUDE_SLATE_SURFACE_COLOR = (48, 48, 46)
CLAUDE_SLATE_LIGHT_COLOR = (64, 64, 62)
CLAUDE_CLOUD_DARK_COLOR = (102, 102, 99)
CLAUDE_CLOUD_MEDIUM_COLOR = (145, 145, 141)
CLAUDE_CLOUD_LIGHT_COLOR = (191, 191, 186)
CLAUDE_OLIVE_DEEP_COLOR = (92, 114, 62)
CLAUDE_OLIVE_LIGHT_COLOR = (166, 190, 126)
CLAUDE_SKY_DEEP_COLOR = (64, 110, 160)
CLAUDE_SKY_LIGHT_COLOR = (130, 176, 226)
CLAUDE_ERROR_COLOR = (191, 77, 67)
CLAUDE_ERROR_LIGHT_COLOR = (236, 128, 114)
CLAUDE_ATTENTION_COLOR = (232, 94, 74)
CLAUDE_AMBER_COLOR = (236, 178, 92)

PANEL_BACKGROUND_COLOR = CLAUDE_SLATE_DARKEST_COLOR
BODY_TEXT_COLOR = CLAUDE_IVORY_MEDIUM_COLOR
MUTED_TEXT_COLOR = CLAUDE_CLOUD_MEDIUM_COLOR
MUTED_BODY_COLOR = CLAUDE_CLOUD_LIGHT_COLOR
DARK_TEXT_COLOR = CLAUDE_SLATE_DARK_COLOR
CLAUDE_ACCENT_COLOR = CLAUDE_CLAY_COLOR
ALLOW_COLOR = CLAUDE_OLIVE_DEEP_COLOR
ALLOW_TEXT_COLOR = CLAUDE_OLIVE_LIGHT_COLOR
ALLOW_ALWAYS_COLOR = CLAUDE_SKY_DEEP_COLOR
ALLOW_ALWAYS_TEXT_COLOR = CLAUDE_SKY_LIGHT_COLOR
REJECT_COLOR = CLAUDE_ERROR_COLOR
REJECT_TEXT_COLOR = CLAUDE_ERROR_LIGHT_COLOR
PRIMARY_ACTION_COLOR = CLAUDE_CRAIL_COLOR
NAVIGATION_COLOR = CLAUDE_SLATE_SURFACE_COLOR
ICON_COLOR = CLAUDE_IVORY_COLOR
NAVIGATION_LABEL_COLOR = CLAUDE_CLOUD_LIGHT_COLOR
ACCENT_LABEL_COLOR = CLAUDE_IVORY_COLOR
ACCENT_CAPTION_COLOR = CLAUDE_IVORY_MEDIUM_COLOR
TERMINAL_KEY_COLOR = CLAUDE_SLATE_MEDIUM_COLOR
DISABLED_KEY_COLOR = CLAUDE_SLATE_LIGHT_COLOR
OPTION_BACKGROUND_COLOR = (54, 50, 46)
OPTION_CHOSEN_COLOR = CLAUDE_OLIVE_DEEP_COLOR
OPTION_NUMBER_CHIP_COLOR = CLAUDE_CLAY_COLOR
RECOMMENDED_MARK_COLOR = CLAUDE_KRAFT_COLOR
PENDING_ALERT_COLOR = CLAUDE_ATTENTION_COLOR
WAITING_ALERT_COLOR = CLAUDE_AMBER_COLOR
IDLE_MAIN_KEY_COLOR = CLAUDE_SLATE_MEDIUM_COLOR
MAIN_KEY_PENDING_BACKGROUND_COLOR = (88, 32, 26)
MAIN_KEY_WAITING_BACKGROUND_COLOR = (62, 46, 24)
MASCOT_BODY_COLOR = CLAUDE_CLAY_COLOR
MASCOT_EYE_COLOR = CLAUDE_SLATE_DARK_COLOR
MASCOT_SHADOW_COLOR = (0, 0, 0)
MASCOT_SLEEPING_BODY_COLOR = (150, 96, 78)
PAUSED_MACHINE_COLOR = CLAUDE_SLATE_LIGHT_COLOR
HIDDEN_SESSION_BACKGROUND_COLOR = (26, 26, 25)
HIDDEN_SESSION_TITLE_COLOR = CLAUDE_CLOUD_MEDIUM_COLOR
HIDDEN_SESSION_PROJECT_COLOR = CLAUDE_CLOUD_DARK_COLOR
HIDDEN_SESSION_STATUS_TEXT_COLOR = (125, 125, 121)
VISIBLE_SESSION_PROJECT_COLOR = CLAUDE_MANILLA_COLOR
VISIBLE_SESSION_TINT_WEIGHT = 0.32
PENDING_CARD_TINT_WEIGHT = 0.3
MACHINE_WITHOUT_VISIBLE_SESSIONS_TINT_WEIGHT = 0.35
SWITCH_ON_TRACK_COLOR = CLAUDE_CLAY_COLOR
SWITCH_OFF_TRACK_COLOR = CLAUDE_SLATE_LIGHT_COLOR
SWITCH_OFF_TRACK_ON_MATCHING_BACKGROUND_COLOR = CLAUDE_SLATE_DARKEST_COLOR
SWITCH_TRACK_MINIMUM_BRIGHTNESS_DIFFERENCE = 60
TOGGLE_SWITCH_ON_KNOB_COLOR = CLAUDE_IVORY_COLOR
TOGGLE_SWITCH_OFF_KNOB_COLOR = CLAUDE_CLOUD_MEDIUM_COLOR
HIDDEN_SESSION_DOT_OUTLINE_COLOR = CLAUDE_IVORY_MEDIUM_COLOR
NEW_SESSION_STATUS_COLOR = CLAUDE_CLOUD_MEDIUM_COLOR
WORKING_SESSION_STATUS_COLOR = CLAUDE_SKY_LIGHT_COLOR
FINISHED_SESSION_STATUS_COLOR = CLAUDE_AMBER_COLOR
WAITING_SESSION_BACKGROUND_COLOR = CLAUDE_SLATE_MEDIUM_COLOR
SENT_BACKGROUND_COLOR = (58, 74, 38)
RELEASED_BACKGROUND_COLOR = CLAUDE_SLATE_LIGHT_COLOR
EMPTY_KEY_COLOR = (0, 0, 0)
UNKNOWN_MACHINE_COLOR = CLAUDE_CLOUD_DARK_COLOR
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
    "personal": MachineDisplay("PERSONAL", (118, 96, 166)),
    "trabajo": MachineDisplay("TRABAJO", (58, 118, 176)),
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
EMPTY_HOME_MASCOT_KEY_LOCATION = (1, 2)
EMPTY_HOME_CAPTION = "nada pendiente"
HOME_CLAUDE_KEY_LOCATION = (0, 2)
SESSIONS_PAUSED_HINT_KEY_ROWS = ((0, (2, 3)),)
SESSIONS_BACK_KEY_LOCATION = (0, 0)
SESSIONS_TITLE_KEY_LOCATION = (0, 1)
SESSIONS_LEGEND_ON_KEY_LOCATION = (0, 2)
SESSIONS_LEGEND_OFF_KEY_LOCATION = (0, 3)
SESSIONS_MACHINE_PAUSE_KEY_LOCATION = (0, 4)
HOME_LIST_LOCATIONS = tuple((row, column) for row in (1, 2) for column in ALL_COLUMNS)
REQUEST_KIND_LABELS = {"question": "pregunta", "permission": "permiso"}
SESSIONS_LEGEND_SWITCH_ON_TEXT = "te avisa aquí"
SESSIONS_LEGEND_SWITCH_OFF_TEXT = "solo en la terminal"
SESSIONS_BANNER_PAUSED_HINT = "Mac en pausa: todo queda en la terminal"
MACHINE_ROUTING_ON_TEXT = "Mac activa"
MACHINE_ROUTING_OFF_TEXT = "Mac en pausa"
AUTO_OPEN_ON_TEXT = "se abre sola"
AUTO_OPEN_OFF_TEXT = "no se abre"
SENT_SCREEN_CAPTION_KEY_LOCATION = (1, 2)
SENT_SCREEN_SYMBOL_KEY_LOCATION = (1, 1)
SENT_SCREEN_MACHINE_KEY_LOCATION = (1, 3)
SESSION_ACTIVITY_NEW = "new"
SESSION_ACTIVITY_WORKING = "working"
SESSION_ACTIVITY_FINISHED = "finished"
ACTIVITY_STATE_BY_HOOK_EVENT = {
    "UserPromptSubmit": SESSION_ACTIVITY_WORKING,
    "PermissionRequest": SESSION_ACTIVITY_WORKING,
    "Stop": SESSION_ACTIVITY_FINISHED,
}
SESSION_START_SOURCES_KEEPING_ACTIVITY = frozenset({"compact"})
TEAMMATE_COLORS = {
    "red": (239, 83, 80),
    "blue": (66, 165, 245),
    "green": (102, 187, 106),
    "yellow": (255, 213, 79),
    "purple": (171, 71, 188),
    "orange": (255, 152, 0),
    "pink": (240, 98, 146),
    "cyan": (38, 198, 218),
}


@dataclass(frozen=True)
class SessionStatusPresentation:
    text: str
    color: tuple
    shows_elapsed_time: bool
    demands_attention: bool


SESSION_STATUS_PRESENTATIONS = {
    SESSION_ACTIVITY_NEW: SessionStatusPresentation("nueva", NEW_SESSION_STATUS_COLOR, False, False),
    SESSION_ACTIVITY_WORKING: SessionStatusPresentation("trabajando", WORKING_SESSION_STATUS_COLOR, False, False),
    SESSION_ACTIVITY_FINISHED: SessionStatusPresentation("listo", FINISHED_SESSION_STATUS_COLOR, True, False),
    "question": SessionStatusPresentation("te pregunta", PENDING_ALERT_COLOR, False, True),
    "permission": SessionStatusPresentation("pide permiso", PENDING_ALERT_COLOR, False, True),
}


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
    elif not design.label_text:
        icon_size = ICON_KEY_SOLO_ICON_SIZE
        icon_top = (KEY_PIXEL_SIZE - icon_size) // 2
    icon_image = render_line_icon(design.icon_name, icon_size, design.icon_color)
    image.paste(icon_image, ((KEY_PIXEL_SIZE - icon_size) // 2, icon_top), icon_image)
    if design.label_text:
        label_font = load_font(NARROW_BOLD_FONT_PATH, ICON_KEY_LABEL_FONT_SIZE)
        draw_centered_single_line(drawing, design.label_text, label_font, ICON_KEY_LABEL_TOP, design.label_color)
    return image


def off_track_color_contrasting_with(background_color):
    brightness_difference = abs(sum(background_color) - sum(SWITCH_OFF_TRACK_COLOR))
    if brightness_difference >= SWITCH_TRACK_MINIMUM_BRIGHTNESS_DIFFERENCE:
        return SWITCH_OFF_TRACK_COLOR
    return SWITCH_OFF_TRACK_ON_MATCHING_BACKGROUND_COLOR


@lru_cache(maxsize=32)
def render_toggle_switch(switch_width, switch_height, switch_is_on, track_color):
    canvas_width = switch_width * ICON_SUPERSAMPLING_FACTOR
    canvas_height = switch_height * ICON_SUPERSAMPLING_FACTOR
    switch_image = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
    drawing = ImageDraw.Draw(switch_image)
    drawing.rounded_rectangle(
        [0, 0, canvas_width - 1, canvas_height - 1], radius=canvas_height // 2, fill=track_color
    )
    knob_inset = TOGGLE_SWITCH_KNOB_INSET * ICON_SUPERSAMPLING_FACTOR
    knob_diameter = canvas_height - 2 * knob_inset
    knob_left = canvas_width - knob_inset - knob_diameter if switch_is_on else knob_inset
    knob_color = TOGGLE_SWITCH_ON_KNOB_COLOR if switch_is_on else TOGGLE_SWITCH_OFF_KNOB_COLOR
    drawing.ellipse([knob_left, knob_inset, knob_left + knob_diameter, knob_inset + knob_diameter], fill=knob_color)
    return switch_image.resize((switch_width, switch_height), Image.LANCZOS)


@lru_cache(maxsize=32)
def render_status_dot(dot_diameter, fill_color, outline_color):
    canvas_size = dot_diameter * ICON_SUPERSAMPLING_FACTOR
    dot_image = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    drawing = ImageDraw.Draw(dot_image)
    outline_width = round(STATUS_DOT_OUTLINE_WIDTH * ICON_SUPERSAMPLING_FACTOR) if outline_color else 0
    drawing.ellipse(
        [0, 0, canvas_size - 1, canvas_size - 1], fill=fill_color, outline=outline_color, width=outline_width
    )
    return dot_image.resize((dot_diameter, dot_diameter), Image.LANCZOS)


def paste_centered_horizontally(image, overlay_image, vertical_position):
    image.paste(overlay_image, ((KEY_PIXEL_SIZE - overlay_image.width) // 2, vertical_position), overlay_image)


def fit_text_into_line_layouts(text, font_path, maximum_width, font_size_and_line_count_attempts):
    for allow_word_splitting in (False, True):
        for font_size, maximum_line_count in font_size_and_line_count_attempts:
            font = load_font(font_path, font_size)
            wrapped_lines = wrap_text_to_width(text, font, maximum_width, allow_word_splitting)
            if wrapped_lines is not None and len(wrapped_lines) <= maximum_line_count:
                return font, wrapped_lines
    last_font_size, last_maximum_line_count = font_size_and_line_count_attempts[-1]
    font = load_font(font_path, last_font_size)
    all_wrapped_lines = wrap_text_to_width(text, font, maximum_width, True)
    wrapped_lines = all_wrapped_lines[:last_maximum_line_count]
    if len(all_wrapped_lines) > last_maximum_line_count:
        wrapped_lines[-1] = ellipsize_to_width(wrapped_lines[-1] + " " + all_wrapped_lines[last_maximum_line_count], font, maximum_width)
    return font, wrapped_lines


def draw_single_line_at(drawing, text, font, horizontal_position, vertical_position, maximum_width, color):
    fitted_text = text if font.getlength(text) <= maximum_width else ellipsize_to_width(text, font, maximum_width)
    drawing.text((horizontal_position, vertical_position), fitted_text, font=font, fill=color)


def draw_centered_fitting_line(drawing, text, font_path, maximum_font_size, minimum_font_size, slot_top, color):
    available_width = KEY_PIXEL_SIZE - 2 * LABEL_HORIZONTAL_PADDING
    chosen_font = load_font(font_path, minimum_font_size)
    for font_size in range(maximum_font_size, minimum_font_size - 1, -1):
        candidate_font = load_font(font_path, font_size)
        if candidate_font.getlength(text) <= available_width:
            chosen_font = candidate_font
            break
    vertically_centered_top = slot_top + (maximum_font_size - chosen_font.size) // 2
    draw_centered_single_line(drawing, text, chosen_font, vertically_centered_top, color)


@dataclass(frozen=True)
class SessionKeyDesign:
    title_text: str
    project_text: str
    status_text: str
    status_color: tuple
    status_text_color: tuple
    background_color: tuple
    title_color: tuple
    project_color: tuple
    switch_is_on: bool
    switch_track_color: tuple
    teammate_color: tuple = None
    border_color: tuple = None
    shows_switch: bool = True
    project_text_is_bold: bool = False


@lru_cache(maxsize=256)
def render_session_key(design):
    image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), design.background_color)
    drawing = ImageDraw.Draw(image)
    if design.border_color is not None:
        drawing.rectangle(
            [0, 0, KEY_PIXEL_SIZE - 1, KEY_PIXEL_SIZE - 1], outline=design.border_color, width=SESSION_KEY_BORDER_WIDTH
        )
    if design.teammate_color is not None:
        drawing.rectangle([0, 0, TEAMMATE_STRIPE_WIDTH - 1, KEY_PIXEL_SIZE - 1], fill=design.teammate_color)
    content_left = SESSION_KEY_MARGIN
    content_width = KEY_PIXEL_SIZE - 2 * SESSION_KEY_MARGIN
    top_row_right_edge = KEY_PIXEL_SIZE - SESSION_KEY_MARGIN
    if design.shows_switch:
        switch_image = render_toggle_switch(
            SESSION_SWITCH_WIDTH, SESSION_SWITCH_HEIGHT, design.switch_is_on, design.switch_track_color
        )
        switch_left = KEY_PIXEL_SIZE - SESSION_KEY_MARGIN - SESSION_SWITCH_WIDTH
        image.paste(switch_image, (switch_left, SESSION_KEY_TOP_ROW_TOP), switch_image)
        top_row_right_edge = switch_left - SESSION_KEY_TOP_ROW_GAP
    project_font = load_font(
        label_font_path(design.project_text, design.project_text_is_bold), SESSION_KEY_SMALL_FONT_SIZE
    )
    draw_single_line_at(
        drawing,
        design.project_text,
        project_font,
        content_left,
        SESSION_KEY_TOP_ROW_TOP - 1,
        top_row_right_edge - content_left,
        design.project_color,
    )
    title_font, title_lines = fit_text_into_line_layouts(
        design.title_text,
        label_font_path(design.title_text, True),
        content_width,
        SESSION_TITLE_FONT_SIZE_AND_LINE_COUNT_ATTEMPTS,
    )
    title_line_spacing = SESSION_TITLE_LINE_SPACING_UP_TO_TWO_LINES if len(title_lines) <= 2 else 0
    title_line_height = title_font.size + title_line_spacing
    title_block_height = len(title_lines) * title_line_height
    title_top = SESSION_TITLE_AREA_TOP + (SESSION_TITLE_AREA_HEIGHT - title_block_height) // 2
    for line_position, line_text in enumerate(title_lines):
        drawing.text(
            (content_left, title_top + line_position * title_line_height),
            line_text,
            font=title_font,
            fill=design.title_color,
        )
    status_dot = render_status_dot(STATUS_DOT_DIAMETER, design.status_color, None)
    status_text_top = KEY_PIXEL_SIZE - SESSION_KEY_MARGIN - SESSION_KEY_SMALL_FONT_SIZE - 1
    status_dot_top = status_text_top + (SESSION_KEY_SMALL_FONT_SIZE + 2 - STATUS_DOT_DIAMETER) // 2 + 1
    image.paste(status_dot, (content_left, status_dot_top), status_dot)
    status_text_left = content_left + STATUS_DOT_DIAMETER + STATUS_DOT_TEXT_GAP
    status_font = load_font(label_font_path(design.status_text, False), SESSION_KEY_SMALL_FONT_SIZE)
    draw_single_line_at(
        drawing,
        design.status_text,
        status_font,
        status_text_left,
        status_text_top,
        KEY_PIXEL_SIZE - SESSION_KEY_MARGIN - status_text_left,
        design.status_text_color,
    )
    return image


@dataclass(frozen=True)
class MachineSummaryDesign:
    machine_label: str
    headline_text: str
    footer_text: str
    background_color: tuple
    session_dot_kinds: tuple
    headline_color: tuple = BODY_TEXT_COLOR
    footer_color: tuple = ACCENT_CAPTION_COLOR


def session_dot_image(session_dot_kind):
    if session_dot_kind == "alert":
        return render_status_dot(MACHINE_SESSION_DOT_DIAMETER, PENDING_ALERT_COLOR, None)
    if session_dot_kind == "on":
        return render_status_dot(MACHINE_SESSION_DOT_DIAMETER, ICON_COLOR, None)
    return render_status_dot(MACHINE_SESSION_DOT_DIAMETER, None, HIDDEN_SESSION_DOT_OUTLINE_COLOR)


@lru_cache(maxsize=64)
def render_machine_summary_key(design):
    image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), design.background_color)
    drawing = ImageDraw.Draw(image)
    caption_font = load_font(NARROW_BOLD_FONT_PATH, LABEL_CAPTION_FONT_SIZE)
    draw_centered_single_line(drawing, design.machine_label, caption_font, MACHINE_SUMMARY_CAPTION_TOP, ACCENT_CAPTION_COLOR)
    draw_centered_fitting_line(
        drawing,
        design.headline_text,
        label_font_path(design.headline_text, True),
        MACHINE_SUMMARY_HEADLINE_MAXIMUM_FONT_SIZE,
        MACHINE_SUMMARY_HEADLINE_MINIMUM_FONT_SIZE,
        MACHINE_SUMMARY_HEADLINE_TOP,
        design.headline_color,
    )
    sorted_dot_kinds = sorted(design.session_dot_kinds, key=SESSION_DOT_KIND_DISPLAY_ORDER.__getitem__)
    visible_dot_kinds = sorted_dot_kinds[:MAXIMUM_MACHINE_SESSION_DOTS]
    if visible_dot_kinds:
        dots_width = len(visible_dot_kinds) * MACHINE_SESSION_DOT_DIAMETER + (len(visible_dot_kinds) - 1) * MACHINE_SESSION_DOT_GAP
        dot_left = (KEY_PIXEL_SIZE - dots_width) // 2
        for session_dot_kind in visible_dot_kinds:
            dot_image = session_dot_image(session_dot_kind)
            image.paste(dot_image, (dot_left, MACHINE_SUMMARY_DOTS_TOP), dot_image)
            dot_left += MACHINE_SESSION_DOT_DIAMETER + MACHINE_SESSION_DOT_GAP
    footer_top = KEY_PIXEL_SIZE - LABEL_EDGE_MARGIN - MACHINE_KEY_FOOTER_MAXIMUM_FONT_SIZE - 1
    draw_centered_fitting_line(
        drawing,
        design.footer_text,
        label_font_path(design.footer_text, False),
        MACHINE_KEY_FOOTER_MAXIMUM_FONT_SIZE,
        MACHINE_KEY_FOOTER_MINIMUM_FONT_SIZE,
        footer_top,
        design.footer_color,
    )
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


@dataclass(frozen=True)
class OptionKeyDesign:
    option_number: int
    label_text: str
    multi_select: bool
    chosen: bool
    recommended: bool


def option_label_without_recommendation(label):
    return RECOMMENDED_SUFFIX_PATTERN.sub("", label).strip() or label


def option_key_design(option_index, label, multi_select, chosen):
    recommended = RECOMMENDED_SUFFIX_PATTERN.search(label) is not None
    clean_label = option_label_without_recommendation(label)
    return OptionKeyDesign(
        option_number=option_index + 1,
        label_text=clean_label,
        multi_select=multi_select,
        chosen=chosen,
        recommended=recommended,
    )


@lru_cache(maxsize=32)
def render_number_chip(number, diameter, chip_color, number_color):
    canvas_size = diameter * ICON_SUPERSAMPLING_FACTOR
    chip_image = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    drawing = ImageDraw.Draw(chip_image)
    drawing.ellipse([0, 0, canvas_size - 1, canvas_size - 1], fill=chip_color)
    number_font = load_font(BOLD_FONT_PATH, OPTION_NUMBER_FONT_SIZE * ICON_SUPERSAMPLING_FACTOR)
    drawing.text((canvas_size / 2, canvas_size / 2), str(number), font=number_font, fill=number_color, anchor="mm")
    return chip_image.resize((diameter, diameter), Image.LANCZOS)


@lru_cache(maxsize=4)
def render_option_checkbox(checked):
    canvas_size = OPTION_CHECKBOX_SIZE * ICON_SUPERSAMPLING_FACTOR
    corner_radius = OPTION_CHECKBOX_CORNER_RADIUS * ICON_SUPERSAMPLING_FACTOR
    checkbox_image = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    drawing = ImageDraw.Draw(checkbox_image)
    if checked:
        drawing.rounded_rectangle([0, 0, canvas_size - 1, canvas_size - 1], radius=corner_radius, fill=CLAUDE_IVORY_COLOR)
    else:
        drawing.rounded_rectangle(
            [0, 0, canvas_size - 1, canvas_size - 1],
            radius=corner_radius,
            outline=CLAUDE_CLOUD_LIGHT_COLOR,
            width=OPTION_CHECKBOX_OUTLINE_WIDTH * ICON_SUPERSAMPLING_FACTOR,
        )
    checkbox_image = checkbox_image.resize((OPTION_CHECKBOX_SIZE, OPTION_CHECKBOX_SIZE), Image.LANCZOS)
    if checked:
        check_size = OPTION_CHECKBOX_SIZE - 2 * OPTION_CHECKBOX_CHECK_INSET
        check_image = render_line_icon("check", check_size, OPTION_CHOSEN_COLOR)
        checkbox_image.alpha_composite(check_image, (OPTION_CHECKBOX_CHECK_INSET, OPTION_CHECKBOX_CHECK_INSET))
    return checkbox_image


@lru_cache(maxsize=256)
def render_option_key(design):
    background_color = OPTION_CHOSEN_COLOR if design.chosen else OPTION_BACKGROUND_COLOR
    image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), background_color)
    drawing = ImageDraw.Draw(image)
    if design.chosen:
        chip_color, number_color = CLAUDE_IVORY_COLOR, OPTION_CHOSEN_COLOR
    else:
        chip_color, number_color = OPTION_NUMBER_CHIP_COLOR, DARK_TEXT_COLOR
    number_chip = render_number_chip(design.option_number, OPTION_NUMBER_CHIP_DIAMETER, chip_color, number_color)
    image.paste(number_chip, (OPTION_KEY_MARGIN, OPTION_KEY_MARGIN), number_chip)
    marker_row_center = OPTION_KEY_MARGIN + OPTION_NUMBER_CHIP_DIAMETER / 2
    marker_right_edge = KEY_PIXEL_SIZE - OPTION_KEY_MARGIN
    if design.multi_select:
        checkbox_image = render_option_checkbox(design.chosen)
        checkbox_left = marker_right_edge - OPTION_CHECKBOX_SIZE
        image.paste(checkbox_image, (checkbox_left, round(marker_row_center - OPTION_CHECKBOX_SIZE / 2)), checkbox_image)
        marker_right_edge = checkbox_left - OPTION_MARKER_GAP
    if design.recommended:
        star_font = load_font(BOLD_FONT_PATH, OPTION_RECOMMENDED_FONT_SIZE)
        star_color = CLAUDE_IVORY_COLOR if design.chosen else RECOMMENDED_MARK_COLOR
        star_left = marker_right_edge - star_font.getlength(RECOMMENDED_MARK_TEXT)
        drawing.text((star_left, marker_row_center), RECOMMENDED_MARK_TEXT, font=star_font, fill=star_color, anchor="lm")
    label_font, label_lines = fit_text_into_line_layouts(
        design.label_text,
        label_font_path(design.label_text, True),
        KEY_PIXEL_SIZE - 2 * OPTION_KEY_MARGIN,
        OPTION_LABEL_FONT_SIZE_AND_LINE_COUNT_ATTEMPTS,
    )
    line_height = label_font.size + (OPTION_LABEL_LINE_SPACING if len(label_lines) <= 2 else 0)
    label_area_height = KEY_PIXEL_SIZE - OPTION_LABEL_AREA_TOP - OPTION_KEY_MARGIN
    label_block_top = OPTION_LABEL_AREA_TOP + (label_area_height - len(label_lines) * line_height) // 2
    label_color = CLAUDE_IVORY_COLOR if design.chosen else BODY_TEXT_COLOR
    for line_position, line_text in enumerate(label_lines):
        draw_centered_single_line(drawing, line_text, label_font, label_block_top + line_position * line_height, label_color)
    return image


@dataclass(frozen=True)
class MascotPose:
    lift_units: int = 0
    crouch_units: int = 0
    arms_raised: bool = False
    eyes_closed: bool = False


MASCOT_STANDING_POSE = MascotPose()
MASCOT_CROUCHING_POSE = MascotPose(crouch_units=1)
MASCOT_CHEERING_POSE = MascotPose(arms_raised=True)
MASCOT_SLEEPING_POSE = MascotPose(eyes_closed=True)
MASCOT_JUMP_ANIMATION_POSES = (
    MASCOT_STANDING_POSE,
    MASCOT_CROUCHING_POSE,
    MascotPose(lift_units=2),
    MascotPose(lift_units=4),
    MascotPose(lift_units=4),
    MascotPose(lift_units=2),
    MASCOT_CROUCHING_POSE,
    MASCOT_STANDING_POSE,
    MASCOT_STANDING_POSE,
    MASCOT_STANDING_POSE,
    MASCOT_STANDING_POSE,
    MASCOT_STANDING_POSE,
)


def fill_mascot_cells(drawing, pixel_unit, left_unit, top_unit, width_units, height_units, color):
    drawing.rectangle(
        [
            left_unit * pixel_unit,
            top_unit * pixel_unit,
            (left_unit + width_units) * pixel_unit - 1,
            (top_unit + height_units) * pixel_unit - 1,
        ],
        fill=color,
    )


@lru_cache(maxsize=64)
def render_claude_mascot(pixel_unit, pose, body_color):
    canvas = Image.new(
        "RGBA", (MASCOT_CANVAS_WIDTH_UNITS * pixel_unit, MASCOT_CANVAS_HEIGHT_UNITS * pixel_unit), (0, 0, 0, 0)
    )
    drawing = ImageDraw.Draw(canvas)
    leg_height_units = MASCOT_LEG_HEIGHT_UNITS - pose.crouch_units
    body_bottom_unit = MASCOT_CANVAS_HEIGHT_UNITS - leg_height_units
    body_height_units = MASCOT_BODY_HEIGHT_UNITS - pose.crouch_units
    body_top_unit = body_bottom_unit - body_height_units
    body_left_unit = MASCOT_BODY_LEFT_UNIT - pose.crouch_units
    body_width_units = MASCOT_BODY_WIDTH_UNITS + 2 * pose.crouch_units
    fill_mascot_cells(drawing, pixel_unit, body_left_unit, body_top_unit, body_width_units, body_height_units, body_color)
    if pose.arms_raised:
        arm_offset_units, arm_height_units = MASCOT_RAISED_ARM_TOP_OFFSET_UNITS, MASCOT_RAISED_ARM_HEIGHT_UNITS
    else:
        arm_offset_units, arm_height_units = MASCOT_RESTING_ARM_TOP_OFFSET_UNITS, MASCOT_ARM_HEIGHT_UNITS
    arm_top_unit = body_top_unit + arm_offset_units
    for arm_left_unit in (body_left_unit - MASCOT_ARM_WIDTH_UNITS, body_left_unit + body_width_units):
        fill_mascot_cells(
            drawing, pixel_unit, arm_left_unit, arm_top_unit, MASCOT_ARM_WIDTH_UNITS, arm_height_units, body_color
        )
    for leg_column_unit in MASCOT_LEG_COLUMN_UNITS:
        fill_mascot_cells(drawing, pixel_unit, leg_column_unit, body_bottom_unit, 1, leg_height_units, body_color)
    eye_height_units = MASCOT_CLOSED_EYE_HEIGHT_UNITS if pose.eyes_closed else MASCOT_OPEN_EYE_HEIGHT_UNITS
    eye_top_unit = body_top_unit + MASCOT_EYE_TOP_OFFSET_UNITS + MASCOT_OPEN_EYE_HEIGHT_UNITS - eye_height_units
    for eye_column_unit in MASCOT_EYE_COLUMN_UNITS:
        fill_mascot_cells(drawing, pixel_unit, eye_column_unit, eye_top_unit, 1, eye_height_units, MASCOT_EYE_COLOR)
    return canvas


def draw_mascot_shadow(drawing, pixel_unit, pose, ground_top, background_color, horizontal_center):
    full_shadow_width = MASCOT_BODY_WIDTH_UNITS * pixel_unit
    shrink_ratio = max(0.4, 1 - MASCOT_SHADOW_SHRINK_PER_LIFT_UNIT * pose.lift_units)
    shadow_width = full_shadow_width * shrink_ratio
    shadow_left = horizontal_center - shadow_width / 2
    shadow_color = blend_colors(MASCOT_SHADOW_COLOR, background_color, MASCOT_SHADOW_WEIGHT)
    drawing.ellipse(
        [shadow_left, ground_top - MASCOT_SHADOW_HEIGHT // 2, shadow_left + shadow_width, ground_top + MASCOT_SHADOW_HEIGHT // 2],
        fill=shadow_color,
    )


def paste_mascot_on_ground(
    image,
    pixel_unit,
    pose,
    ground_top,
    body_color=MASCOT_BODY_COLOR,
    background_color=None,
    horizontal_center=KEY_PIXEL_SIZE // 2,
):
    if background_color is not None:
        draw_mascot_shadow(ImageDraw.Draw(image), pixel_unit, pose, ground_top, background_color, horizontal_center)
    mascot_image = render_claude_mascot(pixel_unit, pose, body_color)
    mascot_left = horizontal_center - mascot_image.width // 2
    mascot_top = ground_top - mascot_image.height - pose.lift_units * pixel_unit
    image.paste(mascot_image, (mascot_left, mascot_top), mascot_image)


def draw_sleeping_marks(drawing, color):
    for font_size, horizontal_position, vertical_position in SLEEPING_MARK_PLACEMENTS:
        drawing.text((horizontal_position, vertical_position), "z", font=load_font(BOLD_FONT_PATH, font_size), fill=color)


@lru_cache(maxsize=16)
def render_mascot_key(pose, caption_text, background_color, caption_color, body_color=MASCOT_BODY_COLOR):
    image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), background_color)
    drawing = ImageDraw.Draw(image)
    ground_top = MASCOT_KEY_GROUND_TOP if caption_text else MASCOT_KEY_UNCAPTIONED_GROUND_TOP
    paste_mascot_on_ground(image, MASCOT_KEY_PIXEL_UNIT, pose, ground_top, body_color, background_color)
    if pose.eyes_closed:
        draw_sleeping_marks(drawing, caption_color)
    if caption_text:
        draw_centered_fitting_line(
            drawing,
            caption_text,
            NARROW_BOLD_FONT_PATH,
            MASCOT_KEY_CAPTION_MAXIMUM_FONT_SIZE,
            MASCOT_KEY_CAPTION_MINIMUM_FONT_SIZE,
            MASCOT_KEY_CAPTION_TOP,
            caption_color,
        )
    return image


@lru_cache(maxsize=8)
def render_sessions_title_key(machine_label, background_color, machine_label_color):
    image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), background_color)
    drawing = ImageDraw.Draw(image)
    paste_mascot_on_ground(
        image,
        SESSIONS_TITLE_MASCOT_PIXEL_UNIT,
        MASCOT_STANDING_POSE,
        SESSIONS_TITLE_MASCOT_GROUND_TOP,
        background_color=background_color,
    )
    title_font = load_font(NARROW_BOLD_FONT_PATH, SESSIONS_TITLE_FONT_SIZE)
    draw_centered_single_line(drawing, "SESIONES", title_font, SESSIONS_TITLE_LABEL_TOP, BODY_TEXT_COLOR)
    machine_font = load_font(NARROW_BOLD_FONT_PATH, LABEL_CAPTION_FONT_SIZE)
    draw_centered_single_line(drawing, machine_label, machine_font, SESSIONS_TITLE_MACHINE_TOP, machine_label_color)
    return image


@lru_cache(maxsize=16)
def render_switch_legend_key(switch_is_on, legend_text, background_color):
    image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), background_color)
    drawing = ImageDraw.Draw(image)
    track_color = SWITCH_ON_TRACK_COLOR if switch_is_on else off_track_color_contrasting_with(background_color)
    switch_image = render_toggle_switch(LEGEND_SWITCH_WIDTH, LEGEND_SWITCH_HEIGHT, switch_is_on, track_color)
    paste_centered_horizontally(image, switch_image, LEGEND_SWITCH_TOP)
    legend_font, legend_lines = fit_text_into_line_layouts(
        legend_text,
        NARROW_BOLD_FONT_PATH,
        KEY_PIXEL_SIZE - 2 * LABEL_HORIZONTAL_PADDING,
        LEGEND_TEXT_FONT_SIZE_AND_LINE_COUNT_ATTEMPTS,
    )
    legend_color = BODY_TEXT_COLOR if switch_is_on else MUTED_BODY_COLOR
    line_height = legend_font.size + 2
    for line_position, line_text in enumerate(legend_lines):
        draw_centered_single_line(
            drawing, line_text, legend_font, LEGEND_TEXT_AREA_TOP + line_position * line_height, legend_color
        )
    return image


@lru_cache(maxsize=16)
def render_switch_key(caption_text, switch_is_on, footer_text, background_color):
    image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), background_color)
    drawing = ImageDraw.Draw(image)
    caption_font = load_font(NARROW_BOLD_FONT_PATH, LABEL_CAPTION_FONT_SIZE)
    draw_centered_single_line(drawing, caption_text, caption_font, MACHINE_SUMMARY_CAPTION_TOP, ACCENT_CAPTION_COLOR)
    track_color = SWITCH_ON_TRACK_COLOR if switch_is_on else off_track_color_contrasting_with(background_color)
    switch_image = render_toggle_switch(MACHINE_SWITCH_WIDTH, MACHINE_SWITCH_HEIGHT, switch_is_on, track_color)
    paste_centered_horizontally(image, switch_image, MACHINE_SWITCH_TOP)
    footer_top = KEY_PIXEL_SIZE - LABEL_EDGE_MARGIN - MACHINE_KEY_FOOTER_MAXIMUM_FONT_SIZE - 1
    draw_centered_fitting_line(
        drawing,
        footer_text,
        NARROW_BOLD_FONT_PATH,
        MACHINE_KEY_FOOTER_MAXIMUM_FONT_SIZE,
        MACHINE_KEY_FOOTER_MINIMUM_FONT_SIZE,
        footer_top,
        BODY_TEXT_COLOR if switch_is_on else MUTED_BODY_COLOR,
    )
    return image


def draw_count_badge(drawing, count, badge_color, text_color, ring_color):
    badge_center_x = KEY_PIXEL_SIZE - MAIN_KEY_BADGE_RADIUS - MAIN_KEY_BADGE_EDGE_MARGIN
    badge_center_y = MAIN_KEY_BADGE_RADIUS + MAIN_KEY_BADGE_EDGE_MARGIN
    drawing.ellipse(
        [
            badge_center_x - MAIN_KEY_BADGE_RADIUS,
            badge_center_y - MAIN_KEY_BADGE_RADIUS,
            badge_center_x + MAIN_KEY_BADGE_RADIUS,
            badge_center_y + MAIN_KEY_BADGE_RADIUS,
        ],
        fill=badge_color,
        outline=ring_color,
        width=MAIN_KEY_BADGE_OUTLINE_WIDTH,
    )
    if count <= MAIN_KEY_BADGE_MAXIMUM_EXACT_COUNT:
        badge_text, badge_font_size = str(count), MAIN_KEY_BADGE_SINGLE_DIGIT_FONT_SIZE
    else:
        badge_text, badge_font_size = f"{MAIN_KEY_BADGE_MAXIMUM_EXACT_COUNT}+", MAIN_KEY_BADGE_OVERFLOW_FONT_SIZE
    badge_font = load_font(BOLD_FONT_PATH, badge_font_size)
    drawing.text((badge_center_x, badge_center_y), badge_text, font=badge_font, fill=text_color, anchor="mm")


MASCOT_JUMP_LOOP_SECONDS = len(MASCOT_JUMP_ANIMATION_POSES) * MAIN_KEY_ANIMATION_FRAME_SECONDS


def jump_pose_after(seconds_into_animation):
    frame_position = int(seconds_into_animation / MAIN_KEY_ANIMATION_FRAME_SECONDS) % len(MASCOT_JUMP_ANIMATION_POSES)
    return MASCOT_JUMP_ANIMATION_POSES[frame_position]


def main_key_mascot_pose_at(newest_request_created_at, now):
    if newest_request_created_at is None:
        return MASCOT_STANDING_POSE, False
    seconds_since_request = max(0.0, now - newest_request_created_at)
    if seconds_since_request < MAIN_KEY_ANIMATION_DURATION_SECONDS:
        return jump_pose_after(seconds_since_request), True
    seconds_into_reminder_cycle = (
        seconds_since_request - MAIN_KEY_ANIMATION_DURATION_SECONDS
    ) % MAIN_KEY_REMINDER_JUMP_INTERVAL_SECONDS
    if seconds_into_reminder_cycle < MASCOT_JUMP_LOOP_SECONDS:
        return jump_pose_after(seconds_into_reminder_cycle), True
    return MASCOT_STANDING_POSE, False


@lru_cache(maxsize=128)
def render_main_page_claude_key(pending_count, waiting_count, mascot_pose=MASCOT_STANDING_POSE):
    if not pending_count and not waiting_count:
        image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), IDLE_MAIN_KEY_COLOR)
        idle_mascot = render_claude_mascot(MAIN_KEY_IDLE_MASCOT_PIXEL_UNIT, MASCOT_STANDING_POSE, MASCOT_BODY_COLOR)
        headroom_height = MASCOT_HEADROOM_UNITS * MAIN_KEY_IDLE_MASCOT_PIXEL_UNIT
        visible_mascot_height = idle_mascot.height - headroom_height
        image.paste(
            idle_mascot,
            (
                (KEY_PIXEL_SIZE - idle_mascot.width) // 2,
                (KEY_PIXEL_SIZE - visible_mascot_height) // 2 - headroom_height,
            ),
            idle_mascot,
        )
        return image
    background_color = MAIN_KEY_PENDING_BACKGROUND_COLOR if pending_count else MAIN_KEY_WAITING_BACKGROUND_COLOR
    image = Image.new("RGB", (KEY_PIXEL_SIZE, KEY_PIXEL_SIZE), background_color)
    drawing = ImageDraw.Draw(image)
    if pending_count:
        drawing.rectangle(
            [0, 0, KEY_PIXEL_SIZE - 1, KEY_PIXEL_SIZE - 1], outline=PENDING_ALERT_COLOR, width=MAIN_KEY_BORDER_WIDTH
        )
    pose = mascot_pose if pending_count else MASCOT_STANDING_POSE
    paste_mascot_on_ground(
        image,
        MAIN_KEY_ALERT_MASCOT_PIXEL_UNIT,
        pose,
        MAIN_KEY_ALERT_MASCOT_GROUND_TOP,
        background_color=background_color,
        horizontal_center=MAIN_KEY_ALERT_MASCOT_HORIZONTAL_CENTER,
    )
    if pending_count:
        label_text, label_color = "RESPONDER", BODY_TEXT_COLOR
        draw_count_badge(drawing, pending_count, PENDING_ALERT_COLOR, CLAUDE_IVORY_COLOR, background_color)
    else:
        label_text, label_color = "LISTO", WAITING_ALERT_COLOR
        draw_count_badge(drawing, waiting_count, WAITING_ALERT_COLOR, DARK_TEXT_COLOR, background_color)
    label_font = load_font(NARROW_BOLD_FONT_PATH, MAIN_KEY_LABEL_FONT_SIZE)
    draw_centered_single_line(drawing, label_text, label_font, MAIN_KEY_LABEL_TOP, label_color)
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


def session_override_storage_key(session_key):
    machine, session_id = session_key
    return f"{machine}/{session_id}"


def parse_session_deck_overrides(stored_overrides):
    session_deck_overrides = {}
    if not isinstance(stored_overrides, dict):
        return session_deck_overrides
    for storage_key, stored_override in stored_overrides.items():
        machine, separator, session_id = str(storage_key).partition("/")
        if not separator or not session_id or normalize_machine_name(machine) is None:
            continue
        if not isinstance(stored_override, dict) or not isinstance(stored_override.get("enabled"), bool):
            continue
        stored_updated_at = stored_override.get("updated_at")
        session_deck_overrides[(machine, session_id)] = SessionDeckOverride(
            enabled=stored_override["enabled"],
            updated_at=float(stored_updated_at) if isinstance(stored_updated_at, (int, float)) else time.time(),
        )
    return session_deck_overrides


def describe_session_count(session_count):
    return "1 sesión" if session_count == 1 else f"{session_count} sesiones"


def describe_switched_on_sessions(switched_on_session_count, total_session_count):
    if switched_on_session_count == 0:
        return "apagada" if total_session_count == 1 else "todas apagadas"
    if switched_on_session_count == 1:
        return "1 encendida"
    return f"{switched_on_session_count} encendidas"


def activity_state_reported_by(request_body):
    hook_event_name = request_body.get("activity_event")
    if hook_event_name == "SessionStart":
        if request_body.get("session_start_source") in SESSION_START_SOURCES_KEEPING_ACTIVITY:
            return None
        return SESSION_ACTIVITY_NEW
    return ACTIVITY_STATE_BY_HOOK_EVENT.get(hook_event_name)


def readable_session_title(session_label, project):
    title = session_label or project
    if " " not in title:
        title = title.replace("-", " ").replace("_", " ")
    project_prefix = project.lower() + " "
    if title.lower().startswith(project_prefix) and len(title) > len(project_prefix):
        remaining_title = title[len(project_prefix) :]
        title = remaining_title[0].upper() + remaining_title[1:]
    return title


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
class KnownSession:
    machine: str
    session_id: str
    project: str
    session_label: str
    deck_enabled: bool
    registered_at: float
    last_seen_at: float
    activity_state: str
    activity_changed_at: float
    teammate_color: tuple


@dataclass
class SessionDeckOverride:
    enabled: bool
    updated_at: float


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
    shows_home_screen: bool = False


@dataclass(frozen=True)
class MainKeyAppearance:
    pending_count: int
    waiting_count: int
    mascot_pose: MascotPose


@lru_cache(maxsize=128)
def encode_main_key_appearance(appearance):
    data_url = encode_key_image_as_data_url(
        render_main_page_claude_key(appearance.pending_count, appearance.waiting_count, appearance.mascot_pose)
    )
    return data_url, hashlib.sha256(data_url.encode("ascii")).hexdigest()


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
        self.known_sessions_by_key = {}
        (
            self.routing_enabled_by_machine,
            self.auto_open_enabled,
            self.session_deck_overrides,
        ) = self.load_preferences()
        self.sessions_screen_machine = None
        self.sessions_list_page_index = 0
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
            "open_machine_sessions": self.press_open_machine_sessions,
            "sessions_next_list_page": self.press_sessions_next_list_page,
            "toggle_session_on_deck": self.press_toggle_session_on_deck,
        }

    def load_preferences(self):
        routing_enabled_by_machine = {machine: True for machine in KNOWN_MACHINE_DISPLAYS}
        auto_open_enabled = True
        try:
            stored_state = json.loads(self.state_file_path.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            return routing_enabled_by_machine, auto_open_enabled, {}
        if not isinstance(stored_state, dict):
            return routing_enabled_by_machine, auto_open_enabled, {}
        stored_routing = stored_state.get("routing_enabled_by_machine")
        if isinstance(stored_routing, dict):
            for machine, enabled in stored_routing.items():
                if normalize_machine_name(machine) and isinstance(enabled, bool):
                    routing_enabled_by_machine[machine] = enabled
        if isinstance(stored_state.get("auto_open_enabled"), bool):
            auto_open_enabled = stored_state["auto_open_enabled"]
        session_deck_overrides = parse_session_deck_overrides(stored_state.get("session_deck_overrides"))
        return routing_enabled_by_machine, auto_open_enabled, session_deck_overrides

    def save_preferences(self):
        temporary_state_path = self.state_file_path.with_suffix(".json.partial")
        stored_state = {
            "routing_enabled_by_machine": self.routing_enabled_by_machine,
            "auto_open_enabled": self.auto_open_enabled,
            "session_deck_overrides": {
                session_override_storage_key(session_key): {
                    "enabled": session_override.enabled,
                    "updated_at": session_override.updated_at,
                }
                for session_key, session_override in self.session_deck_overrides.items()
            },
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

    def initial_deck_visibility(self, session_key, request_body):
        stored_override = self.session_deck_overrides.get(session_key)
        if stored_override is not None:
            return stored_override.enabled
        return request_body.get("deck_enabled_by_environment") is True

    def register_session_activity(self, request_body, machine, session_id, reported_activity_state):
        session_key = (machine, session_id)
        now = time.monotonic()
        project = normalize_project_label(request_body.get("project"))
        session_label = normalize_optional_label(request_body.get("session_label"), MAXIMUM_SESSION_LABEL_CHARACTERS)
        teammate_color = TEAMMATE_COLORS.get(request_body.get("teammate_color"))
        known_session = self.known_sessions_by_key.get(session_key)
        if known_session is None:
            known_session = KnownSession(
                machine=machine,
                session_id=session_id,
                project=project,
                session_label=session_label,
                deck_enabled=self.initial_deck_visibility(session_key, request_body),
                registered_at=now,
                last_seen_at=now,
                activity_state=reported_activity_state or SESSION_ACTIVITY_NEW,
                activity_changed_at=now,
                teammate_color=teammate_color,
            )
            self.known_sessions_by_key[session_key] = known_session
            visibility_description = "on deck" if known_session.deck_enabled else "hidden"
            log_event(f"session {machine}/{session_id[:8]} {project} registered {visibility_description}")
            self.mark_state_changed()
            return known_session
        known_session.last_seen_at = now
        label_changed = known_session.project != project or (session_label and known_session.session_label != session_label)
        if label_changed:
            known_session.project = project
            known_session.session_label = session_label or known_session.session_label
            self.mark_state_changed()
        if teammate_color is not None and known_session.teammate_color != teammate_color:
            known_session.teammate_color = teammate_color
            self.mark_state_changed()
        if reported_activity_state and known_session.activity_state != reported_activity_state:
            known_session.activity_state = reported_activity_state
            known_session.activity_changed_at = now
            self.mark_state_changed()
        return known_session

    def session_is_on_deck(self, machine, session_id):
        known_session = self.known_sessions_by_key.get((machine, session_id))
        return known_session is not None and known_session.deck_enabled

    def visible_waiting_sessions(self):
        return [
            session
            for session in self.waiting_sessions_by_key.values()
            if self.session_is_on_deck(session.machine, session.session_id)
        ]

    def known_sessions_of_machine(self, machine):
        machine_sessions = [session for session in self.known_sessions_by_key.values() if session.machine == machine]
        return sorted(machine_sessions, key=lambda session: session.registered_at)

    def pending_requests_of_session(self, session_key):
        return [
            request
            for request in self.requests_by_id.values()
            if request.status == "pending" and (request.machine, request.session_id) == session_key
        ]

    def queue_parked_requests_of_session(self, session_key):
        for request in self.pending_requests_of_session(session_key):
            if request.request_id not in self.queued_request_ids:
                self.queued_request_ids.append(request.request_id)
        self.queued_request_ids.sort(key=lambda request_id: self.requests_by_id[request_id].created_at)

    def park_queued_requests_of_session(self, session_key):
        session_request_ids = {request.request_id for request in self.pending_requests_of_session(session_key)}
        self.queued_request_ids = [
            request_id for request_id in self.queued_request_ids if request_id not in session_request_ids
        ]
        if self.focused_request_id in session_request_ids:
            self.focused_request_id = None
            self.confirm_choice = None

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
            known_session = self.register_session_activity(
                request_body, machine, session_id, SESSION_ACTIVITY_WORKING
            )
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
            self.remove_waiting_session((machine, session_id))
            if not known_session.deck_enabled:
                self.mark_state_changed()
                log_event(f"request {request.request_id[:8]} {kind} from {machine}/{request.project} parked (session hidden)")
                return {"status": "pending", "request_id": request.request_id}
            self.queued_request_ids.append(request.request_id)
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
            self.register_session_activity(request_body, machine, session_id, SESSION_ACTIVITY_FINISHED)
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
            self.register_session_activity(
                request_body, machine, session_id, activity_state_reported_by(request_body)
            )
            self.withdraw_requests_resolved_in_terminal(machine, session_id)
            self.remove_waiting_session((machine, session_id))

    def mark_session_ended(self, request_body):
        machine = normalize_machine_name(request_body.get("machine"))
        session_id = request_body.get("session_id")
        if machine is None or not isinstance(session_id, str):
            raise InvalidRequestBody("machine and session_id are required")
        session_key = (machine, session_id)
        with self.condition:
            for request in self.pending_requests_of_session(session_key):
                self.withdraw_request_from_deck(request, "resolved_in_terminal")
            self.remove_waiting_session(session_key)
            if self.known_sessions_by_key.pop(session_key, None) is not None:
                log_event(f"session {machine}/{session_id[:8]} ended")
            if self.session_deck_overrides.pop(session_key, None) is not None:
                self.save_preferences()
            self.mark_state_changed()

    def health_summary(self):
        with self.condition:
            return {
                "ok": True,
                "companion_reachable": self.companion_is_reachable,
                "pending_requests": len(self.queued_request_ids),
                "parked_requests": sum(
                    1
                    for request in self.requests_by_id.values()
                    if request.status == "pending" and request.request_id not in self.queued_request_ids
                ),
                "waiting_sessions": len(self.waiting_sessions_by_key),
                "waiting_sessions_on_deck": len(self.visible_waiting_sessions()),
                "known_sessions": len(self.known_sessions_by_key),
                "sessions_on_deck": sum(1 for session in self.known_sessions_by_key.values() if session.deck_enabled),
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
        if self.screen in ("confirm", "reading", "sessions"):
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
            for request in list(self.requests_by_id.values()):
                if request.status == "pending" and request.machine == machine:
                    self.withdraw_request_from_deck(request, "released")
        log_event(f"routing for {machine} {'enabled' if routing_enabled else 'paused'}")
        self.mark_state_changed()

    def press_toggle_auto_open(self, unused_argument):
        self.auto_open_enabled = not self.auto_open_enabled
        self.save_preferences()
        log_event(f"auto open {'enabled' if self.auto_open_enabled else 'disabled'}")
        self.mark_state_changed()

    def press_open_waiting_reading(self, session_key):
        if session_key not in self.waiting_sessions_by_key or not self.session_is_on_deck(*session_key):
            return
        self.reading_context = ReadingContext("waiting", session_key, 0, "home")
        self.transition_to_screen("reading")

    def press_dismiss_waiting_session(self, session_key):
        self.waiting_sessions_by_key.pop(session_key, None)
        self.reading_context = None
        self.transition_to_screen("home")

    def press_open_machine_sessions(self, machine):
        self.sessions_screen_machine = machine
        self.sessions_list_page_index = 0
        self.confirm_choice = None
        self.reading_context = None
        self.transition_to_screen("sessions")

    def press_sessions_next_list_page(self, unused_argument):
        self.sessions_list_page_index += 1
        self.mark_state_changed()

    def press_toggle_session_on_deck(self, session_key):
        known_session = self.known_sessions_by_key.get(session_key)
        if known_session is None:
            return
        known_session.deck_enabled = not known_session.deck_enabled
        self.session_deck_overrides[session_key] = SessionDeckOverride(known_session.deck_enabled, time.time())
        self.save_preferences()
        if known_session.deck_enabled:
            self.queue_parked_requests_of_session(session_key)
        else:
            self.park_queued_requests_of_session(session_key)
        visibility_description = "shown on deck" if known_session.deck_enabled else "hidden from deck"
        log_event(f"session {known_session.machine}/{known_session.session_id[:8]} {visibility_description}")
        self.mark_state_changed()

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
            self.prune_stale_sessions(now)
            if self.screen == "sent" and now >= self.sent_screen_visible_until:
                self.focus_next_request_or_return_home()
            if now - self.last_time_label_refresh_at >= TIME_LABEL_REFRESH_SECONDS:
                self.last_time_label_refresh_at = now
                self.mark_state_changed()

    def prune_stale_sessions(self, now):
        for session_key, known_session in list(self.known_sessions_by_key.items()):
            session_is_stale = now - known_session.last_seen_at > KNOWN_SESSION_RETENTION_SECONDS
            if session_is_stale and not self.pending_requests_of_session(session_key):
                self.known_sessions_by_key.pop(session_key)
                log_event(f"session {known_session.machine}/{known_session.session_id[:8]} forgotten after inactivity")
                self.mark_state_changed()
        wall_clock_now = time.time()
        expired_override_keys = [
            session_key
            for session_key, session_override in self.session_deck_overrides.items()
            if session_key not in self.known_sessions_by_key
            and wall_clock_now - session_override.updated_at > SESSION_DECK_OVERRIDE_RETENTION_SECONDS
        ]
        for session_key in expired_override_keys:
            self.session_deck_overrides.pop(session_key)
        if expired_override_keys:
            self.save_preferences()

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
            waiting_count = len(self.visible_waiting_sessions())
            newest_request_created_at = max(
                (self.requests_by_id[request_id].created_at for request_id in self.queued_request_ids), default=None
            )
            return pending_count, waiting_count, newest_request_created_at

    def current_main_key_appearance(self):
        pending_count, waiting_count, newest_request_created_at = self.main_page_key_alert_state()
        mascot_pose, is_animating = main_key_mascot_pose_at(newest_request_created_at, time.monotonic())
        return MainKeyAppearance(pending_count, waiting_count, mascot_pose), is_animating

    def build_main_page_key_image(self):
        appearance, unused_is_animating = self.current_main_key_appearance()
        return render_main_page_claude_key(appearance.pending_count, appearance.waiting_count, appearance.mascot_pose)

    def build_deck_frame(self):
        with self.condition:
            frame_builder = self.select_frame_builder()
            key_images, key_actions = frame_builder()
            for row in range(DECK_ROW_COUNT):
                for column in range(DECK_COLUMN_COUNT):
                    key_images.setdefault((row, column), empty_key_image())
            return DeckFrame(
                key_images=key_images,
                key_actions=key_actions,
                main_page_key_image=self.build_main_page_key_image(),
                view_token=self.view_token,
                state_version=self.state_version,
                shows_home_screen=frame_builder == self.build_home_frame,
            )

    def reading_source_is_available(self):
        if self.reading_context is None:
            return False
        if self.reading_context.source_kind == "request":
            request = self.requests_by_id.get(self.reading_context.source_key)
            return request is not None and request.status == "pending" and request.request_id in self.queued_request_ids
        session_key = self.reading_context.source_key
        return session_key in self.waiting_sessions_by_key and self.session_is_on_deck(*session_key)

    def select_frame_builder(self):
        if self.screen == "sent":
            return self.build_sent_frame
        if self.screen == "sessions" and self.sessions_screen_machine is not None:
            return self.build_sessions_frame
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
            presentation = SESSION_STATUS_PRESENTATIONS[request.kind]
            list_entries.append(
                (
                    SessionKeyDesign(
                        title_text=readable_session_title(request.session_label, request.project),
                        project_text=display.label,
                        status_text=presentation.text,
                        status_color=presentation.color,
                        status_text_color=presentation.color,
                        background_color=blend_colors(PENDING_ALERT_COLOR, PANEL_BACKGROUND_COLOR, PENDING_CARD_TINT_WEIGHT),
                        title_color=CLAUDE_IVORY_COLOR,
                        project_color=VISIBLE_SESSION_PROJECT_COLOR,
                        switch_is_on=True,
                        switch_track_color=SWITCH_ON_TRACK_COLOR,
                        teammate_color=display.color,
                        border_color=PENDING_ALERT_COLOR,
                        shows_switch=False,
                        project_text_is_bold=True,
                    ),
                    ("focus_request_by_id", request_id),
                )
            )
        waiting_sessions = sorted(
            self.visible_waiting_sessions(), key=lambda session: session.waiting_since, reverse=True
        )
        finished_presentation = SESSION_STATUS_PRESENTATIONS[SESSION_ACTIVITY_FINISHED]
        for session in waiting_sessions:
            display = machine_display_for(session.machine)
            list_entries.append(
                (
                    SessionKeyDesign(
                        title_text=readable_session_title(session.session_label, session.project),
                        project_text=display.label,
                        status_text=f"{finished_presentation.text} · {describe_elapsed_time(now - session.waiting_since)}",
                        status_color=finished_presentation.color,
                        status_text_color=finished_presentation.color,
                        background_color=WAITING_SESSION_BACKGROUND_COLOR,
                        title_color=BODY_TEXT_COLOR,
                        project_color=MUTED_BODY_COLOR,
                        switch_is_on=True,
                        switch_track_color=SWITCH_ON_TRACK_COLOR,
                        teammate_color=display.color,
                        shows_switch=False,
                        project_text_is_bold=True,
                    ),
                    ("open_waiting_reading", (session.machine, session.session_id)),
                )
            )
        return list_entries

    def place_paged_list(self, key_images, key_actions, list_entries, page_index, next_page_action_name):
        if len(list_entries) <= len(HOME_LIST_LOCATIONS):
            visible_entries = list_entries
        else:
            entries_per_page = len(HOME_LIST_LOCATIONS) - 1
            page_count = math.ceil(len(list_entries) / entries_per_page)
            page_number = page_index % page_count
            first_entry_position = page_number * entries_per_page
            visible_entries = list_entries[first_entry_position : first_entry_position + entries_per_page]
            more_location = HOME_LIST_LOCATIONS[-1]
            key_images[more_location] = navigation_key_image(
                "chevron_right", "MÁS", caption=f"{page_number + 1}/{page_count}"
            )
            key_actions[more_location] = (next_page_action_name, None)
        for location, (design, action) in zip(HOME_LIST_LOCATIONS, visible_entries):
            key_images[location] = render_session_key(design) if isinstance(design, SessionKeyDesign) else render_label_key(design)
            key_actions[location] = action

    def session_dot_kind(self, known_session):
        session_key = (known_session.machine, known_session.session_id)
        if self.pending_requests_of_session(session_key):
            return "alert"
        return "on" if known_session.deck_enabled else "off"

    def machine_sessions_key_image(self, machine):
        display = machine_display_for(machine)
        machine_sessions = self.known_sessions_of_machine(machine)
        switched_on_session_count = sum(1 for session in machine_sessions if session.deck_enabled)
        dimmed_machine_color = blend_colors(display.color, PANEL_BACKGROUND_COLOR, MACHINE_WITHOUT_VISIBLE_SESSIONS_TINT_WEIGHT)
        session_dot_kinds = tuple(self.session_dot_kind(session) for session in machine_sessions)
        if not self.routing_enabled_by_machine.get(machine, True):
            design = MachineSummaryDesign(
                machine_label=display.label,
                headline_text="en pausa",
                footer_text=describe_session_count(len(machine_sessions)),
                background_color=PAUSED_MACHINE_COLOR,
                session_dot_kinds=session_dot_kinds,
                headline_color=MUTED_BODY_COLOR,
                footer_color=MUTED_BODY_COLOR,
            )
        elif not machine_sessions:
            design = MachineSummaryDesign(
                machine_label=display.label,
                headline_text="sin sesiones",
                footer_text="",
                background_color=dimmed_machine_color,
                session_dot_kinds=(),
                headline_color=MUTED_BODY_COLOR,
            )
        else:
            design = MachineSummaryDesign(
                machine_label=display.label,
                headline_text=describe_session_count(len(machine_sessions)),
                footer_text=describe_switched_on_sessions(switched_on_session_count, len(machine_sessions)),
                background_color=display.color if switched_on_session_count else dimmed_machine_color,
                session_dot_kinds=session_dot_kinds,
            )
        return render_machine_summary_key(design)

    def build_home_frame(self):
        key_images = {}
        key_actions = {}
        now = time.monotonic()
        for column, machine in enumerate(KNOWN_MACHINE_DISPLAYS):
            key_images[(0, column)] = self.machine_sessions_key_image(machine)
            key_actions[(0, column)] = ("open_machine_sessions", machine)
        key_images[HOME_CLAUDE_KEY_LOCATION] = self.build_main_page_key_image()
        if self.queued_request_ids:
            key_actions[HOME_CLAUDE_KEY_LOCATION] = ("focus_first_request", None)
        key_images[(0, 3)] = render_switch_key(
            "AUTO-ABRIR",
            self.auto_open_enabled,
            AUTO_OPEN_ON_TEXT if self.auto_open_enabled else AUTO_OPEN_OFF_TEXT,
            NAVIGATION_COLOR,
        )
        key_actions[(0, 3)] = ("toggle_auto_open", None)
        key_images[(0, 4)] = navigation_key_image("exit", "SALIR")
        key_actions[(0, 4)] = ("leave_deck", None)
        list_entries = self.build_home_list_entries(now)
        if not list_entries:
            key_images[EMPTY_HOME_MASCOT_KEY_LOCATION] = render_mascot_key(
                MASCOT_SLEEPING_POSE, EMPTY_HOME_CAPTION, EMPTY_KEY_COLOR, MUTED_TEXT_COLOR, MASCOT_SLEEPING_BODY_COLOR
            )
            return key_images, key_actions
        self.place_paged_list(key_images, key_actions, list_entries, self.home_list_page_index, "home_next_list_page")
        return key_images, key_actions

    def session_status_text_and_presentation(self, known_session, now):
        session_key = (known_session.machine, known_session.session_id)
        pending_requests = sorted(self.pending_requests_of_session(session_key), key=lambda request: request.created_at)
        if pending_requests:
            presentation = SESSION_STATUS_PRESENTATIONS[pending_requests[0].kind]
        else:
            presentation = SESSION_STATUS_PRESENTATIONS.get(
                known_session.activity_state, SESSION_STATUS_PRESENTATIONS[SESSION_ACTIVITY_NEW]
            )
        if not presentation.shows_elapsed_time:
            return presentation.text, presentation
        elapsed_description = describe_elapsed_time(now - known_session.activity_changed_at)
        return f"{presentation.text} · {elapsed_description}", presentation

    def session_toggle_list_entry(self, known_session, now):
        session_key = (known_session.machine, known_session.session_id)
        display = machine_display_for(known_session.machine)
        status_text, presentation = self.session_status_text_and_presentation(known_session, now)
        title_text = readable_session_title(known_session.session_label, known_session.project)
        if known_session.deck_enabled:
            design = SessionKeyDesign(
                title_text=title_text,
                project_text=known_session.project,
                status_text=status_text,
                status_color=presentation.color,
                status_text_color=presentation.color if presentation.demands_attention else BODY_TEXT_COLOR,
                background_color=blend_colors(display.color, PANEL_BACKGROUND_COLOR, VISIBLE_SESSION_TINT_WEIGHT),
                title_color=BODY_TEXT_COLOR,
                project_color=VISIBLE_SESSION_PROJECT_COLOR,
                switch_is_on=True,
                switch_track_color=SWITCH_ON_TRACK_COLOR,
                teammate_color=known_session.teammate_color,
                border_color=PENDING_ALERT_COLOR if presentation.demands_attention else None,
            )
        else:
            design = SessionKeyDesign(
                title_text=title_text,
                project_text=known_session.project,
                status_text=status_text,
                status_color=presentation.color,
                status_text_color=presentation.color if presentation.demands_attention else HIDDEN_SESSION_STATUS_TEXT_COLOR,
                background_color=HIDDEN_SESSION_BACKGROUND_COLOR,
                title_color=HIDDEN_SESSION_TITLE_COLOR,
                project_color=HIDDEN_SESSION_PROJECT_COLOR,
                switch_is_on=False,
                switch_track_color=SWITCH_OFF_TRACK_COLOR,
                teammate_color=known_session.teammate_color,
            )
        return design, ("toggle_session_on_deck", session_key)

    def build_sessions_frame(self):
        machine = self.sessions_screen_machine
        display = machine_display_for(machine)
        routing_enabled = self.routing_enabled_by_machine.get(machine, True)
        banner_background_color = banner_background_for(display)
        if routing_enabled:
            key_images = {
                SESSIONS_LEGEND_ON_KEY_LOCATION: render_switch_legend_key(
                    True, SESSIONS_LEGEND_SWITCH_ON_TEXT, banner_background_color
                ),
                SESSIONS_LEGEND_OFF_KEY_LOCATION: render_switch_legend_key(
                    False, SESSIONS_LEGEND_SWITCH_OFF_TEXT, banner_background_color
                ),
            }
        else:
            key_images = render_text_panel(
                (TextParagraph(SESSIONS_BANNER_PAUSED_HINT, WAITING_ALERT_COLOR),),
                SESSIONS_PAUSED_HINT_KEY_ROWS,
                banner_background_color,
            )
        key_images[SESSIONS_TITLE_KEY_LOCATION] = render_sessions_title_key(
            display.label, banner_background_color, blend_colors(display.color, CLAUDE_IVORY_COLOR, 0.45)
        )
        key_actions = {}
        key_images[SESSIONS_BACK_KEY_LOCATION] = navigation_key_image("back", "ATRÁS")
        key_actions[SESSIONS_BACK_KEY_LOCATION] = ("show_home", None)
        key_images[SESSIONS_MACHINE_PAUSE_KEY_LOCATION] = render_switch_key(
            display.label,
            routing_enabled,
            MACHINE_ROUTING_ON_TEXT if routing_enabled else MACHINE_ROUTING_OFF_TEXT,
            display.color if routing_enabled else PAUSED_MACHINE_COLOR,
        )
        key_actions[SESSIONS_MACHINE_PAUSE_KEY_LOCATION] = ("toggle_machine_routing", machine)
        now = time.monotonic()
        list_entries = [
            self.session_toggle_list_entry(session, now) for session in self.known_sessions_of_machine(machine)
        ]
        if not list_entries:
            key_images.update(
                render_text_panel(
                    (TextParagraph(f"No hay sesiones abiertas en {display.label}", MUTED_TEXT_COLOR),),
                    EMPTY_HOME_MESSAGE_KEY_ROWS,
                    EMPTY_KEY_COLOR,
                )
            )
            return key_images, key_actions
        self.place_paged_list(
            key_images, key_actions, list_entries, self.sessions_list_page_index, "sessions_next_list_page"
        )
        return key_images, key_actions

    def add_request_navigation_row(self, key_images, key_actions):
        key_images[(2, 0)] = navigation_key_image("exit", "SALIR")
        key_actions[(2, 0)] = ("leave_deck", None)
        key_images[(2, 1)] = navigation_key_image("full_text", "VER TODO")
        key_actions[(2, 1)] = ("open_request_reading", None)
        other_request_count = len(self.queued_request_ids) - 1
        if other_request_count > 0:
            key_images[(2, 2)] = accent_key_image(
                "skip_forward", "SIGUIENTE", PRIMARY_ACTION_COLOR, caption=f"+{other_request_count} EN COLA"
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
            key_images[location] = render_option_key(
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
                TextParagraph(option_label_without_recommendation(option["label"]), BODY_TEXT_COLOR, True),
            ]
            if option["description"]:
                paragraphs.append(TextParagraph(option["description"], MUTED_BODY_COLOR))
            return paragraphs
        if choice["kind"] == "multi":
            options = self.current_question(request)["options"]
            chosen_labels = [
                option_label_without_recommendation(options[option_index]["label"])
                for option_index in sorted(request.multi_select_choices)
            ]
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
            send_caption, send_color = "RESPUESTA", PRIMARY_ACTION_COLOR
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
        if answered:
            key_images[SENT_SCREEN_SYMBOL_KEY_LOCATION] = render_mascot_key(
                MASCOT_CHEERING_POSE, "", background_color, BODY_TEXT_COLOR
            )
        else:
            key_images[SENT_SCREEN_SYMBOL_KEY_LOCATION] = render_icon_key(
                IconKeyDesign(icon_name="terminal", label_text="", background_color=background_color)
            )
        key_images[SENT_SCREEN_CAPTION_KEY_LOCATION] = render_label_key(
            LabelKeyDesign(
                primary_text="ENVIADO" if answered else "EN LA TERMINAL",
                background_color=background_color,
                primary_color=CLAUDE_IVORY_COLOR,
                maximum_font_size=16,
            )
        )
        key_images[SENT_SCREEN_MACHINE_KEY_LOCATION] = render_label_key(
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
        self.main_key_is_animating = False
        self.push_executor = ThreadPoolExecutor(max_workers=PUSH_WORKER_COUNT)

    def current_loop_interval_seconds(self):
        return MAIN_KEY_ANIMATION_FRAME_SECONDS if self.main_key_is_animating else RENDER_LOOP_INTERVAL_SECONDS

    def run_forever(self):
        while True:
            self.coordinator.render_wakeup_event.wait(timeout=self.current_loop_interval_seconds())
            self.coordinator.render_wakeup_event.clear()
            try:
                self.coordinator.run_periodic_maintenance()
                self.probe_companion_health_when_due()
                self.render_when_needed()
                self.refresh_main_key_animation()
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

    def claude_key_locations_to_animate(self):
        locations = [(MAIN_PAGE_NUMBER, MAIN_PAGE_CLAUDE_KEY_ROW, MAIN_PAGE_CLAUDE_KEY_COLUMN)]
        displayed_frame = self.coordinator.last_displayed_frame
        if displayed_frame is not None and displayed_frame.shows_home_screen:
            locations.append((CLAUDE_PAGE_NUMBER, *HOME_CLAUDE_KEY_LOCATION))
        return locations

    def refresh_main_key_animation(self):
        appearance, self.main_key_is_animating = self.coordinator.current_main_key_appearance()
        data_url, digest = encode_main_key_appearance(appearance)
        for location in self.claude_key_locations_to_animate():
            if self.pushed_digest_by_location.get(location) == digest:
                continue
            if self.push_key_image(location, data_url):
                self.pushed_digest_by_location[location] = digest

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
        frame = self.coordinator.build_deck_frame()
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
        if parsed_url.path == "/api/sessions/ended":
            self.coordinator.mark_session_ended(self.read_json_body())
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
