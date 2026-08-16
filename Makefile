# PC Engine / PC Engine CD — standalone Retro-Go SD core (pce-go + porting).
#
#   make                  — build + pack → pce.bin
#   make docker           — same build inside Docker (no host toolchain)
#   make docker_shell     — interactive shell in the builder image
#
# One core binary, two launcher tabs: HuCard ROMs (dirname=pce, parse=rom)
# and CD-ROM² .cue images (dirname=pcecd, parse=cdrom). CPU-hot objects
# live in ITCM (see ld/pce_core.ld). Verbose compiler lines: make V=
#
# BUILD_DIR must stay `build`: ld/pce_core.ld names objects as build/*.o
# (a `*pce.o` glob would also match main_pce.o).

#######################################
# Project identity
#######################################
PROJECT_KIND ?= core

CORE_NAME  := pce
CORE_ENTRY := app_main_pce

CORE_C_SOURCES := \
src/pce-go/gfx.c \
src/pce-go/h6280.c \
src/pce-go/pce.c \
src/porting/sound_pce.c \
src/porting/pce_cd.c \
src/porting/pce_scsi.c \
src/porting/pce_adpcm.c \
src/main_pce.c

CORE_C_INCLUDES := \
-Isrc/porting \
-Isrc/pce-go

# Relative path so Docker bind-mounts work (do NOT use $(abspath) — it
# bakes the host path into Make prerequisites / .d files). Do not name
# this SDK_ROOT: that env var is commonly set by Android SDK installs.
GNW_CORE_SDK ?= sdk
# Must match EXCLUDE_FILE / .core_itcm paths in ld/pce_core.ld.
BUILD_DIR ?= build

#######################################
# Kind-specific compile defs + packing
#######################################
ifeq ($(PROJECT_KIND),core)
# Match release-firmware layout of retro_emulator_file_t: COVERFLOW fields
# sit before cheat_* — CHEAT_CODES alone with COVERFLOW=0 misaligns pointers.
# MAX_CHEAT_CODES mirrors Makefile.common's release default.
CORE_C_DEFS := \
-DPROJECT_KIND_CORE=1 \
-DCOVERFLOW=1 \
-DCHEAT_CODES=1 \
-DMAX_CHEAT_CODES=13

PACKED_BIN := $(CORE_NAME).bin
PAD_LOGO     := src/assets/pad.bmp
HEADER_LOGO  := src/assets/header.bmp
HEADER_CD    := src/assets/header_cd.bmp

CORE_LDSCRIPT := ld/pce_core.ld
CORE_EXTRA_SEGMENTS := itcm:core_itcm

else
$(error PROJECT_KIND must be 'core' (got '$(PROJECT_KIND)'))
endif

include $(GNW_CORE_SDK)/Makefile

PACK_CORE := $(GNW_CORE_SDK)/tools/pack_core.py

#######################################
# Pack
#######################################
.PHONY: pack

pack: $(TARGET_BIN) $(BUILD_DIR)/pce_core_itcm.bin $(PAD_LOGO) $(HEADER_LOGO) $(HEADER_CD)
	$(V)$(ECHO) [ PACK CORE ] $(PACKED_BIN)
	$(V)python3 $(PACK_CORE) \
		--elf $(TARGET_ELF) --bin $(TARGET_BIN) \
		--system name="PC Engine",dirname=pce,pad_logo=$(PAD_LOGO),header_logo=$(HEADER_LOGO),ext=pce,parse=rom,cheat_ext=pceplus \
		--system name="PC Engine CD",dirname=pcecd,pad_logo=$(PAD_LOGO),header_logo=$(HEADER_CD),ext=cue,parse=cdrom,cheat_ext=pceplus \
		--logo-invert \
		--segment itcm:__ITCM_CORE_START__:__CORE_ITCM_CODE_END__:__CORE_ITCM_BSS_END__:$(BUILD_DIR)/pce_core_itcm.bin \
		--core-name "PCE-GO" \
		--version 1.0.0 \
		--out $(PACKED_BIN)

all: pack

# Read-only helpers for CI / scripts (make print-PROJECT_KIND, etc.).
.PHONY: print-PROJECT_KIND print-PACKED_BIN print-CORE_NAME print-DOCKER_IMAGE
print-PROJECT_KIND:
	@echo $(PROJECT_KIND)
print-PACKED_BIN:
	@echo $(PACKED_BIN)
print-CORE_NAME:
	@echo $(CORE_NAME)
print-DOCKER_IMAGE:
	@echo $(DOCKER_IMAGE)

clean::
	$(V)rm -f $(PACKED_BIN)

#######################################
# Docker (same image as firmware repo)
#######################################
.PHONY: docker docker_pull docker_shell

RELEASE_VERSION ?= v1.5
DOCKER_REPOSITORY ?= sylverb/retro-go-sd-builder
DOCKER_IMAGE ?= $(DOCKER_REPOSITORY):$(RELEASE_VERSION)

DOCKER_TTY_FLAG := $(shell if [ -t 0 ]; then echo -it; else echo; fi)
# Host UID so build/ artifacts are not root-owned on the bind mount.
DOCKER_USER := $(shell id -u):$(shell id -g)
DOCKER_RUN := docker run --rm $(DOCKER_TTY_FLAG) \
	--user $(DOCKER_USER) \
	-v "$(CURDIR):/opt/workdir" \
	-w /opt/workdir \
	$(DOCKER_IMAGE)

# Compile inside the published builder image (uses the local copy).
# Refresh with `make docker_pull` when you want a newer digest for the tag.
docker:
	$(V)$(ECHO) "[ DOCKER ]" $(DOCKER_IMAGE) "PROJECT_KIND=$(PROJECT_KIND)"
	$(V)$(DOCKER_RUN) make --no-print-directory -j$$(nproc) PROJECT_KIND=$(PROJECT_KIND)

docker_pull:
	$(V)$(ECHO) "[ PULL ]" $(DOCKER_IMAGE)
	$(V)docker pull $(DOCKER_IMAGE)

# Interactive shell with the same image / mount as `make docker`.
docker_shell:
	$(DOCKER_RUN) bash
