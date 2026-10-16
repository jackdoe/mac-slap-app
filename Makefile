APP     := SlapMe
VERSION := 1.0.0
BUILD   := $(shell git rev-list --count HEAD 2>/dev/null || echo 1)

BUNDLE  := dist/$(APP).app
BINARY  := $(BUNDLE)/Contents/MacOS/$(APP)
ARCHIVE := dist/$(APP)-v$(VERSION).zip
TARGET  := $(shell [ -w /Applications ] && echo /Applications || echo $(HOME)/Applications)

.PHONY: app run test install uninstall release icon clean

app:
	swift build -c release
	rm -rf "$(BUNDLE)"
	mkdir -p "$(BUNDLE)/Contents/MacOS" "$(BUNDLE)/Contents/Resources"
	cp ".build/release/$(APP)" "$(BINARY)"
	strip -S -x "$(BINARY)"
	@if LC_ALL=C grep -aq "$(HOME)" "$(BINARY)"; then echo "error: $(BINARY) contains $(HOME)" >&2; exit 1; fi
	sed -e 's/__VERSION__/$(VERSION)/' -e 's/__BUILD__/$(BUILD)/' Resources/Info.plist > "$(BUNDLE)/Contents/Info.plist"
	cp Resources/AppIcon.icns "$(BUNDLE)/Contents/Resources/"
	codesign --force --sign - --options runtime --timestamp=none "$(BUNDLE)"

run: app
	"$(BINARY)"

test:
	swift test

install: app
	pkill -x $(APP) || true
	mkdir -p "$(TARGET)"
	rm -rf "$(TARGET)/$(APP).app"
	ditto "$(BUNDLE)" "$(TARGET)/$(APP).app"
	open "$(TARGET)/$(APP).app"

uninstall:
	for bundle in "/Applications/$(APP).app" "$(HOME)/Applications/$(APP).app"; do \
		[ -x "$$bundle/Contents/MacOS/$(APP)" ] && "$$bundle/Contents/MacOS/$(APP)" --unregister-login-item; \
		rm -rf "$$bundle"; \
	done
	pkill -x $(APP) || true

release: test app
	rm -rf dist/release "$(ARCHIVE)"
	mkdir -p "dist/release/$(APP)-v$(VERSION)"
	ditto "$(BUNDLE)" "dist/release/$(APP)-v$(VERSION)/$(APP).app"
	cp install.sh README.md "dist/release/$(APP)-v$(VERSION)/"
	cd dist/release && ditto -c -k --keepParent "$(APP)-v$(VERSION)" "../$(APP)-v$(VERSION).zip"
	rm -rf dist/release

icon:
	swift Scripts/icon.swift

clean:
	rm -rf .build dist
