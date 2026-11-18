ARCHS = arm64 arm64e
TARGET = iphone:clang:16.5:16.0
THEOS_PACKAGE_SCHEME ?= rootless
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = MinisThinkingRules
MinisThinkingRules_FILES = Tweak.m Snapshot.m
MinisThinkingRules_CFLAGS = -fobjc-arc
MinisThinkingRules_FRAMEWORKS = UIKit Foundation CoreFoundation
include $(THEOS_MAKE_PATH)/tweak.mk

ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
THEOS_PACKAGE_ARCH = iphoneos-arm64e
else
THEOS_PACKAGE_ARCH = iphoneos-arm64
endif
