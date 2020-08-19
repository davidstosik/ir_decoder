IR decoder
==========

:warning: The code in this repository is experimental, and your results may vary. I recommend you take some time to read the source and understand what it does.

## How to use

The system is split in two parts:
- An Arduino sketch to upload to a micro-controller development board, connected to an IR receiver.
- A Ruby program that read the micro-controller's output on serial.

### Arduino sketch

File name: `ir_decoder.ino`.

This is a very simple sketch that measures time intervals between changes in output level from an IR sensor.
There are a few constants you can play with:

```cpp
const uint8_t irPin = 13; // D13 on ESP32 (change to the pin you want to use)
const uint32_t timeoutUs = 0.1e6; // 0.1 second
const uint8_t intervalsMaxLen = 1000; // buffer size
const uint8_t serialFreq = 115200;
```

- `irPin` is the pin number connected to the IR sensor's output. It will be passed to `pinMode` and `digitalWrite`, so set according to your circuit and your board.
- `timeoutUs` is the reading timeout in microseconds. If the IR sensor shows no changes after that time, then the received IR message is considered complete, then output to Serial.
- `intervalsMaxLen` is the size of the buffer in which the time intervals are stored before outputting them. 1000 is quite a lot already, but if you think you're reading partial messages, try increasing this value.
- `serialFreq` is the serial frequency, take note of it, as it is used in the Ruby script as well

### Ruby program

File name: `ir_decoder.rb`.

This file reads the values output by your development board on the serial port.
You will need the [`serialport` gem](https://github.com/hparra/ruby-serialport):

```sh
gem install serialport
```

To run the script, simply use `ruby`:

```sh
ruby ir_decoder.rb
```

What the script does:

- purge the serial input (in case some data is waiting to be read)
- prompt the user to press a button on their remote controller
- read data on serial until it stops (according to `READ_TIMEOUT_MS`)
- repeat the above a total of 10 times (`READING_COUNT`)
- ensure all readings have the same number of intervals (the idea is to send the same message 10 times and average the intervals)
- calculate averages
- normalize intervals to represent the message with a reduced set of intervals
- assign letters to those intervals, and display them
- display the remote's original message using those letters (downcase letters are "silence", capitals are "noise")

Change the following constants to adapt to your setup:

```rb
READ_TIMEOUT_MS = 500
SERIAL_PORT = "/dev/cu.SLAB_USBtoUART"
SERIAL_FREQ = 115200
READING_COUNT = 10
```

- `READ_TIMEOUT_MS` is how long the serial reader will wait until it decides a message is complete.
- `SERIAL_PORT` is the serial port on which your Arduino (or other board) writes.
- `SERIAL_FREQ` is the serial frequency. This must be the same as in the Arduino script.
- `READING_COUNT` is how many readings of the same message you want to make then average.
