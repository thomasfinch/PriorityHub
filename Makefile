ARCHS = armv7 arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 7.0
ADDITIONAL_OBJCFLAGS = -fobjc-arc
THEOS_BUILD_DIR = debs
# GO_EASY_ON_ME = 1
PACKAGE_VERSION = 1.4.2

# DEBUG = 1

include theos/makefiles/common.mk

TWEAK_NAME = PriorityHub
PriorityHub_FILES = Tweak.xm PHView.xm PHAppView.m PHPullToClearView.m
PriorityHub_FRAMEWORKS = UIKit CoreGraphics CoreTelephony QuartzCore
PriorityHub_PRIVATE_FRAMEWORKS = IMAVCore

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
