module io (input clock, 
           input reset,
			  input [17:0] sw,
			  input enter,
			  input confirm,
			  output reg valid,
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
		enter_x=4'd3,
		enter_y=4'd4, 
		enter_scale=4'd5,
		display_params=4'd6,
		done=4'd7,
		confirm_c_real=4'd8,
		confirm_c_comp=4'd9,
		confirm_x=4'd10,
		confirm_y=4'd11, 
		confirm_scale=4'd12
		;
  

	always @(posedge clock) begin
		if (reset)
		begin
			state <= enter_c_real;
			lcd_text <="Enter c_real.";
			c_real <= 18'd0;
			c_comp <= 18'd0;
			x <= 18'd0;
			y <= 18'd0;
			valid <= 1'b0;
		end
		else
		begin
			case (state)
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
						state <= enter_c_comp;
						lcd_text <= "Enter c_comp.";
					end
					else
					begin
						state <= confirm_c_real;
						lcd_text <= "Display c_real.";
					end
				end
				
				
				
				enter_c_comp:
				begin
					if (enter)
					begin
						state <= confirm_c_comp;
						lcd_text <= "Display c_comp";
						c_comp <= switches;
					end
					else
					begin
						state <= enter_c_comp;
						lcd_text <= "Enter c_comp.";
					end
				end

				confirm_c_comp:
				begin
					if (confirm)
					begin
						state <= enter_x;
						lcd_text <= "Enter x.";
					end
					else
					begin
						state <= confirm_c_comp;
						lcd_text <= "Display c_comp.";
					end
				end

				enter_x:
				begin
					if (enter)
					begin
						state <= confirm_x;
						lcd_text <= "Display x";
						x <= switches;
					end
					else
					begin
						state <= enter_x;
						lcd_text <= "Enter x.";
					end
				end

				confirm_x:
				begin
					if (confirm)
					begin
						state <= enter_y;
						lcd_text <= "Enter y.";
					end
					else
					begin
						state <= confirm_x;
						lcd_text <= "Display x.";
					end
				end				
				
				
				enter_y:
				begin
					if (enter)
					begin
						state <= confirm_y;
						lcd_text <= "Display y";
						y <= switches;
					end
					else
					begin
						state <= enter_y;
						lcd_text <= "Enter y.";
					end
				end

				confirm_y:
				begin
					if (confirm)
					begin
						state <= enter_scale;
						lcd_text <= "Enter scale.";
					end
					else
					begin
						state <= confirm_y;
						lcd_text <= "Display y.";
					end
				end
						
				
				enter_scale:
				begin
					if (enter)
					begin
						state <= confirm_scale;
						lcd_text <= "Display scale";
						scale <= switches;
					end
					else
					begin
						state <= enter_scale;
						lcd_text <= "Enter scale.";
					end
				end

				confirm_scale:
				begin
					if (confirm)
					begin
						state <= done;
						lcd_text <= "Done.";
					end
					else
					begin
						state <= confirm_scale;
						lcd_text <= "Display scale.";
					end
				end
				
				done:
				begin
					state <= done;
					lcd_text <= "Done";
					valid <= 1'b1;
				end
			endcase
		end
	end
	
endmodule
