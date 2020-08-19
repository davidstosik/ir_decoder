/*
 * This Arduino sketch is used to measure time intervals between changes in the IR sensor's output.
 * Time intervals are saved to a buffer (as using serial while reading would impact the timing),
 * then when a message seems complete (based on timeout), they are written to the serial output.
 * The Arduino is then readied to read another IR message.
 * 
 * This works on ESP32 as well.
 */

const uint8_t irPin = 13; // D13 on ESP32 (change to the pin you want to use)
const uint32_t timeoutUs = 0.1e6; // 0.1 second
const uint8_t intervalsMaxLen = 1000; // buffer size
const uint8_t serialFreq = 115200;

uint16_t intervals[intervalsMaxLen];
uint16_t intervalsLen;
bool irState, irLastState, receiving;
uint32_t nowUs, lastChangeUs;

void reset() {
  irLastState = digitalRead(irPin);
  lastChangeUs = micros();
  receiving = false;
  intervalsLen = 0;
}

void setup() {
  Serial.begin(serialFreq);
  pinMode(irPin, INPUT);
  reset();
  Serial.println("Ready.");
}

void loop() {
  irState = digitalRead(irPin);
  nowUs = micros();

  if (irState != irLastState) { // catch a change in the IR sensor's output (between 0 and 1)
    if (receiving) {
      intervals[intervalsLen] = nowUs - lastChangeUs;
      intervalsLen += 1;
    } else { // discards the first value that is just a long "silence"
      receiving = true;
    }
    irLastState = irState;
    lastChangeUs = nowUs;

  } else if (receiving && (nowUs - lastChangeUs > timeoutUs || nowUs < lastChangeUs)) {
    // Output intervals when complete
    for (int i = 0; i < intervalsLen; i++) {
      Serial.println(intervals[i]);
    }
    reset();
  }
}
