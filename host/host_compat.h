/*
 * Host stand-in for gw_core_bridge.h macros / linker symbols.
 * Include instead of gw_core_bridge.h when building with -DHOST_BUILD.
 */
#pragma once

#include <stdint.h>
#include "rom_manager.h"
#include "gw_malloc.h"
#include "common.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Same names the device linker script exports. */
extern uint32_t __CORE_BSS_END__;
extern uint32_t __CORE_CODE_END__;

void gw_core_bridge_init(void);

/* Optional: path passed on the CLI / HOST_ROM for core ROM load. */
void host_set_rom_path(const char *path);
int host_poll_events(void); /* returns 0 if the window should quit */

/* Live RAM_EMU bump cursor (64-bit safe). Device code casts uint32_t ram_start. */
void *host_ram_bump_ptr(void);

/* Map a firmware SD absolute path ("/bios/pce/syscard3.pce") onto the host
 * filesystem. Prefix with $HOST_SD when set (SD card root mirror). */
int host_map_sd_path(const char *sd_path, char *out, size_t out_sz);

/* Load an SD-absolute file via host_map_sd_path + fopen. Caller owns the buffer. */
uint8_t *host_load_sd_file(const char *sd_path, uint32_t *size_out);

#ifdef __cplusplus
}
#endif
