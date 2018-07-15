include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ncquote
ncquote_FILES = SQDRootListController.m
ncquote_INSTALL_PATH = /Library/PreferenceBundles
ncquote_FRAMEWORKS = UIKit
ncquote_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ncquote.plist$(ECHO_END)
