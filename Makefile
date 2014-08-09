ARCHS = armv7 armv7s arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 7.0
TARGET_CC = xcrun -sdk iphoneos clang
TARGET_CXX = xcrun -sdk iphoneos clang++
TARGET_LD = xcrun -sdk iphoneos clang++
SHARED_CFLAGS = -fobjc-arc
THEOS_BUILD_DIR = debs
DEBUG = 1

include theos/makefiles/common.mk

TWEAK_NAME = PriorityHub
PriorityHub_FILES = Tweak.xm PHController.m UIImage+AverageColor.m
PriorityHub_FRAMEWORKS = UIKit CoreGraphics CoreTelephony
PriorityHub_PRIVATE_FRAMEWORKS = IMAVCore

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 backboardd"
