# AgriCart - Agricultural Marketplace

🌾 **AgriCart** - Agricultural marketplace app connecting farmers, local buyers, suppliers, and agribusinesses in the Philippines. Built with Flutter and Django, featuring real-time chat, multiple payment options, and comprehensive analytics.

## About

AgriCart is a complete agricultural marketplace platform enabling direct connections between agricultural producers and consumers. The platform supports farmers, local buyers, suppliers/traders, and agribusinesses with features like product browsing, real-time chat, order tracking, and analytics.

## Features

### For Buyers
- Browse products by category, price, or location
- Add to cart and checkout easily
- Real-time chat with sellers
- Track orders in real-time
- Rate and review sellers
- Search and filter products

### For Sellers (Farmers)
- Create seller profile with verification
- Post listings with photos, prices, and quantity
- Manage inventory and sales
- Real-time notifications for orders and inquiries
- Access sales analytics (top products, revenue trends)
- Seller dashboard with comprehensive metrics

### Communication
- Real-time in-app chat powered by Django Channels
- WebSocket-based messaging
- Push notifications via Firebase Cloud Messaging

### Payments
- Cash on Delivery (COD)
- Mobile wallets (GCash)
- Bank transfer integration via PayMongo

### Product Categories
- Fresh Produce (vegetables, fruits)
- Livestock & Poultry
- Seeds & Fertilizers
- Farm Tools & Equipment
- Processed Goods (honey, dairy, meat products)

### Security
- Verified user registration (via ID or phone number)
- JWT-based authentication
- Role-based access control

## Tech Stack

### Frontend
- **Framework**: Flutter 3.0+
- **State Management**: BLoC pattern
- **Theme**: Green and white color scheme
- **Real-time Chat**: WebSocket client

### Backend
- **Framework**: Django 5.0.1 + Django REST Framework
- **Database**: MongoDB (primary data storage)
- **Real-time Chat**: Django Channels + Redis
- **Image Storage**: Local Django media files
- **Push Notifications**: Firebase Cloud Messaging
- **Payments**: PayMongo integration
- **Authentication**: JWT tokens

## Project Structure

```
AgriCartApp/
├── Backend/              # Django REST API backend
│   ├── agricart_api/    # Django project settings
│   ├── apps/            # Django applications
│   │   ├── users/       # User authentication & profiles
│   │   ├── products/    # Product management
│   │   ├── orders/      # Order processing
│   │   ├── payments/    # Payment processing (PayMongo)
│   │   ├── chat/        # Real-time messaging (Django Channels)
│   │   └── analytics/   # Sales analytics
│   └── utils/           # Utility modules
├── AgriCart/            # Flutter mobile application
│   ├── lib/
│   │   ├── bloc/        # BLoC state management
│   │   ├── models/      # Data models
│   │   ├── screens/     # UI screens
│   │   ├── services/    # API and WebSocket services
│   │   └── theme/       # App theme (green/white)
│   └── pubspec.yaml     # Flutter dependencies
├── README.md            # This file
├── SETUP_INSTRUCTIONS.md # Setup guide
└── API_DOCUMENTATION.md  # API reference
```

## Quick Start

1. **Backend Setup**
   ```bash
   cd Backend
   python -m venv venv
   source venv/bin/activate  # or .\venv\Scripts\Activate.ps1 on Windows
   pip install -r requirements.txt
   python manage.py runserver
   ```

2. **Frontend Setup**
   ```bash
   cd AgriCart
   flutter pub get
   flutter run
   ```

3. **Prerequisites**
   - Python 3.8+
   - Flutter SDK 3.0+
   - MongoDB running locally
   - Redis server (for real-time chat)
   - Firebase project configured
   - PayMongo account

For detailed setup instructions, see [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)

## Documentation

- [Setup Instructions](SETUP_INSTRUCTIONS.md) - Complete setup guide
- [Backend README](Backend/README.md) - Backend API documentation
- [Flutter README](AgriCart/README.md) - Flutter app architecture
- [API Documentation](API_DOCUMENTATION.md) - Complete API reference

## Development Status

🚧 **Currently in active development** - Complete rewrite in progress with MongoDB backend, Django Channels for real-time chat, and green/white themed Flutter frontend.

## License

[Add your license here]
