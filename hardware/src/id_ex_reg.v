// Instruction Decode / Execute (and Control Unit) Pipeline Register
module id_ex_reg_unit #(parameter CORE = 0, DATA_WIDTH=32, ADDRESS_BITS = 20)(
    clock, reset,

    id_opcode,
    id_funct3,
    id_funct7,
    id_rs1_data,
    id_rs2_data,
    id_rd,
    id_branch,
    id_branch_target,
    id_inst_PC,
    id_JAL_target,
    id_extend_imm,
    cu_extend_sel,
    cu_next_PC_select,
    ex_write,
    ex_write_reg,
    ex_write_data,

    ex_opcode,
    ex_funct3,
    ex_funct7,
    ex_rs1_data,
    ex_rs2_data,
    ex_rd,
    ex_branch,
    ex_branch_target,
    ex_inst_PC,
    ex_JAL_target,
    ex_extend_imm,
    id_extend_sel,
    id_next_PC_select,
    id_write,
    id_write_reg,
    id_write_data,
);

input clock;
input reset;

input [6:0] id_opcode;
input [2:0] id_funct3;
input [6:0] id_funct7;
input [31:0] id_rs1_data;
input [31:0] id_rs2_data;
input [4:0] id_rd;
input id_branch;
input [ADDRESS_BITS-1:0] id_branch_target;
input [ADDRESS_BITS-1:0] id_inst_PC;
input [ADDRESS_BITS-1:0] id_JAL_target;
input [31:0] id_extend_imm;
input [1:0] cu_extend_sel;
input [1:0] cu_next_PC_select;
input ex_write;
input [4:0] ex_write_reg;
input [DATA_WIDTH-1:0] ex_write_data;

output reg [6:0] ex_opcode;
output reg [2:0] ex_funct3;
output reg [6:0] ex_funct7;
output reg [31:0] ex_rs1_data;
output reg [31:0] ex_rs2_data;
output reg [4:0] ex_rd;
output reg ex_branch;
output reg [ADDRESS_BITS-1:0] ex_branch_target;
output reg [ADDRESS_BITS-1:0] ex_inst_PC;
output reg [ADDRESS_BITS-1:0] ex_JAL_target;
output reg [31:0] ex_extend_imm;
output reg [1:0] id_extend_sel;
output reg [1:0] id_next_PC_select;
output reg id_write;
output reg [4:0] id_write_reg;
output reg [DATA_WIDTH-1:0] id_write_data;

always @(posedge clock) begin
    ex_opcode <= id_opcode;
    ex_funct3 <= id_funct3;
    ex_funct7 <= id_funct7;
    ex_rs1_data <= id_rs1_data;
    ex_rs2_data <= id_rs2_data;
    ex_rd <= id_rd;
    ex_branch <= id_branch;
    ex_branch_target <= id_branch_target;
	ex_inst_PC <= id_inst_PC;
	ex_JAL_target <= id_JAL_target;
    ex_extend_imm <= id_extend_imm;
    id_extend_sel <= cu_extend_sel;
    id_next_PC_select <= cu_next_PC_select;
    id_write <= ex_write;
    id_write_reg <= ex_write_reg;
    id_write_data <= ex_write_data;
end
endmodule
