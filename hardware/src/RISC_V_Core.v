/** @module : RISC_V_Core
 *  @author : Adaptive & Secure Computing Systems (ASCS) Laboratory

 *  Copyright (c) 2018 BRISC-V (ASCS/ECE/BU)
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.

 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 *
 */

module RISC_V_Core #(parameter CORE = 0, DATA_WIDTH = 32, INDEX_BITS = 6,
                     OFFSET_BITS = 3, ADDRESS_BITS = 20)(
    clock,
    reset,
    start,
    prog_address,

    from_peripheral,
    from_peripheral_data,
    from_peripheral_valid,
    to_peripheral,
    to_peripheral_data,
    to_peripheral_valid,

    report
);

input  clock, reset, start;
input  [ADDRESS_BITS - 1:0]  prog_address;

// For I/O funstions
input  [1:0]   from_peripheral;
input  [31:0]  from_peripheral_data;
input          from_peripheral_valid;
output [1:0]   to_peripheral;
output [31:0]  to_peripheral_data;
output         to_peripheral_valid;

input  report; // performance reporting

wire [31:0]  instruction;
wire [ADDRESS_BITS-1: 0] inst_PC;
wire i_valid, i_ready;
wire d_valid, d_ready;

wire [ADDRESS_BITS-1: 0] JAL_target;
wire [ADDRESS_BITS-1: 0] JALR_target;
wire [ADDRESS_BITS-1: 0] branch_target;

wire  write;
wire  [4:0]  write_reg;
wire  [DATA_WIDTH-1:0] write_data;

wire [DATA_WIDTH-1:0]  rs1_data;
wire [DATA_WIDTH-1:0]  rs2_data;
wire [4:0]   rd;

wire [6:0]  opcode;
wire [6:0]  funct7;
wire [2:0]  funct3;

wire memRead;
wire memtoReg;
wire [2:0] ALUOp;
wire branch_op;
wire [1:0] next_PC_sel;
wire [1:0] operand_A_sel;
wire operand_B_sel;
wire [1:0] extend_sel;
wire [DATA_WIDTH-1:0]  extend_imm;

wire memWrite;
wire regWrite;

wire branch;
wire [DATA_WIDTH-1:0]   ALU_result;
wire [ADDRESS_BITS-1:0] generated_addr = ALU_result; // the case the address is not 32-bit

wire ALU_branch;
wire zero; // Have not done anything with this signal

wire [DATA_WIDTH-1:0]    memory_data;
wire [ADDRESS_BITS-1: 0] memory_addr; // To use to check the address coming out the memory stage

reg  [1:0]   to_peripheral;
reg  [31:0]  to_peripheral_data;
reg          to_peripheral_valid;

// Pipeline wires
wire [31:0] if_instruction;
wire [ADDRESS_BITS-1:0] if_inst_PC;
wire if_branch;
wire [ADDRESS_BITS-1:0] if_branch_target;
wire [ADDRESS_BITS-1:0] if_JAL_target;
wire [ADDRESS_BITS-1:0] if_JALR_target;
wire [1:0] if_next_PC_select;

wire [31:0] id_instuction;
wire [ADDRESS_BITS-1:0] id_inst_PC;
wire id_branch;
wire [ADDRESS_BITS-1:0] id_branch_target;
wire [ADDRESS_BITS-1:0] id_JAL_target;
wire [ADDRESS_BITS-1:0] id_JALR_target;
wire [1:0] id_next_PC_select;
wire [1:0] id_extend_sel;
wire [6:0] id_opcode;
wire [2:0] id_funct3;
wire [6:0] id_funct7;
wire [31:0] id_rs1_data;
wire [31:0] id_rs2_data;
wire [4:0] id_rd;
wire [31:0] id_extend_imm;
wire id_write;
wire [4:0] id_write_reg;
wire [31:0] id_write_data;

wire [1:0] cu_extend_sel;
wire [1:0] cu_next_PC_select;
wire ex_write;
wire [4:0] ex_write_reg;
wire [DATA_WIDTH-1:0] ex_write_data;
wire [6:0] ex_opcode;
wire [2:0] ex_funct3;
wire [6:0] ex_funct7;
wire [31:0] ex_rs1_data;
wire [31:0] ex_rs2_data;
wire [4:0] ex_rd;
wire ex_branch;
wire [ADDRESS_BITS-1:0] ex_branch_target;
wire [31:0] ex_extend_imm;
wire [ADDRESS_BITS-1:0] ex_JAL_target;
wire ex_memRead;
wire ex_memWrite;
wire ex_regWrite;
wire [DATA_WIDTH-1:0] ex_ALU_result;

wire mem_write;
wire [4:0] mem_write_reg;
wire [DATA_WIDTH-1:0] mem_write_data;
wire mem_load;
wire mem_store;
wire mem_regWrite;
wire [DATA_WIDTH-1:0] mem_ALU_result;
wire [DATA_WIDTH-1:0] mem_rs2_data;
wire [4:0] mem_rd;
wire mem_memRead;
wire [DATA_WIDTH-1:0] mem_memory_data;

wire wb_write;
wire [4:0] wb_write_reg;
wire [DATA_WIDTH-1:0] wb_write_data;
wire wb_regWrite;
wire wb_memRead;
wire [4:0] wb_rd;
wire [DATA_WIDTH-1:0] wb_memory_data;
wire [DATA_WIDTH-1:0] wb_ALU_result;


fetch_unit #(CORE, DATA_WIDTH, INDEX_BITS, OFFSET_BITS, ADDRESS_BITS) IF (
        .clock(clock),
        .reset(reset),
        .start(start),

        .PC_select(if_next_PC_select),
        .program_address(prog_address),
        .JAL_target(if_JAL_target),
        .JALR_target(if_JALR_target),
        .branch(if_branch),
        .branch_target(if_branch_target),

        .instruction(if_instruction),
        .inst_PC(if_inst_PC),
        .valid(i_valid),
        .ready(i_ready),

        .report(report)
);

if_id_reg_unit #(CORE, DATA_WIDTH, ADDRESS_BITS) IF_ID_REG (
        .clock(clock),
        .reset(reset),

        .if_instruction(if_instruction),
        .if_inst_PC(if_inst_PC),
        .id_branch(id_branch),
        .id_branch_target(id_branch_target),
        .id_JAL_target(id_JAL_target),
        .id_JALR_target(id_JALR_target),
        .id_next_PC_select(id_next_PC_select),

        .id_instruction(id_instruction),
        .id_inst_PC(id_inst_PC),
        .if_branch(if_branch),
        .if_branch_target(if_branch_target),
        .if_JAL_target(if_JAL_target),
        .if_JALR_target(if_JALR_target),
        .if_next_PC_select(if_next_PC_select)
);

decode_unit #(CORE, ADDRESS_BITS) ID (
        .clock(clock),
        .reset(reset),

        .instruction(id_instruction),
        .PC(id_inst_PC),
        .extend_sel(id_extend_sel),
        .write(id_write),
        .write_reg(id_write_reg),
        .write_data(id_write_data),

        .opcode(id_opcode),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .rs1_data(id_rs1_data),
        .rs2_data(id_rs2_data),
        .rd(id_rd),
        .extend_imm(id_extend_imm),
        .branch_target(id_branch_target),
        .JAL_target(id_JAL_target),

        .report(report)
);

id_ex_reg_unit #(CORE, DATA_WIDTH, ADDRESS_BITS) ID_EU_REG (
        .clock(clock),
        .reset(reset),

        .id_opcode(id_opcode),
        .id_funct3(id_funct3),
        .id_funct7(id_funct7),
        .id_rs1_data(id_rs1_data),
        .id_rs2_data(id_rs2_data),
        .id_rd(id_rd),
        .id_branch(id_branch),
        .id_branch_target(id_branch_target),
        .id_inst_PC(id_inst_PC),
        .id_extend_imm(id_extend_imm),
        .cu_extend_sel(cu_extend_sel),
        .cu_next_PC_select(cu_next_PC_select),
        .ex_write(ex_write),
        .ex_write_reg(ex_write_reg),
        .ex_write_data(ex_write_data),

        .ex_opcode(ex_opcode),
        .ex_funct3(ex_funct3),
        .ex_funct7(ex_funct7),
        .ex_rs1_data(ex_rs1_data),
        .ex_rs2_data(ex_rs2_data),
        .ex_rd(ex_rd),
        .ex_branch(ex_branch),
        .ex_branch_target(ex_branch_target),
        .ex_inst_PC(ex_inst_PC),
        .ex_extend_imm(ex_extend_imm),
        .id_extend_sel(id_extend_sel),
        .id_next_PC_select(id_next_PC_select),
        .id_write(id_write),
        .id_write_reg(id_write_reg),
        .id_write_data(id_write_data)
);

control_unit #(CORE) CU (
        .clock(clock),
        .reset(reset),
        .opcode(ex_opcode),

        .branch_op(branch_op),
        .memRead(cu_memRead),
        .ALUOp(ALUOp),
        .memWrite(cu_memWrite),
        .next_PC_sel(cu_next_PC_select),
        .operand_A_sel(operand_A_sel),
        .operand_B_sel(operand_B_sel),
        .extend_sel(cu_extend_sel),
        .regWrite(cu_regWrite),

        .report(report)
);

execution_unit #(CORE, DATA_WIDTH, ADDRESS_BITS) EU (
        .clock(clock),
        .reset(reset),

        .ALU_Operation(ALUOp),
        .funct3(ex_funct3),
        .funct7(ex_funct7),
        .branch_op(branch_op),
        .PC(ex_inst_PC),
        .ALU_ASrc(operand_A_sel),
        .ALU_BSrc(operand_B_sel),
        .regRead_1(ex_rs1_data),
        .regRead_2(ex_rs2_data),
        .extend(ex_extend_imm),

        .ALU_result(ex_ALU_result),
        .zero(zero),
        .branch(ex_branch),
        .JALR_target(ex_JALR_target),

        .report(report)
);

ex_mem_reg_unit #(CORE, DATA_WIDTH, ADDRESS_BITS) EX_MEM_REG (
        .clock(clock),
        .reset(reset),

        .ex_memRead(cu_memRead),
        .ex_regWrite(cu_regWrite),
        .ex_ALU_result(ex_ALU_result),
        .ex_rs2_data(ex_rs2_data),
        .ex_rd(ex_rd),
        .mem_write(mem_write),
        .mem_write_reg(mem_write_reg),
        .mem_write_data(mem_write_data),

        .mem_load(mem_load),
        .mem_store(mem_store),
        .mem_ALU_result(mem_ALU_result),
        .mem_store_data(mem_rs2_data),
        .mem_rd(mem_rd),
        .ex_write(ex_write),
        .ex_write_reg(ex_write_reg),
        .ex_write_data(ex_write_data)
);

memory_unit #(CORE, DATA_WIDTH, INDEX_BITS, OFFSET_BITS, ADDRESS_BITS) MU (
        .clock(clock),
        .reset(reset),

        .load(mem_load),
        .store(mem_store),
        .address(generated_addr),
        .store_data(mem_rs2_data),

        .data_addr(mem_memory_addr),
        .load_data(mem_memory_data),
        .valid(d_valid),
        .ready(d_ready),

        .report(report)
);

mem_wb_reg_unit #(CORE, DATA_WIDTH, ADDRESS_BITS) MEM_WB_REG (
        .mem_regWrite(mem_regWrite),
        .mem_memRead(mem_memRead),
        .mem_rd(mem_rd),
        .mem_memory_data(mem_memory_data),
        .mem_ALU_result(mem_ALU_result),
        .wb_write(wb_write),
        .wb_write_reg(wb_write_reg),
        .wb_write_data(wb_write_data),

        .wb_regWrite(wb_regWrite),
        .wb_memRead(wb_memRead),
        .wb_rd(wb_rd),
        .wb_memory_data(wb_memory_data),
        .wb_ALU_result(wb_ALU_result),
        .mem_write(mem_write),
        .mem_write_reg(mem_write_reg),
        .mem_write_data(mem_write_data)
);

writeback_unit #(CORE, DATA_WIDTH) WB (
        .clock(clock),
        .reset(reset),

        .opWrite(wb_regWrite),
        .opSel(wb_memRead),
        .opReg(wb_rd),
        .ALU_Result(wb_ALU_result),
        .memory_data(wb_memory_data),

        .write(wb_write),
        .write_reg(wb_write_reg),
        .write_data(wb_write_data),

        .report(report)
);

//Registers s1-s11 [$9,$x18-$x27] are saved across calls ... Using s1-s9 [$9,x18-x25] for final results
always @ (posedge clock) begin
         if (write && (((write_reg >= 18) && (write_reg <= 25))|| (write_reg == 9)))  begin
              to_peripheral       <= 0;
              to_peripheral_data  <= write_data;
              to_peripheral_valid <= 1;
              $display (" Core [%d] Register [%d] Value = %d", CORE, write_reg, write_data);
         end
         else to_peripheral_valid <= 0;
end

endmodule
