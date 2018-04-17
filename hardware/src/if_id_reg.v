// Instruction Fetch / Instruction Dispatch Register
module if_id_reg_unit #(parameter CORE = 0, DATA_WIDTH = 32, ADDRESS_BITS=20)(
    clock, reset,

    if_instruction,
    if_inst_PC,
    id_branch,
    id_branch_target,
    id_JAL_target,
    id_JALR_target,
    id_next_PC_select,

    id_instruction,
    id_inst_PC,
    if_branch,
    if_branch_target,
    if_JAL_target,
    if_JALR_target,
    if_next_PC_select
);

input clock, reset;

input [DATA_WIDTH-1:0] if_instruction;
input [ADDRESS_BITS-1:0] if_inst_PC;
input id_branch;
input [ADDRESS_BITS-1:0] id_branch_target;
input [ADDRESS_BITS-1:0] id_JAL_target;
input [ADDRESS_BITS-1:0] id_JALR_target;
input [1:0] id_next_PC_select;

output reg [31:0] id_instruction;
output reg [ADDRESS_BITS-1:0] id_inst_PC;
output reg if_branch;
output reg [ADDRESS_BITS-1:0] if_branch_target;
output reg [ADDRESS_BITS-1:0] if_JAL_target;
output reg [ADDRESS_BITS-1:0] if_JALR_target;
output reg [1:0] if_next_PC_select;

always @(posedge clock) begin
    id_instruction <= if_instruction;
    id_inst_PC <= if_inst_PC;
    if_branch <= id_branch;
    if_branch_target <= id_branch_target;
    if_JAL_target <= id_JAL_target;
    if_JALR_target <= id_JALR_target;
    if_next_PC_select <= id_next_PC_select;
end
endmodule
