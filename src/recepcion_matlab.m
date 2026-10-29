% recepcion_matlab.m  (CORREGIDO)
clear
clc

PORT = "COM3";     % Cambiar por el puerto del ESP32
BAUD = 9600;

s = serialport(PORT, BAUD);
pause(2);
flush(s);

disp("Esperando datos desde FPGA... (Ctrl+C para salir)");

while true
    if s.NumBytesAvailable > 0
        dato = read(s, 1, "uint8");
        disp(['Recibido: ', num2str(double(dato))]);
    else
        pause(0.01);   % No saturar el CPU
    end
end
