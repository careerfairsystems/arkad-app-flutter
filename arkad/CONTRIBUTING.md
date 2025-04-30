# Contributing to Arkad App

Thank you for your interest in contributing to our Flutter project! This document provides guidelines and instructions for setting up your development environment and contributing to the project.

## Prerequisites

- Flutter SDK (version 3.13.0 or higher)
- Dart SDK (latest stable version)
- Git
- A code editor (VS Code or Android Studio recommended)
- For iOS development: macOS and Xcode
- For Android development: Android Studio and Android SDK

## Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/arkad-app-flutter.git
   cd arkad-app-flutter
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Pre-commit Hooks**
   We use pre-commit hooks to ensure code quality before commits. To set up:

   ```bash
   # Install pre-commit
   pip install pre-commit

   # Install the git hooks
   pre-commit install
   ```

   The pre-commit hooks will automatically run:
   - Flutter analyze
   - Dart format
   - Unit tests
   - Build verification

4. **Verify Setup**
   ```bash
   flutter doctor
   flutter analyze
   flutter test
   ```

## Development Workflow

1. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Your Changes**
   - Follow the code style guidelines
   - Write tests for new features
   - Update documentation as needed

3. **Local Testing**
   Before committing, ensure your code passes all checks:
   ```bash
   # Run all tests
   flutter test

   # Generate coverage report
   flutter test --coverage

   # Run analysis
   flutter analyze

   # Format code
   dart format .
   ```

4. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```
   Note: The pre-commit hooks will run automatically

5. **Push and Create Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Code Quality Standards

### Commit Message Format
We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `style:` for formatting changes
- `refactor:` for code refactoring
- `test:` for adding tests
- `chore:` for maintenance tasks

### Code Style
- Follow the Flutter style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Write tests for new features

### Testing Requirements
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for critical flows
- Maintain minimum 80% code coverage

## CI/CD Pipeline

Our CI/CD pipeline automatically runs the following checks on every PR:

1. **Analysis**
   - Code formatting
   - Static analysis
   - Linting rules

2. **Testing**
   - Unit tests
   - Widget tests
   - Coverage reporting

3. **Build Verification**
   - Android build
   - iOS build
   - Web build

4. **Security Checks**
   - Dependency vulnerability scanning
   - Package version checks
   - Null safety verification

## Pull Request Process

1. Update the README.md with details of changes if needed
2. Update the CHANGELOG.md with your changes
3. Ensure all CI checks pass
4. Request review from at least one maintainer
5. Address any review comments
6. Once approved, a maintainer will merge your PR

## Getting Help

- Open an issue for bug reports or feature requests
- Join our community chat (if available)
- Check existing issues and PRs before creating new ones

## License

By contributing, you agree that your contributions will be licensed under the project's license.
