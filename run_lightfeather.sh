#!/bin/sh
echo "starting run_lightfeather.sh script"
echo "cd backend"
cd backend/
echo "npm ci && start backend"
npm ci && npm start &
echo "sleep 300"
sleep 300

#this was a necessary workaround due to
#docker on windows copying the frontend and backend
#files multiples times in a recursive fashion
#not sure why it was doing that, but it was only on windows
echo "cd .. and rm -rf junk files"
cd ../
rm -rf frontend/backend
rm -rf frontend/frontend
rm -rf frontend/run_lightfeather.sh
rm -rf frontend/.dockerignore
rm -rf frontend/.gitignore
echo "cd frontend"
cd frontend
echo "npm ci && start frontend"
npm ci && npm start &
echo "sleep 900"
sleep 900