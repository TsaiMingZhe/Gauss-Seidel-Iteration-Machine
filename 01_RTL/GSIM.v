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

			default : x_reg_w = x_reg;
		endcase
	end
	always @(posedge i_clk or posedge i_reset) begin//matrix memory control
		if (i_reset) begin
			o_mem_rreq <= 0;
			o_mem_addr <= 0;
		end else begin
			case (state)
				`idle : begin
					o_mem_rreq <= (i_module_en); 
					o_mem_addr <= (round_n * 17) - 1;
				end
				`load_b : begin
					o_mem_rreq <= 1; 
					o_mem_addr <= (i_mem_rrdy) ? o_mem_addr - 1 : o_mem_addr; 
				end
				`load_a : begin
					o_mem_rreq <= ~&{i_mem_rrdy, a_cnt};
					o_mem_addr <= (i_mem_rrdy) ? o_mem_addr - 1 : o_mem_addr;
				end
				default : begin
					o_mem_rreq <= 0;
					o_mem_addr <= 0;
				end
			endcase
		end
	end
	always @(posedge i_clk or posedge i_reset) begin
		if (i_reset) begin
			state <= `idle;
			round_n <= 1;
			o_proc_done <= 0;//test
			a_cnt <= 0;
			iter_cnt <= 0;
			x_reg <= 0;
		end else begin
			state <= next_state;
			round_n <= (state == `next_mtx) ? round_n + 1 : round_n;
			o_proc_done <= 0;//test
			a_cnt <= (state == `load_a & i_mem_rrdy) ? a_cnt + 1 : a_cnt;
			iter_cnt <= (state == `iteration) ? iter_cnt + 1 : iter_cnt;
			x_reg <= (state == `load_a & ~|a_cnt) ? i_mem_dout : x_reg;
		end
	end
endmodule
module mult_a_x (input [15:0]i_a, input [31:0]i_x, output [31:0]o_data);
	wire [47:0] m_ax;
	assign m_ax = $signed(i_a) * $signed(i_x);
	assign o_data = (m_ax[47]) ? (&m_ax[46:31]) ? m_ax[31:0] : 32'h80000000
							   : (|m_ax[46:31]) ? 32'h7fffffff : m_ax[31:0];
endmodule

module mult_b_a (input [15:0]i_b, input [15:0]i_a, output [31:0]o_data);
	wire [31:0] m_ba;
	assign m_ba = $signed(i_b) * $signed(i_a);
	assign o_data = (m_ba[31]) ? (&m_ba[30:29]) ? {m_ba[31], m_ba[28:0], 2'b0} : 32'h80000000
							   : (|m_ba[30:29]) ? 32'h7fffffff : {m_ba[31], m_ba[28:0], 2'b0};	
endmodule