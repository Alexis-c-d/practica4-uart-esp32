# Práctica 4 — Sistemas Embebidos: UART bidireccional (PC ↔ FPGA)

Comunicación serie bidireccional entre PC y FPGA a través de un puente ESP32.
Un byte enviado por el PC llega a la FPGA, que lo procesa y devuelve el byte + 1.

## Arquitectura

```
PC ──UART── ESP32 (puente)──UART── FPGA (DE10-Lite)
                     9600 8N1          9600 8N1
```

- **ESP32** actúa como puente transparente entre el puerto serie del PC y la FPGA.
- **FPGA** recibe el byte, le suma 1 y lo retransmite.
- Toda la comunicación es a **9600 baud, 8 bits, sin paridad, 1 stop (8N1)**.

## Estructura

```
src/
├── top_uart_de10lite.v      # Módulo superior de la FPGA (instancia RX + TX)
├── uart_rx.v                # Receptor UART 8N1 (FSM + sincronizador)
├── uart_tx.v                # Transmisor UART 8N1
├── tb_top_uart.v            # Testbench: envía 5 bytes y verifica byte+1
├── esp32_puente/
│   └── esp32_puente.ino     # Firmware ESP32: puente PC ↔ FPGA
├── comunicacion_serial.py    # Script Python (PC) de comunicación bidireccional
├── transmision_matlab.m     # Script MATLAB: solo transmite
├── recepcion_matlab.m       # Script MATLAB: solo recibe
└── bidireccional_matlab.m   # Script MATLAB: transmite y recibe (byte+1)
```

## FPGA (DE10-Lite, 50 MHz)

- `uart_rx` : detecta el start bit, muestrea los 8 datos en el centro de cada bit (LSB primero) y exige stop bit = 1 para entregar el byte.
- `uart_tx` : transmite el byte con start bit (0), 8 datos y stop bit (1).
- `top_uart_de10lite` : cuando `rx_done` y la línea no está ocupada, calcula `rx_data + 1` y dispara la transmisión.

## ESP32

Pins: `FPGA_RX_PIN = 16`, `FPGA_TX_PIN = 17`. El loop copia byte a byte en ambas direcciones (`Serial ↔ FPGA_Serial`).

## Scripts de PC

- **Python** (`comunicacion_serial.py`): envía un byte (0–255) por `COM3` y lee la respuesta. Usa `pyserial`.
- **MATLAB** (`bidireccional_matlab.m`): mismo flujo con `serialport`. Los scripts `transmision_matlab.m` y `recepcion_matlab.m` son versiones unidireccionales.

Cambia `PORT` / `COM3` / `COM7` según tu puerto real.

## Testbench

`tb_top_uart.v` envía `{10, 25, 100, 200, 255}` y verifica que la FPGA responda `byte + 1`. Espera `TODAS LAS PRUEBAS PASARON`.

## Cómo probar la FPGA

```bash
# Con ModelSim / Quartus
vlog tb_top_uart.v top_uart_de10lite.v uart_rx.v uart_tx.v
vsim tb_top_uart
```

## Notas

- Los archivos `.bak` son copias de seguridad de versiones anteriores y no forman parte del diseño.
- El PDF `practica4_v2_sistemas_embebidos.pdf` contiene la especificación original de la práctica.