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
			`idle : next_state = (i_module_en) ? `load_b : `idle;
			`load_b : next_state = `load_a;
			`load_a : next_state = (&a_cnt) ? `iteration : `load_a;
			`iteration : next_state = (&iter_cnt) ? `data_out : `iteration;
			`data_out : next_state = (1) ? `endding : `data_out;
			`next_mtx : next_state = (round_n == i_matrix_num) ? `endding : `load_b;
			`endding : next_state = `endding;
			default : next_state = state;
		endcase
	end
	always @(*) begin
		case (state)//matrix memory address control
			`load_b : o_mem_addr_w = (round_n * 17) - 1;
			`load_a : o_mem_addr_w = (round_n * 17) - 2 - a_cnt;
			default : o_mem_addr_w = 0;
		endcase
		case (a_cnt)
			0 : x_reg_w = i_mem_dout;

			default: 
		endcase
	end
	always @(posedge i_clk or posedge i_reset) begin
		if (i_reset) begin
			state <= `idle;
			round_n <= 1;
			o_proc_done <= 0;//test
			o_mem_rreq <= 0;//test
			o_mem_addr <= 0;
			a_cnt <= 0;
			iter_cnt <= 0;
			x_reg <= 0;
		end else begin
			state <= next_state;
			round_n <= (state == `next_mtx) ? round_n + 1 : round_n;
			o_proc_done <= 0;//test
			o_mem_rreq <= i_module_en;
			o_mem_addr <= o_mem_addr_w;
			a_cnt <= (state == `load_a) ? a_cnt + 1 : a_cnt;
			iter_cnt <= (state == `iteration) ? iter_cnt + 1 : iter_cnt;
			x_reg <= (state == `load_a & ~|a_cnt) ? i_mem_dout : x_reg;
		end
	end
endmodule