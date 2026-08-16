# PC Engine / PC Engine CD — Retro-Go SD core

Standalone Game & Watch Retro-Go SD core for **PC Engine (HuCard)** and
**PC Engine CD-ROM²**. One tree, one packed binary (`pce.bin`) that the
launcher discovers as two tabs.

This is a freestanding Cortex-M7 image linked into `RAM_EMU` (plus an
ITCM code segment). It talks to the firmware **only** through
`gw_firmware_abi_t`. You do not link against the firmware ELF.

| | |
|--|--|
| Packer | `sdk/tools/pack_core.py` (`CORE`) |
| SD path | `/cores/pce.bin` |
| HuCard tab | dirname `pce`, extensions `.pce`, parse=rom, cheats `pceplus` |
| CD tab | dirname `pcecd`, extensions `.cue`, parse=cdrom, cheats `pceplus` |
| BIOS (CD) | `/bios/pce/syscard3.pce` or `syscard3.bin` |

Emulator: [HuExpress-GO](https://github.com/ducalex/pce-go) (`src/pce-go/`,
GPL-2) plus the Game & Watch CD/SCSI/ADPCM port (`src/porting/`,
`src/main_pce.c`). Headers, ABI bridge, linker scripts, and packers are
vendored under `sdk/`. You do **not** need a firmware checkout to compile.

## Requirements

**Local build**

- `arm-none-eabi-gcc` (v10+, same family as the firmware; hard-float
  `fpv5-d16` is mandatory — ABI calling convention must match)
- GNU Make
- Python 3 + Pillow (`pip install -r requirements.txt`) for packaging logos

**Docker build** (no host toolchain)

- Docker
- Image [`sylverb/retro-go-sd-builder`](https://hub.docker.com/r/sylverb/retro-go-sd-builder)
  (same tag as the firmware repo, default `v1.5`)

## Quick start

```bash
make
# or: make docker
```

Produces `pce.bin`. Copy it to `/cores/` on the SD card.

- HuCard ROMs: `/roms/pce/*.pce`
- CD-ROM²: `/roms/pcecd/<game>/<game>.cue` (+ sibling `.bin` tracks)
- System Card (CD): `/bios/pce/syscard3.pce` (or `.bin`)

Requires firmware whose ABI matches `SDK_VERSION` in this repository.

Useful Docker targets:

- `make docker` — build + pack in the local builder image
- `make docker_pull` — refresh the image from Docker Hub
- `make docker_shell` — interactive shell in the same mount

Override the image tag if needed: `make docker RELEASE_VERSION=v1.5`.

## Layout

```
Makefile            Project build + pack + docker
ld/pce_core.ld      RAM_EMU + ITCM linker script
src/main_pce.c      Device glue (ROM/CD mount, audio, savestates)
src/pce-go/         HuExpress-GO CPU / VDC / memory map
src/porting/        CD-ROM² SCSI, ADPCM, CUE/BIN, PSG mixer
src/assets/         Pad + header 1bpp logos (HuCard + CD)
sdk/                Vendored ABI, bridge, linker fragments, packers
scripts/            Sync helper
```

CPU-hot objects (`gfx`, `h6280`, `pce`, `sound_pce`, `pce_cd`,
`pce_scsi`, `pce_adpcm`) are placed in **ITCM** (64 KiB). `main_pce.o`
and the ABI bridge stay in **RAM_EMU**. See `ld/pce_core.ld`.

Include order in `src/main_pce.c`: firmware-style headers first, then
`#include "gw_core_bridge.h"` last (macros rewrite `ACTIVE_FILE` /
`ram_start` / `common_emu_state`).

Undefined references at link time usually mean a symbol is missing from
`sdk/src/gw_core_bridge_redefine_syms.txt` and/or lacks a `core_*`
trampoline in `sdk/src/gw_core_bridge.c`. If the symbol is not on the ABI
yet, extend the **firmware** ABI first, then refresh this SDK (see below).

## ABI compatibility

The packed core embeds `required_abi_version` and `required_abi_min_size`
(from `GW_CORE_BUILT_ABI_*` in the bridge). The firmware refuses to load a
binary that asks for a newer/larger ABI than it provides.

See `SDK_VERSION` for the snapshot this tree was cut from.

## Refreshing the SDK from firmware

If you maintain this tree alongside a firmware checkout:

```bash
./scripts/sync_from_firmware.sh /path/to/game-and-watch-retro-go-sd
```

That re-copies headers (including `gwhb.h`), bridge sources, linker
scripts, `pack_core.py`, and `pack_homebrew.py`. Review the diff before
committing. Re-copy PCE sources from `cores/pce` / `pce-go` /
`Core/Src/porting/pce` separately if those changed.

## License

The emulator (`src/pce-go/`) is **GPL-2.0** (HuExpress-GO / Hu-Go! /
Bero). See `src/pce-go/COPYING`. Combined with the rest of this tree, the
distributed core is GPL-2.

Vendored files under `sdk/include/` keep their upstream licenses
(firmware / HAL / FatFs / etc.).
