module seven_segment	(input [3:0] number, output reg [6:0] data);

always @(number) begin
	case(number)
		4'h0: data = 7'b1000000;
		4'h1: data = 7'b1111001;
		4'h2: data = 7'b0100100;
		4'h3: data = 7'b0110000;
		4'h4: data = 7'b0011001;
		4'h5: data = 7'b0010010;
		4'h6: data = 7'b0000010;
		4'h7: data = 7'b1111000; 
		4'h8: data = 7'b0000000; 
		4'h9: data = 7'b0011000; 	
		4'ha: data = 7'b0001000;
		4'hb: data = 7'b0000011;
		4'hc: data = 7'b1000110;
		4'hd: data = 7'b0100001;
		4'he: data = 7'b0000110;
		4'hf: data = 7'b0001110;
		default : data = 7'b1111111;
	endcase
end

endmodule
