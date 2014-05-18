ARCHS = armv7 armv7s arm64
THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222
THEOS_BUILD_DIR = debs
GO_EASY_ON_ME = 1

include theos/makefiles/common.mk

TWEAK_NAME = PriorityHub
PriorityHub_FILES = Tweak.xm PHController.m
PriorityHub_FRAMEWORKS = UIKit CoreGraphics CoreTelephony
PriorityHub_PRIVATE_FRAMEWORKS = IMAVCore

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall -9 backboardd"