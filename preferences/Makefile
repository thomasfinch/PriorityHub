ARCHS = armv7 arm64
GO_EASY_ON_ME = 1

include theos/makefiles/common.mk

BUNDLE_NAME = PriorityHub
PriorityHub_FILES = PriorityHub.mm
PriorityHub_INSTALL_PATH = /Library/PreferenceBundles
PriorityHub_FRAMEWORKS = UIKit
PriorityHub_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PriorityHub.plist$(ECHO_END)
