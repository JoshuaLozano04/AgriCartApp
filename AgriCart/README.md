# AgriCart Flutter App

**AgriCart** - A mobile marketplace connecting farmers, buyers, suppliers, and agribusinesses for agricultural products in the Philippines. Built with Flutter and featuring a beautiful green and white theme.

## About AgriCart

AgriCart is a comprehensive agricultural marketplace platform that enables direct connections between agricultural producers and consumers. Users can browse products by category, location, and price; communicate with sellers via **real-time chat** powered by WebSocket; and complete purchases with multiple payment options including COD, GCash, and bank transfers.

## Architecture

The app uses **BLoC (Business Logic Component)** pattern for state management, separating business logic from UI.

### Project Structure

```
lib/
├── theme/             # App theme configuration
│   └── app_theme.dart  # Green and white color scheme
├── bloc/              # Business logic components
│   ├── auth/          # Authentication
│   ├── products/      # Product browsing
│   ├── cart/          # Shopping cart
│   ├── orders/        # Order management
│   ├── chat/          # Real-time messaging (WebSocket)
│   └── seller/        # Seller dashboard
├── models/            # Data models
│   ├── user.dart
│   ├── product.dart
│   ├── order.dart
│   ├── cart.dart
│   ├── message.dart
│   └── review.dart
├── services/          # API and external services
│   ├── api_service.dart        # REST API service
│   ├── websocket_service.dart # WebSocket service for real-time chat
│   └── notification_service.dart # Firebase push notifications
├── screens/           # UI screens
│   ├── auth/          # Login, register
│   ├── buyer/         # Product browsing, cart, checkout, orders, reviews
│   ├── seller/        # Seller dashboard, product management, analytics
│   └── chat/          # Chat list and chat detail screens
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
- User registration with role selection (Buyer/Seller)
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
- **Real-time in-app chat** via WebSocket connection
- Live message updates without page refresh
- Chat list and conversation views
- Push notifications (Firebase Cloud Messaging) for new messages and orders

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

**REST API**: All API calls are made through `ApiService` class located in `lib/services/api_service.dart`.

**WebSocket**: Real-time chat connections are handled by `WebSocketService` in `lib/services/websocket_service.dart`.

Configuration via `.env` file:
```env
API_BASE_URL=http://localhost:8000/api
WS_URL=ws://localhost:8000/ws/chat
```

For Android emulator, use:
```env
API_BASE_URL=http://10.0.2.2:8000/api
WS_URL=ws://10.0.2.2:8000/ws/chat
```

## Dependencies

- `flutter_bloc` - State management
- `http` - HTTP client for REST API
- `web_socket_channel` - WebSocket client for real-time chat
- `firebase_core`, `firebase_messaging` - Firebase push notifications
- `image_picker` - Image selection
- `cached_network_image` - Image caching
- `flutter_dotenv` - Environment variable management
- `equatable` - Value equality
- `url_launcher` - Launch phone calls to sellers

## Theme

The app uses a **green and white color scheme**:
- Primary green: `#2E7D32` (or similar shade)
- White background: `#FFFFFF`
- Accent greens for highlights and buttons
- Consistent green/white styling throughout all screens

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
