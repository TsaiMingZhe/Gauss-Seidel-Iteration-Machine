`include "define.v"
module GSIM (
	input i_clk,
	input i_reset,
	input i_module_en,
	input [4:0]	i_matrix_num,
	output reg o_proc_done,
	// matrix memory
	output reg o_mem_rreq,
	output reg [9:0] o_mem_addr,
	input i_mem_rrdy,
	input [255:0] i_mem_dout,
	input i_mem_dout_vld,
	// output result
	output          o_x_wen,
	output  [  8:0] o_x_addr,
	output  [ 31:0] o_x_data  
	);
////
	reg 	[3:0]	state, next_state, a_cnt, iter_cnt;
	reg		[4:0]	round_n;
	reg 	[9:0]	o_mem_addr_w;
	reg		[255:0]	x_reg, x_reg_w;
////output assign
	assign o_x_wen = 1;
	assign o_x_addr = 0;
	assign o_x_data = 0;
////
	always @(*) begin//state
		case (state)
			`init : next_state = `mtx_num;
			`mtx_num : next_state = (i_module_en) ? `load_mtx : `mtx_num;
			`load_mtx : next_state = (1) ? `iteration : `load_mtx;
			default : next_state = state;
		endcase
	end
	always @(*) begin
		
	end
	always @(posedge i_clk or posedge i_reset) begin
		if (i_reset) begin
			state <= `init;
		end else begin
			state <= next_state;
		end
	end
endmodule