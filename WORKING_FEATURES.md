# AgriCart - Working Features

A simple guide to what you can do in the AgriCart app right now.

---

## 📱 About This App

**AgriCart** is a mobile marketplace app that connects farmers with buyers in the Philippines. Think of it like an "online market" where farmers can sell their products and buyers can shop for fresh agricultural goods.

### How This App Was Built

This app was created using modern technology tools:

**Frontend (What Users See and Touch):**
- **Flutter** - This is Google's tool for building mobile apps. It allows us to create one app that works on both Android and iPhone phones. The app you see on your screen - all the buttons, pages, and how it looks - was built with Flutter.

**Backend (The Brain Behind the App):**
- **Django** - This is a Python framework that runs the server and handles all the business logic. It's like the "brain" of the app that processes orders, payments, messages, and stores all the data.
- **MongoDB** - This is the database where all information is stored - like user accounts, products, orders, and messages. Think of it as a big filing cabinet that keeps everything organized.

**Development Tool:**
- **Cursor** - This is an AI-powered code editor that helped build the app faster. It's like having a smart assistant that helps write code, suggests improvements, and catches errors while building the app.

### What This Means for You

Don't worry if you don't understand all these technical terms! What matters is that:

✅ **The app works** - You can use it right now on your phone  
✅ **It's secure** - Your payments and data are protected  
✅ **It's fast** - Everything happens in real-time  
✅ **It looks good** - Beautiful green and white design  

You don't need to know how it works behind the scenes - just enjoy using it!

---

## 🔐 User Account & Login

✅ **Create an account**
- Sign up with email and password
- Choose your role: Buyer or Seller
- Add your name, phone number, and address

✅ **Login to your account**
- Sign in with email and password
- Your login is remembered on your device

✅ **View and update your profile**
- See your account information
- Update your details anytime

---

## 🛒 For Buyers (Shopping & Orders)

### Browsing Products
✅ **Browse all products**
- See products from all sellers
- View product photos, prices, and descriptions

✅ **Search for products**
- Search by product name
- Find what you're looking for quickly

✅ **Filter products**
- Filter by category (vegetables, fruits, livestock, etc.)
- Filter by price range
- Filter by location

✅ **View product details**
- See full product information
- View multiple photos
- Check quantity available
- See seller information

### Shopping Cart
✅ **Add products to cart**
- Add items you want to buy
- Add multiple quantities

✅ **Manage your cart**
- View all items in your cart
- Update quantities
- Remove items
- See total price

### Checkout & Payment
✅ **Place an order**
- Enter shipping address
- Choose payment method:
  - Cash on Delivery (COD)
  - GCash (online payment)
  - Bank Transfer (online payment)

✅ **Online payments (GCash & Bank Transfer)**
- Secure payment processing through PayMongo
- Beautiful branded payment page before checkout
- Automatic redirect to payment gateway
- Payment success/failed pages
- Automatic payment verification
- Deep link back to app after payment

### Order Management
✅ **View your orders**
- See all your past and current orders
- Filter orders by status (pending, confirmed, etc.)

✅ **Track orders**
- See order status updates in real-time
- View order details (items, total, address)
- See payment status
- Track order progress

✅ **Order details**
- View complete order information
- See individual items ordered
- Check shipping address
- View payment method used
- Make payment if not paid yet

---

## 👨‍🌾 For Sellers (Selling & Managing)

### Product Management
✅ **Add products**
- Create product listings
- Add product photos
- Set price and quantity
- Write product description
- Choose product category

✅ **Manage your products**
- View all your products
- Edit product information
- Update prices and quantities
- Delete products

✅ **Inventory tracking**
- See how many items you have in stock
- Stock automatically reduces when orders are placed

### Order Management
✅ **Receive orders**
- See all orders from buyers
- Get notified when new orders come in

✅ **Update order status**
- Mark orders as confirmed
- Update to processing
- Add tracking number when shipping
- Mark as delivered when complete

✅ **View order details**
- See buyer information
- View items ordered
- Check shipping address
- See payment status

### Sales & Analytics
✅ **View sales dashboard**
- See total revenue earned
- View total number of orders
- Check pending orders count
- See recent revenue (last 7 days)
- View recent orders

✅ **Sales analytics**
- Total revenue from paid orders
- Revenue trends over time
- Top selling products
- Sales by product category
- Monthly sales breakdown
- Average order value

---

## 💬 Messaging & Communication

✅ **Chat with sellers/buyers**
- Send messages in real-time
- Receive instant message notifications
- View chat history
- See when messages are sent

✅ **Chat features**
- Real-time messaging (no page refresh needed)
- See conversation list
- Open individual chats
- Send text messages instantly

---

## 💳 Payment Features

✅ **Multiple payment options**
- Cash on Delivery (COD)
- GCash (mobile wallet)
- Bank Transfer

✅ **Online payment process**
- Secure payment gateway integration
- Beautiful branded payment pages
- Automatic payment verification
- Payment status updates
- Automatic revenue tracking for sellers

✅ **Payment confirmation**
- Payment status automatically updates when successful
- Order payment status shows "paid" after successful payment
- Seller revenue updates immediately when payment is successful

---

## 🔔 Notifications

✅ **Push notifications**
- Get notified about new orders
- Receive messages notifications
- Get payment status updates

---

## 📱 App Features

✅ **Beautiful design**
- Green and white theme
- Easy to use interface
- Smooth animations
- Modern look and feel

✅ **Works on Android**
- Fully functional mobile app
- Deep linking support
- External browser integration for payments

✅ **Real-time updates**
- Orders update in real-time
- Messages appear instantly
- No need to refresh the page

---

## 🌾 Product Categories Available

- Fresh Produce (vegetables, fruits)
- Livestock & Poultry
- Seeds & Fertilizers
- Farm Tools & Equipment
- Processed Goods (honey, dairy, etc.)

---

## ✅ What Works Right Now

### Complete Working Features:
1. ✅ User registration and login
2. ✅ Browse and search products
3. ✅ Add to cart and checkout
4. ✅ Place orders with different payment methods
5. ✅ Online payment with GCash and Bank Transfer
6. ✅ Payment success/failed pages with auto-redirect
7. ✅ Order tracking and management
8. ✅ Seller product management
9. ✅ Seller order management
10. ✅ Sales analytics and revenue tracking
11. ✅ Real-time chat messaging
12. ✅ Push notifications
13. ✅ Profile management

### Payment Flow:
1. ✅ Buyer selects payment method at checkout
2. ✅ Creates payment and gets payment URL
3. ✅ Opens branded redirect page
4. ✅ Automatically redirects to PayMongo checkout
5. ✅ Completes payment on PayMongo
6. ✅ Returns to success/failed page
7. ✅ Automatically redirects back to app
8. ✅ Payment status verified and updated
9. ✅ Seller revenue updated immediately

---

## 📝 Notes

- All features listed above are **fully working** and tested
- The app supports both buyers and sellers
- Payments are processed securely through PayMongo
- Real-time features work via WebSocket connections
- Analytics automatically calculate revenue from successful payments

