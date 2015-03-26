module julia_set_stripe(input clock, 
                        input reset, 
								input signed [17:0] c_real_wire,
								input signed [17:0] c_comp_wire,
								input signed [17:0] x_wire,
								input signed [17:0] y_wire,
								input signed [17:0] scale_wire,
								input valid,
								input [18:0] pixel_address,
								input vga_clock,
								output [3:0] mem_bit,
								input update,
								output pause_signal);
								
parameter start_row = 9'd0;
parameter end_row = 9'd479;
parameter start_col = 10'd0;
parameter end_col = 10'd320;

//state names
parameter
   compute_pixel_init=4'd1,
	compute_pixel_loop=4'd2,
	draw_pixel=4'd7,
	draw_pixel1=4'd12, 
	draw_pixel2=4'd13,
   done= 4'd14	;
	
////////////////////////////////////
//DLA state machine variables
reg [3:0] state;	//state machine
reg [23:0] color;
wire [3:0] state_bit ; // current data from m4k to state machine
reg we ; // write enable for a
reg [16:0] addr_reg ; // for a
reg signed [3:0] data_reg ; // for a
reg [9:0] x_cursor;
reg [8:0] y_cursor;
reg [9:0] i; //iteration.
reg signed [9:0] x_start;
reg signed [9:0] x_end;
reg signed [8:0] y_start;
reg signed [8:0] y_end;
reg pause;
assign pause_signal = pause;
wire [15:0] pixel_address_fixed = {pixel_address[17:9] - start_col,pixel_address[8:0]};
reg signed 	[36:0] z_real;  //real part of z 3.33 fixed point
reg signed [36:0] z_comp;  //complex part of z 3.33 fixed point
reg signed [36:0] c_real;
reg signed [36:0] c_comp;
wire signed [39:0] z_real_real;
wire signed [39:0] z_comp_comp;
wire signed [39:0] z_real_comp;
reg signed [73:0] x_increment;
reg signed [73:0] y_increment;

reg signed [36:0] c_real_reg;
reg signed [36:0] c_comp_reg;
reg signed [36:0] x_reg;
reg signed [36:0] y_reg;
reg signed [36:0] scale_reg;

video_buffer display(
	.address_a (addr_reg) , 
	.address_b (pixel_address_fixed), // vga current address
	.clock_a (clock),
	.clock_b (vga_clock),
	.data_a (data_reg),
	.data_b (4'b0), // never write on port b
	.wren_a (we),
	.wren_b (1'b0), // never write on port b
	.q_a (state_bit),
	.q_b (mem_bit) ); // data used to update VGA


always @ (posedge clock) //VGA_CTRL_CLK
begin
	if (reset)
	begin
		c_real_reg <= -37'd6871947673;  // -0.8
		c_comp_reg <= 37'd1340029796;  //  0.156
		x_reg <= 37'd0;
		y_reg <= 37'd0;
		scale_reg <= $signed({4'd2, {33{1'b0}}});
		x_increment <= ((37'd13421772 * {4'd2, {33{1'b0}}})<<<1);
		y_increment <= ((37'd17895697 * {4'd2, {33{1'b0}}})<<<1);
		
		addr_reg <= pixel_address ;	// [17:0]
		we <= 1'b1;								//write some memory
		data_reg <= 4'd0;	//write all zeros (black)	
		//init a randwalker to just left of center
		x_cursor <= start_col;
		y_cursor <= start_row;
		c_real <= c_real_reg;
		c_comp <= c_comp_reg;
		z_real <= 37'd0;
		z_comp <= 37'd0;
		i <= 10'd0;
		state <= compute_pixel_init;	//first state in regular state machine 
		pause <= 1'b0;
	end
	else if (valid && update)
	begin
		c_real_reg <= {c_real_wire, 19'b0};//c_real_reg;//
		c_comp_reg <= {c_comp_wire, 19'b0};//c_comp_reg;//
		x_reg <= {x_wire, 19'b0};
		y_reg <= {y_wire, 19'b0};
		scale_reg <= {scale_wire, 19'b0};
		x_increment <= ((37'd13421772 * {scale_wire, 19'b0})<<<1);
		y_increment <= ((37'd17895697 * {scale_wire, 19'b0})<<<1);
		
		//clear the screen
		addr_reg <= pixel_address ;	// [18:0]
		we <= 1'b1;								//write some memory
		data_reg <= 4'd0;	//write all zeros (black)	
		//init a randwalker to just left of center
		x_cursor <= start_col;
		y_cursor <= start_row;
		c_real <= c_real_reg;
		c_comp <= c_comp_reg;
		z_real <= 37'd0;
		z_comp <= 37'd0;
		i <= 10'd0;
		state <= compute_pixel_init;	//first state in regular state machine 
		pause <= 1'b0;
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
				z_real <= x_reg - scale_reg + $signed(x_increment[72:33]* x_cursor);  //-2.0 + x*(increment=2*scale/640)
				z_comp <= x_reg - scale_reg + $signed(y_increment[72:33]* y_cursor);  //-2.0 + y*(increment=2*scale/480)
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
				addr_reg <= {x_cursor - start_col, y_cursor};
				
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
				if (x_cursor < end_col)
				begin
					x_cursor <= x_cursor + 10'd1;
				end
				else
				begin
					x_cursor <= start_col;
					if (y_cursor < end_row)
					begin
						y_cursor <= y_cursor + 9'd1;
					end
				end
				
				//Compute new pixel at updated cursor, if there are more pixels
				//otherwise just go to done and wait for reset.
				if (x_cursor == end_col && y_cursor == end_row)
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
				 pause <= 1'b1;
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
