# Arkad App Flutter

A mobile application for the Arkad career fair, built with Flutter. This cross-platform application provides information about companies, events, and facilitates connections between students and potential employers.

![Arkad Logo](arkad/assets/icons/arkad_logo_inverted.png)

## Project Overview

Arkad App is the official mobile application for the Arkad career fair. It allows users to:

- Browse participating companies
- View event schedules and details
- Create and manage user profiles
- Customize app appearance with theme options
- Receive notifications about important events

The application is built for Android, iOS, and web platforms using Flutter.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (version 3.13.0 or higher)
- **Dart SDK** (latest stable version)
- **Git** for version control
- **IDE**: Visual Studio Code or Android Studio (recommended)

### Platform-specific Requirements

- **iOS Development**:
  - macOS with Xcode installed
  - iOS Simulator or physical device
- **Android Development**:
  - Android Studio with Android SDK
  - Android Emulator or physical device

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/arkad-app-flutter.git
cd arkad-app-flutter
```

### 2. Install Dependencies

```bash
cd arkad
flutter pub get
```

### 3. Verify Setup

```bash
flutter doctor
flutter analyze
```

### 4. Run the App

```bash
flutter run
```

This will launch the app on your connected device or emulator.

## Project Structure

```
arkad/
├── assets/             # App assets (images, fonts, icons)
├── lib/                # Source code
│   ├── config/         # Configuration files
│   ├── models/         # Data models
│   ├── navigation/     # Navigation and routing
│   ├── providers/      # State management
│   ├── screens/        # UI screens
│   ├── services/       # Services and APIs
│   ├── utils/          # Utility functions
│   └── widgets/        # Reusable UI components
├── test/               # Test files
└── web/                # Web-specific configuration
```

## Development

### Workflow

1. Create a new branch for your feature or bugfix:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following the code style guidelines

3. Test your changes:

   ```bash
   # Run analysis
   flutter analyze

   # Format code
   dart format .

   # Build the app for testing
   flutter build apk --debug
   ```

4. Commit your changes using conventional commit format:

   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

5. Push your changes and create a pull request:
   ```bash
   git push origin feature/your-feature-name
   ```

### Code Quality Standards

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages:

- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `style:` for formatting changes
- `refactor:` for code refactoring
- `test:` for adding tests
- `chore:` for maintenance tasks

### CI/CD Pipeline

Our GitHub workflow automatically runs checks on every PR:

1. **Analysis**: Code formatting and static analysis
2. **Build Verification**: Android, iOS, and web builds
