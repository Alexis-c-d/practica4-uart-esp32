# Práctica 4 — Sistemas Embebidos: UART bidireccional (PC ↔ FPGA)

Comunicación serie bidireccional entre una PC y una FPGA DE10-Lite mediante UART,
con un módulo ESP32 functioning as puente USB-UART. La FPGA recibe un byte, le suma
1 y lo retransmite.

**Especificación original:** `practica4_v2_sistemas_embebidos.pdf` (UDLAP, 14 pp.).

## Arquitectura

```
PC ──USB── ESP32 (puente) ──UART── FPGA (DE10-Lite)
               9600 8N1           9600 8N1
```

- La PC se comunica con el ESP32 por USB (puerto serie virtual).
- El ESP32 retransmite por una segunda UART hardware hacia la FPGA.
- La FPGA responde por UART al ESP32, que la reenvía a la PC.
- Niveles lógicos: ESP32 y FPGA operan a **3.3 V**, por lo que la interconexión es
  directa. Es indispensable **tierra común** entre FPGA y ESP32.
- Conexión cruzada: TX del ESP32 → RX de la FPGA, RX del ESP32 → TX de la FPGA.

Formato: **9600 baudios, 8 bits, sin paridad, 1 bit de paro (8N1)**.
Con el reloj de 50 MHz de la FPGA: `N = 50_000_000 / 9600 ≈ 5208` ciclos por bit.

## Estructura

```
src/
├── top_uart_de10lite.v      # Módulo superior de la FPGA (instancia RX + TX)
├── uart_rx.v                # Receptor UART 8N1 (FSM de 4 estados + sincronizador)
├── uart_tx.v                # Transmisor UART 8N1
├── tb_top_uart.v            # Testbench: envía 5 bytes y verifica byte+1
├── esp32_puente/
│   └── esp32_puente.ino     # Firmware ESP32: puente transparente PC ↔ FPGA
├── comunicacion_serial.py    # Script Python (PC) de comunicación bidireccional
├── transmision_matlab.m     # Script MATLAB: solo transmite
├── recepcion_matlab.m       # Script MATLAB: solo recibe
└── bidireccional_matlab.m   # Script MATLAB: transmite y recibe (byte+1)
```

## FPGA (DE10-Lite, 50 MHz)

- **`uart_rx`** : sincronizador de 2 FF para la línea `rx` asincrónica; FSM de 4
  estados (`IDLE → START → DATA → STOP`). Muestrea el start bit a medio bit y los 8
  datos en el centro de cada bit (LSB primero); solo entrega el byte si el stop bit
  es 1. Es la versión **corregida** de la práctica: la del PDF original carece de
  sincronizador y de verificación de stop bit.
- **`uart_tx`** : transmite start bit (0), 8 datos y stop bit (1). La línea inicia
  en alto (`1'b1`) y el shift register se carga con `{1'b1, data_in, 1'b0}`.
- **`top_uart_de10lite`** : cuando `rx_done` y la línea no está ocupada (`!tx_busy`),
  calcula `rx_data + 8'd1` y dispara la transmisión. (Nota: en el PDF original
  `rx_done` se declara como `wire [7:0]`, error corregido aquí a `wire`.)

## ESP32

Pines: `FPGA_RX_PIN = 16` (RX del ESP32 ← TX de la FPGA),
`FPGA_TX_PIN = 17` (TX del ESP32 → RX de la FPGA). Usa `HardwareSerial FPGA_Serial(2)`.
El loop copia byte a byte en ambas direcciones (`Serial ↔ FPGA_Serial`), comportamiento
de puente transparente.

## Scripts de PC

- **Python** (`comunicacion_serial.py`): envía un byte (0–255) por `COM3` y lee la
  respuesta. Usa `pyserial`. Valida rango y tipo de entrada.
- **MATLAB** (`bidireccional_matlab.m`): mismo flujo con `serialport`. Los scripts
  `transmision_matlab.m` y `recepcion_matlab.m` son versiones unidireccionales.

Las versiones de los scripts son **mejoradas** respecto al PDF original: validan que la
entrada sea entero (rechazan `12.5`), esperan la respuesta con un timeout de 1 s en
lugar de un `pause(0.1)` fijo, y descartan bytes viejos (`flush`) antes de cada envío.

Cambia `PORT` / `COM3` / `COM7` según tu puerto real (debe ser el asignado al ESP32).

## Tabla de pruebas (especificación, sección 19)

| Dato enviado | Esperado | Comentario |
|-------------|----------|------------|
| 10 | 11 | Incremento en 1 |
| 25 | 26 | Incremento en 1 |
| 100 | 101 | Incremento en 1 |
| 200 | 201 | Incremento en 1 |
| 255 | 0 | Caso límite: `255 + 1 = 0` en 8 bits |

## Testbench

`tb_top_uart.v` envía `{10, 25, 100, 200, 255}` y verifica que la FPGA responda
`byte + 1`. Espera `TODAS LAS PRUEBAS PASARON`.

## Cómo probar la FPGA

```bash
# Con ModelSim / Quartus
vlog tb_top_uart.v top_uart_de10lite.v uart_rx.v uart_tx.v
vsim tb_top_uart
```

## Entrega del estudiante (sección 20)

Capturas de simulación del transmisor y receptor, evidencia de la conexión física
FPGA–ESP32, capturas del monitor serial y de la consola de MATLAB, fotografías del
funcionamiento experimental y comparación entre resultados esperados y obtenidos.

## Notas

- Los archivos `.bak` son copias de seguridad de versiones anteriores y no forman
  parte del diseño (están en `.gitignore`).
- El PDF contiene la especificación original de la práctica; esta README describe la
  versión implementada de los archivos, que incluye correcciones y mejoras.