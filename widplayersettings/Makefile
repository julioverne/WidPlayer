include theos/makefiles/common.mk

BUNDLE_NAME = WidPlayer
WidPlayer_FILES = WidPlayerController.mm
WidPlayer_INSTALL_PATH = /Library/PreferenceBundles
WidPlayer_FRAMEWORKS = UIKit QuartzCore CoreGraphics MessageUI Social Twitter
WidPlayer_PRIVATE_FRAMEWORKS = Preferences
WidPlayer_CFLAGS = -fobjc-arc
WidPlayer_ARCHS = armv7 arm64
export ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/bundle.mk
