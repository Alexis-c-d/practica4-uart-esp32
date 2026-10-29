// ============================================
// tb_top_uart.v  - Testbench para la captura de simulacion del reporte
// Envia bytes al top por UART_RX y verifica que UART_TX responda byte + 1
// ============================================
`timescale 1ns/1ps

module tb_top_uart;

reg  CLOCK_50 = 1'b0;
reg  RESET_N  = 1'b0;
reg  UART_RX  = 1'b1;
wire UART_TX;

top_uart_de10lite dut (
    .CLOCK_50(CLOCK_50),
    .RESET_N (RESET_N),
    .UART_RX (UART_RX),
    .UART_TX (UART_TX)
);

always #10 CLOCK_50 = ~CLOCK_50;     // 50 MHz

localparam integer BIT_NS = 104167;  // 1e9 / 9600

// Simula a la PC/ESP32 enviando un byte 8N1
task send_byte(input [7:0] b);
    integer i;
    begin
        UART_RX = 1'b0; #(BIT_NS);                 // start
        for (i = 0; i < 8; i = i + 1) begin
            UART_RX = b[i]; #(BIT_NS);             // datos LSB primero
        end
        UART_RX = 1'b1; #(BIT_NS);                 // stop
    end
endtask

// Decodifica lo que transmite la FPGA
task recv_byte(output [7:0] b);
    integer j;
    begin
        @(negedge UART_TX);                        // flanco del start bit
        #(BIT_NS + BIT_NS/2);                      // centro del bit 0
        for (j = 0; j < 8; j = j + 1) begin
            b[j] = UART_TX; #(BIT_NS);
        end
        #(BIT_NS);                                 // stop bit
    end
endtask

reg [7:0] tests [0:4];
reg [7:0] resp;
reg [7:0] esperado;
integer k;
integer errores;

initial begin
    $dumpfile("tb_top_uart.vcd");
    $dumpvars(0, tb_top_uart);

    tests[0] = 8'd10;
    tests[1] = 8'd25;
    tests[2] = 8'd100;
    tests[3] = 8'd200;
    tests[4] = 8'd255;
    errores  = 0;

    #200 RESET_N = 1'b1;
    #(BIT_NS);

    for (k = 0; k < 5; k = k + 1) begin
        fork
            send_byte(tests[k]);
            recv_byte(resp);
        join
        esperado = tests[k] + 8'd1;
        if (resp === esperado)
            $display("PASS: envie %0d, FPGA respondio %0d", tests[k], resp);
        else begin
            $display("FAIL: envie %0d, esperaba %0d, recibi %0d", tests[k], esperado, resp);
            errores = errores + 1;
        end
        #(2*BIT_NS);
    end

    if (errores == 0) $display("TODAS LAS PRUEBAS PASARON");
    else              $display("HAY %0d ERRORES", errores);
    $finish;
end

endmodule
