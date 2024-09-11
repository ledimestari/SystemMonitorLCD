#include <Adafruit_NeoPixel.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// LED strip settings
#define LED_PIN 4      // Pin connected to the LED strip
#define NUM_LEDS 3     // Number of LEDs on the strip
Adafruit_NeoPixel strip = Adafruit_NeoPixel(NUM_LEDS, LED_PIN, NEO_RGB + NEO_KHZ800);  // Using NEO_GRB

// LCD settings
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Buzzer settings
#define BUZZER_PIN 2   // Pin connected to the buzzer

// Duration for different beep types
const int SHORT_BEEP_DURATION = 50;   // Duration for short beep in milliseconds (reduced for faster beeps)
const int LONG_BEEP_DURATION = 500;    // Duration for long beep in milliseconds
const int RAPID_BEEP_COUNT = 5;        // Number of short beeps for rapid mode
const int RAPID_BEEP_DELAY = 100;      // Delay between beeps in milliseconds (reduced for faster beeps)

// Duration and modes for buzzer
String buzzerMode = "";
bool buzzerActive = false;

// LED and gradient settings
bool blinkMode = false;      // Flag for blinking mode for LEDs
bool rainbowMode = false;    // Flag for rainbow mode
bool gradientMode = false;   // Flag for gradient mode
int blinkInterval = 1000;    // Blinking interval in milliseconds (1 second on, 1 second off)
unsigned long previousMillis = 0;  // Stores the last time the LEDs or buzzer were updated

// Store the RGB color when blinking
int storedRed = 0;
int storedGreen = 0;
int storedBlue = 0;

String inputString = "";    // String to hold the incoming serial data
bool stringComplete = false;  // Whether the string is complete

void setup() {
  // Initialize the LED strip
  strip.begin();
  strip.show();  // Initialize all LEDs to 'off'

  // Initialize the LCD
  lcd.init();
  lcd.backlight();

  // Initialize the buzzer pin
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  Serial.begin(9600);  // Set serial communication to 9600 baud rate
  inputString.reserve(64);  // Reserve space for input string
}

void loop() {
  if (stringComplete) {
    // Process the serial input string
    processInput(inputString);

    // Clear the input string and reset the flag
    inputString = "";
    stringComplete = false;
  }

  // If in rainbow mode, run the rainbow animation
  if (rainbowMode) {
    rainbow(20);  // Adjust speed of rainbow animation here
  }

  // If in blink mode, handle the blinking logic for the LED strip
  if (blinkMode) {
    unsigned long currentMillis = millis();

    if (currentMillis - previousMillis >= blinkInterval) {
      previousMillis = currentMillis;

      // Toggle LEDs on and off
      static bool ledState = false;
      if (ledState) {
        strip.clear();  // Turn off the LEDs
        strip.show();
      } else {
        // Restore the stored color and show it on the strip
        for (int i = 0; i < NUM_LEDS; i++) {
          strip.setPixelColor(i, strip.Color(storedGreen, storedRed, storedBlue));  // Correct order GRB
        }
        strip.show();
      }
      ledState = !ledState;
    }
  }

  // Handle buzzer if active
  if (buzzerActive) {
    unsigned long currentMillis = millis();
    if (buzzerMode == "short") {
      tone(BUZZER_PIN, 1000);  // Play tone for short beep
      delay(SHORT_BEEP_DURATION);
      noTone(BUZZER_PIN);
      buzzerActive = false;
    } 
    else if (buzzerMode == "long") {
      tone(BUZZER_PIN, 1000);  // Play tone for long beep
      delay(LONG_BEEP_DURATION);
      noTone(BUZZER_PIN);
      buzzerActive = false;
    } 
    else if (buzzerMode == "rapid") {
      for (int i = 0; i < RAPID_BEEP_COUNT; i++) {
        tone(BUZZER_PIN, 1000);  // Play tone for short beep
        delay(SHORT_BEEP_DURATION);
        noTone(BUZZER_PIN);
        delay(RAPID_BEEP_DELAY);  // Delay between beeps
      }
      buzzerActive = false;
    }
  }
}

// Function to process the serial input
void processInput(String input) {
  if (input.startsWith("led")) {
    if (input.endsWith("/static")) {
      // Parse RGB values and set static color
      setLEDColor(input.substring(3, 12));  // Extract RGB part from "ledRRRGGGBBB/static"
      blinkMode = false;   // Disable blinking mode
      rainbowMode = false; // Disable rainbow mode
      gradientMode = false; // Disable gradient mode
    } 
    else if (input.endsWith("/blink")) {
      // Parse RGB values and set color with blink effect
      setLEDColor(input.substring(3, 12));  // Extract RGB part from "ledRRRGGGBBB/blink"
      blinkMode = true;    // Enable blinking mode
      rainbowMode = false; // Disable rainbow mode
      gradientMode = false; // Disable gradient mode
    } 
    else if (input.equalsIgnoreCase("led/rainbow")) {
      // Enable rainbow mode
      rainbowMode = true;  // Enable rainbow mode
      blinkMode = false;   // Disable blinking mode
      gradientMode = false; // Disable gradient mode
    } 
    else if (input.endsWith("/gradient")) {
      // Extract percentage and set gradient mode
      int percentage = input.substring(3, input.indexOf('/')).toInt();
      setGradient(percentage);
      blinkMode = false;   // Disable blinking mode
      rainbowMode = false; // Disable rainbow mode
      gradientMode = true; // Enable gradient mode
    }
  } 
  else if (input.equalsIgnoreCase("lcdon")) {
    lcd.backlight();  // Turn on the backlight
  } 
  else if (input.equalsIgnoreCase("lcdoff")) {
    lcd.noBacklight();  // Turn off the backlight
  } 
  else if (input.startsWith("beep")) {
    // Handle buzzer commands
    if (input.equalsIgnoreCase("beep/short")) {
      buzzerMode = "short";
      buzzerActive = true;
    } 
    else if (input.equalsIgnoreCase("beep/long")) {
      buzzerMode = "long";
      buzzerActive = true;
    } 
    else if (input.equalsIgnoreCase("beep/rapid")) {
      buzzerMode = "rapid";
      buzzerActive = true;
    }
  } 
  else {
    // LCD display commands for any other input starting with "lcd"
    int separatorIndex = input.indexOf('/');
    if (separatorIndex != -1) {
      String firstRow = input.substring(0, separatorIndex);
      String secondRow = input.substring(separatorIndex + 1);  // Extract second part after '/'
      
      // Display the message on the LCD
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print(firstRow);
      lcd.setCursor(0, 1);
      lcd.print(secondRow);
    }
  }
}

// Function to set the LED color based on the RRRGGGBBB string
void setLEDColor(String rgb) {
  if (rgb.length() == 9) {
    // Extract R, G, and B values from the string
    storedRed = rgb.substring(0, 3).toInt();
    storedGreen = rgb.substring(3, 6).toInt();
    storedBlue = rgb.substring(6, 9).toInt();

    // Set the color of all LEDs in the strip
    for (int i = 0; i < NUM_LEDS; i++) {
      strip.setPixelColor(i, strip.Color(storedGreen, storedRed, storedBlue));  // Correct order GRB
    }
    strip.show();
  }
}

// Function to set the gradient based on the percentage value (0-100)
void setGradient(int percentage) {
  // Ensure percentage is between 0 and 100
  percentage = constrain(percentage, 0, 100);

  // Interpolate between red (255,0,0) and green (0,255,0)
  int redValue = map(percentage, 0, 100, 0, 255);    // Red increases as percentage increases
  int greenValue = map(percentage, 0, 100, 255, 0);  // Green decreases as percentage increases
  int blueValue = 0;  // No blue in the gradient

  // Set the color for all LEDs in the strip
  for (int i = 0; i < NUM_LEDS; i++) {
    strip.setPixelColor(i, strip.Color(greenValue, redValue, blueValue));  // Correct order GRB
  }
  strip.show();
}

// Rainbow effect for the LEDs
void rainbow(uint8_t wait) {
  static uint16_t j = 0;

  for (int i = 0; i < NUM_LEDS; i++) {
    strip.setPixelColor(i, wheel((i + j) & 255));
  }
  strip.show();
  delay(wait);
  j++;
}

// Generate rainbow colors across 255 positions
uint32_t wheel(byte wheelPos) {
  wheelPos = 255 - wheelPos;
  if (wheelPos < 85) {
    return strip.Color(255 - wheelPos * 3, 0, wheelPos * 3);
  }
  if (wheelPos < 170) {
    wheelPos -= 85;
    return strip.Color(0, wheelPos * 3, 255 - wheelPos * 3);
  }
  wheelPos -= 170;
  return strip.Color(wheelPos * 3, 255 - wheelPos * 3, 0);
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
