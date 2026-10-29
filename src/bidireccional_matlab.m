% bidireccional_matlab.m  (CORREGIDO)
clear
clc

PORT = "COM7";     % Cambiar por el puerto del ESP32
BAUD = 9600;

s = serialport(PORT, BAUD);
pause(2);
flush(s);

disp("Comunicacion bidireccional iniciada");
disp("La FPGA regresara el byte recibido mas 1 (Enter vacio para salir)");

while true
    entrada = input('Ingrese un numero entre 0 y 255: ', 's');
    if isempty(entrada), break; end

    valor = str2double(entrada);
    if isnan(valor) || valor < 0 || valor > 255 || valor ~= floor(valor)
        disp('Entrada no valida o fuera de rango');
        continue;
    end

    flush(s);                          % Descartar bytes viejos
    write(s, uint8(valor), "uint8");
    disp(['Enviado: ', num2str(valor)]);

    % Esperar la respuesta hasta 1 s en vez de un pause fijo
    t0 = tic;
    while s.NumBytesAvailable == 0 && toc(t0) < 1
        pause(0.005);
    end

    if s.NumBytesAvailable > 0
        respuesta = read(s, 1, "uint8");
        disp(['Respuesta de FPGA: ', num2str(double(respuesta))]);
    else
        disp('No se recibio respuesta');
    end
end

clear s            % Cierra el puerto