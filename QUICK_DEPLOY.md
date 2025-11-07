# 🚀 Quick Deployment Steps

## ✅ COMPLETED:
1. ✅ Code pushed to GitHub: https://github.com/nani-coder-ship-it/MyCommunityConnect
2. ✅ Deployment files created (render.yaml)

## 📋 NEXT STEPS (Follow in Order):

### Step 1: Create MongoDB Database (5 minutes)
1. Go to: https://www.mongodb.com/cloud/atlas/register
2. Sign up (free account)
3. Create a free cluster (M0)
4. Click "Connect" → "Connect your application"
5. **Copy the connection string** (looks like: `mongodb+srv://username:password@cluster...`)
6. Replace `<password>` with your actual password
7. Add `/connectapp` at the end before `?retryWrites`
   - Example: `mongodb+srv://user:pass@cluster.net/connectapp?retryWrites=true`

### Step 2: Deploy to Render (10 minutes)
1. Go to: https://render.com/register
2. Sign up with your GitHub account
3. Authorize Render to access your repositories
4. Click "New +" → "Web Service"
5. Click "Connect a repository"
6. Find and select: `nani-coder-ship-it/MyCommunityConnect`
7. Fill in details:
   - **Name**: `mycommunity-backend`
   - **Region**: Singapore
   - **Branch**: main
   - **Root Directory**: `server`
   - **Runtime**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: Free

8. Click "Advanced" and add these Environment Variables:

   | Key | Value |
   |-----|-------|
   | NODE_ENV | production |
   | PORT | 4000 |
   | MONGO_URI | <paste your MongoDB connection string from Step 1> |
   | JWT_SECRET | <any random 32 character string> |
   | ADMIN_CODE | admin2025 |
   | CORS_ORIGIN | * |

9. Click "Create Web Service"
10. **Wait 5-10 minutes** for deployment
11. **Copy your backend URL** (shows at top, like: `https://mycommunity-backend.onrender.com`)

### Step 3: Update Mobile App (2 minutes)
1. In VS Code, open: `mobile/lib/src/services/config_service.dart`
2. Find line 16:
   ```dart
   static const String _kDefaultBaseUrl = 'http://10.109.132.6:4000';
   ```
3. Replace with your Render URL:
   ```dart
   static const String _kDefaultBaseUrl = 'https://mycommunity-backend.onrender.com';
   ```
4. Save the file

### Step 4: Build APK (3 minutes)
Run in terminal:
```bash
cd mobile
flutter build apk --release
```

APK location: `mobile/build/app/outputs/flutter-apk/app-release.apk`

### Step 5: Test (2 minutes)
1. Install APK on your phone
2. Open the app
3. Register a new account
4. Login and test features

## 🎯 Quick Checklist:
- [ ] MongoDB connection string ready
- [ ] Deployed to Render
- [ ] Backend URL copied
- [ ] Updated config_service.dart with Render URL
- [ ] Built release APK
- [ ] Installed and tested on phone

## ⚠️ Important:
- **MongoDB**: Make sure to whitelist all IPs (0.0.0.0/0) in MongoDB Atlas Network Access
- **Render Free Tier**: Server sleeps after 15 min inactivity (first request takes 30-60s)
- **Admin Code**: Use `admin2025` during registration to get admin access

## 🔗 Useful Links:
- GitHub Repo: https://github.com/nani-coder-ship-it/MyCommunityConnect
- MongoDB Atlas: https://cloud.mongodb.com
- Render Dashboard: https://dashboard.render.com

## 💡 Generate JWT Secret:
Run this in terminal to get a random secret:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## 🐛 Troubleshooting:
- **Can't connect**: Check backend URL in config_service.dart
- **Deployment failed**: Check Render logs (Dashboard → Service → Logs)
- **Database error**: Verify MongoDB connection string format
- **Test backend**: Visit `https://your-backend-url.onrender.com/health`

Good luck with your review tomorrow! 🎉
