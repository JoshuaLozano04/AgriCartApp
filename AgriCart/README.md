# AgriCart Flutter App

**AgriCart** - A mobile marketplace connecting farmers, buyers, suppliers, and traders for agricultural products in the Philippines. Browse, shop, and manage agricultural goods with ease using our Flutter-based application.

## About AgriCart

AgriCart is a comprehensive agricultural marketplace platform that enables direct connections between agricultural producers and consumers. Users can browse products by category, location, and price; communicate with sellers via in-app chat; and complete purchases with multiple payment options including COD, GCash, Maya, and bank transfers.

## Architecture

The app uses **BLoC (Business Logic Component)** pattern for state management, separating business logic from UI.

### Project Structure

```
lib/
├── bloc/              # Business logic components
│   ├── auth/          # Authentication
│   ├── products/      # Product browsing
│   ├── cart/          # Shopping cart
│   ├── orders/        # Order management
│   ├── chat/          # Messaging
│   └── seller/        # Seller dashboard
├── models/            # Data models
│   ├── user.dart
│   ├── product.dart
│   ├── order.dart
│   ├── cart.dart
│   ├── message.dart
│   └── review.dart
├── services/          # API and external services
│   ├── api_service.dart
│   └── notification_service.dart
├── screens/           # UI screens
│   ├── auth/          # Login, register
│   ├── buyer/         # Product browsing, cart, checkout, orders
│   ├── seller/        # Seller dashboard, product management
│   └── common/        # Shared screens (chat)
└── widgets/           # Reusable widgets
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Backend API running
- Firebase project configured

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Configure environment variables:
   - Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
   - Edit `.env` and update:
     - `API_BASE_URL`: Your backend API URL (default: `http://localhost:8000/api`)
     - `IMAGE_SERVICE_URL`: Your image service URL (default: `http://localhost:8000/api/images`)

3. Ensure Firebase is configured:
   - `firebase_options.dart` should be present
   - `google-services.json` (Android) in `android/app/`
   - `GoogleService-Info.plist` (iOS) in `ios/Runner/`

4. Run the app:
```bash
flutter run
```

## Environment Variables

The app uses `.env` file for configuration. Key variables:

- `API_BASE_URL`: Backend API base URL
- `IMAGE_SERVICE_URL`: Image service URL

Create `.env` from `.env.example` and update as needed.

## Features

### Authentication
- User registration with role selection (Buyer/Seller/Trader)
- Login with email and password
- User verification (ID upload, phone verification)

### Buyer Features
- Browse products by category
- Search and filter products
- View product details with images
- Shopping cart management
- Checkout with payment options
- Order tracking and history
- Chat with sellers

### Seller Features
- Seller dashboard with sales overview
- Product listing with photo upload
- Inventory management
- Sales analytics dashboard
- Order management
- Chat with buyers

### Communication
- In-app chat interface
- Push notifications (Firebase Cloud Messaging)

## BLoC Pattern

### Example: Products BLoC

**Events:**
- `LoadProductsEvent` - Load products with filters
- `LoadProductDetailsEvent` - Load single product

**States:**
- `ProductsLoading` - Loading state
- `ProductsLoaded` - Products loaded successfully
- `ProductsError` - Error state

**Usage:**
```dart
BlocBuilder<ProductsBloc, ProductsState>(
  builder: (context, state) {
    if (state is ProductsLoaded) {
      return ListView(...);
    }
    return CircularProgressIndicator();
  },
)
```

## API Integration

All API calls are made through `ApiService` class located in `lib/services/api_service.dart`.

The base URL is configured via `.env` file:
```env
API_BASE_URL=http://localhost:8000/api
```

## Dependencies

- `flutter_bloc` - State management
- `http` - HTTP client
- `firebase_core`, `firebase_auth`, `firebase_messaging` - Firebase services
- `image_picker` - Image selection
- `cached_network_image` - Image caching
- `flutter_dotenv` - Environment variable management
- `equatable` - Value equality

## State Management

The app uses BLoC pattern where:
- **Events** represent user actions
- **BLoC** processes events and emits states
- **States** represent the UI state
- **Widgets** react to state changes

## Navigation

Routes are defined in `main.dart`:
- `/` - Login screen
- `/home` - Products list (after login)

## Development

### Running Tests
```bash
flutter test
```

### Building
```bash
# Android
flutter build apk

# iOS
flutter build ios
```

## Troubleshooting

### Environment Variables Not Loading
- Ensure `.env` file exists in the root of `AgriCart/` directory
- Check that `.env` is listed in `pubspec.yaml` under `assets:`
- Restart the app after changing `.env`

### API Connection Issues
- Verify `API_BASE_URL` in `.env` matches your backend server
- Check that backend is running and accessible
- For Android emulator, use `http://10.0.2.2:8000/api` instead of `localhost`
- For iOS simulator, use `http://localhost:8000/api` or your local IP
