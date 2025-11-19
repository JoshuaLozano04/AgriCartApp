# AgriCart Backend - Render Deployment Guide

## 🚀 Quick Deploy to Render

Your Django backend is now ready to deploy to Render with MongoDB Atlas and Upstash Redis!

### Prerequisites

- ✅ MongoDB Atlas cluster: `cluster0.jwfcyuo.mongodb.net`
- ✅ Upstash Redis instance: `fun-hedgehog-24996.upstash.io`
- ✅ Firebase service account JSON file
- ✅ GitHub repository pushed to `Final` branch

---

## 📋 Step-by-Step Deployment

### Step 1: Configure MongoDB Atlas

1. Go to [MongoDB Atlas](https://cloud.mongodb.com/)
2. Navigate to **Network Access** → **Add IP Address**
3. Click **Allow Access from Anywhere** (0.0.0.0/0)
4. Verify your database name is `agricart_db`

### Step 2: Create Render Web Service

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click **New** → **Web Service**
3. Connect your GitHub account and select repository: `JoshuaLozano04/AgriCartApp`
4. Configure service:
   - **Name**: `agricart-backend` (or your choice)
   - **Region**: Singapore (closest to your target users)
   - **Branch**: `Final`
   - **Root Directory**: `Backend`
   - **Runtime**: Python 3
   - **Build Command**: `chmod +x build.sh && ./build.sh`
   - **Start Command**: `daphne -b 0.0.0.0 -p $PORT agricart_api.asgi:application`

### Step 3: Add Environment Variables

Go to **Environment** tab and add these variables:

```bash
# Django Core (REQUIRED)
SECRET_KEY=<generate-new-secure-key>
DEBUG=False
ALLOWED_HOSTS=<your-app>.onrender.com

# CORS (Your Flutter App URL)
CORS_ALLOWED_ORIGINS=https://your-flutter-app.com

# MongoDB Atlas (REQUIRED)
MONGODB_CONNECTION_STRING=mongodb+srv://admin:root@cluster0.jwfcyuo.mongodb.net/
MONGODB_DATABASE_NAME=agriCart

# Upstash Redis (REQUIRED for WebSocket)
REDIS_URL=rediss://default:AWGkAAIncDI4MTdmZWFmNDc5MWY0ZWRjYjgwNmJhOTc1M2ZjMmFhZnAyMjQ5OTY@fun-hedgehog-24996.upstash.io:6379
REDIS_TOKEN=AWGkAAIncDI4MTdmZWFmNDc5MWY0ZWRjYjgwNmJhOTc1M2ZjMmFhZnAyMjQ5OTY

# Firebase (REQUIRED for push notifications)
FIREBASE_PROJECT_ID=agricart-11da1
FIREBASE_SERVICE_ACCOUNT_PATH=/etc/secrets/serviceAccountKey.json
FIREBASE_STORAGE_BUCKET=agricart-11da1.firebasestorage.app

# PayMongo (REQUIRED for payments)
PAYMONGO_PUBLIC_KEY=<your-paymongo-public-key>
PAYMONGO_SECRET_KEY=<your-paymongo-secret-key>

# Security
CSRF_COOKIE_SECURE=True

# Image Service
IMAGE_SERVICE_URL=https://<your-app>.onrender.com/api/images
```

**To generate SECRET_KEY:**

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### Step 4: Upload Firebase Service Account

1. In Render Dashboard, go to your web service
2. Navigate to **Environment** → **Secret Files**
3. Click **Add Secret File**
4. **Filename**: `serviceAccountKey.json`
5. **Contents**: Copy entire contents from `Backend/serviceAccountKey.json`
6. Click **Save**

### Step 5: Deploy

1. Click **Create Web Service**
2. Wait for deployment (5-10 minutes)
3. Monitor logs for any errors

---

## ✅ Testing Your Deployment

### Test API Endpoints

```bash
# Health check
curl https://your-app.onrender.com/api/

# User registration
curl -X POST https://your-app.onrender.com/api/users/register/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test User"}'
```

### Test WebSocket Connection

Use a WebSocket client or your Flutter app to connect:

```
wss://your-app.onrender.com/ws/chat/<conversation_id>/
```

---

## 🔧 Troubleshooting

### Deployment Fails

- Check Render logs for errors
- Verify all environment variables are set
- Ensure `build.sh` has execute permissions

### MongoDB Connection Issues

- Verify IP whitelist includes `0.0.0.0/0`
- Check connection string format
- Confirm database user credentials

### Redis/WebSocket Issues

- Verify `REDIS_URL` and `REDIS_TOKEN` are correct
- Test Upstash Redis connection at console.upstash.com
- Check Render logs for connection errors

### Static Files Not Loading

- Ensure `collectstatic` runs in build.sh
- Verify WhiteNoise is in MIDDLEWARE
- Check STATIC_ROOT and STATIC_URL settings

---

## ⚠️ Important Production Considerations

### 1. Media File Storage

**Current Issue**: Product images stored in `media/uploads/` won't persist on Render (ephemeral filesystem)

**Solutions**:

- **Cloudinary** (Recommended): Free tier, easy integration
- **AWS S3**: Scalable, requires AWS account
- **Firebase Storage**: Already using Firebase

### 2. Render Free Tier Limitations

- App spins down after 15 minutes of inactivity
- First request after spin-down takes 50+ seconds
- 750 hours/month free (enough for 1 app)

**Upgrade to Paid Plan** ($7/month) for:

- Always-on service
- Faster response times
- More resources

### 3. Database Backups

- MongoDB Atlas: Enable automatic backups
- Export important data regularly
- Test restore procedures

### 4. Monitoring

- Set up Render notifications for deployment failures
- Monitor Upstash Redis usage
- Track MongoDB Atlas metrics

---

## 📱 Update Flutter App

After deployment, update your Flutter app's API configuration:

**AgriCart/lib/services/api_config.dart** (or wherever you store API URL):

```dart
class ApiConfig {
  static const String baseUrl = 'https://your-app.onrender.com';
  static const String apiUrl = '$baseUrl/api';
  static const String wsUrl = 'wss://your-app.onrender.com/ws';
}
```

---

## 🎉 Next Steps

1. ✅ Deploy backend to Render
2. ✅ Test all API endpoints
3. ✅ Verify WebSocket connectivity
4. ✅ Test payment flow with PayMongo
5. ✅ Test push notifications
6. ⚠️ Implement media file storage (Cloudinary/S3)
7. ✅ Update Flutter app with production URLs
8. ✅ Test end-to-end flows

---

## 📞 Support Resources

- **Render Docs**: https://render.com/docs
- **MongoDB Atlas**: https://docs.atlas.mongodb.com/
- **Upstash Redis**: https://docs.upstash.com/redis
- **Django Deployment**: https://docs.djangoproject.com/en/5.0/howto/deployment/

---

**Your backend is now production-ready! 🚀**

Remember to keep your environment variables secure and never commit them to Git.
