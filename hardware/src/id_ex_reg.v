// Instruction Decode / Execute (and Control Unit) Pipeline Register
module id_ex_reg_unit #(parameter CORE = 0, ADDRESS_BITS = 20)(
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

input [6:0] id_opcode;
input [2:0] id_funct3;
input [6:0] id_funct7;
input [31:0] id_rs1_data;
input [31:0] id_rs2_data;
input [4:0] id_rd;
input id_branch;
input [ADDRESS_BITS-1:0] id_branch_target;
input [31:0] id_extend_imm;
input [1:0] cu_extend_sel;
input [1:0] cu_next_PC_select;
input ex_write;
input [4:0] ex_write_reg;
input [DATA_WIDTH-1:0] ex_write_data;

output [6:0] ex_opcode;
output [2:0] ex_funct3;
output [6:0] ex_funct7;
output [31:0] ex_rs1_data;
output [31:0] ex_rs2_data;
output [4:0] ex_rd;
output ex_branch;
output [ADDRESS_BITS-1:0] ex_branch_target;
output [31:0] ex_extend_imm;
output [1:0] id_extend_sel;
output [1:0] id_next_PC_select;
output id_write;
output [4:0] id_write_reg;
output [DATA_WIDTH-1:0] id_write_data;

always @(posedge clock) begin
    ex_opcode <= id_opcode;
    ex_funct3 <= id_funct3;
    ex_funct7 <= id_funct7;
    ex_rs1_data <= id_rs1_data;
    ex_rs2_data <= id_rs2_data;
    ex_rd <= id_rd;
    ex_branch <= id_branch;
    ex_branch_target <= id_branch_target;
    ex_extend_imm <= id_extend_imm;
    id_extend_sel <= ex_extend_sel;
    id_next_PC_select <= cu_next_PC_select;
    id_write <= ex_write;
    id_write_reg <= ex_write_reg;
    id_write_data <= ex_write_data;
end