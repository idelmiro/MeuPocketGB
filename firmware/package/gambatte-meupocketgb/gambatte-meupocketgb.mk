################################################################################
#
# gambatte-meupocketgb
#
################################################################################

# Gambatte-DMS upstream, fixed commit. Our changes live in emulador/patches/.
GAMBATTE_MEUPOCKETGB_VERSION = 0b0416f70ad46a85c298c8d6f5d272f54cf267bc
GAMBATTE_MEUPOCKETGB_SITE = $(call github,tiopex,gambatte-dms,$(GAMBATTE_MEUPOCKETGB_VERSION))
GAMBATTE_MEUPOCKETGB_LICENSE = GPL-2.0
GAMBATTE_MEUPOCKETGB_LICENSE_FILES = COPYING
GAMBATTE_MEUPOCKETGB_DEPENDENCIES = sdl sdl_image sdl_mixer zlib

GAMBATTE_MEUPOCKETGB_PATCHES_DIR = $(BR2_EXTERNAL_MEUPOCKETGB_PATH)/../emulador/patches

define GAMBATTE_MEUPOCKETGB_APPLY_MEUPOCKETGB_PATCHES
	$(APPLY_PATCHES) $(@D) $(GAMBATTE_MEUPOCKETGB_PATCHES_DIR) \*.patch
endef
GAMBATTE_MEUPOCKETGB_POST_PATCH_HOOKS += GAMBATTE_MEUPOCKETGB_APPLY_MEUPOCKETGB_PATCHES

define GAMBATTE_MEUPOCKETGB_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) -f Makefile.meupocketgb \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		SDL_CONFIG="$(STAGING_DIR)/usr/bin/sdl-config" \
		STATIC=0 \
		OPT_FLAGS="$(TARGET_CFLAGS) -Ofast -fdata-sections -ffunction-sections -fno-common" \
		EXTRA_LDFLAGS="-s"
endef

define GAMBATTE_MEUPOCKETGB_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/gambatte-meupocketgb \
		$(TARGET_DIR)/usr/bin/gambatte-meupocketgb
endef

$(eval $(generic-package))
