import serial
import time

PORT = 'COM3'      # Cambia por el puerto de tu ESP32
BAUD = 9600

ser = None

try:
    ser = serial.Serial(PORT, BAUD, timeout=1)
    time.sleep(2)              # El ESP32 se resetea al abrir el puerto: esperar a que arranque
    ser.reset_input_buffer()   # Tirar la basura del boot del ESP32

    print("Comunicacion bidireccional iniciada")
    print("La FPGA regresara el byte recibido mas 1")

    while True:
        dato = input("Ingrese un numero entre 0 y 255 (o 'q' para salir): ").strip()

        if dato.lower() == 'q':
            break

        try:
            valor = int(dato)
        except ValueError:
            print("Entrada no valida")
            continue

        if valor < 0 or valor > 255:
            print("Valor fuera de rango")
            continue

        ser.reset_input_buffer()          # Evita leer bytes viejos como si fueran la respuesta
        ser.write(bytes([valor]))
        print(f"Enviado: {valor}")

        respuesta = ser.read(1)           # Espera hasta 1 s (timeout)

        if respuesta:
            valor_rx = respuesta[0]
            print(f"Respuesta de FPGA: {valor_rx}")
        else:
            print("No se recibio respuesta")

except serial.SerialException as e:
    print(f"Error en el puerto serial: {e}")

except KeyboardInterrupt:
    print("\nFin de comunicacion")

finally:
    if ser is not None and ser.is_open:
        ser.close()
