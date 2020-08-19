IR decoder
==========

:warning: The code in this repository is experimental, and your results may vary. I recommend you take some time to read the source and understand what it does.

## How it works

The system is split in two parts:
- An Arduino sketch to upload to a micro-controller development board, connected to an IR receiver.
- A Ruby program that reads the micro-controller's output on the serial port.

### Arduino sketch

File name: `ir_decoder.ino`.

This is a very simple sketch that measures time intervals between changes in output level from an IR sensor.

### Ruby program

File name: `ir_decoder.rb`.

This file reads the values output by your development board on the serial port.

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

## How to use

### Arduino side

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

1. Adjust the constants above then flash the `.ino` file to your development board of choice. (You can use Arduino IDE, or PlatformIO with little changes.) I'm using a no-name ESP32 development board but Arduino Uno should work as well.
2. Connect an IR sensor to your development board, according to the pin number you chose above.
3. Open the serial monitor (in Arduino IDE, PlatformIO, or any other method you like), and check your board's output:
    - It should say "Ready." when it is ready to receive.
    - If you press a button on an IR remote, it should start receiving, and when it's done, output a list of numbers on the serial port. These are the interval times we're looking for!
4. Close the serial monitor, otherwise, we won't be able to open the serial port in Ruby.

### Ruby side

Here too, a few constants will allow you to adjust your setup:

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

1. Before running the Ruby script, you will need to install the [`serialport` gem](https://github.com/hparra/ruby-serialport):

    ```sh
    gem install serialport
    ```
2. Adjust the constants explained above in the `.rb` file.
3. Simply run the script using `ruby` and follow instructions:

    ```sh
    ruby ir_decoder.rb
    ```

### Sample output:

```
Purging serial...
Press a button on the remote.
Reading...
8973, 4458, 571, 536, 573, 532, 574, 1665, 571, 535, 573, 533, 574, 532, 575, 531, 576, 531, 567, 1672, 574, 1665, 570, 536, 602, 1636, 569, 1669, 577, 1662, 573, 1666, 570, 1669, 598, 1640, 575, 1663, 573, 534, 594, 1644, 601, 1637, 578, 531, 566, 1671, 575, 1662, 573, 1666, 569, 537, 571, 536, 602, 504, 593, 1646, 601, 1637, 577, 529, 600, 506, 601, 39457, 8999, 2193, 570, 30837, 9004, 2190, 573
Read 75 intervals.

... (as many times is defined)

Press a button on the remote.
Reading...
8974, 4457, 573, 533, 574, 533, 576, 1662, 573, 533, 574, 532, 575, 532, 596, 509, 599, 507, 600, 1639, 576, 1663, 573, 532, 575, 1665, 602, 1636, 599, 1639, 597, 1642, 603, 1640, 565, 1669, 597, 1642, 573, 533, 575, 1663, 572, 1667, 568, 538, 601, 1638, 577, 1661, 595, 1644, 602, 504, 573, 533, 574, 532, 575, 1663, 573, 1665, 571, 535, 603, 504, 603, 39454, 9001, 2191, 572, 30834, 8996, 2196, 567
Read 75 intervals.

Averaging readings...
Normalized values:
a. 525us silence
B. 581us noise
c. 1654us silence
d. 2209us silence
e. 4456us silence
F. 8980us noise
g. 30826us silence
h. 39473us silence
(normalizing max distance <= 39.0)

All readings match the same normalized string!
FeBaBaBcBaBaBaBaBaBcBcBaBcBcBcBcBcBcBcBaBcBcBaBcBcBcBaBaBaBcBcBaBaBhFdBgFdB
```
