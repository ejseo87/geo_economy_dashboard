# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

- **Name**: OECD 38개국 경제지표 (Geo Economy Dashboard)
- **Type**: Flutter mobile/web application with Firebase backend and World Bank API integration
- **SDK**: Flutter 3.8.1+
- **Description**: A comprehensive OECD economic indicators dashboard that allows users to compare Korea's economic position with 38 OECD countries through 20 key indicators, featuring real-time data visualization and offline capabilities

## Development Environment

- **Shell**: Use `zsh` for all terminal commands
- **Platform**: Multi-platform Flutter app (iOS, Android, Web, macOS, Linux, Windows)
- **Conversation Language**: Always use Korean for conversation per .cursorrules

## Architecture & Key Technologies

- **State Management**: Riverpod with code generation (`riverpod_generator`, `riverpod_annotation`)
- **Navigation**: GoRouter with authentication guards
- **Backend**: Firebase (Core, Auth, Firestore, Storage) + World Bank API + SQLite (local caching)
- **Data Classes**: Freezed for immutable data models and UI states
- **Code Generation**: build_runner for generating Riverpod and JSON serialization code
- **UI Design System**: Custom design tokens following 10s-1min-5min rule with OECD-friendly color palette
- **Internationalization**: Korean/English (ko/en) support
- **Accessibility**: WCAG compliance, font scaling, color-blind palette

### Project Structure

```
lib/
├── common/                 # Shared utilities and widgets
│   ├── logger.dart        # Centralized logging utility
│   ├── utils.dart         # Common utility functions
│   └── widgets/           # Reusable UI components (cards, buttons, charts)
├── constants/             # Design system constants
│   ├── colors.dart        # Color palette (#0055A4, #00A86B, indicator colors)
│   ├── typography.dart    # Typography system (Noto Sans KR, Roboto)
│   ├── gaps.dart          # Spacing constants
│   └── sizes.dart         # Size constants
├── features/              # Feature-based architecture
│   ├── authentication/    # Login/signup with Firebase Auth + SNS login
│   ├── home/             # Main dashboard with 3-tab structure (10s-1min-5min)
│   ├── search/           # Country/indicator search functionality
│   ├── countries/        # Country detail view with economic indicators
│   ├── indicators/       # Indicator detail view with OECD rankings
│   ├── admin/            # Admin panel (data collection, audit, management)
│   ├── bookmarks/        # User favorites and sharing functionality
│   ├── settings/         # App settings, profile management, language
│   ├── users/            # User profile management with avatar/nickname
│   └── data/             # Data layer (World Bank API, Firestore, SQLite)
├── models/               # Data models for indicators, countries, users
├── services/             # External API services (World Bank, Firebase)
├── router/               # GoRouter configuration with auth guards
└── main.dart            # App entry point with Firebase initialization
```

### Core Features Implementation

#### 1. 10s-1min-5min Rule Dashboard

- **10s Tab**: Country summary card with Top 5 indicators and trend badges
- **1min Tab**: Comparative analysis (Country vs Country OR Indicator vs All Countries)
- **5min Tab**: Complete 20 indicators with QoQ/YoY change arrows

#### 2. Data Architecture

- **Data Priority**: SQLite (local cache) → Firestore → World Bank API
- **Firestore Structure**:
  - `/indicators/{indicatorCode}/series/{countryCode}` (normalized)
  - `/countries/{countryCode}/indicators/{indicatorCode}` (denormalized for speed)
- **20 Core Indicators**: GDP growth, unemployment, inflation, etc. (see PRD section 첨부3)

#### 3. Admin Features (role-based access)

- Data collection from World Bank API
- Firestore audit and cleanup
- System monitoring and user management
- Access: Users with `role: admin`

#### 4. User Management

- Guest access (no login required)
- Firebase Authentication with email/password + SNS login
- Profile management (avatar in Firebase Storage, nickname)
- Bookmark and sharing features (login required)

### State Management Pattern

- **ViewModels**: Use Riverpod providers with `@riverpod` annotation
- **UI States**: Define with Freezed for immutable state classes
- **Repositories**: Separate data layer with repository pattern for World Bank API, Firestore, SQLite
- **Controllers**: Business logic layer that handles data synchronization and UI state updates

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
- **Performance**: Target <2s response time, implement proper caching

### Design System Usage

#### Colors (Indicator-Based)

- **Positive Indicators** (growth=good): Blue (#1E88E5, #90CAF9, #0D47A1)
- **Negative Indicators** (growth=bad): Red/Orange (#E53935, #FF7043)
- **Neutral Indicators**: Purple/Teal (#26A69A, #7E57C2)
- **Missing Data**: Gray (#BDBDBD)
- **UI Colors**: Primary #0055A4, Accent #00A86B, Warning #FFD700

#### Typography

- **Korean**: Noto Sans KR
- **English/Numbers**: Roboto
- **Accessibility**: Font scaling support

#### Components

- **Buttons**: 8px rounded corners, Primary/Secondary variants
- **Cards**: 12px radius, 16px padding, 2dp shadow
- **Charts**: Sparklines, bar charts, line charts with OECD ranking context

### Badge System

- **Trend Badges**: ↑↓ with color coding based on indicator type
- **Percentile Badges**: Top 10% (gold), Q1-Q4 ranking within OECD
- **Freshness Badges**: Data recency indicators (up to date/stale/outdated)

## Data Integration

### World Bank API

- **Endpoint**: https://api.worldbank.org/v2
- **Rate Limiting**: Implement proper throttling and retry logic
- **Data Validation**: Handle missing values and outliers
- **OECD Countries**: Filter to 38 OECD member countries only

### Firebase Configuration

- Firebase is initialized in `main.dart` with error handling
- Firestore for data storage with dual structure (normalized + denormalized)
- Firebase Storage for user avatars
- Authentication state managed through `AuthenticationRepository`

### SQLite Caching

- Local cache for offline functionality
- Auto-cleanup policy for old data
- Priority-based data retrieval system

## Admin Panel Requirements

### Access Control

- Admin access for users with `role: admin` field
- 4-tab dashboard: Overview, Data Collection, Data Management, Settings

### Data Management

- Batch data collection from World Bank API
- Progress tracking and error handling
- Firestore audit capabilities
- Duplicate detection and cleanup

## Internationalization

- Support for Korean (ko) and English (en)
- Proper text handling for mixed Korean/English content
- Currency and number formatting based on locale

## Performance Requirements

- **Response Time**: <2 seconds for all operations
- **Offline Support**: Cache recent data for subway/airplane usage
- **Memory Management**: Efficient image loading and data pagination

## Security Requirements

- HTTPS mandatory for all communications
- User data encryption
- Secure API key management
- Role-based access control for admin features

## Code Generation Requirements

After modifying any files with:

- `@riverpod` annotations
- `@JsonSerializable` classes
- Freezed models

Run: `dart run build_runner build --delete-conflicting-outputs`

## Known Issues & Considerations

- Firebase initialization may fail in some environments (handled gracefully)
- iOS development requires proper codesign setup (use Apple's codesign, not conda's)
- World Bank API rate limits require proper throttling implementation
- Some OECD indicators may have data gaps requiring fallback strategies
- Admin role assignment needs careful security consideration

## Success Metrics Implementation

- Track user engagement: bookmark creation, sharing, search usage
- Monitor data freshness and API reliability
- Measure app performance and crash rates
- A/B testing framework for UI improvements
