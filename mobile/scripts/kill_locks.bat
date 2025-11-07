@echo off
REM Kill common processes that lock Flutter/Gradle build folders on Windows
for %%P in (dart.exe java.exe gradle.exe adb.exe node.exe) do (
  tasklist /FI "IMAGENAME eq %%P" | find /I "%%P" >NUL
  if "%ERRORLEVEL%"=="0" (
    echo Killing %%P
    taskkill /F /IM %%P >NUL 2>&1
  )
)
exit /B 0
