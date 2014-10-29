ARCHS = armv7 arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 7.0
ADDITIONAL_OBJCFLAGS = -fobjc-arc
THEOS_BUILD_DIR = debs
THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222
GO_EASY_ON_ME = 1
DEBUG = 1

include theos/makefiles/common.mk

TWEAK_NAME = PriorityHub
PriorityHub_FILES = Tweak.xm PHController.m PHAppsScrollView.m PHAppView.m UIImage+AverageColor.m PHPullToClearView.m
PriorityHub_FRAMEWORKS = UIKit CoreGraphics CoreTelephony QuartzCore
PriorityHub_PRIVATE_FRAMEWORKS = IMAVCore

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 backboardd"
