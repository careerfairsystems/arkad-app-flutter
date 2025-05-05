# Arkad App Flutter

A mobile application for the Arkad career fair, built with Flutter. This cross-platform application provides information about companies, events, and facilitates connections between students and potential employers.
Arkad App is the official mobile application for the Arkad career fair. It allows users to:

- Browse participating companies
- View event schedules and details
- Create and manage user profiles
- Customize app appearance with theme options
- Receive notifications about important events

The application is built for Android, iOS, and web platforms using Flutter.

![Arkad Logo](arkad/assets/icons/arkad_logo_inverted.png)

# Development

## Prerequisites

Before you begin, ensure you have the following installed:
- **Git** for version control
- **IDE**: Visual Studio Code or Android Studio (recommended)

### Platform-specific Requirements
- **Android Development**:
  - Android Studio with Android SDK
  - Android Emulator or physical device

## Getting Started

### 1. Install Flutter and verify installation
Follow the guide at https://docs.flutter.dev/get-started/install

Then verify your installation with
```bash
https://docs.flutter.dev/get-started/install
```
### 2. Clone the Repository

```bash
git clone git@github.com:careerfairsystems/arkad-app-flutter.git
cd arkad-app-flutter
```
### 3. Setup emulator/physical device
TODO: Fix Hanxuan

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
└──
```

## Development

### Workflow

2. Create a new branch for your feature:

   ```bash
   git checkout -b feature/your-feature-name
   ```


3. Test your changes:

   ```bash
   # Run analysis
   flutter analyze

   # Format code
   dart format .

   ```

4. Commit changes after each iteration of your code:

   ```bash
   git add .
   git commit -m "describe your changes"
   ```

5. Push your changes
   ```bash
   git push
   ```
6. Create PR
When you are satisfied with your code and everything works you can create a PR
TODO: Hanxuan describe what they do here


### CI/CD Pipeline

Our GitHub workflow automatically runs checks on every PR to check that your code builds and follows code standards defined.
