# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

typeMode is a customized fork of GNU nano 8.7, transformed into a minimal, distraction-free terminal text editor with GPaste clipboard integration. It syncs upstream weekly via GitHub Actions.

### Custom Modifications (on top of upstream nano)

1. **GPaste clipboard integration** (`src/files.c`): When launched without a file argument, loads the last GPaste clipboard entry into the buffer. Ctrl+S saves back to GPaste instead of disk. Controlled by the `gpaste_mode` global flag.
2. **UI chrome stripping** (`src/nano.c`, `src/winio.c`): Removed title bar, bottom shortcut hints, and welcome message. Edit area fills the entire screen. Non-critical status messages (importance < AHEM) are suppressed.
3. **Executable rename** (`src/Makefile.am`): Binary is `typeMode` instead of `nano`.

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

Dependencies: ncurses/ncursesw, libintl (gettext). Optional: libmagic, zlib.

## Testing

There are no unit tests. `nano-regress` is a Perl script that tests ~256 combinations of configure options by running `./configure [flags] && make clean all` for each.

## Architecture

The codebase is standard GNU nano C code (~22K lines in `src/`):

- **nano.c** — Main entry point, event loop, initialization, command dispatch
- **winio.c** — Terminal rendering (ncurses), keyboard input, status bar
- **text.c** — Text manipulation, undo/redo, cut/copy/paste logic
- **files.c** — File I/O, buffer management, GPaste integration (`load_gpaste_into_buffer()`, `save_to_gpaste()`)
- **global.c** — Global variables, menu definitions, keybinding tables
- **rcfile.c** — `.nanorc` configuration file parsing
- **definitions.h** — All data structures, constants, and macros
- **prototypes.h** — All function declarations and extern variables

Key data flow: `nano.c:main()` → initializes ncurses → loads file or GPaste clipboard → enters `do_input()` event loop → dispatches to editing functions → renders via `winio.c`.

## Working with Custom Code

All typeMode-specific code can be found by searching for `gpaste` (clipboard integration) or checking the three commits on top of upstream. The `gpaste_mode` boolean in `prototypes.h` gates clipboard vs. file behavior in `files.c`.

When merging upstream nano changes, conflicts are most likely in `nano.c` (UI initialization), `winio.c` (display functions), and `files.c` (save functions).
