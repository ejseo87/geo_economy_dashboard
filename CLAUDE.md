# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

- **Name**: geo_economy_dashboard
- **Type**: Flutter mobile/web application with Firebase backend
- **SDK**: Flutter 3.8.1+
- **Description**: A Flutter-based geo economy dashboard application with authentication and settings management

## Development Environment

- **Shell**: Use `zsh` for all terminal commands
- **Platform**: Multi-platform Flutter app (iOS, Android, Web, macOS, Linux, Windows)
- **Conversation Language**: Always use Korean for conversation per .cursorrules

## Architecture & Key Technologies

- **State Management**: Riverpod with code generation (`riverpod_generator`, `riverpod_annotation`)
- **Navigation**: GoRouter with authentication guards
- **Backend**: Firebase (Core, Auth, Firestore, Storage)
- **Data Classes**: Freezed for immutable data models and UI states
- **Code Generation**: build_runner for generating Riverpod and JSON serialization code
- **UI Design System**: Custom design tokens with consistent color palette and typography

### Project Structure

```
lib/
├── common/                 # Shared utilities and widgets
│   ├── logger.dart        # Centralized logging utility
│   ├── utils.dart         # Common utility functions
│   └── widgets/           # Reusable UI components
├── constants/             # Design system constants
│   ├── colors.dart        # Color palette (#0055A4, #00A86B, etc.)
│   ├── typography.dart    # Typography system (Noto Sans KR, Roboto)
│   ├── gaps.dart          # Spacing constants
│   └── sizes.dart         # Size constants
├── features/              # Feature-based architecture
│   ├── authentication/    # Login/signup with Firebase Auth
│   ├── home/             # Main dashboard
│   ├── settings/         # App settings with SharedPreferences
│   └── users/            # User profile management
├── router/               # GoRouter configuration with auth guards
└── main.dart            # App entry point with Firebase initialization
```

### State Management Pattern

- **ViewModels**: Use Riverpod providers with `@riverpod` annotation
- **UI States**: Define with Freezed for immutable state classes
- **Repositories**: Separate data layer with repository pattern
- **Controllers**: Business logic layer that updates UI state

## Common Commands

```bash
# Install dependencies
flutter pub get

# Code generation (run after adding Riverpod providers or Freezed classes)
dart run build_runner build

# Watch mode for continuous code generation during development
dart run build_runner watch

# Run the app
flutter run

# Run on specific device
flutter run -d macos
flutter run -d chrome

# Run tests
flutter test

# Code analysis
flutter analyze

# Format code
dart format .

# Clean build artifacts
flutter clean

# Build for production
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
```

## Development Guidelines (per .cursorrules)

- **Language**: Use English for code, Korean for conversation
- **Type Safety**: Always declare types, avoid `var`
- **Architecture**: Follow clean architecture with feature-based organization
- **Widget Structure**: Avoid deep nesting, break into smaller reusable widgets
- **State**: Use Riverpod for state management
- **Testing**: Write unit tests for public functions, widget tests for UI

### Design System Usage

- **Colors**: Use `AppColors` constants (primary: #0055A4, accent: #00A86B)
- **Typography**: Use `AppTypography` styles with appropriate fonts
- **Buttons**: Use `FormButtonWidget` with `ButtonType.primary` or `ButtonType.secondary`
- **Cards**: Use `AppCard` component for consistent card styling (12px radius, 16px padding, 2dp shadow)

## Firebase Configuration

- Firebase is initialized in `main.dart` with error handling
- `GoogleService-Info.plist` is configured for iOS
- `google-services.json` is configured for Android
- Authentication state is managed through `AuthenticationRepository`

## Code Generation Requirements

After modifying any files with:

- `@riverpod` annotations
- `@freezed` classes
- `@JsonSerializable` classes

Run: `dart run build_runner build --delete-conflicting-outputs`

## Known Issues

- Firebase initialization may fail in some environments (handled gracefully)
- iOS development requires proper codesign setup (use Apple's codesign, not conda's)
