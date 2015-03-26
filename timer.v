module timer (
	input clk,rst,pause,

	output reg [9:0] usecond_cntr,
	output reg [9:0] msecond_cntr,
		
	output reg usecond_pulse,
	output reg msecond_pulse
);

parameter CLOCK_MHZ = 200;

reg [7:0] tick_cntr;
reg tick_cntr_max;

always @(posedge clk) begin
	if (rst) begin
		tick_cntr <= 0;
		tick_cntr_max <= 0;
	end
	else if (pause) begin
	end
	else begin
		if (tick_cntr_max) tick_cntr <= 1'b0;
		else tick_cntr <= tick_cntr + 1'b1;
		tick_cntr_max <= (tick_cntr == (CLOCK_MHZ - 2'd2));
	end
end

/////////////////////////////////
// Count off 1000 us to form 1 ms
/////////////////////////////////
reg usecond_cntr_max;

always @(posedge clk) begin
	if (rst) begin
		usecond_cntr <= 0;
		usecond_cntr_max <= 0;
	end
	else if (tick_cntr_max) begin
		if (usecond_cntr_max) usecond_cntr <= 1'b0;
		else usecond_cntr <= usecond_cntr + 1'b1;
		usecond_cntr_max <= (usecond_cntr == 10'd998);
	end
end

/////////////////////////////////
// Count off 1000 ms to form 1 s
/////////////////////////////////
reg msecond_cntr_max;

always @(posedge clk) begin
	if (rst) begin
		msecond_cntr <= 0;
		msecond_cntr_max <= 0;
	end
	else if (usecond_cntr_max & tick_cntr_max) begin
		if (msecond_cntr_max) msecond_cntr <= 1'b0;
		else msecond_cntr <= msecond_cntr + 1'b1;
		msecond_cntr_max <= (msecond_cntr == 10'd998);
	end
end

/////////////////////////////////////
// Filtered output pulses 
/////////////////////////////////////
always @(posedge clk) begin
	if (rst) begin
		usecond_pulse <= 1'b0;
		msecond_pulse <= 1'b0;
	end
	else begin
		usecond_pulse <= tick_cntr_max;
		msecond_pulse <= tick_cntr_max & usecond_cntr_max;
	end
end			

endmodule
