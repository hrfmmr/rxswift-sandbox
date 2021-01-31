XCODE_WORKSPACE := rxswiftsandbox.xcworkspace
BUNDLE_PATH ?= vendor/bundle

.PHONY: default
default: bootstrap open

.PHONY: bootstrap
bootstrap:
	mint bootstrap
	"$(MAKE)" build-prj
	"$(MAKE)" pod

.PHONY: build-prj
build-prj:
	mint run xcodegen

.PHONY: gems
gems:
	bundle config set path '$(BUNDLE_PATH)'
	bundle install

.PHONY: pod
pod: gems
	bundle exec pod install

.PHONY: open
open:
	open $(XCODE_WORKSPACE)
