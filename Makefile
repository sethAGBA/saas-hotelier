.PHONY: web-dev web-build web-lint web-start flutter-get flutter-run-desktop flutter-run-ios flutter-clean

web-dev:
	npm run dev:web

web-build:
	npm run build:web

web-lint:
	npm run lint:web

web-start:
	npm run start:web

flutter-get:
	cd roommaster && flutter pub get

flutter-run-desktop:
	cd roommaster && flutter run -d macos

flutter-run-ios:
	cd roommaster && flutter run -d ios

flutter-clean:
	cd roommaster && flutter clean
