# Arkad Flutter App - Development Guidelines

## Project Overview

Arkad Flutter app for career fair management - student profiles, company browsing, session applications. Built with Flutter clean architecture, MVVM pattern, command system, and auto-generated API client.

## 🚨 CRITICAL GUIDELINES

### ⚠️ API-First Development

**ALWAYS verify backend API before coding:**

1. **Check backend docs**: `https://staging.backend.arkadtlth.se/api/docs#/`
2. **Verify OpenAPI schema**: `https://staging.backend.arkadtlth.se/api/openapi.json`
3. **Regenerate API client**: `flutter pub run build_runner build --delete-conflicting-outputs`
4. **Validate integration**: Test endpoints before implementing features

### ⚠️ Command State Management

**ALL commands must follow this EXACT defensive pattern:**

```dart
class SignInCommand extends ParameterizedCommand<SignInParams, AuthSession> {
  @override
  Future<void> executeWithParams(SignInParams params) async {
    if (isExecuting) return;

    clearError();           // ⚠️ CRITICAL: Clear stale errors
    setExecuting(true);

    try {
      final result = await _signInUseCase.call(params);
      result.when(
        success: (session) => setResult(session),
        failure: (error) => setError(error),
      );
    } catch (e) {
      setError(UnknownError(e.toString()));
    } finally {
      setExecuting(false);  // ⚠️ CRITICAL: Always stop loading
    }
  }
}
```

### ⚠️ Screen State Reset Pattern

**ALL screens MUST reset command state in initState:**

```dart
@override
void initState() {
  super.initState();
  
  // ⚠️ CRITICAL: Prevent stale state display
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    authViewModel.signInCommand.reset();
  });
}
```

### ⚠️ Bearer Token Handling

**Backend returns tokens WITH "Bearer " prefix. ALWAYS strip before storing:**

```dart
String _stripBearer(String token) {
  return token.startsWith('Bearer ') ? token.substring(7) : token;
}

// In data source implementation
await _secureStorage.write(
  key: 'token', 
  value: _stripBearer(userToken)
);
```

## Folder Structure

```
lib/
├── api/                         # Auto-generated API client
│   └── extensions.dart         # Response handling extensions
├── features/                    # Clean architecture by feature
│   ├── auth/                   # 📚 Reference implementation
│   │   ├── domain/            # Entities, repositories, use cases
│   │   ├── data/              # Remote/local data sources, mappers
│   │   └── presentation/      # Commands, screens, view models
│   ├── profile/               # 📚 Reference implementation
│   ├── company/               # 🔄 Clean architecture + command hybrid
│   ├── student_session/       # 🔄 Clean architecture + command hybrid
│   ├── event/                 # 🚧 Minimal placeholder
│   └── map/                   # 🚧 Minimal placeholder
├── shared/                     # 🏗️ Cross-cutting concerns
│   ├── presentation/          # Base commands, UI components, themes
│   │   ├── commands/         # Command<T>, ParameterizedCommand<T,R>
│   │   ├── widgets/          # ArkadButton, ArkadFormField, AsyncStateBuilder
│   │   └── themes/           # ArkadTheme, ArkadColors, ThemeProvider
│   ├── domain/                # Result<T>, UseCase<T,R>, validation
│   ├── data/                  # BaseRepository, extensions, utilities
│   ├── errors/                # AppError hierarchy, error mapping
│   ├── events/                # Domain events, auth events
│   └── infrastructure/        # File service, core utilities
├── navigation/                 # GoRouter + auth integration
├── services/                   # GetIt dependency injection
└── widgets/                    # App-level shared UI components
```

## Auto-Generated API Integration

### Client Structure

```dart
// Auto-generated at /api/arkad_api/lib/
export 'package:arkad_api/src/api/authentication_api.dart';
export 'package:arkad_api/src/api/companies_api.dart';
export 'package:arkad_api/src/api/user_profile_api.dart';
// ... other APIs

// Generated models
export 'package:arkad_api/src/model/profile_schema.dart';
export 'package:arkad_api/src/model/company_out.dart';
// ... other models
```

### Integration Workflow

```dart
// 1. Repository implementation using generated client
class AuthRepositoryImpl extends BaseRepository {
  final ArkadApi _api;
  
  Future<Result<String>> signUp(SignupData data) {
    return executeOperation(
      () async {
        final schema = SignupSchema((b) => b
          ..email = data.email
          ..password = data.password);
          
        final response = await _api.getAuthenticationApi()
            .userModelsApiBeginSignup(signupSchema: schema);
            
        if (response.isSuccess) {
          return response.data!;
        } else {
          throw Exception(response.error);
        }
      },
      'sign up user',
    );
  }
}

// 2. Response extension usage (from /lib/api/extensions.dart)
extension SuccessResponse<T> on Response<T> {
  bool get isSuccess => statusCode != null && statusCode! >= 200 && statusCode! < 300;
  
  String get error {
    if (isSuccess) return '';
    if (data is String) return data as String;
    // ... handle error extraction
    return 'An error occurred';
  }
}
```

### API Generation Commands

**🚨 CRITICAL: Use OpenAPI CLI Generator (Not build_runner)**

```bash
# Method 1: Use provided scripts (recommended)
./scripts/generate_api.sh          # Linux/macOS
./scripts/generate_api.ps1         # Windows

# Method 2: Manual generation
# Download and run OpenAPI Generator CLI
curl -L https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/7.9.0/openapi-generator-cli-7.9.0.jar -o openapi-generator-cli.jar
java -jar openapi-generator-cli.jar generate \
  -i https://staging.backend.arkadtlth.se/api/openapi.json \
  -g dart-dio \
  -o api/arkad_api \
  --additional-properties=pubName=arkad_api,pubVersion=1.0.0,pubDescription="OpenAPI API client"
flutter pub get

# Clean build if needed (after generation)
flutter clean && flutter pub get
```

**⚠️ Why Not build_runner?**
- Causes circular dependency in CI (arkad_api needed for pub get, but build_runner needs pub get)
- OpenAPI CLI is more reliable and standard industry practice
- No pubspec.yaml manipulation required

## Clean Architecture Implementation

### Feature Development Workflow

```bash
# 1. Verify API changes
curl https://staging.backend.arkadtlth.se/api/openapi.json

# 2. Regenerate client using OpenAPI CLI
./scripts/generate_api.sh

# 3. Create feature structure
lib/features/new_feature/
├── domain/
│   ├── entities/           # Business objects
│   ├── repositories/       # Abstract contracts
│   └── use_cases/         # Business logic
├── data/
│   ├── data_sources/      # Remote/local implementations
│   ├── mappers/           # DTO ↔ Entity conversion
│   └── repositories/      # Repository implementations
└── presentation/
    ├── commands/          # State management commands
    ├── screens/           # UI screens
    ├── view_models/       # Coordinate commands
    └── widgets/           # Feature-specific UI

# 4. Register dependencies in service_locator.dart
# 5. Add providers to main.dart
# 6. Validate implementation
flutter analyze && dart format .
```

### Layer Responsibilities

```dart
// DOMAIN: Business logic and rules
class GetCompaniesUseCase {
  final CompanyRepository repository;
  
  Future<Result<List<Company>>> call([CompanyFilter? filter]) {
    return repository.getCompanies(filter);
  }
}

// DATA: External concerns
class CompanyRepositoryImpl implements CompanyRepository {
  final CompanyRemoteDataSource remoteDataSource;
  final CompanyMapper mapper;
  
  Future<Result<List<Company>>> getCompanies([CompanyFilter? filter]) {
    return executeOperation(
      () async {
        final dtos = await remoteDataSource.fetchCompanies(filter);
        return dtos.map(mapper.fromDto).toList();
      },
      'fetch companies',
    );
  }
}

// PRESENTATION: UI and state management
class GetCompaniesCommand extends ParameterizedCommand<CompanyFilter?, List<Company>> {
  final GetCompaniesUseCase _useCase;
  
  Future<void> loadCompanies({CompanyFilter? filter, bool forceRefresh = false}) {
    return executeWithParams(filter);
  }
}
```

## Shared Directory Architecture

### Purpose: Cross-Cutting Concerns

The `shared/` directory provides **reusable infrastructure** that enables clean architecture across all features:

### Base Commands (`shared/presentation/commands/`)

```dart
// Foundation for all state management
abstract class Command<T> extends ChangeNotifier {
  bool _isExecuting = false;
  AppError? _error;
  T? _result;
  bool _hasBeenExecuted = false;  // ⚠️ Critical for state lifecycle
  
  bool get isExecuting => _isExecuting;
  bool get hasError => _error != null;
  bool get isCompleted => _hasBeenExecuted && !_isExecuting && _error == null;
  bool get isIdle => !_hasBeenExecuted && !_isExecuting && _error == null;
  
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
  
  void reset({bool notify = true}) {
    _isExecuting = false;
    _error = null;
    _result = null;
    _hasBeenExecuted = false;
    if (notify) notifyListeners();
  }
}
```

### Shared UI Components (`shared/presentation/widgets/`)

```dart
// Consistent button system
ArkadButton(
  text: 'Sign In',
  onPressed: () => authViewModel.signIn(email, password),
  isLoading: authViewModel.signInCommand.isExecuting,
  variant: ArkadButtonVariant.primary,
  size: ArkadButtonSize.large,
)

// Reactive state handling
AsyncStateBuilder<List<Company>>(
  command: companyViewModel.getCompaniesCommand,
  builder: (context, companies) => CompanyList(companies),
  loadingBuilder: (context) => CircularProgressIndicator(),
  errorBuilder: (context, error) => ErrorDisplay(error),
)
```

### Theme System (`shared/presentation/themes/`)

```dart
// ✅ ALWAYS use theme colors
backgroundColor: ArkadColors.arkadTurkos,    // Primary brand
backgroundColor: ArkadColors.arkadGreen,     // Success states
backgroundColor: ArkadColors.lightRed,      // Error states

// ❌ NEVER use raw colors
backgroundColor: Colors.blue,      // FORBIDDEN
backgroundColor: Colors.green,     // FORBIDDEN
```

### Repository Foundation (`shared/data/`)

```dart
abstract class BaseRepository {
  Future<Result<T>> executeOperation<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    try {
      final result = await operation();
      return Result.success(result);
    } on NetworkException catch (e) {
      return Result.failure(NetworkError(e.message));
    } catch (e) {
      return Result.failure(UnknownError('Failed to $operationName: $e'));
    }
  }
}
```

## Core Patterns

### State Management (Provider + GetIt + Commands)

```dart
// 1. Service registration (service_locator.dart)
void _setupAuthFeature() {
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      serviceLocator<AuthRemoteDataSource>(),
      serviceLocator<AuthLocalDataSource>(),
    ),
  );
  
  serviceLocator.registerLazySingleton<AuthViewModel>(
    () => AuthViewModel(
      signInUseCase: serviceLocator<SignInUseCase>(),
      // ... other dependencies
    ),
  );
}

// 2. Provider setup (main.dart)
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: serviceLocator<AuthViewModel>()),
    ChangeNotifierProvider.value(value: serviceLocator<CompanyViewModel>()),
    // ... other providers
  ],
  child: MaterialApp.router(/* ... */),
)

// 3. UI consumption
Consumer<AuthViewModel>(
  builder: (context, authViewModel, child) {
    return ArkadButton(
      text: 'Sign In',
      onPressed: authViewModel.signInCommand.isExecuting 
          ? null 
          : () => authViewModel.signIn(email, password),
      isLoading: authViewModel.signInCommand.isExecuting,
    );
  },
)
```

## State Management Architecture

### 4-Layer State Management System

The app uses a structured 4-layer state management approach:

```dart
// Layer 1: COMMANDS - Handle execution state and results
class SignInCommand extends ParameterizedCommand<SignInParams, AuthSession> {
  bool get isExecuting => _isExecuting;
  bool get hasError => _error != null;
  AuthSession? get result => _result;
}

// Layer 2: VIEWMODELS - Coordinate commands and business logic  
class AuthViewModel extends ChangeNotifier {
  AuthViewModel() {
    _signInCommand.addListener(_onSignInCommandChanged);  // Command coordination
  }
  
  Future<void> signIn(String email, String password) {
    return _signInCommand.signIn(email, password);  // Business API
  }
  
  void _onSignInCommandChanged() {
    if (_signInCommand.isCompleted && _signInCommand.result != null) {
      _currentSession = _signInCommand.result;  // State coordination
      _fireAuthEvent(AuthSessionChangedEvent(_signInCommand.result!));  // Event dispatch
    }
    notifyListeners();  // Provider notification
  }
}

// Layer 3: PROVIDER - Reactive state propagation
Consumer<AuthViewModel>(
  builder: (context, authViewModel, child) {
    return ArkadButton(
      isLoading: authViewModel.signInCommand.isExecuting,  // Command state access
      onPressed: () => authViewModel.signIn(email, password),  // ViewModel API call
    );
  },
)

// Layer 4: ROUTER INTEGRATION - Navigation state bridge
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._authViewModel) {
    _authViewModel.addListener(_onAuthStateChanged);  // Bridge pattern
  }
  
  bool get isAuthenticated => _authViewModel.isAuthenticated;
}
```

### State Access Patterns

```dart
// ✅ ACTIONS: Use Provider.of with listen: false  
final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
await authViewModel.signIn(email, password);

// ✅ REACTIVE UI: Use Consumer for automatic rebuilds
Consumer<AuthViewModel>(
  builder: (context, authViewModel, child) {
    if (authViewModel.signInCommand.isExecuting) return LoadingIndicator();
    return LoginForm();
  },
)

// ✅ COMMAND STATE: Check for successful completion before navigation
if (authViewModel.signInCommand.isCompleted && !authViewModel.signInCommand.hasError) {
  context.go('/profile');
}

// ❌ WRONG: Direct command execution
authViewModel.signInCommand.executeWithParams(params);  // Use ViewModel method instead
```

## Cross-Feature Event Messaging

### Event Bus Architecture

Simple, type-safe event bus for loose coupling between features:

```dart
// Event bus singleton with generic type support
class AppEvents {
  static Stream<T> on<T>() => _instance._getStream<T>();
  static void fire(Object event) => _instance._fire(event);
}

// Structured event types
class AuthSessionChangedEvent {
  const AuthSessionChangedEvent(this.session);
  final AuthSession session;
}

class UserLoggedOutEvent {
  const UserLoggedOutEvent();
}
```

### Event Usage Patterns

```dart
// ✅ FIRING EVENTS: From ViewModels only
class AuthViewModel extends ChangeNotifier {
  void _onSignInCommandChanged() {
    if (_signInCommand.isCompleted && _signInCommand.result != null) {
      _fireAuthEvent(AuthSessionChangedEvent(_signInCommand.result!));  // Cross-feature notification
    }
  }
  
  void _fireAuthEvent(Object event) => AppEvents.fire(event);
}

// ✅ SUBSCRIBING TO EVENTS: In ViewModel constructors
class CompanyViewModel extends ChangeNotifier {
  CompanyViewModel() {
    _subscribeToLogoutEvents();
  }
  
  void _subscribeToLogoutEvents() {
    _logoutSubscription = AppEvents.on<UserLoggedOutEvent>().listen((_) {
      _handleUserLogout();  // Feature-specific cleanup
    });
  }
  
  void _handleUserLogout() {
    // Reset feature state
    _currentSearchQuery = '';
    _displayedCompanies = [];
    _getCompaniesCommand.reset();
    notifyListeners();
  }
}

// ✅ CLEANUP: Always dispose subscriptions
@override
void dispose() {
  _logoutSubscription?.cancel();
  super.dispose();
}
```

### Navigation with Authentication

```dart
// Use context methods, NEVER Navigator directly
context.go('/companies');     // Replace current route
context.push('/profile');     // Push new route
context.pop();               // Go back

// Conditional navigation based on successful command completion
if (mounted && authViewModel.signInCommand.isCompleted && !authViewModel.signInCommand.hasError) {
  context.go('/profile');
}
```

### Result Pattern for Error Handling

```dart
sealed class Result<T> {
  const Result();
  
  factory Result.success(T value) = Success<T>;
  factory Result.failure(AppError error) = Failure<T>;
  
  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      Failure<T>(:final error) => failure(error),
    };
  }
}
```

## Development Commands

```bash
# Core Development
flutter run                        # Debug mode
flutter analyze                    # Static analysis
dart format .                      # Code formatting
flutter clean && flutter pub get   # Clean build

# API Client Generation (Use OpenAPI CLI)
./scripts/generate_api.sh                    # Regenerate API client (Linux/macOS)
./scripts/generate_api.ps1                   # Regenerate API client (Windows)

# Testing
flutter test                       # Run unit tests
flutter test integration_test     # Run integration tests
```

## Architecture Status & Migration

### 📚 Reference Implementations
- **Auth Feature**: Production-ready patterns with command system
- **Profile Feature**: Complete clean architecture with file uploads

### 🔄 Hybrid Implementations  
- **Company Feature**: Clean architecture + commands, some legacy patterns
- **Student Session Feature**: Clean architecture + commands, transitioning

### 🚧 Minimal Implementations
- **Event Feature**: Placeholder with basic structure
- **Map Feature**: Placeholder with basic structure

## Essential Configuration Files

### Core App Structure
- `lib/main.dart` - App entry point, provider setup
- `lib/services/service_locator.dart` - Dependency injection container
- `lib/navigation/app_router.dart` - Route definitions with auth guards
- `lib/navigation/router_notifier.dart` - Auth state integration

### Shared Infrastructure
- `lib/shared/domain/result.dart` - Result pattern implementation
- `lib/shared/errors/app_error.dart` - Error hierarchy and handling
- `lib/shared/presentation/commands/base_command.dart` - Command foundation
- `lib/api/extensions.dart` - API response helper extensions

## Key Rules

### Critical Patterns
- **Commands**: Always `clearError()` + try-catch-finally + defensive execution
- **Navigation**: Only navigate on `isCompleted && !hasError`
- **State Reset**: In `initState()` for all auth-related screens  
- **Error Display**: Use `ArkadColors.lightRed` for consistency
- **Token Storage**: Strip "Bearer " prefix before secure storage
- **Boolean Validation**: Use defensive parsing for cached/API data

### State Management Rules
- **Provider Access**: Use `Provider.of(context, listen: false)` for actions only
- **Reactive UI**: Use `Consumer<T>` for automatic rebuilds and state display
- **Command Coordination**: ViewModels coordinate commands, never execute directly
- **Command Listeners**: Always call `notifyListeners()` in ViewModel command listeners
- **State Propagation**: Commands → ViewModels → Providers → UI (4-layer flow)
- **Router Integration**: Use `RouterNotifier` to bridge auth state with navigation

### Event Messaging Rules
- **Event Firing**: Only ViewModels fire events, never from UI or commands
- **Event Subscription**: Subscribe in ViewModel constructors, dispose in `dispose()`
- **Cross-Feature Communication**: Use events for loose coupling between features
- **Event Types**: Create structured event classes, never use primitives
- **Memory Management**: Always cancel event subscriptions in `dispose()` method
- **Cleanup Events**: Use `UserLoggedOutEvent` for feature state reset

### Code Style
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase` 
- **Variables**: `camelCase`
- **Private members**: `_privateMember`

### Dependency Management
- **Version Constraints**: Never use `any` for package versions - always specify ranges (e.g., `dio: ^5.0.0`)
- **API Client Dependencies**: Ensure compatibility between main app and generated API client dependencies
- **Security**: Avoid loose version constraints that could introduce vulnerabilities

### Security Requirements
- **HTTPS**: All API communication
- **Token Storage**: `flutter_secure_storage` only
- **Bearer Token**: Always strip prefix before storage
- **Sensitive Data**: Never log credentials, tokens, or PII

## Dependencies

### Core Stack
- `provider` - State management and reactive UI
- `go_router` - Navigation with auth integration
- `get_it` - Dependency injection container
- `flutter_secure_storage` - Secure token storage

### API & Generation
- `arkad_api` - Auto-generated API client (local package)
- `dio` - HTTP client library used by generated API client
- `openapi_generator_annotations` - Client generation
- `build_runner` - Code generation tooling