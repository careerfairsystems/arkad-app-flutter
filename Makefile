lint:
	flutter analyze --no-fatal-infos

format:
	dart format lib/

format-check:
	@if ! dart format --set-exit-if-changed lib/; then \
		echo "Code formatting issues found. Run 'make format' to fix."; \
		exit 1; \
	fi

fix: lint format

