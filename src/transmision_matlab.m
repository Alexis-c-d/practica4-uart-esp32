% transmision_matlab.m  (CORREGIDO)
clear
clc

PORT = "COM3";     % Cambiar por el puerto del ESP32
BAUD = 9600;

s = serialport(PORT, BAUD);
pause(2);          % El ESP32 se resetea al abrir el puerto
flush(s);          % Tirar la basura del boot

disp("Transmision iniciada (Enter vacio para salir)");

while true
    entrada = input('Ingrese un numero entre 0 y 255: ', 's');
    if isempty(entrada), break; end

    valor = str2double(entrada);
    if isnan(valor) || valor < 0 || valor > 255 || valor ~= floor(valor)
        disp('Entrada no valida o fuera de rango');
        continue;
    end

    write(s, uint8(valor), "uint8");
    disp(['Enviado: ', num2str(valor)]);
end

clear s            % Cierra el puerto
