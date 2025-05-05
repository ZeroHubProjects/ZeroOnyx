:: This is a Windows script to build and run the server in a Docker container
:: Make sure that you have Docker/Docker Desktop installed and running
:: This script will stop any existing containers named `zeroonyx` and will remove any images named `zeroonyx-server`

:: This script must be started from the root folder of the build
:: This script will automatically mount your config/ and data/ folders into the container.
:: Please adjust the `docker run` command if you want to change this behavior.

:: After successful start you will be able to connect to your server with the following address: `localhost:14076`.
:: Port 14076 is used by default, but may be changed in the `Dockerfile`.

:: Note that on Docker Desktop for Windows you have to go to Docker settings, Features in development, and tick Enable host networking.
:: Otherwise your server will not be accessible due to a Docker limitation.
:: Alternatively, switch networking mode from host to an internal network, but all connected players will have the same IP.

@echo off

echo Removing old container and image

docker rm -f zeroonyx 2>nul
docker image rm zeroonyx-server 2>nul

echo Building docker image!

docker build -t zeroonyx-server .
if errorlevel 1 (
	echo Failed to build the image
	pause
	exit
)


echo.
echo Image built, starting...
docker run --restart=unless-stopped -d -v %cd%\config:/ss13config -v %cd%\data:/ss13data --network host --name zeroonyx zeroonyx-server
if errorlevel 1 (
	echo Failed to start the container
	pause
	exit
)

echo.
echo Container successfully started!

pause
