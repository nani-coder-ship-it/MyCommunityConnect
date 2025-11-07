# Deployment Guide for Render

## Step 1: Push Code to GitHub ✅ DONE
Your code is now at: https://github.com/nani-coder-ship-it/MyCommunityConnect

## Step 2: Deploy Backend to Render

### A. Create Render Account
1. Go to https://render.com
2. Click "Get Started for Free"
3. Sign up with your GitHub account
4. Authorize Render to access your repositories

### B. Create MongoDB Database
1. In Render Dashboard, click "New +"
2. Select "PostgreSQL" then switch to "MongoDB" (if available) OR use MongoDB Atlas:
   - Go to https://www.mongodb.com/cloud/atlas
   - Create free account
   - Create a free cluster
   - Get connection string (looks like: `mongodb+srv://username:password@cluster.mongodb.net/connectapp`)

### C. Deploy Backend
1. In Render Dashboard, click "New +" → "Web Service"
2. Connect your GitHub repository: `nani-coder-ship-it/MyCommunityConnect`
3. Configure the service:
   - **Name**: `mycommunity-backend`
   - **Region**: Singapore (or closest to you)
   - **Branch**: `main`
   - **Root Directory**: `server`
   - **Runtime**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free

4. Add Environment Variables (click "Advanced" → "Add Environment Variable"):
   ```
   NODE_ENV=production
   PORT=4000
   MONGO_URI=<your-mongodb-connection-string>
   JWT_SECRET=<generate-random-32-char-string>
   ADMIN_CODE=admin2025
   CORS_ORIGIN=*
   ```

5. Click "Create Web Service"
6. Wait 5-10 minutes for deployment
7. **Copy your backend URL**: Will be like `https://mycommunity-backend.onrender.com`

## Step 3: Update Mobile App with Production URL

1. Open: `mobile/lib/src/services/config_service.dart`
2. Change line 16 from:
   ```dart
   static const String _kDefaultBaseUrl = 'http://10.109.132.6:4000';
   ```
   To:
   ```dart
   static const String _kDefaultBaseUrl = 'https://mycommunity-backend.onrender.com';
   ```

3. Build release APK:
   ```bash
   cd mobile
   flutter build apk --release
   ```

4. APK will be at: `mobile/build/app/outputs/flutter-apk/app-release.apk`

## Step 4: Test Your Deployed App

1. Open the APK on your phone
2. Register a new account
3. Login and test all features
4. For admin access, use the code: `admin2025` during registration

## Important Notes

### Free Tier Limitations:
- Render free tier spins down after 15 min of inactivity
- First request after spin-down takes 30-60 seconds
- Database has storage limits (512 MB on free tier)

### MongoDB Connection String Format:
```
mongodb+srv://username:password@cluster.mongodb.net/connectapp?retryWrites=true&w=majority
```

### Generate JWT Secret (use in terminal):
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Troubleshooting:
- If deployment fails, check Render logs: Dashboard → Your Service → Logs
- If app can't connect, verify the backend URL is correct in config_service.dart
- Test backend health: `https://your-backend-url.onrender.com/health`

## Render Dashboard URLs
- Main Dashboard: https://dashboard.render.com
- Services: https://dashboard.render.com/services
- Logs: Click on your service → Logs tab

## Your Repository
https://github.com/nani-coder-ship-it/MyCommunityConnect

## Contact
If you face any issues:
1. Check Render logs for backend errors
2. Check Flutter logs: `flutter logs`
3. Verify MongoDB connection string is correct
