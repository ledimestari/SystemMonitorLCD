# SystemMonitorLCD# System Monitoring with Serial LCD Control

This project is a Linux-based bash script that monitors various system parameters such as uptime, disk usage, load averages, CPU temperature, memory usage, and more. The output is sent to a serial-connected LCD screen via `/dev/ttyUSB0`. Additionally, the script can turn the LCD display on or off based on the current time.

![collection](https://github.com/user-attachments/assets/0c04c9a8-9d8c-4b3d-b1d1-36ec4382f37c)

## Features

### LCD screen

- **Display uptime**: Shows how long the system has been running.
- **Disk usage**: Displays the current disk usage.
- **Load averages**: Shows system load averages over 1, 5, and 15 minutes.
- **CPU temperature**: Monitors and displays the CPU temperature.
- **Memory usage**: Displays memory usage as a ratio of used to total memory.
- **Swap usage**: Displays swap memory usage.
- **Top processes**:
  - CPU: Shows the process consuming the most CPU.
  - Memory: Shows the process consuming the most memory.
- **IP Address**: Displays the system's IP address.
- **Network speeds**: Monitors Ethernet upload and download speeds.
- **Number of logged-in users**: Shows how many users are currently logged in.
- **System time**: Displays the current system time.
- **Security updates**: Lists available security updates (requires `apt-get`).
- **Disk I/O**: Monitors total disk read and write speeds.
- **Process count**: Displays the number of running processes.
- **Open files**: Displays the number of open file descriptors.
- **Last login**: Displays the username and time of the last login.
- **LCD control**: Automatically turns the LCD off between 22:00 and 08:00 and back on during the day.

### LED light

- **LED Strip Control**:
  - **Static Color**: Set the color of a WS2812B LED strip using RGB values in the format `ledRRRGGGBBB/static`.
  - **Blinking**: Make the LED strip blink in a specified color with the command `ledRRRGGGBBB/blink`.
  - **Rainbow Mode**: Cycle through a rainbow effect with the command `led/rainbow`.
  - **Gradient**: Create a gradient from green to red based on a percentage value from 0 to 100 using `led<percentage>/gradient`.
 
  **Example**:
  Set the led light to blink as red
  ```bash
  echo "led255000000/blink" > /dev/ttyUSB0

### Buzzer

- **Buzzer Control**:
  - **Short Beep**: Activate a short beep with the command `beep/short`.
  - **Long Beep**: Activate a long beep with the command `beep/long`.
  - **Rapid Beep**: Activate a series of five short beeps with the command `beep/rapid`.

  **Example**:
  Make a short beep
  ```bash
  echo "beep/short" > /dev/ttyUSB0

You can use the main loop at the end of the script to comment out or change order of prints you wish to see on the lcd.

## Installation

1. **Dependencies**: Ensure the following packages are installed:
   - `screenfetch`
   - `sensors` (for CPU temperature monitoring)
   - `iostat` (for disk I/O monitoring)
   - `bc` (for arithmetic calculations)
   - `procps` (for system monitoring)

   You can install them using the following command:
   ```bash
   sudo apt-get install screenfetch lm-sensors sysstat bc procps

2. **Wiring and arduino library**
   
    Wiring an I2C 1602 LCD Screen to an Arduino
    If you're using an I2C 1602 LCD screen with an Arduino, follow these steps to wire it correctly:
    
    Components:
    Arduino (e.g., Uno, Nano, etc.)
    1602 LCD screen with I2C module
    Jumper wires

   Wiring:
    Connect the I2C pins of the LCD to the Arduino:
    
    - GND (LCD) -> GND (Arduino)
    - VCC (LCD) -> 5V (Arduino)
    - SDA (LCD) -> A4 (Arduino)
    - SCL (LCD) -> A5 (Arduino)
    
    Install the I2C LCD library:
    
    In the Arduino IDE, go to Sketch -> Include Library -> Manage Libraries.
    Search for "LiquidCrystal I2C" and install the library by Frank de Brabander.

3. **Permissions on the server**
   
    You can use `ls /dev/` to check which USB device port was assinged to your arduino. If you don't have any other serial USB-devices it probably shows up as `/dev/ttyUSB0`.

   If your device gets some other serial port just change the `serial_device="/dev/ttyUSB0"` row accordingly.

   You might need to add your user to `dialout` user group in order to have permissions to write into the serial port.

   Other option is to set 777 permission on the `/dev/ttyUSB0` port but I don't know how bad of a idea that might be.

   After your user have the permissions you just run the script.

## Contributions

Feel free to fork the project, make improvements, and submit pull requests. If you find any issues or have feature requests, please open an issue on the repository.
   
