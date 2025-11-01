# AgriCart API Documentation

Complete REST API endpoint reference with request/response examples.

## Base URL
```
http://localhost:8000/api
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

Payment methods: `cod`, `gcash`, `maya`, `bank_transfer`

## Chat

### Send Message
**POST** `/messages/send/`

Request:
```json
{
  "sender_id": "uuid",
  "receiver_id": "uuid",
  "message": "Hello, is this available?"
}
```

### Get Conversation
**GET** `/messages/conversation/`

Query parameters:
- `user1_id`: first user ID
- `user2_id`: second user ID

## Analytics

### Get Sales Analytics
**GET** `/analytics/sales/`

Query parameters:
- `seller_id`: seller user ID

Response:
```json
{
  "success": true,
  "analytics": {
    "total_revenue": 50000.00,
    "total_orders": 150,
    "top_products": [
      {"product_id": "uuid", "quantity_sold": 100}
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
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 500: Internal Server Error

