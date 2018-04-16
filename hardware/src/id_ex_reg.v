// Instruction Decode / Execute (and Control Unit) Pipeline Register
module id_ex_reg_unit #(parameter CORE = 0, ADDRESS_BITS = 20)(
    clock, reset,

    id_opcode,
    id_funct3, id_funct7,
    id_rs1_data, id_rs2_data, id_rd,
    id_extend_imm,
    id_branch_target,
    id_JAL_target,
    cu_extend_sel,

    ex_opcode,
    ex_funct3, ex_funct7,
    ex_rs1_data, ex_rs2_data, ex_rd,
    ex_extend_imm,
    ex_branch_target,
    ex_JAL_target,
    id_extend_sel
);

input [6:0] id_opcode;
input [6:0] id_funct7;
input [2:0] id_funct3;
input [31:0] id_rs1_data;
input [31:0] id_rs2_data;
input [4:0] id_rd;
input [31:0] id_extend_imm;
input [ADDRESS_BITS-1:0] id_branch_target;
input [ADDRESS_BITS-1:0] id_JAL_target;
input [1:0] cu_extend_sel;

output [6:0] ex_opcode;
output [6:0] ex_funct7;
output [2:0] ex_funct3;
output [31:0] ex_rs1_data;
output [31:0] ex_rs2_data;
output [4:0] ex_rd;
output [31:0] ex_extend_imm;
output [ADDRESS_BITS-1:0] ex_branch_target;
output [ADDRESS_BITS-1:0] ex_JAL_target;
output [1:0] id_extend_sel;

always @(posedge clock) begin
    ex_opcode <= id_opcode;
    ex_funct3 <= id_funct3;
    ex_funct7 <= id_funct7;
    ex_rs1_data <= id_rs1_data;
    ex_rs2_data <= id_rs2_data;
    ex_rd <= id_rd;
    ex_extend_imm <= id_extend_imm;
    ex_branch_target <= id_branch_target;
    ex_JAL_target <= id_JAL_target;

    id_extend_sel <= cu_extend_sel;
end