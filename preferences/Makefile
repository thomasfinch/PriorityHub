ARCHS = armv7 arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 7.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PriorityHub
PriorityHub_FILES = PHRoot.mm PHLockScreenPrefs.mm PHNCPrefs.mm PHVerticalAdjustmentTableCell.m PHSubtitleSwitchTableCell.m PHPrefsHeaderCell.m
PriorityHub_INSTALL_PATH = /Library/PreferenceBundles
PriorityHub_FRAMEWORKS = UIKit
PriorityHub_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PriorityHub.plist$(ECHO_END)
