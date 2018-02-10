NAME = HapticKey

DERIVED_DATA_PATH = build

BUNDLE_PATH = $(DERIVED_DATA_PATH)/Build/Products/Release/$(NAME).app
TARGET = $(DERIVED_DATA_PATH)/$(NAME).app.zip

.PHONY: all
all: $(TARGET)

Pods/Manifest.lock: Podfile Podfile.lock
	scripts/pod install

$(BUNDLE_PATH): Pods/Manifest.lock
	xcodebuild \
		-workspace "$(NAME).xcworkspace" \
		-scheme "$(NAME)" \
		-configuration "Release" \
		-derivedDataPath "$(DERIVED_DATA_PATH)"

$(TARGET): $(BUNDLE_PATH)
	ditto -c -k --sequesterRsrc --keepParent $(BUNDLE_PATH) $@

.PHONY: claen
clean:
	git clean -dfX
