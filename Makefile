ARCHS = armv7 arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 7.0
THEOS_BUILD_DIR = debs

include $(THEOS)/makefiles/common.mk

SOURCE_FILES=$(wildcard tweak/*.m tweak/*.mm tweak/*.x tweak/*.xm)

TWEAK_NAME = PriorityHub
PriorityHub_FILES = $(SOURCE_FILES)
PriorityHub_FRAMEWORKS = UIKit CoreGraphics CoreTelephony QuartzCore
PriorityHub_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 SpringBoard"
