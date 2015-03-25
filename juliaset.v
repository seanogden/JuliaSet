/*
TODO:
wire switches and buttons to take in: c's value, and the zoom-in ranges
being able to zoom in
pipelining and observe difference
adjust clock speed
*/s
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module juliaset(

	//////////// CLOCK //////////
	input 		          		CLOCK_50,
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// SW //////////
	input 		    [17:0]		SW,

	//////////// LCD //////////
	output		          		LCD_BLON,
	inout 		     [7:0]		LCD_DATA,
	output		          		LCD_EN,
	output		          		LCD_ON,
	output		          		LCD_RS,
	output		          		LCD_RW,

	//////////// RS232 //////////
	input 		          		UART_CTS,
	output		          		UART_RTS,
	input 		          		UART_RXD,
	output		          		UART_TXD,

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

assign LCD_DATA = 8'bzzzzzzzz;
wire	VGA_CTRL_CLK;
wire	AUD_CTRL_CLK;
wire	DLY_RST;
wire [7:0]	mVGA_R;				//memory output to VGA
wire [7:0]	mVGA_G;
wire [7:0]	mVGA_B;
wire [9:0]  Coord_X, Coord_Y;	//display coods

Reset_Delay			r0	(	.iCLK(CLOCK_50),.oRESET(DLY_RST)	);

VGA_PLL p1 (.areset(~KEY[1]), .inclk0(CLOCK_50), .c0(VGA_CTRL_CLK), .c1(VGA_CLK));

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



////////////////////////////////////
//DLA state machine variables
wire reset;
reg [3:0] state;	//state machine
wire [3:0] mem_bit ; //current data from m4k to VGA
reg [3:0] disp_bit ; // registered data from m4k to VGA
reg [23:0] color;
wire [3:0] state_bit ; // current data from m4k to state machine
reg we ; // write enable for a
reg [18:0] addr_reg ; // for a
reg signed [3:0] data_reg ; // for a
reg [9:0] x_cursor;
reg [8:0] y_cursor;
reg [9:0] i; //iteration.
reg signed 	[36:0] z_real;  //real part of z 3.33 fixed point
reg signed [36:0] z_comp;  //complex part of z 3.33 fixed point
reg signed [36:0] c_real;
reg signed [36:0] c_comp;
wire signed [39:0] z_real_real;
wire signed [39:0] z_comp_comp;
wire signed [39:0] z_real_comp;


reg signed [60:0] real_test;
reg signed [60:0] real_final_test;
reg signed [60:0] comp_test;
reg signed [60:0] real_test_org;


//TODO:  We only need to store 4 bits, because we just want 
//       log of the # of iterations, and there are only up to
//       1000 iterations. log2(1000)=9.9 thus an unsigned i needs 10 bits
video_buffer display(
	.address_a (addr_reg) , 
	.address_b ({Coord_X[9:0],Coord_Y[8:0]}), // vga current address
	.clock_a (VGA_CTRL_CLK),
	.clock_b (VGA_CTRL_CLK),
	.data_a (data_reg),
	.data_b (4'b0), // never write on port b
	.wren_a (we),
	.wren_b (1'b0), // never write on port b
	.q_a (state_bit),
	.q_b (mem_bit) ); // data used to update VGA

// Color translation
assign  mVGA_R = color[23:16];
assign  mVGA_G = color[15:8];
assign  mVGA_B = color[7:0];

// DLA state machine
assign reset = ~KEY[0];

//state names
parameter
   compute_pixel_init=4'd1,
	compute_pixel_loop=4'd2,
	draw_pixel=4'd7,
	draw_pixel1=4'd12, 
	draw_pixel2=4'd13,
   done= 4'd14	;
	
always @ (negedge VGA_CTRL_CLK)
begin
	// register the m4k output for better timing on VGA
	// negedge seems to work better than posedge
	if (reset) color <= 24'd0;
	else case(mem_bit)
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

always @ (posedge VGA_CTRL_CLK) //VGA_CTRL_CLK
begin

	if (reset)		//synch reset assumes KEY0 is held down 1/60 second
	begin
		//clear the screen
		addr_reg <= {Coord_X[9:0],Coord_Y[8:0]} ;	// [17:0]
		we <= 1'b1;								//write some memory
		data_reg <= 4'd0;	//write all zeros (black)	
		//init a randwalker to just left of center
		x_cursor <= 10'd318;
		y_cursor <= 9'd50;
		c_real <= -37'd6871947673;  // -0.8
		c_comp <=  37'd1340029796;  //  0.156
		z_real <= 37'd0;
		z_comp <= 37'd0;
		i <= 10'd0;
		state <= compute_pixel_init;	//first state in regular state machine 
	end
	
	//begin state machine to modify display 
	else
	begin
		case(state)
		
			/**************************************************
			 * This section is the set of states we use to loop
			 * up to n times in order to compute the value for
			 * the pixel at x_cursor, y_cursor
			 ***************************************************/
			compute_pixel_init:
			begin
				//compute the 3.33 fp number corresponding to x_cursor
				//compute the 3.33 fp number corresonding to the y_cursor
				
				//The resolution of 3.33 fp is 2^-33.
				//We want to map integers 0-639 onto -2.0, 2.0 fp, and 0-479 onto -1.0, 1.0
				//4/640/2^-33 = 53687091.2, so this is our increment on x.
				//4/480/2^-33 = 35791394.1, so this is our increment on y.
				//We round it down.  Note that we don't need to do an actual
				//fixed point multiply because this will never overflow by design.
				z_real <= $signed({-4'd2, {33{1'b0}}}) + $signed(37'd53687091 * x_cursor);  //-2.0 + x*(increment=4/640)
				z_comp <= $signed({-4'd2, {33{1'b0}}}) + $signed(37'd71732230 * y_cursor); //-1.0 + y*(increment=4/480)
				//NOTE: We can increment this at the bottom to avoid this multiply.
				//TODO:  Make the increment numbers a function of the range of x and y.
				
				i <= 10'd0;
				state <= compute_pixel_loop;
			end
			

			compute_pixel_loop:
			begin
				//      We avoid doing the sqrt part of getting the absolute value by squaring the RHS
				//      of the comparison.
				//
				//      We can do this step with 3 fixed point multiplies.
				//      1.  z_real*z_real
				//      2.  z_comp*z_comp
				//      3.  z_real*z_comp
				
				//Not finished, do another iteration
				if (z_real_real + z_comp_comp < $signed({4'b0100, {33{1'b0}}}) 
						&&  i < 10'd1000) // if (abs(z)*abs(z) < 4 && n < termination)
				begin
					z_real <= (z_real_real) - (z_comp_comp) + c_real;
					z_comp <= (z_real_comp <<< 1) + c_comp;
					i <= i + 10'd1;
					state <= compute_pixel_loop;
				end
				
				// Done iterating, go draw the pixel.
				else
				begin
					state <= draw_pixel;
				end
			end
			
			
			/**************************************************
			 * This section is for drawing a fully computed pixel
			 * by writing it to the proper M9K block.
			 ***************************************************/
			draw_pixel: //register address and data for write.
			begin
			   we <= 1'b0;
				addr_reg <= {x_cursor, y_cursor};
				
				//approximate log of i.
				if (i[9] == 1)      data_reg <= 4'd10;
				else if (i[8] == 1) data_reg <= 4'd9;
				else if (i[7] == 1) data_reg <= 4'd8;
				else if (i[6] == 1) data_reg <= 4'd7;
				else if (i[5] == 1) data_reg <= 4'd6;
				else if (i[4] == 1) data_reg <= 4'd5;
				else if (i[3] == 1) data_reg <= 4'd4;
				else if (i[2] == 1) data_reg <= 4'd3;
				else if (i[1] == 1) data_reg <= 4'd2;
				else if (i[0] == 1) data_reg <= 4'd1;
				else                data_reg <= 4'd0;
				
				state <= draw_pixel1 ;	
			end
			
			draw_pixel1: //initiate the write.
			begin
				we <= 1'b1; // memory write enable 
				state <= draw_pixel2 ;
			end
			
			draw_pixel2: // finish the write and increment the cursor
			begin
				we <= 1'b0; 
				
				//Move cursor
				if (x_cursor < 10'd637)
				begin
					x_cursor <= x_cursor + 10'd1;
				end
				else
				begin
					x_cursor <= 10'd0;
					if (y_cursor < 9'd479)
					begin
						y_cursor <= y_cursor + 9'd1;
					end
				end
				
				//Compute new pixel at updated cursor, if there are more pixels
				//otherwise just go to done and wait for reset.
				if (x_cursor == 637 && y_cursor == 9'd479)
				begin
					state <= done;
				end
				else
				begin
					state <= compute_pixel_init;
				end
			end
			
			done:  //after computing all pixels in the block, just wait here.
			begin
			    state <= done;
			end
		endcase
	end // else
	
end // always @ (posedge VGA_CTRL_CLK)

signed_mult zrs(.out(z_real_real),
                .a(z_real),
					 .b(z_real));
					 
signed_mult zcs(.out(z_comp_comp),
                .a(z_comp),
					 .b(z_comp));

signed_mult zcr(.out(z_real_comp),
                .a(z_comp),
					 .b(z_real));
endmodule

//3.33 fixed point signed multiply.
module signed_mult (out, a, b);
	output	[36:0]	out;
	input 	signed	[36:0] 	a;//3.33 37bit
	input 	signed	[36:0] 	b;
	wire	signed	[39:0]	out;
	wire 	signed	[73:0]	mult_out;
	assign mult_out = a * b;
	assign out = {mult_out[73], mult_out[71:33]}; //1+39
endmodule
