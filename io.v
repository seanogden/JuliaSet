module io (input clock, 
           input reset,
			  input [17:0] sw,
			  input enter,
			  input confirm,
			  output valid,
			  output reg [17:0] c_real, 
			  output reg [17:0] c_comp,
			  output reg [17:0] x,
			  output reg [17:0] y,
			  output reg [17:0] scale,
			  output reg [32*8-1:0] lcd_text);
	
	reg [3:0] state;
	reg [17:0] switches;
	
	always @*
		switches <= sw;
		
	parameter
		enter_c_real=4'd1,
		enter_c_comp=4'd2,
		enter_z_comp=4'd3,
		enter_z_real=4'd4, 
		enter_z_scale=4'd5,
		display_params=4'd6,
		done=4'd7,
		confirm_c_real=4'd8,
		confirm_c_comp=4'd9,
		confirm_z_comp=4'd10,
		confirm_z_real=4'd11, 
		confirm_z_scale=4'd12
		;
  
  `define 	state_transition(FROM, TO) \
		enter_c_real: begin \
			if (enter) begin \
				state <= confirm_c_real ; \
				lcd_text <= "Display "; \
				c_real <= switches; \
			end \
			else begin \
				state <= enter_c_real ; \
				lcd_text <= "Enter c_real."; \
			end \
		end \
		confirm_c_real : \
		begin \
			if (confirm) begin \
				state <= enter_c_comp ; \
				lcd_text <= "Enter c_comp."; \
			end \
			else begin \
				state <= confirm_c_real ; \
				lcd_text <= "Display c_real."; \
			end \
		end
				
	always @(posedge clock) begin
	//always @* begin
		if (reset)
		begin
			state <= enter_c_real;
			lcd_text <="Enter c_real.";
			c_real <= 18'd0;
			c_comp <= 18'd0;
			x <= 18'd0;
			y <= 18'd0;
		end
		else
		begin
			case (state)
			  /*
				enter_c_real:
				begin
					if (enter)
					begin
						state <= confirm_c_real;
						lcd_text <= "Display c_real";
						c_real <= switches;
					end
					else
					begin
						state <= enter_c_real;
						lcd_text <= "Enter c_real.";
					end
				end

				confirm_c_real:
				begin
					if (confirm)
					begin
						state <= enter_z_real;
						lcd_text <= "Enter c_comp.";
					end
					else
					begin
						state <= confirm_c_real;
						lcd_text <= "Display c_real.";
					end
				end*/
				
				`state_transition(c_real, c_comp)
				
				
				
				enter_z_real:
				begin
					state <= enter_z_real;
					lcd_text <= "Done";
				end
			endcase
		end
	end
	
endmodule