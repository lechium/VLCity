ARCHS = arm64
TARGET = appletv:clang:10.1:10.1
export GO_EASY_ON_ME=1
export SDKVERSION=10.2
THEOS_DEVICE_IP=bedroom.local
DEBUG=0
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = VLCity
VLCity_FILES = VLCity.m Download/DownloadOperation.m Download/DownloadManager.m
VLCity_INSTALL_PATH = /Library/PreferenceBundles
VLCity_FRAMEWORKS = UIKit Sharing
VLCity_PRIVATE_FRAMEWORKS = TVSettingKit
VLCity_LDFLAGS = -undefined dynamic_lookup -IDownload
#VLCity_CFLAGS+= -I. -ITVSettings -ITVSettingsKit 
VLCity_CFLAGS+= -F. -IDownload
VLCity_CODESIGN_FLAGS=-Sent.plist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/$(BUNDLE_NAME).plist$(ECHO_END)

after-install::
	install.exec "killall -9 TVSettings ; lsdtrip launch com.apple.TVSettings"
	
