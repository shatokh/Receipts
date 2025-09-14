# Biedronka Expenses — MVP

A Flutter app for tracking Biedronka PDF receipts with on-device processing.

## Features

- **Local Processing**: All PDF parsing and data storage happens on your device
- **Biedronka Focus**: Specifically designed for Biedronka receipt format (MVP)
- **Dashboard**: Monthly spending overview with charts and insights
- **Receipt Management**: Browse, search, and view detailed receipt breakdowns
- **Privacy First**: No data sent to external servers (except optional crash reports)

## Requirements

- **Flutter**: 3.24.0 or later
- **Dart**: 3.6.0 or later
- **Android**: JDK 17, minSdk 24, compileSdk/targetSdk 34
- **iOS**: iOS 12.0 or later (prepared but not fully tested)

## Setup Instructions

### 1. Clone and Install Dependencies

```bash
flutter pub get
```

### 2. Android Setup

Ensure you have:
- JDK 17 installed and configured
- Android SDK with API level 34
- Android Gradle Plugin 8.x

The app uses:
- MinSdk: 24 (Android 7.0)
- TargetSdk: 34 (Android 14)
- PdfBox-Android for PDF text extraction

### 3. Run the App

```bash
# Debug build
flutter run

# Release build (Android)
flutter build apk --release
```

### 4. Sample Data

The app includes demo data for August 2025 to showcase functionality:
- 15 sample receipts with realistic Polish grocery items
- Monthly totals from October 2024 to September 2025
- Category breakdowns (Produce, Meat, Dairy, Household, Bakery)

### 5. PDF Import (Demo Mode)

In debug mode, the app can:
- Pick PDF files via Android SAF (Storage Access Framework)
- Process sample receipt text from `assets/sample_receipt.txt`
- Demonstrate the parsing flow without real PDF processing

To test real PDF processing, you need:
- A Biedronka PDF receipt with text layer (not scanned)
- The receipt should contain Polish text with standard Biedronka format

## Enable Sentry Crash Reporting

Crash reporting is disabled by default. To enable:

1. **Get Sentry DSN**: Create account at [sentry.io](https://sentry.io)
2. **Set Environment Variable**: 
   ```bash
   export SENTRY_DSN="your_dsn_here"
   flutter run
   ```
3. **Or pass at build time**:
   ```bash
   flutter run --dart-define=SENTRY_DSN=your_dsn_here
   ```
4. **Enable in Settings**: Use the toggle in app Settings screen

## Architecture

```
lib/
├── app/                    # App-level configuration
│   ├── main_scaffold.dart  # Bottom navigation
│   ├── providers.dart      # Riverpod state management
│   ├── router.dart         # go_router configuration
│   └── theme.dart          # Material 3 theme
├── data/                   # Data layer
│   ├── database.dart       # SQLite setup
│   ├── demo_data.dart      # Sample data
│   └── repositories/       # Data access
├── domain/                 # Business logic
│   ├── models/            # Data models
│   └── services/          # Use cases & parsing
├── features/              # UI screens
│   ├── dashboard/         # Home with KPIs and charts
│   ├── month/            # Monthly overview
│   ├── receipts/         # All receipts list
│   ├── receipt_details/  # Individual receipt view
│   ├── import/           # PDF import screen
│   ├── settings/         # App settings
│   └── onboarding/       # First-run experience
└── platform/             # Platform channels
    └── pdf_text_extractor/ # Android PDF processing
```

## Database Schema

- **receipts**: Main receipt data with totals and metadata
- **line_items**: Individual items per receipt with categories
- **merchants**: Store information (Biedronka data)
- **categories**: Product categorization (Produce, Meat, etc.)
- **monthly_totals**: Precomputed aggregates for performance
- **category_month_totals**: Category breakdowns by month

## Platform Channel (Android)

The app includes Android-specific PDF text extraction using PdfBox-Android:

- **Method Channel**: `pdf_text_extractor`
- **Methods**: `extractTextPages`, `pageCount`, `fileHash`
- **SAF Integration**: Uses Android Storage Access Framework
- **Unicode Handling**: Normalizes text to NFC form for Polish characters

## Testing

Run tests with:

```bash
# Unit tests
flutter test

# Integration tests (if available)
flutter test integration_test/
```

## Build Configuration

The app is configured for:
- **Package Name**: `app.biedronka.biedronka_expenses`
- **Kotlin**: 1.9+ with JDK 17
- **Material 3**: Full Material You theming
- **Offline-First**: No network dependencies in core functionality

## Known Limitations (MVP)

- Only supports Biedronka receipts
- PDF must have text layer (no OCR)
- Polish language parsing rules
- Android-focused (iOS prepared but not fully tested)
- No receipt backup/sync between devices
- No bulk import or batch processing
- Demo data is hardcoded for August 2025

## Support

This is an MVP (Minimum Viable Product) focused on core functionality. For issues:
1. Check that PDF has text layer (not a scanned image)
2. Verify receipt is from Biedronka with standard format
3. Ensure Android requirements are met (API 24+, JDK 17)

## Privacy

- All data processed locally on device
- No network access except optional Sentry crash reports
- PDF files copied to app storage for reliable access
- No analytics or tracking beyond crash reports (if enabled)