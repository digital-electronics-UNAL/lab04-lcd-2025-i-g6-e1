`timescale 1ns / 1ps
`include "src/lcd1602_text.v"

module LCD1602_controller_tb();

// Parámetros de simulación
parameter SIM_COUNT_MAX = 20;  // Valor reducido para simulación rápida
parameter CLK_PERIOD = 10;     // 10 ns = 100 MHz

// Señales de entrada
reg clk;
reg reset;
reg ready_i;
reg [7:0] temperatura;
reg [7:0] humedad;

// Señales de salida
wire rs;
wire rw;
wire enable;
wire [7:0] data;

// Instancia del DUT con parámetros reducidos para simulación
LCD1602_controller #(
    .COUNT_MAX(SIM_COUNT_MAX)  // Tiempo reducido para simulación
) dut (
    .clk(clk),
    .reset(reset),
    .ready_i(ready_i),
    .temperatura(temperatura),
    .humedad(humedad),
    .rs(rs),
    .rw(rw),
    .enable(enable),
    .data(data)
);

// Generación de reloj
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// Secuencia de inicialización y estímulos
initial begin
    // Inicialización
    reset = 0;
    ready_i = 0;
    temperatura = 8'd25;   // 25°C
    humedad = 8'd80;       // 80% humedad
    
    // Archivo VCD para GTKWave
    $dumpfile("lcd_sim.vcd");
    $dumpvars(0, LCD1602_controller_tb);
    
    // Reset inicial
    #(CLK_PERIOD*2) reset = 1;
    #(CLK_PERIOD*10) ready_i = 1;  // Activar señal ready
    
    // Cambiar valores durante la simulación
    #(CLK_PERIOD*500) temperatura = 8'd125; // Cambio de temperatura
    #(CLK_PERIOD*500) humedad = 8'd95;      // Cambio de humedad
    #(CLK_PERIOD*500) temperatura = 8'd5;   // Temperatura baja
    #(CLK_PERIOD*500) $finish;
end

// Monitoreo de estados y señales
always @(posedge enable) begin
    $display("Tiempo: %0t ns | Estado: %b | RS: %b | Data: 0x%h", 
             $time, dut.fsm_state, rs, data);
    
    // Decodificación de comandos/data
    if(rs == 0) begin
        case(data)
            dut.CLEAR_DISPLAY: $display("   Comando: CLEAR_DISPLAY");
            dut.SHIFT_CURSOR_RIGHT: $display("   Comando: SHIFT_CURSOR_RIGHT");
            dut.DISPON_CURSOROFF: $display("   Comando: DISPON_CURSOROFF");
            dut.LINES2_MATRIX5x8_MODE8bit: $display("   Comando: INIT");
            dut.START_2LINE: $display("   Comando: START_2LINE");
            8'h80: $display("   Comando: SET_CURSOR_LINE1");
            8'hC0: $display("   Comando: SET_CURSOR_LINE2");
            default: $display("   Comando desconocido: 0x%h", data);
        endcase
    end
    else begin
        $display("   Dato ASCII: '%s'", data);
    end
end

endmodule