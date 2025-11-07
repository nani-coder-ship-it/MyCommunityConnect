@echo off
echo Testing connection to backend server...
echo.
echo 1. Checking if server is running on port 4000...
netstat -ano | findstr :4000
echo.
echo 2. Testing HTTP connection...
curl -v http://10.2.1.19:4000/api/contacts 2>&1
echo.
echo 3. Your Wi-Fi IP Address:
ipconfig | findstr "IPv4"
echo.
pause
