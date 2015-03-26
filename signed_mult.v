//3.33 fixed point signed multiply.
module signed_mult (out, a, b);
	output	[39:0]	out;
	input 	signed	[36:0] 	a;//3.33 37bit
	input 	signed	[36:0] 	b;
	wire	signed	[39:0]	out;
	wire 	signed	[73:0]	mult_out;
	assign mult_out = a * b;
	assign out = {mult_out[73], mult_out[71:33]}; //1+39
endmodule