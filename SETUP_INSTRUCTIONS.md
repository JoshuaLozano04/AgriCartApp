# AgriCart Setup Instructions

Complete step-by-step setup guide for both backend and frontend.

## Prerequisites

- Python 3.8+ installed
- Flutter SDK 3.0+ installed
- MongoDB installed and running
- Firebase project created
- PayMongo account (for payments)

## Backend Setup

### 1. Navigate to Backend directory
```bash
cd Backend
```

### 2. Create and activate virtual environment
```bash
python -m venv venv
# Windows
.\venv\Scripts\Activate.ps1
# Linux/Mac
source venv/bin/activate
```

### 3. Install dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure environment variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Edit `.env` and fill in the following:
- `SECRET_KEY`: Generate a Django secret key
- `FIREBASE_SERVICE_ACCOUNT_PATH`: Path to your Firebase service account JSON file
- `MONGODB_CONNECTION_STRING`: Your MongoDB connection string (default: mongodb://localhost:27017)
- `PAYMONGO_PUBLIC_KEY`: Your PayMongo public key
- `PAYMONGO_SECRET_KEY`: Your PayMongo secret key
- `FCM_SERVER_KEY`: Firebase Cloud Messaging server key

### 5. Run migrations (if using Django models)
```bash
python manage.py migrate
```

### 6. Start the development server
```bash
python manage.py runserver
```

The API will be available at `http://localhost:8000`

## Frontend Setup

### 1. Navigate to AgriCart directory
```bash
cd AgriCart
```

### 2. Install Flutter dependencies
```bash
flutter pub get
```

### 3. Configure Firebase
- Ensure `firebase_options.dart` is properly configured
- The file should already exist with your Firebase project details

### 4. Configure environment variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Edit `.env` and update the following:
- `API_BASE_URL`: Your backend API URL (default: `http://localhost:8000/api`)
  - For Android emulator, use: `http://10.0.2.2:8000/api`
  - For iOS simulator, use: `http://localhost:8000/api` or your local IP
  - For physical device, use your computer's local IP address
- `IMAGE_SERVICE_URL`: Your image service URL (default: `http://localhost:8000/api/images`)

### 5. Run the app
```bash
flutter run
```

## MongoDB Setup

1. Install MongoDB from https://www.mongodb.com/try/download/community
2. Start MongoDB service:
   ```bash
   # Windows (if installed as service)
   net start MongoDB
   
   # Linux/Mac
   sudo systemctl start mongod
   ```
3. MongoDB will run on `localhost:27017` by default

## Firebase Setup

1. Go to Firebase Console: https://console.firebase.google.com
2. Create a new project or use existing
3. Add Android/iOS app to the project
4. Download `google-services.json` (Android) and place in `android/app/`
5. Download `GoogleService-Info.plist` (iOS) and place in `ios/Runner/`
6. Generate and download Service Account Key JSON file
7. Place the service account key in Backend directory and update `.env`

## PayMongo Setup

1. Sign up at https://paymongo.com
2. Get your API keys from the dashboard
3. Add keys to Backend `.env` file

## Testing the Setup

### Backend
1. Start Django server: `python manage.py runserver`
2. Test endpoint: `http://localhost:8000/api/auth/register/`
3. Should return JSON response

### Frontend
1. Run `flutter run`
2. App should launch without errors
3. Test registration/login flow

## Troubleshooting

### Backend Issues
- **Module not found**: Ensure virtual environment is activated
- **MongoDB connection error**: Check MongoDB is running and connection string is correct
- **Firebase error**: Verify service account JSON path is correct

### Frontend Issues
- **Build errors**: Run `flutter clean` then `flutter pub get`
- **API connection**: Check backend is running and URL is correct
- **Firebase errors**: Verify `firebase_options.dart` configuration

## Next Steps

- See `Backend/README.md` for API documentation
- See `AgriCart/README.md` for Flutter architecture details
- See `API_DOCUMENTATION.md` for complete API reference

