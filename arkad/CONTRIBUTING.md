# Contributing to Arkad App

Thank you for your interest in contributing to our Flutter project!

## Development Workflow

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run linting locally to verify your changes:
   ```bash
   flutter analyze
   dart format .
   ```
5. Commit your changes (`git commit -m 'Add some amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Code Style and Linting

This project uses Flutter's linting system with customized rules defined in `analysis_options.yaml`. All code must pass these linting rules before being merged.

### Running Linting Locally

Before submitting a PR, ensure your code passes all linting rules:

```bash
flutter analyze
```

For code formatting, run:

```bash
dart format .
```

## Automatic Checks

GitHub Actions will automatically run linting and formatting checks on your PR. Look for the status checks on your PR and fix any issues that arise.
