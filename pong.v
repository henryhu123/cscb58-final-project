// Part 2 skeleton

module lab6_p2
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		HEX2,
		HEX3,
		HEX0,
		HEX1
	);
	wire movL;
	wire movR;
	assign movL= KEY[2];
	assign movR = KEY[0];
	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	output [6:0] HEX1,HEX0,HEX2,HEX3;
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
//	reg bar_x;
//	bar_x <= 30;
//always@(*)
//begin
//if(movL)
//// when x is true (i.e., logic 1)
//bar_x = bar_x -1;
//// w gets set to 1
//if(movR)
//bar_x =bar_x +1;
//end
//	wire [7:0] bar_x;
//	assign bar_x = 30;
////	hex_display h0(.IN(bar_x[3:0]),.OUT(HEX0));
////	hex_display h1(.IN(bar_x[7:4]),.OUT(HEX1));
////	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [5:0] x;	
	wire [6:0] y;
	wire writeEn, ld_x, ld_y;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			wire [2:0] stateNum;
			wire [3:0] x_val;
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    // Instansiate datapath
	datapath d0(.clk(CLOCK_50), .ld_x(ld_x), .ld_y(ld_y), .in(SW[6:0]), .reset_n(resetn), .x(x), .y(y), .colour(colour), .cl_in(SW[9:7]), .stateNum(stateNum));

    // Instansiate FSM control
    	control c0(.clk(CLOCK_50), .to_load(~KEY[3]), .to_plot(~KEY[1]), .reset_n(resetn), .ld_x(ld_x), .ld_y(ld_y), .write(writeEn), .stateNum(stateNum));
    
endmodule

module control(clk, to_load, to_plot, reset_n, ld_x, ld_y, write,stateNum);

	input clk, to_load, to_plot, reset_n;
	output reg ld_y, ld_x, write;		

	reg [2:0] curr, next;
	output reg [2:0] stateNum;
	localparam  S_CLEAR   = 3'b000;
			localparam S_LOAD_X	= 3'b001;
			localparam S_WAIT_Y	= 3'b010;
			localparam S_LOAD_Y	= 3'b011;
			localparam S_PLOT		= 3'b100;
			localparam S_PLOT2 	= 3'b101;
	
	always @(*)
	begin: state_table
		case (curr)
			S_CLEAR: next = to_load ? S_LOAD_X : S_CLEAR;
			S_LOAD_X: next = to_load ? S_WAIT_Y : S_LOAD_X;
			S_WAIT_Y: next = to_plot ? S_LOAD_Y : S_WAIT_Y;
			S_LOAD_Y: next = to_plot ? S_PLOT : S_LOAD_Y;
			S_PLOT: next = to_load ? S_PLOT2 : S_PLOT;
			
		default: next = S_CLEAR;
		endcase
	end

	always@(*)
	begin: enable_signals
		ld_x = 1'b0;
		ld_y = 1'b0;
		write = 1'b0;
		stateNum = 3'b000;
		case (curr)
			S_CLEAR: // Find out how to send a clear signal
			S_LOAD_X: begin
				stateNum = 3'b000;
				write <= 1'b1;
				end
			
			S_LOAD_Y: begin
				stateNum = 3'b001;
				write <= 1'b1;
				end
			S_PLOT: begin
			stateNum = 3'b010;
				end
			S_PLOT2: begin
				stateNum = 3'b011;
				end
		endcase
	end

	always @(posedge clk)
	begin: states
		if(!reset_n)
			curr <= S_LOAD_X;
		else
			curr <= next;
	end

endmodule

module datapath(clk, ld_x, ld_y, in, reset_n, x, y, colour, cl_in, stateNum);
	input clk;
	input [6:0] in;
	input ld_x, ld_y;
	input [2:0] cl_in;
	input reset_n;
	output reg [2:0] colour;
	output reg [6:0] y;
	output reg [8:0] x;
	input [2:0] stateNum;
	reg[8:0] i,j,k,l;
	
	always @(posedge clk)
	begin
		if(!reset_n)
		begin
			x <= 8'b00010100;
			y <= 7'b0;
			colour <= 3'b100;
		end
		else
		begin
			if(stateNum == 3'b000)
				begin
				for(i=0;i<5;i=i+1)
					x<=x+1;
				end
		end
			if(stateNum == 3'b001)
			begin
				x<=60;
				x<=61;
				y<=100;
				y<=101;
			end
		end	
	endmodule
	
	
module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end

endmodule
				

	