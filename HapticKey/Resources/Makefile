.PHONY: all clean

BASE_NAME = AppIcon
GENERATOR_PATH = $(BASE_NAME)-assets
ICNS_NAME = $(BASE_NAME).icns
ICONSET_NAME = $(BASE_NAME).iconset

TARGET = $(ICNS_NAME)
ICONSET_PATH = $(GENERATOR_PATH)/$(ICONSET_NAME)

all: $(TARGET)

clean:
	rm -f $(TARGET)

$(TARGET): $(ICONSET_PATH) \
	$(ICONSET_PATH)/icon_16x16.png \
	$(ICONSET_PATH)/icon_16x16@2x.png \
	$(ICONSET_PATH)/icon_32x32.png \
	$(ICONSET_PATH)/icon_32x32@2x.png \
	$(ICONSET_PATH)/icon_128x128.png \
	$(ICONSET_PATH)/icon_128x128@2x.png \
	$(ICONSET_PATH)/icon_256x256.png \
	$(ICONSET_PATH)/icon_256x256@2x.png \
	$(ICONSET_PATH)/icon_512x512.png \
	$(ICONSET_PATH)/icon_512x512@2x.png
	iconutil --convert icns -o $@ $<

