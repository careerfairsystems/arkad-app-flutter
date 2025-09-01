# Arkad Flutter App - Development Guidelines

## Project Overview

Arkad Flutter app for career fair management - student profiles, company browsing, session applications. Built with Flutter clean architecture, MVVM pattern, and auto-generated API client.

## 🚨 CRITICAL GUIDELINES

### ⚠️ API-First Development

**ALWAYS verify backend API before coding:**

1. Check docs: `https://staging.backend.arkadtlth.se/api/docs#/`
2. Verify OpenAPI: `https://staging.backend.arkadtlth.se/api/openapi.json`
3. Regenerate client: `flutter pub run build_runner build --delete-conflicting-outputs`
4. Ask for clarification if unclear

### ⚠️ View Models vs API Models

**API Models** (`/api/arkad_api/`): Auto-generated DTOs for type-safe API communication
**View Models** (`/lib/features/*/presentation/view_models/`): UI state management, business logic, caching

```dart
// ❌ WRONG: Direct API usage
final response = await api.getCompaniesApi().getCompanies();

// ✅ CORRECT: View Model abstraction
final companyModel = Provider.of<CompanyModel>(context);
await companyModel.getAllCompanies(); // Handles loading, caching, errors
```

### 🔑 Bearer Token Handling

Backend returns tokens WITH "Bearer " prefix. Always strip before storing:

```dart
final userToken = res.data!;
final cleanToken = userToken.startsWith('Bearer ')
    ? userToken.substring(7)
    : userToken;
_apiService.setBearerAuth("AuthBearer", cleanToken);
```

### Base Classes & Abstractions

- **Command System**: Abstract base classes
- **UI Components**: Unified button, form field, and state management widgets
- **Repository Base**: Common error handling, retry logic, and caching
- **Consistent Patterns**: Standardized naming and behavior across all features
- **Theme Management**: Moved to shared layer with Provider integration

## Folder Structure

```
lib/
├── features/                    # 🎯 ALL FEATURES USE CLEAN ARCHITECTURE
│   ├── auth/
│   │   ├── domain/             # Entities, repositories, use cases
│   │   ├── data/              # Data sources, mappers, repository impl
│   │   └── presentation/      # Screens, commands, view models, widgets
│   ├── profile/               # Same clean architecture structure
│   ├── company/               # Full clean architecture with filtering
│   ├── student_session/       # Complete clean architecture
│   ├── event/                 # Minimal clean architecture (placeholder)
│   └── map/                   # Minimal clean architecture (placeholder)
├── navigation/               # GoRouter + RouterNotifier
├── services/                 # GetIt service locator (organized by features)
├── shared/                   # Enhanced with base classes and abstractions
│   ├── presentation/         # Base commands, UI components, themes
│   │   ├── commands/        # BaseCommand, ParameterizedCommand, etc.
│   │   ├── widgets/         # ArkadButton, ArkadFormField, AsyncStateBuilder
│   │   └── themes/          # ArkadTheme, ThemeProvider
│   ├── data/                # Repository base classes
│   │   └── repositories/    # BaseRepository, CachedRepositoryMixin
│   ├── domain/              # result.dart, use_case.dart
│   ├── errors/              # app_error.dart, error_mapper.dart
│   ├── events/              # Domain events
│   └── infrastructure/      # File service, utilities
├── config/                   # API config
├── utils/                    # Validation, helpers
├── widgets/                  # Shared UI components (navigation bar)
└── api/                      # Auto-generated API client extensions
```

## Core Patterns

### State Management (Provider + GetIt)

```dart
// 1. Register in service_locator.dart
serviceLocator.registerLazySingleton<AuthViewModel>(() => AuthViewModel(...));

// 2. Provider setup in main.dart
ChangeNotifierProvider.value(value: serviceLocator<AuthViewModel>())

// 3. Usage in widgets
Consumer<AuthViewModel>(
  builder: (context, authViewModel, child) {
    if (authViewModel.signInCommand.isExecuting) return LoadingIndicator();
    return LoginForm(onSignIn: authViewModel.signIn);
  }
)
```

### Navigation (GoRouter)

```dart
// Use GoRouter methods, NOT Navigator
context.go('/path');      // Replace route
context.push('/path');    // Push route
context.pop();            // Go back
```

### API Integration

```dart
// Auto-generated client usage
final response = await _api.getApi().getData();
if (response.isSuccess) {
  return response.data;
} else {
  throw Exception(response.error);
}
```

### Clean Architecture Pattern (Auth/Profile)

```dart
// Domain Entity
class User {
  final String email;
  final String name;
  // ...
}

// Use Case
class SignInUseCase {
  Future<Result<AuthSession>> execute(String email, String password);
}

// ✅ NEW: Command using Base Classes
class SignInCommand extends ParameterizedCommand<SignInParams, AuthSession> {
  @override
  Future<void> executeWithParams(SignInParams params) async {
    // Base class handles state management automatically
    setExecuting(true);
    final result = await _useCase.call(params);
    result.when(
      success: (session) => setResult(session),
      failure: (error) => setError(error),
    );
    setExecuting(false);
  }

  // Convenience method
  Future<void> signIn(String email, String password) {
    return executeWithParams(SignInParams(email: email, password: password));
  }
}

// ViewModel (Coordinates Commands)
class AuthViewModel extends ChangeNotifier {
  SignInCommand get signInCommand => _signInCommand;

  Future<void> signIn(String email, String password) {
    return _signInCommand.signIn(email, password);
  }
}
```

### Result Pattern (Error Handling)

```dart
// Consistent error handling
sealed class Result<T> {
  factory Result.success(T value) = Success<T>;
  factory Result.failure(AppError error) = Failure<T>;

  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  });
}
```

## 🏗️ Base Classes & Abstractions

### Command Base Classes (`lib/shared/presentation/commands/`)

```dart
// All commands extend these base classes for consistent state management
abstract class Command<T> extends ChangeNotifier {
  bool get isExecuting;
  bool get hasError;
  T? get result;
  AppError? get error;
}

class SignInCommand extends ParameterizedCommand<SignInParams, AuthSession> {
  Future<void> signIn(String email, String password) => executeWithParams(...);
}
```

### Shared UI Components (`lib/shared/presentation/widgets/`)

```dart
// Consistent state handling
AsyncStateBuilder<Profile>(
  command: profileViewModel.getProfileCommand,
  builder: (context, profile) => ProfileDisplay(profile),
  loadingBuilder: (context) => LoadingIndicator(),
)

// Unified buttons
ArkadButton(
  text: 'Sign In',
  onPressed: () => viewModel.signIn(),
  isLoading: viewModel.signInCommand.isExecuting,
)

// Enhanced form fields
ArkadFormFieldConfig.email(
  controller: emailController,
  validator: EmailValidator.validate,
)
```

### Repository Base (`lib/shared/data/repositories/`)

```dart
class AuthRepositoryImpl extends BaseRepository {
  Future<Result<AuthSession>> signIn(String email, String password) {
    return executeOperation(
      () async => _performSignIn(email, password),
      'sign in user',
    );
  }
}
```

## Essential Files

### Configuration

- `lib/main.dart` - App entry, provider setup
- `lib/services/service_locator.dart` - Dependency injection
- `lib/navigation/app_router.dart` - Routing configuration
- `lib/navigation/router_notifier.dart` - Auth state bridge

### Clean Architecture Features

- `lib/features/auth/presentation/view_models/auth_view_model.dart`
- `lib/features/profile/presentation/view_models/profile_view_model.dart`

### Legacy View Models (TODO: Migrate)

- `lib/view_models/company_model.dart`
- `lib/view_models/student_session_model.dart`
- `lib/view_models/theme_model.dart`

### Shared Infrastructure

- `lib/shared/domain/result.dart` - Result pattern
- `lib/shared/errors/app_error.dart` - Error hierarchy
- `lib/api/extensions.dart` - API response extensions

## Development Workflow

### Feature Development

```bash
# 1. API verification
flutter pub run build_runner build --delete-conflicting-outputs

# 2. Follow clean architecture for new features
lib/features/new_feature/
├── domain/      # Entities, repositories, use cases
├── data/        # Data sources, mappers, repository impl
└── presentation/ # Commands, view models, widgets

# 3. Register in service_locator.dart
# 4. Add to providers in main.dart
# 5. Validate
flutter analyze && dart format .
```

### Legacy Pattern (Company/StudentSession)

```dart
class FeatureModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<Data> _data = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Data> get data => _data;

  Future<bool> loadData() async {
    _setLoading(true);
    try {
      final response = await _api.getData();
      if (response.isSuccess) {
        _data = response.data ?? [];
        return true;
      } else {
        _setError(response.error);
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }
}
```

## Commands Reference

### Development

```bash
flutter run                     # Debug mode
flutter analyze                 # Static analysis
dart format .                   # Code formatting
flutter clean && flutter pub get # Clean build
```

### API Generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Architecture Migration Plan

### Phase 1: Legacy Fixes (Current)

- Fix CompanyModel to extend ChangeNotifier
- Replace Navigator.push() with GoRouter
- Standardize error handling

### Phase 2: Feature Migration

- Migrate CompanyModel to clean architecture
- Migrate StudentSessionModel to clean architecture
- Add Repository pattern for legacy features

### Phase 3: Advanced Patterns

- Offline-first with local persistence
- Comprehensive testing infrastructure
- Performance optimizations

## Key Rules

### Code Style

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables: `camelCase`
- Private: `_privateMember`

### State Management Rules

- All view models extend `ChangeNotifier`
- Use `Provider.of(context, listen: false)` for actions
- Use `Consumer<T>` for reactive UI
- Register services in `service_locator.dart`

### Navigation Rules

- Use `context.go()` and `context.push()`
- Define routes in `app_router.dart`
- NO direct Navigator usage

### Security Requirements

- HTTPS for all API calls
- Store tokens in `flutter_secure_storage`
- Strip "Bearer " prefix before storing tokens
- Never log sensitive data

## Dependencies

### Core

- `provider` - State management
- `go_router` - Navigation
- `get_it` - Dependency injection
- `flutter_secure_storage` - Token storage

### API & Generation

- `arkad_api` - Auto-generated client (local)
- `openapi_generator` - Client generation
- `build_runner` - Code generation
