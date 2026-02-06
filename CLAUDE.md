# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

typeMode is a customized fork of GNU nano 8.7, transformed into a minimal, distraction-free terminal text editor with GPaste clipboard integration. It syncs upstream weekly via GitHub Actions.

### Custom Modifications (on top of upstream nano)

1. **GPaste clipboard integration** (`src/files.c`): In GPaste mode (launched without a file argument), starts with an empty buffer. Ctrl+S saves to GPaste instead of disk. Ctrl+Up/Down browse GPaste history like bash shell history, preserving any user-typed text. Controlled by the `gpaste_mode` global flag.
2. **System clipboard copy** (`src/cut.c`): Ctrl+C copies the entire buffer to the system clipboard via `xclip`.
3. **UI chrome stripping** (`src/nano.c`, `src/winio.c`): Removed title bar, bottom shortcut hints, and welcome message. Edit area fills the entire screen. Non-critical status messages (importance < AHEM) are suppressed.
4. **Custom keybindings** (`src/global.c`): Ctrl+D exits (both modern and classic modes), Ctrl+C copies all text, Ctrl+Up/Down navigate GPaste history.
5. **Executable rename** (`src/Makefile.am`): Binary is `typeMode` instead of `nano`.

## Build Commands

```bash
# First-time setup (regenerate autotools files)
./autogen.sh

# Configure (run from project root)
./configure

# Build
make

# The executable is at src/typeMode
```

Useful configure flags: `--enable-debug` (assertions), `--enable-tiny` (minimal build), `--enable-utf8`.

Dependencies: ncurses/ncursesw, libintl (gettext). Runtime: `xclip` (clipboard), `gpaste-client` (GPaste history, ships with GNOME). Optional: libmagic, zlib.

## Testing

There are no unit tests. `nano-regress` is a Perl script that tests ~256 combinations of configure options by running `./configure [flags] && make clean all` for each.

## Architecture

The codebase is standard GNU nano C code (~22K lines in `src/`):

- **nano.c** — Main entry point, event loop, initialization, command dispatch
- **winio.c** — Terminal rendering (ncurses), keyboard input, status bar
- **text.c** — Text manipulation, undo/redo
- **cut.c** — Cut/copy/paste, includes `copy_all_text()` (Ctrl+C → xclip)
- **files.c** — File I/O, buffer management, GPaste integration (`save_to_gpaste()`, `do_gpaste_older()`, `do_gpaste_newer()`)
- **global.c** — Global variables, menu definitions, keybinding tables
- **rcfile.c** — `.nanorc` configuration file parsing
- **definitions.h** — All data structures, constants, and macros
- **prototypes.h** — All function declarations and extern variables

Key data flow: `nano.c:main()` → initializes ncurses → opens empty buffer (GPaste mode) or loads file → enters `do_input()` event loop → dispatches to editing functions → renders via `winio.c`.

### Custom Keybindings

| Key | Action | Function |
|-----|--------|----------|
| Ctrl+C | Copy entire buffer to system clipboard | `copy_all_text()` in `cut.c` |
| Ctrl+S | Save to GPaste (GPaste mode) or disk | `save_to_gpaste()` in `files.c` |
| Ctrl+D | Exit | `do_exit()` in `nano.c` |
| Ctrl+Up | Browse older GPaste history entries | `do_gpaste_older()` in `files.c` |
| Ctrl+Down | Browse newer GPaste history entries | `do_gpaste_newer()` in `files.c` |

## Working with Custom Code

All typeMode-specific code can be found by searching for `gpaste` (clipboard integration), `copy_all_text` (Ctrl+C), or checking the custom commits on top of upstream. The `gpaste_mode` boolean in `prototypes.h` gates clipboard vs. file behavior in `files.c`.

### Keybinding Gotchas

- Bindings registered first win in `get_shortcut()`. Custom bindings (e.g. `^C`) must be added BEFORE the `MODERN_BINDINGS` if/else block in `global.c` to take priority in both modes.
- Arrow key combos (Ctrl+Up/Down) have TWO registration blocks in `global.c`: one for UTF-8 terminals (escaped sequences like `^\xE2\x96\xb4`) and one for non-UTF-8 (`^Up`). Both must be updated.
- `statusbar()` uses `HUSH` importance which is suppressed by the custom winio.c code. Use `statusline(AHEM, ...)` for messages that should be visible.

### Merge Conflict Zones

When merging upstream nano changes, conflicts are most likely in:
- `nano.c` — UI initialization, startup flow
- `winio.c` — Display functions, status message suppression
- `files.c` — Save functions, GPaste integration
- `global.c` — Keybinding tables
- `cut.c` — `copy_all_text()` at end of file
