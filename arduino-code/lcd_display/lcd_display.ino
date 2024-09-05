#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// Set the LCD address to 0x27 for a 16 chars, 2-line display
LiquidCrystal_I2C lcd(0x27, 16, 2);

String inputString = "";   // String to hold the incoming serial data
bool stringComplete = false;  // Whether the string is complete

void setup() {
  // Initialize the LCD and serial communication
  lcd.init();
  lcd.backlight();  // Turn on the backlight initially
  
  Serial.begin(9600);  // Set serial communication to 9600 baud rate
  inputString.reserve(32);  // Reserve space for input string
}

void loop() {
  // If the string is complete, process and display it
  if (stringComplete) {
    // Check for "lcdoff" command to turn off the backlight
    if (inputString.equalsIgnoreCase("lcdoff")) {
      lcd.noBacklight();  // Turn off the LCD backlight
    }
    // Check for "lcdon" command to turn on the backlight
    else if (inputString.equalsIgnoreCase("lcdon")) {
      lcd.backlight();  // Turn on the LCD backlight
    }
    // Otherwise, process the string as display content
    else {
      // Clear the LCD
      lcd.clear();

      // Find the position of the `/` character
      int separatorIndex = inputString.indexOf('/');

      if (separatorIndex != -1) {
        // Get the first part of the string (before '/')
        String firstRow = inputString.substring(0, separatorIndex);
        
        // Get the second part of the string (after '/')
        String secondRow = inputString.substring(separatorIndex + 1);

        // Print the first part on the first row
        lcd.setCursor(0, 0);  // Set the cursor to the first row
        lcd.print(firstRow);

        // Print the second part on the second row
        lcd.setCursor(0, 1);  // Set the cursor to the second row
        lcd.print(secondRow);
      }
    }

    // Clear the input string and reset the flag
    inputString = "";
    stringComplete = false;
  }
}

// SerialEvent() is called whenever data is received via serial
void serialEvent() {
  while (Serial.available()) {
    // Read the incoming byte
    char inChar = (char)Serial.read();

    // If it's not a newline character, add it to the inputString
    if (inChar != '\n' && inChar != '\r') {
      inputString += inChar;
    }

    // If the newline character is received, mark the string as complete
    if (inChar == '\n') {
      stringComplete = true;
    }
  }
}
