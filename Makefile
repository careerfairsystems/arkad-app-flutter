.PHONY: build run lint icons company-images fmt format-check fix
run: 
	flutter run  --dart-define-from-file=env/prod.json
run-release: 
	flutter run --release  --dart-define-from-file=env/prod.json
lint:
	flutter analyze --no-fatal-infos

icons:
	flutter pub run flutter_launcher_icons

company-images:
	rm assets/images/companies/*.png
	dart scripts/download_company_logos.dart
	rm assets/images/companies/216.png # These are invalid
	rm assets/images/companies/264.png

fmt:
	dart format lib/

format-check:
	@if ! dart format --set-exit-if-changed lib/; then \
		echo "Code formatting issues found. Run 'make format' to fix."; \
		exit 1; \
	fi

fix:
	dart fix --apply
	make lint
	make fmt

prepare:
	make icons
	make company-images
