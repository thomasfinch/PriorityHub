ARCHS = armv7 arm64
THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222
THEOS_BUILD_DIR = debs
GO_EASY_ON_ME = 1

include theos/makefiles/common.mk

TWEAK_NAME = PriorityHub
PriorityHub_FILES = Tweak.xm
PriorityHub_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
