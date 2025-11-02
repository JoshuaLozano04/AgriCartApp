# AgriCart API Documentation

Complete REST API and WebSocket endpoint reference with request/response examples.

## Base URLs

**REST API**: `http://localhost:8000/api`

**WebSocket**: `ws://localhost:8000/ws/chat/`

## Authentication

All REST API endpoints (except registration and login) require JWT authentication via `Authorization` header:
```
Authorization: Bearer <jwt_token>
```

## Authentication

### Register User
**POST** `/auth/register/`

Request body:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "full_name": "John Doe",
  "phone_number": "+639123456789",
  "role": "buyer",
  "address": "Manila, Philippines"
}
```

Response:
```json
{
  "success": true,
  "message": "User registered successfully",
  "user_id": "uuid-here"
}
```

### Login
**POST** `/auth/login/`

Request body:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    "user_id": "uuid",
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "buyer",
    "is_verified": false
  }
}
```

### Verify User
**POST** `/auth/verify/`

Request body:
```json
{
  "user_id": "uuid",
  "verification_type": "id",
  "verification_data": "base64-encoded-image-or-code"
}
```

## Products

### List Products
**GET** `/products/`

Query parameters:
- `category`: fresh_produce, livestock_poultry, seeds_fertilizers, farm_tools, processed_goods
- `min_price`: minimum price filter
- `max_price`: maximum price filter
- `location`: location filter
- `search`: search term
- `seller_id`: filter by seller

Response:
```json
{
  "success": true,
  "products": [...],
  "count": 10
}
```

### Get Product
**GET** `/products/{product_id}/`

Response:
```json
{
  "success": true,
  "product": {
    "product_id": "uuid",
    "seller_id": "uuid",
    "name": "Fresh Tomatoes",
    "description": "...",
    "category": "fresh_produce",
    "price": 150.00,
    "quantity": 50,
    "location": "Manila",
    "image_ids": ["img-id-1", "img-id-2"]
  }
}
```

### Create Product
**POST** `/products/create/`

Request (multipart/form-data):
- `seller_id`: string
- `name`: string
- `description`: string
- `category`: string
- `price`: number
- `quantity`: number
- `location`: string
- `images`: file[] (optional)

### Get Image
**GET** `/images/{image_id}/`

Returns image file directly.

## Orders

### Create Order
**POST** `/orders/create/`

Request:
```json
{
  "buyer_id": "uuid",
  "seller_id": "uuid",
  "items": [
    {
      "product_id": "uuid",
      "quantity": 2,
      "price": 150.00
    }
  ],
  "shipping_address": "123 Main St, Manila",
  "payment_method": "cod",
  "total_amount": 300.00
}
```

### List Orders
**GET** `/orders/`

Query parameters:
- `user_id`: user ID
- `role`: "buyer" or "seller"

### Update Order Status
**PUT** `/orders/{order_id}/update-status/`

Request:
```json
{
  "status": "confirmed",
  "tracking_number": "TRACK123" (optional)
}
```

## Payments

### Create Payment
**POST** `/payments/create/`

Request:
```json
{
  "order_id": "uuid",
  "amount": 300.00,
  "payment_method": "cod"
}
```

Payment methods: `cod`, `gcash`, `bank_transfer`

## Chat

### WebSocket Real-time Chat
**WebSocket** `ws://localhost:8000/ws/chat/<conversation_id>/`

Connect to this endpoint for real-time bidirectional messaging.

**Connection**: 
- Requires JWT token in query parameter: `?token=<jwt_token>`
- Connection URL format: `ws://localhost:8000/ws/chat/<conversation_id>/?token=<jwt_token>`

**Send Message** (via WebSocket):
```json
{
  "type": "chat_message",
  "message": "Hello, is this available?",
  "sender_id": "uuid",
  "receiver_id": "uuid"
}
```

**Receive Message** (via WebSocket):
```json
{
  "type": "chat_message",
  "message": "Yes, it's available!",
  "sender_id": "uuid",
  "receiver_id": "uuid",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### REST API Endpoints (Fallback/Sync)

**Create or Get Conversation**
**POST** `/api/messages/conversation/create/`

Request:
```json
{
  "user1_id": "uuid",
  "user2_id": "uuid"
}
```

Response:
```json
{
  "success": true,
  "conversation_id": "conv-uuid",
  "conversation": {...}
}
```

**Get User Conversations**
**GET** `/api/messages/conversations/`

Query parameters:
- `user_id`: user ID

Response:
```json
{
  "success": true,
  "conversations": [
    {
      "conversation_id": "uuid",
      "other_user": {...},
      "last_message": {...},
      "unread_count": 2
    }
  ]
}
```

**Get Conversation History**
**GET** `/api/messages/conversation/<conversation_id>/`

Response:
```json
{
  "success": true,
  "messages": [
    {
      "message_id": "uuid",
      "sender_id": "uuid",
      "receiver_id": "uuid",
      "message": "Hello!",
      "timestamp": "2024-01-15T10:30:00Z",
      "is_read": true
    }
  ]
}
```

**Send Message** (REST fallback)
**POST** `/api/messages/send/`

Request:
```json
{
  "conversation_id": "uuid",
  "sender_id": "uuid",
  "receiver_id": "uuid",
  "message": "Hello, is this available?"
}
```

**Mark Messages as Read**
**PUT** `/api/messages/conversation/<conversation_id>/mark-read/`

Request:
```json
{
  "user_id": "uuid"
}
```

## Analytics

### Get Sales Analytics
**GET** `/analytics/sales/`

Query parameters:
- `seller_id`: seller user ID (required)
- `start_date`: Start date for analytics (optional, ISO format)
- `end_date`: End date for analytics (optional, ISO format)

Response:
```json
{
  "success": true,
  "analytics": {
    "total_revenue": 50000.00,
    "total_orders": 150,
    "pending_orders": 5,
    "completed_orders": 140,
    "revenue_trends": [
      {"date": "2024-01-01", "revenue": 1200.00},
      {"date": "2024-01-02", "revenue": 1500.00}
    ],
    "top_products": [
      {
        "product_id": "uuid",
        "product_name": "Fresh Tomatoes",
        "quantity_sold": 100,
        "revenue": 15000.00
      }
    ],
    "categories_performance": [
      {"category": "fresh_produce", "revenue": 30000.00, "orders": 80}
    ]
  }
}
```

## Error Responses

All endpoints return errors in this format:
```json
{
  "success": false,
  "message": "Error description"
}
```

HTTP Status Codes:
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized (missing or invalid JWT token)
- 403: Forbidden
- 404: Not Found
- 500: Internal Server Error

## WebSocket Status Codes

WebSocket connections may close with these codes:
- 1000: Normal closure
- 1001: Going away (server restart)
- 1008: Policy violation (invalid token)
- 4000: Custom - Authentication failed
- 4001: Custom - Conversation not found
- 4002: Custom - User not authorized for this conversation

