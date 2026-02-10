APP_NAME = Shy
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
BINARY = $(MACOS_DIR)/$(APP_NAME)

SOURCES = $(wildcard Sources/*.swift)
TARGET = arm64-apple-macosx26.0
SWIFT_FLAGS = -O -whole-module-optimization -target $(TARGET)

.PHONY: all run clean install

all: $(BINARY) $(CONTENTS_DIR)/Info.plist

$(BINARY): $(SOURCES) | $(MACOS_DIR)
	swiftc $(SWIFT_FLAGS) -framework AppKit -o $@ $(SOURCES)

$(CONTENTS_DIR)/Info.plist: Resources/Info.plist | $(CONTENTS_DIR)
	cp $< $@

$(MACOS_DIR):
	mkdir -p $@

$(CONTENTS_DIR):
	mkdir -p $@

run: all
	open $(APP_BUNDLE)

clean:
	rm -rf $(BUILD_DIR)

install: all
	cp -r $(APP_BUNDLE) /Applications/
