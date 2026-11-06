import json
import secrets
import sqlite3
import string
import sys

DATABASE_PATH = sys.argv[1]
COORDINATOR_BASE_URL = "http://127.0.0.1:8791"
CLAUDE_PAGE_NUMBER = 26
JUMP_CONTROL_PAGE_NUMBER = 27
MAIN_PAGE_NUMBER = 1
MAIN_PAGE_CLAUDE_KEY_ROW = "1"
MAIN_PAGE_CLAUDE_KEY_COLUMN = "3"
DECK_ROW_COUNT = 3
DECK_COLUMN_COUNT = 5
JUMP_TARGET_VARIABLE_NAME = "claude_deck_target_page"
EXEC_TIMEOUT_MILLISECONDS = 3000
CURL_MAXIMUM_SECONDS = 2
WHITE_COLOR = 16777215
BLACK_COLOR = 0
CLAUDE_ORANGE_COLOR = 0xD97757
NANOID_ALPHABET = string.ascii_letters + string.digits + "_-"
NANOID_LENGTH = 21


def generate_nanoid():
    return "".join(secrets.choice(NANOID_ALPHABET) for _ in range(NANOID_LENGTH))


def plain_option(value):
    return {"value": value, "isExpression": False}


def build_action(definition_id, options):
    return {
        "id": generate_nanoid(),
        "definitionId": definition_id,
        "connectionId": "internal",
        "options": options,
        "upgradeIndex": 0,
        "type": "action",
    }


def build_curl_exec_action(coordinator_path):
    command = f"curl -s -m {CURL_MAXIMUM_SECONDS} -X POST {COORDINATOR_BASE_URL}{coordinator_path}"
    return build_action(
        "exec",
        {
            "path": plain_option(command),
            "cwd": plain_option(""),
            "timeout": plain_option(EXEC_TIMEOUT_MILLISECONDS),
            "targetVariable": plain_option(None),
        },
    )


def build_set_page_action(surface_id, page_value, page_is_expression):
    return build_action(
        "set_page",
        {
            "surfaceId": plain_option(surface_id),
            "page": {"value": page_value, "isExpression": page_is_expression},
        },
    )


def build_button(text, background_color, down_actions):
    return {
        "type": "button",
        "style": {
            "text": text,
            "textExpression": False,
            "size": 14,
            "alignment": "center:center",
            "pngalignment": "center:center",
            "color": WHITE_COLOR,
            "bgcolor": background_color,
            "show_topbar": False,
        },
        "options": {"stepProgression": "auto", "stepExpression": "", "rotaryActions": False},
        "feedbacks": [],
        "steps": {
            "0": {
                "action_sets": {"down": down_actions, "up": []},
                "options": {"runWhileHeld": []},
            }
        },
        "localVariables": [],
    }


def find_stream_deck_surface_id(connection):
    surface_ids = [row[0] for row in connection.execute("select id from surfaces")]
    stream_deck_surface_ids = [surface_id for surface_id in surface_ids if surface_id.startswith("streamdeck:")]
    if len(stream_deck_surface_ids) != 1:
        raise SystemExit(f"expected one Stream Deck surface, found {surface_ids}")
    return stream_deck_surface_ids[0]


def insert_control(connection, control):
    control_id = f"bank:{generate_nanoid()}"
    connection.execute("insert into controls (id, value) values (?, ?)", (control_id, json.dumps(control)))
    return control_id


def insert_page(connection, page_number, page_name, controls_by_row):
    page = {"id": generate_nanoid(), "name": page_name, "controls": controls_by_row}
    connection.execute("insert into pages (id, value) values (?, ?)", (page_number, json.dumps(page)))


def ensure_pages_are_free(connection):
    existing_page_numbers = {int(row[0]) for row in connection.execute("select id from pages")}
    occupied = existing_page_numbers & {CLAUDE_PAGE_NUMBER, JUMP_CONTROL_PAGE_NUMBER}
    if occupied:
        raise SystemExit(f"pages already exist: {sorted(occupied)}")
    expected_previous_pages = set(range(1, CLAUDE_PAGE_NUMBER))
    if not expected_previous_pages <= existing_page_numbers:
        raise SystemExit(f"missing pages before {CLAUDE_PAGE_NUMBER}: {sorted(expected_previous_pages - existing_page_numbers)}")


def install_claude_page(connection):
    controls_by_row = {}
    for row_number in range(DECK_ROW_COUNT):
        controls_by_row[str(row_number)] = {}
        for column_number in range(DECK_COLUMN_COUNT):
            control = build_button("", BLACK_COLOR, [build_curl_exec_action(f"/deck/press/{row_number}/{column_number}")])
            controls_by_row[str(row_number)][str(column_number)] = insert_control(connection, control)
    insert_page(connection, CLAUDE_PAGE_NUMBER, "CLAUDE", controls_by_row)


def install_jump_control_page(connection, stream_deck_surface_id):
    jump_action = build_set_page_action(stream_deck_surface_id, f"$(custom:{JUMP_TARGET_VARIABLE_NAME})", True)
    jump_control_id = insert_control(connection, build_button("SALTO", BLACK_COLOR, [jump_action]))
    insert_page(connection, JUMP_CONTROL_PAGE_NUMBER, "CLAUDE-CTRL", {"0": {"0": jump_control_id}})


def install_main_page_claude_key(connection):
    main_page_value = connection.execute("select value from pages where id = ?", (MAIN_PAGE_NUMBER,)).fetchone()[0]
    main_page = json.loads(main_page_value)
    main_row_controls = main_page["controls"].setdefault(MAIN_PAGE_CLAUDE_KEY_ROW, {})
    if MAIN_PAGE_CLAUDE_KEY_COLUMN in main_row_controls:
        raise SystemExit(f"MAIN key {MAIN_PAGE_CLAUDE_KEY_ROW},{MAIN_PAGE_CLAUDE_KEY_COLUMN} is already used")
    claude_key = build_button(
        "",
        CLAUDE_ORANGE_COLOR,
        [build_curl_exec_action("/deck/open"), build_set_page_action("self", str(CLAUDE_PAGE_NUMBER), False)],
    )
    main_row_controls[MAIN_PAGE_CLAUDE_KEY_COLUMN] = insert_control(connection, claude_key)
    connection.execute("update pages set value = ? where id = ?", (json.dumps(main_page), MAIN_PAGE_NUMBER))


def install_jump_target_variable(connection):
    existing = connection.execute("select 1 from custom_variables where id = ?", (JUMP_TARGET_VARIABLE_NAME,)).fetchone()
    if existing:
        return
    highest_sort_order = max(
        (json.loads(row[0]).get("sortOrder", 0) for row in connection.execute("select value from custom_variables")),
        default=-1,
    )
    variable = {
        "description": "Página destino del Stream Deck para Claude",
        "defaultValue": str(MAIN_PAGE_NUMBER),
        "persistCurrentValue": False,
        "sortOrder": highest_sort_order + 1,
    }
    connection.execute(
        "insert into custom_variables (id, value) values (?, ?)", (JUMP_TARGET_VARIABLE_NAME, json.dumps(variable))
    )


def main():
    connection = sqlite3.connect(DATABASE_PATH)
    with connection:
        ensure_pages_are_free(connection)
        stream_deck_surface_id = find_stream_deck_surface_id(connection)
        install_jump_target_variable(connection)
        install_claude_page(connection)
        install_jump_control_page(connection, stream_deck_surface_id)
        install_main_page_claude_key(connection)
    page_numbers = sorted(int(row[0]) for row in connection.execute("select id from pages"))
    control_count = connection.execute("select count(*) from controls").fetchone()[0]
    print(f"installed; surface {stream_deck_surface_id}; pages {page_numbers[0]}..{page_numbers[-1]}; controls {control_count}")


if __name__ == "__main__":
    main()
