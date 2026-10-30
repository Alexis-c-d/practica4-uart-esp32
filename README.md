# Practice 4: Bidirectional UART Communication

This project implements a serial communication link between a computer and an
Intel/Altera DE10-Lite FPGA. An ESP32 bridges the computer's USB serial connection
to the FPGA's UART. The FPGA receives one byte, increments it, and sends the
result back to the computer through the ESP32.

## Assignment objective

Design, implement, and test a bidirectional UART system using:

- A DE10-Lite FPGA running at 50 MHz
- An ESP32 acting as a transparent USB-to-UART bridge
- MATLAB scripts on the computer to send and receive data

The FPGA must receive serial data, process at least one byte, and transmit a
response. This implementation returns the received byte plus one. Because the
result is an 8-bit value, sending `255` produces `0`.

## Communication requirements

- UART format: **9600 baud, 8 data bits, no parity, 1 stop bit (8N1)**
- FPGA clock: **50 MHz**
- FPGA clock cycles per UART bit: approximately `50,000,000 / 9,600 = 5,208`
- The ESP32 forwards bytes in both directions without changing them.
- TX and RX must be crossed between the ESP32 and FPGA, and both devices must
  share a common ground.
- The DE10-Lite and ESP32 use 3.3 V logic. Do not connect classic RS-232 voltage
  levels directly to FPGA GPIO pins.

## System architecture

```text
Computer / MATLAB
        |
        | USB serial
        v
ESP32 USB-UART bridge
        |
        | UART2, 9600 baud, 8N1
        v
DE10-Lite FPGA: receive byte -> add 1 -> transmit response
```

Connect the ESP32's GPIO17 (TX) to the FPGA UART RX, GPIO16 (RX) to the FPGA
UART TX, and GND to GND. Select the ESP32's assigned COM port in the computer
script.

## Source files

| File | Purpose |
|---|---|
| `src/top_uart_de10lite.v` | FPGA top-level module; receives a byte and starts transmission of the incremented result. |
| `src/uart_rx.v` | UART receiver for the FPGA. |
| `src/uart_tx.v` | UART transmitter for the FPGA. |
| `src/tb_top_uart.v` | Testbench that sends five sample bytes and checks the responses. |
| `src/esp32_puente/esp32_puente.ino` | ESP32 firmware that bridges USB serial and UART2. |
| `src/bidireccional_matlab.m` | MATLAB script for sending a byte and displaying the response. |
| `src/transmision_matlab.m` | MATLAB transmit-only example. |
| `src/recepcion_matlab.m` | MATLAB receive-only example. |
| `src/comunicacion_serial.py` | Optional Python serial client for sending a byte and reading the response. |

## Setup and operation

1. In Quartus Prime, assign the top-level module's clock, reset, UART RX, and
   UART TX signals to the appropriate DE10-Lite pins, then compile and program
   the FPGA.
2. Open `src/esp32_puente/esp32_puente.ino` in Arduino IDE, select the
   appropriate ESP32 board and COM port, and upload the bridge firmware.
3. Wire the ESP32 and FPGA as described above, including the shared ground.
4. In the MATLAB script, change `PORT` to the COM port assigned to the ESP32.
   Run `src/bidireccional_matlab.m`, enter a value from 0 to 255, and verify
   that the response is one greater (wrapping from 255 to 0).

The optional Python client requires `pyserial`; install it with `pip install
pyserial`, update `PORT` in `src/comunicacion_serial.py`, and run the script.
Close other applications that may have the ESP32 COM port open before running
either client.

## Testbench

The testbench checks the following expected results:

| Byte sent | Expected response |
|---:|---:|
| 10 | 11 |
| 25 | 26 |
| 100 | 101 |
| 200 | 201 |
| 255 | 0 |

For ModelSim or Questa, compile and run from the `src` directory:

```tcl
vlog tb_top_uart.v top_uart_de10lite.v uart_rx.v uart_tx.v
vsim tb_top_uart
run -all
```

The simulation reports whether each byte passed and prints
`TODAS LAS PRUEBAS PASARON` when all five checks succeed.

## Assignment report

The assignment asks for evidence and discussion of the completed system. Include:

- UART transmitter and receiver simulation results
- Photos or evidence of the FPGA-to-ESP32 and ESP32-to-computer connections
- Evidence that the ESP32 bridge firmware was uploaded
- MATLAB screenshots showing transmitted and received values
- A comparison of expected and measured results, plus conclusions about baud
  rate agreement and the ESP32's role as a USB-UART bridge
- Answers to the assignment questions about UART versus RS-232, voltage levels,
  baud rate, crossed TX/RX wiring, MATLAB, and the ESP32 bridge
