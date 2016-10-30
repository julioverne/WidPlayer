include theos/makefiles/common.mk

BUNDLE_NAME = WidPlayer
WidPlayer_FILES = WidPlayerController.mm
WidPlayer_INSTALL_PATH = /Library/PreferenceBundles
WidPlayer_FRAMEWORKS = UIKit QuartzCore CoreGraphics MessageUI Social Twitter
WidPlayer_PRIVATE_FRAMEWORKS = Preferences
WidPlayer_CFLAGS = -fobjc-arc
WidPlayer_LDFLAGS = -Wl,-segalign,4000
WidPlayer_ARCHS = armv7 arm64
export ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/bundle.mk

all::
	@echo "[+] Copying Files..."
	@cp ./obj/WidPlayer.bundle/WidPlayer //Library/PreferenceBundles/WidPlayer.bundle/WidPlayer
	@ldid -S //Library/PreferenceBundles/WidPlayer.bundle/WidPlayer
	@echo "DONE"
	
	