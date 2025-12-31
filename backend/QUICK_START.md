# 🚀 Quick Start Guide

## Starting the Backend Server

### Method 1: Easy Start (Recommended)
```bash
cd backend
npm start
```

### Method 2: Direct Start
```bash
cd backend
npm run server
```

### Method 3: Development Mode
```bash
cd backend
npm run dev
```

## 📱 Mobile App Connection

When the server starts, you'll see output like this:

```
🚀 Food Donation Backend Server Started!
=====================================
📡 Local URL: http://localhost:5000
🌐 API Endpoint: http://localhost:5000/api

📱 For Mobile App Connection:
   1. http://192.168.1.100:5000
      API: http://192.168.1.100:5000/api
   2. http://10.0.0.5:5000
      API: http://10.0.0.5:5000/api

💡 Enter any of the above URLs in the mobile app connection settings
   (Tap the connection icon in the top-right of login screen)

🔧 Health Check: http://localhost:5000/api/health
=====================================
```

## Configuring the Mobile App

1. **Install the APK** on your Android device
2. **Open the app** and go to the login screen
3. **Tap the connection icon** (⚙️) in the top-right corner
4. **Enter the URL** from the server output (e.g., `192.168.1.100:5000`)
5. **Test Connection** to verify it works
6. **Save** the settings

## Health Check Endpoint

The server includes a health check endpoint for testing connectivity:
- **URL**: `/api/health`
- **Method**: GET
- **Response**: 
```json
{
  "status": "healthy",
  "message": "Food Donation Backend is running",
  "timestamp": "2025-12-31T10:30:00.000Z",
  "version": "1.0.0"
}
```

## Troubleshooting

### ❌ "Connection refused" Error
- Make sure the backend server is running
- Check that you're using the correct IP address
- Verify both devices are on the same network

### ❌ "No network interfaces found"
- Make sure your computer is connected to a network
- Check your Wi-Fi/ethernet connection
- Try restarting the server

### ❌ "Health check failed"
- Verify the backend is running on the correct port
- Check for firewall issues
- Ensure the mobile app can reach your computer

## Network Requirements

- **Both devices must be on the same network** (Wi-Fi or local network)
- **Firewall must allow connections** on port 5000
- **Backend must bind to 0.0.0.0** (done automatically)

## Example URLs

- **Local development**: `localhost:5000`
- **Mobile connection**: `192.168.1.100:5000`
- **API endpoint**: `192.168.1.100:5000/api`
- **Health check**: `192.168.1.100:5000/api/health`
