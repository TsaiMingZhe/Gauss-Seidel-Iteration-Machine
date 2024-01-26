`include "define.v"
module GSIM (
	input          i_clk,
	input          i_reset,
	input          i_module_en,
	input  [  4:0] i_matrix_num,
	output         o_proc_done,

	// matrix memory
	output         o_mem_rreq,
	output [  9:0] o_mem_addr,
	input          i_mem_rrdy,
	input  [255:0] i_mem_dout,
	input          i_mem_dout_vld,
	
	// output result
	output         o_x_wen,
	output [  8:0] o_x_addr,
	output [ 31:0] o_x_data  
	);
////	
	reg 	[3:0]	state, next_state;
////output assign
	assign o_x_wen = 1;
	assign o_x_addr = 0;
	assign o_x_data = 0;
////
	always @(*) begin//state
		case (state)
			`init : next_state = `mtx_num;
			`mtx_num : next_state = (i_module_en) ? `load_b : `mtx_num;
			`load_b : next_state = (i_mem_dout_vld) ? `load_a : `load_b;
			`load_a : next_state = (1) ? `iteration : `load_a;
			`iteration : next_state = (1) ? `data_out : `iteration;
			`data_out : next_state = (1) ? `endding : `data_out;
			`endding : next_state = `endding;
			default : next_state = state;
		endcase
	end
	always @(*) begin
		case (state)//matrix memory out
			load_b : begin
				
			end
			default: 
		endcase
	end
	always @(posedge i_clk or posedge i_reset) begin
		if (i_reset) begin
			state <= `init;
			load17_cnt <= 0;
		end else begin
			state <= next_state;
			if (state == `load_mtx) begin
				load17_cnt <= (i_mem_dout_vld) ? (load17_cnt[4]) ? 0 : load17_cnt + 1 : load17_cnt;
			end 
			load17_cnt <= () ? 
		end
	end
endmodule
