# Insta360-Remote-CIQ
Garmin Connect IQ Remote for Insta360 Cameras

This is a very early, in progress, under development widget to Remote Control via Bluetooth the Insta360 One R Modular camera. Don't expect this widget to work ;) 

The 'BLE Barrel' directory contrains a Garmin CIQ Barrel (library) with the main code for interacting with the camera.

the 'OneR Remote' & 'OneR remote DF' contains the actual code (mainly UI) for the widget and datafield 

The widget will scan for and automatically connect to your camera: Press the menu button to select the shooting mode (or to switch GPS telemetry on & off) and press the start button to start and stop the shooting. While shooting, when pressing stop, a menu will be displayed where you can select Stop (for actually stopping the recording), Highlight (will leave a mark in the video file, that you will find in the App) and Track that (will start a Deep Track in the app. you need to hold the selfie stick straight at the person you want to track).

Any widget is accessible from a standard Garmin activity (press 3 seconds on the back / lap button on Fenix). So you can still start your favorite activity and then access the widget. If you have disabled GPS Telemetry, it will be disabled in your activity also.

The widget was developed and tested with the 360 mod. Using this widget with other mod will yield unexpected results. It should also be compatible with the One RS, One X, One X2, X3 but not with the GO, GO2, GO3, Ace & Ace pro.

If you have enabled GPS Telemetry, you can overlay GPS data on your video through the use of the official One R app on Android or IOS or on PC/Max with the Studio application.

User of touch screen devices can just tap on the screen to start & stop shooting.

All Garmin's devices with BLE (Bluetooth Low Energy) and CIQ V3.1 or later are supported. Older watches (Fenix 3/5, Descent MK1, Vivoactive, etc) cannot be supported due do lack of hardware compatibility to communicate with the camera. 

Widget avaialbe at https://apps.garmin.com/apps/bb53f4bb-6c8c-4369-bca9-84cc09b25526

Datafield for touch based Garmin Edge Devices avaialble at https://apps.garmin.com/apps/f0cdaa9c-5733-4748-ba66-1c7a3b008922

## Development Environment (devenv)

This repository is configured with [devenv](https://devenv.sh) to provide a reproducible build environment including JDK 17, Garmin Connect IQ SDK tools (`monkeyc`, `barrelbuild`), and `connect-iq-sdk-manager`.

### Quick Start

1. Enter the devenv shell:
   ```bash
   devenv shell
   ```
   (or allow with `direnv allow` if using direnv)

2. First-time setup:
   - **Log in to Garmin SSO** (required by Garmin to download device definitions):
     ```bash
     ciq-login
     ```
   - **Download target device definitions**:
     ```bash
     download-devices
     ```
   - **Generate a developer signing key** (if you don't already have one):
     ```bash
     generate-key
     ```

3. Build targets:
   - **BLE Barrel**:
     ```bash
     build-barrel
     ```
   - **OneR remote widget**:
     ```bash
     DEVICE=fenix7 build-widget
     ```
   - **OneR remote DF datafield**:
     ```bash
     DEVICE=edge1030 build-datafield
     ```
   - **Build everything**:
     ```bash
     build-all
     ```
   - **Create Store Release Packages (.iq)**:
     ```bash
     package-widget
     package-datafield
     ```
