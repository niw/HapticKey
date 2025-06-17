NAME = HapticKey

BUILD_PATH = build

XCODE_PROJECT_PATH = $(NAME).xcodeproj
XCODE_SCHEME = $(NAME)
XCODE_ARCHIVE_PATH = $(BUILD_PATH)/$(NAME).xcarchive
XCODE_ARCHIVE_BUNDLE_PATH = $(XCODE_ARCHIVE_PATH)/Products/Applications/$(NAME).app

XCODE_SOURCE_PATH = $(NAME)
XCODE_RESOURCES_PATH = $(XCODE_SOURCE_PATH)/Resources

TARGET_PATH = $(XCODE_ARCHIVE_BUNDLE_PATH)

APPCAST_ARCHIVE_PATH = $(BUILD_PATH)/$(NAME).app.zip
APPCAST_PATH = $(BUILD_PATH)/appcast.xml
APPCAST_RELEASE_NOTE_PATH = $(BUILD_PATH)/release_note.md
APPCAST_ARCHIVE_URL = "https://github.com/niw/$(NAME)/releases/download/{{bundle_short_version_string}}/$(NAME).app.zip"

.PHONY: all
all: $(TARGET_PATH)

.PHONY: release
release: $(APPCAST_ARCHIVE_PATH) $(APPCAST_PATH)

.PHONY: claen
clean:
	git clean -dfX

$(XCODE_ARCHIVE_BUNDLE_PATH):
	xcodebuild \
		-project "$(XCODE_PROJECT_PATH)" \
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
		--url="$(APPCAST_ARCHIVE_URL)" \
		--release-note="$(APPCAST_RELEASE_NOTE_PATH)" \
		--output "$@" \
		"$(APPCAST_ARCHIVE_PATH)"
else
	$(error "KEY is missing.")
endif
