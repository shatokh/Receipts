# AI Assistant Instructions for Receipts Project

## Project Overview
Receipts is a Flutter application for tracking and analyzing PDF receipts, with all processing done on-device. The app uses a feature-based architecture with the following key components:

- State Management: flutter_riverpod
- Navigation: go_router
- Database: sqflite
- Charts: fl_chart
- Background Tasks: workmanager
- Error Tracking: sentry_flutter

## Project Structure
```
lib/
├── app/                 # App-wide configs and router
├── data/               # Data layer (database, repositories)
├── domain/             # Business logic and models
├── features/           # Feature modules
│   ├── dashboard/      
│   ├── import/         
│   ├── month/          
│   ├── onboarding/     
│   ├── receipts/       
│   ├── receipt_details/
│   └── settings/       
└── platform/           # Platform-specific implementations
```

## Key Architectural Patterns

### Navigation
- Uses go_router with a shell route pattern for the main app scaffold
- Routes are defined in `lib/app/router.dart`
- Main navigation structure:
  - /onboarding
  - /dashboard (home)
  - /month
  - /receipts
  - /receipt/:id
  - /settings
  - /import

### Feature Structure
Each feature module follows a consistent structure:
- `*_view.dart` - Main UI component
- `*_controller.dart` - Business logic using Riverpod
- `*_state.dart` - Feature state models

### Database Operations
- Uses sqflite with a singleton pattern through DatabaseHelper
- Database operations are asynchronous and should use try-catch blocks
- Database files are in `lib/data/database/`

## Development Workflows

### Local Development
1. Run `flutter pub get` to install dependencies
2. Use `flutter run` to start the app in debug mode

### Testing
- Run tests with `flutter test`
- Widget tests should be placed in the corresponding feature's test directory
- Database tests should use sqflite_common_ffi for testing

### Error Handling
- Sentry integration is configurable via SENTRY_DSN environment variable
- Production builds should always include proper error boundaries
- Use Riverpod's AsyncValue for handling loading/error states

## Common Tasks

### Adding a New Feature
1. Create a new directory under `lib/features/`
2. Implement the view, controller, and state files
3. Add the route in `lib/app/router.dart`
4. Update database schema if needed in `lib/data/database/`

### Background Processing
- Background tasks use workmanager package
- Register tasks in `lib/main.dart` under callbackDispatcher
- Keep tasks lightweight to avoid battery drain

## Platform Integration
- Android: Native configuration in `android/`
- iOS: Native configuration in `ios/`
- Database files are stored in app-specific storage
- File picking uses file_picker package for cross-platform compatibility