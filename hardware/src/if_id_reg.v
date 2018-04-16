// Instruction Fetch / Instruction Dispatch Register
module if_id_reg_unit #(parameter CORE = 0, DATA_WIDTH = 32, ADDRESS_BITS=20)(
    clock, reset,

    if_instruction,
    if_inst_PC,
    id_branch_target,
    id_JAL_target,
    cu_next_PC_select,
    ex_JALR_target,
    ex_branch,

    id_instruction,
    id_inst_PC,
    if_JAL_target,
    if_JALR_target,
    if_next_PC_select,
    if_branch,
    if_branch_target
);

input clock, reset;

input [DATA_WIDTH-1:0] if_instruction;
input [ADDRESS_BITS-1:0] if_inst_PC;
input [ADDRESS_BITS-1:0] id_branch_target;
input [ADDRESS_BITS-1:0] id_JAL_target;
input [1:0] cu_next_PC_sel;
input [ADDRESS_BITS-1:0] ex_JALR_target;
input ex_branch;

output [31:0] id_instruction;
output [ADDRESS_BITS-1:0] id_inst_PC;
output [1:0] if_next_PC_sel;
output [ADDRESS_BITS-1:0] if_JAL_target;
output [ADDRESS_BITS-1:0] if_JALR_target;
output if_branch;
output [ADDRESS_BITS-1:0] if_branch_target;

always @(posedge clock) begin
    id_instruction <= if_instruction;
    id_inst_PC <= if_inst_PC;

    if_JAL_target <= id_JAL_target;
    if_next_PC_select <= cu_next_PC_select;
    if_JALR_target <= ex_JALR_target;
    if_branch <= ex_branch;
    if_branch_target <= id_branch_target;
end