# Arkad App Flutter

A mobile application for the Arkad career fair, built with Flutter. This cross-platform application provides information about companies, events, and facilitates connections between students and potential employers. Arkad App is the official mobile application for the Arkad career fair.

## Getting Started

#### Install Flutter SDK

- Visit the [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)
- Select your operating system (Windows, macOS, or Linux)
- Download the Flutter SDK and extract it to a location on your computer
- Add Flutter to your PATH:
  - Windows: Update your System Variables to include the Flutter bin directory
  - macOS/Linux: Add the Flutter bin directory to your PATH in your shell profile

#### Verify Flutter Installation

Open a terminal or command prompt and run:

```bash
flutter --version
```

You should see information about the installed Flutter version.

### Clone the Repository

Open a terminal and run:

```bash
git clone git@github.com:careerfairsystems/arkad-app-flutter.git
cd arkad-app-flutter
```

### Set Up Android Development Environment

#### Install Android Studio

- Download Android Studio from the [official website](https://developer.android.com/studio)
- Run the installer and follow the setup wizard
- When prompted, choose _Standard_ setup.
- Accept the license to start downloading the SDK components

Now Andriod Studio should be correctly installed.

#### Configure Android SDK

- Insidef Android Studio, navigate to Tools → SDK Manager
- In the SDK Tools tab, make sure these components are installed:
  - Android SDK Command-line Tools (Not installed by default, select it and apply to install)
  - Android SDK Build-Tools
  - Android Emulator
  - Android SDK Platform-Tools

#### Accept Android Licenses

Run this command to accept all Android licenses:

```bash
flutter doctor --android-licenses
```

Follow the prompts and type "y" to accept each license.

#### Verify Setup

Run the Flutter doctor command to ensure everything is set up correctly:

```bash
flutter doctor
```

Fix any issues reported by the command before proceeding.

### Set Up an Emulator

#### Create a Virtual Device

- In Android Studio, click on Device Manager (or Tools → AVD Manager)
- Click "Create Virtual Device"
- Select a phone model (e.g., Pixel 6)
- Choose a system image (Android 12/API level 34 or newer recommended)
- Complete the setup with default options

#### Start the Emulator

- In the AVD Manager, click the play button next to your virtual device
- Wait for the emulator to start completely

Alternatively, you can connect a physical Android device with USB debugging enabled.

### Install Project Dependencies

In the project directory, run:

```bash
flutter pub get
```

This will download and install all the required packages for the project.

### Generating API

This project uses the [OpenAPI Generator](https://openapi-generator.tech/) to generate API client code. To generate the API client, follow these steps:

```sh
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run the App

Make sure your emulator is running or physical device is connected, then execute:

```bash
flutter run
```

The app will build and launch on the selected device.

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

Start off by selecting a task you want to work on. Read through the description and understand the requirements. Ask for clarification if something is ambigious or worth disccusing.

1. Create a new branch for your feature:

   ```bash
   git checkout -b feature/trello-card-id
   ```

2. Implement your changes, try to maintain a solid code quality

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

5. Push your changes:
   ```bash
   git push
   ```
6. Create a Pull Request (PR) when you are satisfied with your solution. It should be tested and complete according to your standard.

### CI/CD Pipeline

Our GitHub workflow automatically runs checks on every PR to verify that your code builds and follows the defined code standards.
