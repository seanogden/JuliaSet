`timescale 1ns/1ns
module testbench();
reg clk_50, reset;
reg [31:0] index;
//Initialize clocks and index
initial begin
clk_50 = 1'b0;
index = 32'd0;
end
//Toggle the clocks
always begin
#10
clk_50 = !clk_50;
end
//Intialize and drive signals
initial begin
reset = 1'b0;
#400
reset = 1'b1;
#20000000
$stop;
end
//Increment index
always @ (posedge clk_50) begin
index <= index + 32'd1;
end
//Instantiation of Device Under Test
juliaset DUT(
//////////// CLOCK //////////
.CLOCK_50(clk_50),
.CLOCK2_50(1'b0),
.CLOCK3_50(1'b0),
//////////// KEY //////////
.KEY({3'b111,reset}),
//////////// SW //////////
.SW({8'd0,5'd4,5'd12}),
	//////////// LCD //////////
.LCD_BLON(),
.LCD_DATA(),
.LCD_EN(),
.LCD_ON(),
.LCD_RS(),
.LCD_RW(),

	//////////// RS232 //////////
.UART_CTS(1'b0),
.UART_RTS(),
.UART_RXD(),
.UART_TXD(),

	//////////// VGA //////////
.VGA_B(),
.VGA_BLANK_N(),
.VGA_CLK(),
.VGA_G(),
.VGA_HS(),
.VGA_R(),
.VGA_SYNC_N(),
.VGA_VS()
);
endmodule