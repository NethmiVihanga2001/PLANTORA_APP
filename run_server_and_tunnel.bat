@echo off
title Plantora Server & Cloud Tunnel
echo ========================================================
echo        PLANTORA MOBILE BACKEND & WIRELESS TUNNEL
echo ========================================================
echo Starting Backend Server on port 3000...
start "Plantora Backend (Port 3000)" cmd /k "cd /d %~dp0backend && node server.js"

echo Waiting 3 seconds for server initialization...
timeout /t 3 /nobreak >nul

echo Starting ngrok tunnel to spiritualistically-transcendental-ted.ngrok-free.dev...
start "Plantora ngrok Tunnel" cmd /k "ngrok http 3000 --domain=spiritualistically-transcendental-ted.ngrok-free.dev"

echo ========================================================
echo Plantora Server and ngrok Tunnel are now RUNNING!
echo You can use your phone wirelessly anywhere (Wi-Fi or Mobile Data).
echo Keep this window or the opened windows open while testing.
echo ========================================================
pause
