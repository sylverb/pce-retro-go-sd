# Changelog

This file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Release tags must
match a section heading exactly (for example `v1.0.0`).

When you cut a release:

1. Move items from `[Unreleased]` into a new `## [vX.Y.Z] - YYYY-MM-DD` section.
2. Commit the changelog update.
3. Push the tag: `git tag vX.Y.Z && git push origin vX.Y.Z`

CI reads the matching section and uses it as the GitHub Release notes. The tag
is also used in staged asset names (`<binary>-<tag>.bin`, `<binary>-<tag>.zip`).

## [Unreleased]

### Fixed

- PC Engine CD: claim Super CD-ROM² RAM via `ram_malloc` / `dtc_malloc` /
  `ahb_malloc` instead of overlaying the free RAM_EMU bump. Firmware SPI SD
  DMA bounce buffers also use `ram_malloc`; the old overlay collided and
  caused System Card "LOAD ERROR", music dropouts, and freezes.
- Move ADPCM 64KB sample RAM to DTCM (`dtc_calloc`) to free RAM_EMU headroom
  for CD banks + SD DMA.

### Added

- Ported the firmware PC Engine / PC Engine CD core (`pce-go` + `porting/pce`)
  into this standalone tree: HuCard + CD-ROM² tabs, ITCM hot path, `pceplus`
  cheats.

### Changed

- Packed output is `pce.bin` (`/cores/pce.bin`). HuCard ROMs under `/roms/pce/`,
  CD images under `/roms/pcecd/`, System Card at `/bios/pce/syscard3.pce`.

## [v1.0.0] - 2026-08-12

Initial public release of the Retro-Go SD core/homebrew template.

### Added

- Freestanding Cortex-M7 skeleton (`src/main.c`) with LCD demo, square-wave
  audio, save/load/screenshot hooks, and watchdog-friendly frame loop.
- Vendored SDK, linker scripts, and ABI bridge for `gw_firmware_abi_t`.
- Packaging for both project kinds:
  - **core** → `pack_core.py`, SD path `/cores/<name>.bin`
  - **homebrew** → `pack_homebrew.py`, SD path `/homebrews/<name>.bin`
- Docker builder integration (`make docker`) using `sylverb/retro-go-sd-builder`.
- CI build on push/PR and automated GitHub Release on `v*` tags.

### Install

**Core (`PROJECT_KIND=core`)**

- Copy `pce.bin` to `/cores/` on the SD card.
- HuCard ROMs: `/roms/pce/*.pce`
- CD-ROM²: `/roms/pcecd/<game>/<game>.cue` (+ sibling `.bin` tracks)
- System Card (CD): `/bios/pce/syscard3.pce` or `syscard3.bin`
- Requires firmware whose ABI matches `SDK_VERSION` in this repository.

The release archive contains the ready-to-copy SD layout (`cores/pce.bin`).
