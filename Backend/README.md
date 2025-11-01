# AgriCart Backend API

Django REST API backend for AgriCart marketplace application.

## Project Structure

```
Backend/
├── agricart_api/          # Django project settings
│   ├── settings.py        # Main configuration
│   ├── urls.py            # Root URL routing
│   └── wsgi.py            # WSGI configuration
├── apps/                   # Django applications
│   ├── users/             # User authentication & profiles
│   ├── products/           # Product management
│   ├── orders/             # Order processing
│   ├── payments/           # Payment processing
│   ├── chat/               # Messaging system
│   └── analytics/          # Sales analytics
├── utils/                   # Utility modules
│   ├── mongodb.py          # MongoDB GridFS service
│   ├── firebase_service.py # Firebase Firestore service
│   ├── paymongo_client.py  # PayMongo integration
│   └── fcm_service.py      # Firebase Cloud Messaging
├── requirements.txt        # Python dependencies
└── .env.example           # Environment variables template
```

## API Endpoints

### Authentication
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - User login
- `POST /api/auth/verify/` - User verification
- `GET /api/users/<user_id>/` - Get user profile
- `PUT /api/users/<user_id>/update/` - Update user profile

### Products
- `GET /api/products/` - List products (with filters)
- `POST /api/products/create/` - Create product
- `GET /api/products/<product_id>/` - Get product details
- `PUT /api/products/<product_id>/update/` - Update product
- `DELETE /api/products/<product_id>/delete/` - Delete product
- `GET /api/images/<image_id>/` - Get product image

### Orders
- `GET /api/orders/` - List orders (filter by user_id and role)
- `POST /api/orders/create/` - Create order
- `GET /api/orders/<order_id>/` - Get order details
- `PUT /api/orders/<order_id>/update-status/` - Update order status

### Payments
- `POST /api/payments/create/` - Create payment
- `POST /api/payments/confirm/` - Confirm payment

### Chat
- `POST /api/messages/send/` - Send message
- `GET /api/messages/conversation/` - Get conversation

### Analytics
- `GET /api/analytics/sales/` - Get sales analytics

## Development

### Running locally
```bash
python manage.py runserver
```

### Environment Variables
See `.env.example` for required environment variables.

## Database

- **Firebase Firestore**: Main database for structured data
- **MongoDB GridFS**: Image storage

## Dependencies

- Django 5.0.1
- Django REST Framework 3.16.1
- Firebase Admin SDK
- PyMongo
- python-decouple

