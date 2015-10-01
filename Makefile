include theos/makefiles/common.mk

TWEAK_NAME = WidPlayer
WidPlayer_FILES = UIWindow.m WidPlayer.xm CBAutoScrollLabel.m
WidPlayer_FRAMEWORKS = UIKit CoreGraphics Foundation CoreFoundation QuartzCore MediaPlayer
WidPlayer_PRIVATE_FRAMEWORKS = MediaRemote Celestial
WidPlayer_CFLAGS = -fobjc-arc -std=c++11
export ARCHS = armv7 arm64
WidPlayer_ARCHS = armv7 arm64
include $(THEOS_MAKE_PATH)/tweak.mk

all::
	@echo "[+] Copying Files..."
	@cp ./obj/WidPlayer.dylib //Library/MobileSubstrate/DynamicLibraries/WidPlayer.dylib
	@cp ./WidPlayer.plist //Library/MobileSubstrate/DynamicLibraries/WidPlayer.plist
	@echo "DONE"
	@killall SpringBoard

	
