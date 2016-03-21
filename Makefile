include theos/makefiles/common.mk

TWEAK_NAME = WidPlayer
WidPlayer_FILES = WidPlayerWindow.m WidPlayer.xm
WidPlayer_FRAMEWORKS = UIKit CoreGraphics CoreImage CFNetwork Foundation CoreFoundation QuartzCore CydiaSubstrate MediaPlayer
WidPlayer_PRIVATE_FRAMEWORKS = MediaRemote MediaPlayerUI
WidPlayer_CFLAGS = -fobjc-arc -std=c++11
WidPlayer_LDFLAGS = -Wl,-segalign,4000 -Wl,-undefined,dynamic_lookup
export ARCHS = armv7 arm64
WidPlayer_ARCHS = armv7 arm64
include $(THEOS_MAKE_PATH)/tweak.mk

all::
	@echo "[+] Copying Files..."
	@ldid -S ./obj/WidPlayer.dylib
	@cp ./obj/WidPlayer.dylib //Library/MobileSubstrate/DynamicLibraries/WidPlayer.dylib
	@cp ./WidPlayer.plist //Library/MobileSubstrate/DynamicLibraries/WidPlayer.plist
	@echo "DONE"
	@killall SpringBoard

	
