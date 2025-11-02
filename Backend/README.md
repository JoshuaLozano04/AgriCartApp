# AgriCart Backend API

Django REST API backend with Django Channels for real-time chat, MongoDB database, and PayMongo payment integration.

## Project Structure

```
Backend/
├── agricart_api/          # Django project settings
│   ├── settings.py        # Main configuration (MongoDB, Redis, Channels)
│   ├── urls.py            # Root URL routing
│   ├── asgi.py            # ASGI configuration (Django Channels)
│   └── wsgi.py            # WSGI configuration
├── apps/                   # Django applications
│   ├── users/             # User authentication & profiles
│   ├── products/           # Product management
│   ├── orders/             # Order processing with real-time updates
│   ├── payments/           # Payment processing (PayMongo)
│   ├── chat/               # Real-time messaging (Django Channels + WebSocket)
│   │   ├── consumers.py   # WebSocket consumer for real-time chat
│   │   ├── routing.py     # WebSocket routing
│   │   └── views.py       # REST API for chat history
│   └── analytics/          # Sales analytics
├── utils/                   # Utility modules
│   ├── mongodb_service.py  # MongoDB CRUD operations
│   ├── fcm_service.py      # Firebase Cloud Messaging (push notifications)
│   ├── paymongo_client.py  # PayMongo integration
│   └── jwt_auth.py        # JWT authentication utilities
├── media/                   # Local media storage (product images)
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
- **WebSocket**: `ws://localhost:8000/ws/chat/<conversation_id>/` - Real-time chat connection
- `POST /api/messages/send/` - Send message (REST fallback)
- `GET /api/messages/conversations/` - Get user's conversations
- `GET /api/messages/conversation/<conversation_id>/` - Get conversation history

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

- **MongoDB**: Primary database for all structured data (users, products, orders, payments, messages, conversations)
- **Django Media Files**: Local file storage for product images (stored in `media/` directory, paths referenced in MongoDB)
- **Redis**: Used as channel layer backend for Django Channels (real-time WebSocket communication)
- **Firebase**: Used only for FCM (Firebase Cloud Messaging) push notifications

## Dependencies

- Django 5.0.1
- Django REST Framework 3.14.0
- Django Channels 4.0.0 (real-time WebSocket support)
- channels-redis 4.1.0 (Redis channel layer)
- daphne 4.0.0 (ASGI server)
- redis 5.0.1 (Redis client)
- Firebase Admin SDK 6.4.0 (for FCM push notifications)
- PyMongo 4.6.1 (MongoDB driver)
- python-decouple 3.8
- Pillow (image processing)

## Real-time Features

The backend uses **Django Channels** with **Redis** as the channel layer to enable:
- Real-time chat messaging via WebSocket
- Real-time order status updates
- Push notifications via Firebase Cloud Messaging
- Live notifications for new orders and messages

WebSocket connections are handled at `/ws/chat/` endpoint.

