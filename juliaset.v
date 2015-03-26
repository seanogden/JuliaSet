/*
TODO:
wire switches and buttons to take in: c's value, and the zoom-in ranges
being able to zoom in
pipelining and observe difference
adjust clock speed
*/
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module juliaset(
	//////////// CLOCK //////////
	input 		          		CLOCK_50,
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,

	//////////// LED //////////
	output		     [8:0]		LEDG,
	output		    [17:0]		LEDR,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// SW //////////
	input 		    [17:0]		SW,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,
	output		     [6:0]		HEX6,
	output		     [6:0]		HEX7,

	//////////// LCD //////////
	output		          		LCD_BLON,
	inout 		     [7:0]		LCD_DATA,
	output		          		LCD_EN,
	output		          		LCD_ON,
	output		          		LCD_RS,
	output		          		LCD_RW,

	//////////// VGA //////////
	output		     [7:0]		VGA_B,
	output		          		VGA_BLANK_N,
	output		          		VGA_CLK,
	output		     [7:0]		VGA_G,
	output		          		VGA_HS,
	output		     [7:0]		VGA_R,
	output		          		VGA_SYNC_N,
	output		          		VGA_VS
);

wire	VGA_CTRL_CLK;
wire	AUD_CTRL_CLK;
wire	DLY_RST;
wire [7:0]	mVGA_R;				//memory output to VGA
wire [7:0]	mVGA_G;
wire [7:0]	mVGA_B;
wire [9:0]  Coord_X, Coord_Y;	//display coods
wire [3:0] mem_bit [6:0]; //current data from m4k to VGA
reg [23:0] color;
wire reset = ~KEY[0];
wire [6:0] pause;

Reset_Delay			r0	(	.iCLK(CLOCK_50),.oRESET(DLY_RST)	);

VGA_PLL p1 (.areset(~DLY_RST), .inclk0(CLOCK_50), .c0(VGA_CTRL_CLK), .c1(VGA_CLK));

VGA_Controller		u1	(	//	Host Side
							.iCursor_RGB_EN(4'b0111),
							.oAddress(),
							.oCoord_X(Coord_X),
							.oCoord_Y(Coord_Y),
							.iCursor_X(10'd0),
							.iCursor_Y(10'd0),
							.iCursor_R(8'd0),
							.iCursor_G(8'd0),
							.iCursor_B(8'd0),
							.iRed(mVGA_R),
							.iGreen(mVGA_G),
							.iBlue(mVGA_B),
							//	VGA Side
							.oVGA_R(VGA_R),
							.oVGA_G(VGA_G),
							.oVGA_B(VGA_B),
							.oVGA_H_SYNC(VGA_HS),
							.oVGA_V_SYNC(VGA_VS),
							.oVGA_SYNC(VGA_SYNC_N),
							.oVGA_BLANK(VGA_BLANK_N),
							.oVGA_CLOCK(),
							//	Control Signal
							.iCLK(VGA_CTRL_CLK),
							.iRST_N(KEY[0])	);

/* IO from the switches */
wire signed [17:0] c_real_wire;
wire signed [17:0] c_comp_wire;
wire signed [17:0] x_wire;
wire signed [17:0] y_wire;
wire signed [17:0] scale_wire;
wire valid;
wire [32*8-1:0] lcd_text;
assign LEDR = scale_wire;

genvar i;
generate
	for (i=0; i<7; i=i+1)
	begin: d
		defparam js.start_col = (i==0) ? 0 : 92*i - 1;
		defparam js.end_col = 92*(i+1); 
		julia_set_stripe js(.clock(CLOCK_50), .reset(reset),
					  .c_real_wire(c_real_wire),
					  .c_comp_wire(c_comp_wire),
					  .x_wire(x_wire),
					  .y_wire(y_wire),
					  .scale_wire(scale_wire),
					  .valid(valid),
					  .pixel_address({Coord_X[9:0],Coord_Y[8:0]}),
					  .vga_clock(VGA_CTRL_CLK),
					  .mem_bit(mem_bit[i]),
					  .update(~KEY[3]),
					  .pause_signal(pause[i]));
	end
endgenerate

// Color translation
assign  mVGA_R = color[23:16];
assign  mVGA_G = color[15:8];
assign  mVGA_B = color[7:0];

reg [3:0] mb;

always @ (posedge CLOCK_50) begin
	if (Coord_X < 93) mb <= mem_bit[0];
	else if (Coord_X < 10'd185) mb <= mem_bit[1];
	else if (Coord_X < 10'd277) mb <= mem_bit[2];
	else if (Coord_X < 10'd369) mb <= mem_bit[3];
	else if (Coord_X < 10'd461) mb <= mem_bit[4];
	else if (Coord_X < 10'd553) mb <= mem_bit[5];
	else mb <= mem_bit[6];
end

always @ (negedge CLOCK_50)
begin
	// register the m4k output for better timing on VGA
	// negedge seems to work better than posedge
	if (reset) color <= 24'd0;
	else begin
		case(mb)
			4'd0: color <= 24'd000000;
			4'd1: color <= 24'h7f00ff;
			4'd2: color <= 24'h0000ff;
			4'd3: color <= 24'h0080ff;
			4'd4: color <= 24'h00ffff;
			4'd5: color <= 24'h00ff80;
			4'd6: color <= 24'h00ff00;
			4'd7: color <= 24'h80ff00;
			4'd8: color <= 24'hffff00;
			4'd9: color <= 24'hff8000;
			4'd10: color <= 24'hff0000;
		endcase
	end
end

io io1(
	.clock(CLOCK_50),
	.reset(reset),
	.enter(~KEY[2]),
	.confirm(~KEY[1]),
	.sw(SW),
	.valid(valid),
	.c_real(c_real_wire),
	.c_comp(c_comp_wire),
	.x(x_wire),
	.y(y_wire),
	.scale(scale_wire),
	.lcd_text(lcd_text)
);

					 
/*LCD CODE*/

assign LCD_BLON = 1'b1;
assign LCD_ON = 1'b1;

asc_to_lcd asc(
	.clk(CLOCK_50),
	.rst(reset),
	.lcd_data(LCD_DATA),	
	.lcd_rnw(LCD_RW),
	.lcd_en(LCD_EN),
	.lcd_rs(LCD_RS),
	.disp_text(lcd_text)
);

/* System Timer code */
wire [9:0] useconds;
wire [9:0] mseconds;
wire usecond_pulse;
wire msecond_pulse;
defparam t1.CLOCK_MHZ = 50; //input clock frequency.


timer t1(
	.clk(CLOCK_50),
	.rst(reset),
	.pause(&pause),
	.usecond_cntr(useconds),
	.msecond_cntr(mseconds),
	.usecond_pulse(usecond_pulse),
	.msecond_pulse(msecond_pulse)
);

/*7SEG display code to show mseconds and useconds in hex.*/
wire [3:0] uhundreds;
wire [3:0] utens;
wire [3:0] uones;
wire [3:0] mhundreds;
wire [3:0] mtens;
wire [3:0] mones;

bcd bcd_u(.binary({2'd0,useconds}),
			.hundreds(uhundreds),
			.tens(utens),
			.ones(uones));
bcd bcd_m(.binary({2'd0,mseconds}),
			.hundreds(mhundreds),
			.tens(mtens),
			.ones(mones));
			
seven_segment ss0(.number(uones), .data(HEX0));
seven_segment ss1(.number(utens), .data(HEX1));
seven_segment ss2(.number(uhundreds), .data(HEX2));
assign HEX3 = 7'b1111111;
seven_segment ss4(.number(mones), .data(HEX4));
seven_segment ss5(.number(mtens), .data(HEX5));
seven_segment ss6(.number(mhundreds), .data(HEX6));
assign HEX7 = 7'b1111111;


endmodule




