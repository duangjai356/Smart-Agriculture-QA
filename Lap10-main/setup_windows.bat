@echo off
chcp 65001 >nul
echo === Smart-Agriculture-QA Setup ===
set XAMPP=C:\xampp

if exist "%XAMPP%\htdocs" (
  echo [1/3] Copy backend -> %XAMPP%\htdocs\smart_farm
  xcopy /E /I /Y "%~dp0backend" "%XAMPP%\htdocs\smart_farm" >nul
  echo      Done. import backend\smart_farm_db.sql ใน http://localhost/phpmyadmin
) else (
  echo [1/3] ไม่พบ XAMPP ที่ %XAMPP% - ข้าม
)

echo [2/3] Flutter: create platform folders + pub get
cd /d "%~dp0mobile_app"
call flutter create . --project-name smart_farm_dashboard
call flutter pub get

echo [3/3] Python packages
cd /d "%~dp0ai_engine"
pip install -r requirements.txt

echo.
echo เสร็จแล้ว อ่านขั้นตอนต่อไปใน README.md
pause
