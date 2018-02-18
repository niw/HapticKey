NAME = HapticKey

BUILD_PATH = build

POD_INSTALL_TAG_PATH = Pods/Manifest.lock

XCODE_WORKSPACE_PATH = $(NAME).xcworkspace
XCODE_SCHEME = $(NAME)
XCODE_ARCHIVE_PATH = $(BUILD_PATH)/$(NAME).xcarchive
XCODE_ARCHIVE_BUNDLE_PATH = $(XCODE_ARCHIVE_PATH)/Products/Applications/$(NAME).app

TARGET_PATH = $(XCODE_ARCHIVE_BUNDLE_PATH)

APPCAST_ARCHIVE_PATH = $(BUILD_PATH)/$(NAME).app.zip
APPCAST_PATH = $(BUILD_PATH)/appcast.xml
APPCAST_RELEASE_NOTE_PATH = $(BUILD_PATH)/release_note.md

.PHONY: all
all: $(TARGET_PATH)

.PHONY: bootstrap
bootstrap: $(POD_INSTALL_TAG_PATH)

.PHONY: release
release: $(APPCAST_ARCHIVE_PATH) $(APPCAST_PATH)

.PHONY: claen
clean:
	git clean -dfX

$(POD_INSTALL_TAG_PATH): Podfile Podfile.lock
	scripts/pod install

$(XCODE_ARCHIVE_BUNDLE_PATH): $(POD_INSTALL_TAG_PATH)
	xcodebuild \
		-workspace "$(XCODE_WORKSPACE_PATH)" \
		-scheme "$(XCODE_SCHEME)" \
		-derivedDataPath "$(BUILD_PATH)" \
		-archivePath "$(XCODE_ARCHIVE_PATH)" \
		archive

# Use `xcodebuild -exportArchive` to sign archive.
# For now, we don't sign archive so directly using archive bundle.
#$(TARGET_PATH): $(XCODE_ARCHIVE_BUNDLE_PATH)
#	xcodebuild \
#		-exportArchive \
#		...

$(APPCAST_ARCHIVE_PATH): $(TARGET_PATH)
	ditto -c -k --sequesterRsrc --keepParent $< $@

.PHONY: require_master_branch
require_master_branch:
ifneq ($(shell git symbolic-ref --short HEAD), master)
	$(error "Current working directory is not master branch.")
endif

.PHONY: tag_version
tag_version: require_master_branch $(TARGET_PATH)
	git tag $(shell scripts/sparkle_appcast info --bundle-short-version-string "$(TARGET_PATH)")

$(APPCAST_RELEASE_NOTE_PATH): require_master_branch tag_version
	git show --format='%B' -s HEAD|tee $@

$(APPCAST_PATH): $(APPCAST_ARCHIVE_PATH) $(APPCAST_RELEASE_NOTE_PATH) $(TARGET_PATH)
ifdef KEY
	scripts/sparkle_appcast appcast \
		--key="$(KEY)" \
		--url="https://github.com/niw/$(NAME)/releases/download/$(shell scripts/sparkle_appcast info --bundle-short-version-string "$(TARGET_PATH)")/$(NAME).app.zip" \
		--release-note="$(APPCAST_RELEASE_NOTE_PATH)" \
		--output "$@" \
		"$(APPCAST_ARCHIVE_PATH)"
else
	$(error "KEY is missing.")
endif
