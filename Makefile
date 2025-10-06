lint:
	flutter analyze --no-fatal-infos

icons:
	flutter pub run flutter_launcher_icons


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

