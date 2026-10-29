// ============================================
// uart_rx.v  (CORREGIDO)
// Receptor UART 8N1: FSM + sincronizador de 2 FF + verificacion de stop
// ============================================
module uart_rx #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 9600
)(
    input  wire clk,
    input  wire reset,
    input  wire rx,
    output reg [7:0] data_out,
    output reg data_valid
);

localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam integer HALF_BIT     = CLKS_PER_BIT / 2;

localparam [1:0] IDLE  = 2'd0,
                 START = 2'd1,
                 DATA  = 2'd2,
                 STOP  = 2'd3;

// Sincronizador (rx es asincrona respecto a clk)
reg rx_sync1, rx_sync2;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        rx_sync1 <= 1'b1;
        rx_sync2 <= 1'b1;
    end else begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
    end
end

reg [1:0]  state;
reg [15:0] clk_count;
reg [2:0]  bit_index;
reg [7:0]  rx_shift;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state      <= IDLE;
        clk_count  <= 0;
        bit_index  <= 0;
        rx_shift   <= 8'd0;
        data_out   <= 8'd0;
        data_valid <= 1'b0;
    end else begin
        data_valid <= 1'b0;

        case (state)
            IDLE: begin
                clk_count <= 0;
                bit_index <= 0;
                if (rx_sync2 == 1'b0)
                    state <= START;
            end

            // Medio bit y confirma que el start sigue en 0 (filtra glitches)
            START: begin
                if (clk_count == HALF_BIT - 1) begin
                    clk_count <= 0;
                    if (rx_sync2 == 1'b0)
                        state <= DATA;
                    else
                        state <= IDLE;
                end else
                    clk_count <= clk_count + 1;
            end

            // Muestrea cada bit de dato en su centro (LSB primero)
            DATA: begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;
                    rx_shift[bit_index] <= rx_sync2;
                    if (bit_index == 3'd7)
                        state <= STOP;
                    else
                        bit_index <= bit_index + 1;
                end else
                    clk_count <= clk_count + 1;
            end

            // Centro del stop bit: solo acepta el dato si stop = 1
            STOP: begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;
                    state     <= IDLE;
                    if (rx_sync2 == 1'b1) begin
                        data_out   <= rx_shift;
                        data_valid <= 1'b1;
                    end
                end else
                    clk_count <= clk_count + 1;
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule