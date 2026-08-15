ARCHS = arm64 arm64e
TARGET := iphone:clang:14.5:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

THEOS_PACKAGE_SCHEME = roothide

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DynamicIslandFullAll

DynamicIslandFullAll_FILES = Tweak.x
DynamicIslandFullAll_CFLAGS = -fobjc-arc
DynamicIslandFullAll_FRAMEWORKS = UIKit CoreGraphics AudioToolbox

include $(THEOS_MAKE_PATH)/tweak.mk
