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

module RISC_V_Core #(parameter CORE = 32'd0, DATA_WIDTH = 32'd32, INDEX_BITS = 32'd6, 
                     OFFSET_BITS = 32'd3, ADDRESS_BITS = 32'd20)(
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

// ----------------------------------------------------------------------------
// IO Declarations
//
input  clock, reset, start; 
input  [ADDRESS_BITS - 1:0]  prog_address; 

// For I/O funstions
input       [1:0] from_peripheral;
input      [31:0] from_peripheral_data; 
input             from_peripheral_valid;
output reg  [1:0] to_peripheral;
output reg [31:0] to_peripheral_data; 
output reg        to_peripheral_valid;

input  report; // performance reporting

// ----------------------------------------------------------------------------
// Internal Signal Declarations
//
//////////////
// IF Stage //
//////////////
//
wire [31:0]              instruction;
wire [ADDRESS_BITS-1: 0] inst_PC;
wire                     predict_taken;
wire [ADDRESS_BITS-1:0]  predicted_address;

reg   [DATA_WIDTH-1:0] ifid_instruction;
reg [ADDRESS_BITS-1:0] ifid_inst_PC;  
reg                    ifid_predict_taken;

//////////////
// ID Stage //
//////////////
//
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
wire [2:0] ALUOp;
wire branch_op;
wire [1:0] next_PC_sel;
wire [1:0] operand_A_sel; 
wire operand_B_sel; 
wire [1:0] extend_sel; 
wire [DATA_WIDTH-1:0]  extend_imm;
    
wire memWrite;
wire regWrite;

wire             [4:0] rs1;
wire             [4:0] rs2;

reg             [31:0] idex_rs1_data; 
reg             [31:0] idex_rs2_data;
reg              [4:0] idex_rd;  
reg              [6:0] idex_funct7; 
reg              [2:0] idex_funct3;
reg             [31:0] idex_extend_imm;
reg                    idex_regWrite;
reg                    idex_memRead;
reg                    idex_memWrite;
reg              [2:0] idex_ALUOp;
reg                    idex_branch_op;
reg [ADDRESS_BITS-1:0] idex_inst_PC;  
reg              [1:0] idex_operand_A_sel; 
reg                    idex_operand_B_sel; 
reg [ADDRESS_BITS-1:0] idex_branch_target; 
reg              [4:0] idex_rs1;
reg              [4:0] idex_rs2;
reg [ADDRESS_BITS-1:0] idex_JAL_target;   
reg              [1:0] idex_next_PC_sel;
reg                    idex_predict_taken;

wire                   stall;

//////////////
// EX Stage //
//////////////
//
reg   [DATA_WIDTH-1:0] fwdd_regRead_1; 
reg   [DATA_WIDTH-1:0] fwdd_regRead_2; 

wire                   branch;
wire  [DATA_WIDTH-1:0] ALU_result; 

reg   [DATA_WIDTH-1:0] exmem_ALU_result;
reg              [4:0] exmem_rd;
reg                    exmem_regWrite;
reg                    exmem_memRead;
reg                    exmem_memWrite;
reg             [31:0] exmem_rs2_data;
reg                    exmem_branch;
reg [ADDRESS_BITS-1:0] exmem_JAL_target;   
reg [ADDRESS_BITS-1:0] exmem_JALR_target;   
reg [ADDRESS_BITS-1:0] exmem_branch_target; 
reg              [1:0] exmem_next_PC_sel;
reg [ADDRESS_BITS-1:0] exmem_inst_PC;  
reg                    exmem_branch_op;
reg                    exmem_ALU_branch;
reg                    exmem_predict_taken;

reg                    flush;
  
///////////////
// MEM Stage //
///////////////
//
wire [DATA_WIDTH-1:0]    memory_data;

reg   [DATA_WIDTH-1:0] memwb_load_data;
reg              [4:0] memwb_rd;
reg                    memwb_regWrite;
reg   [DATA_WIDTH-1:0] memwb_ALU_result;
reg                    memwb_memRead;

// ----------------------------------------------------------------------------
// IF Stage
//
fetch_unit #(CORE, DATA_WIDTH, INDEX_BITS, OFFSET_BITS, ADDRESS_BITS) IF (
        .clock               (clock), 
        .reset               (reset), 
        .start               (start), 
        
        .PC_select           (exmem_next_PC_sel),
        .program_address     (prog_address), 
        .JAL_target          (exmem_JAL_target),
        .JALR_target         (exmem_JALR_target),
        .branch              (exmem_branch), 
        .branch_target       (exmem_branch_target), 
        
        .stall               (stall),
        .flush               (flush),
        .predict_taken       (predict_taken),
        .exmem_predict_taken (exmem_predict_taken),
        .predicted_address   (predicted_address),
        .instruction         (instruction), 
        .inst_PC             (inst_PC),
        .exmem_inst_PC       (exmem_inst_PC),
        .valid               (),
        .ready               (),
        
        .report              (report)
); 
      
always @ (posedge clock) begin : ifid
  if (reset) begin
    ifid_instruction       <= 32'h00000013;
    ifid_inst_PC           <= {ADDRESS_BITS{1'd0}};
    ifid_predict_taken     <= 1'd0;
  end else begin
    if (flush) begin
      ifid_instruction       <= 32'h00000013;
      ifid_inst_PC           <= {ADDRESS_BITS{1'd0}};
      ifid_predict_taken     <= 1'd0;
    end else begin
      if (!stall) begin
        ifid_instruction       <= instruction;
        ifid_inst_PC           <= inst_PC;
        ifid_predict_taken     <= predict_taken;
      end
    end
  end
end

branch_predictor u_BP (
  .clock               (clock),              // (I) 
  .reset               (reset),              // (I)  

  .if_inst_PC          (inst_PC),            // (I)
  .if_instruction      (instruction),        // (I)

  .predict_taken       (predict_taken),      // (O)
  .predicted_address   (predicted_address),  // (O)

  .exmem_inst_PC       (exmem_inst_PC),      // (I)
  .exmem_branch_op     (exmem_branch_op),    // (I)
  .exmem_ALU_branch    (exmem_ALU_branch),   // (I)
  .exmem_next_PC_sel   (exmem_next_PC_sel),  // (I)
  .exmem_JAL_target    (exmem_JAL_target),   // (I)
  .exmem_JALR_target   (exmem_JALR_target),  // (I)
  .exmem_branch_target (exmem_branch_target) // (I)
);



// ----------------------------------------------------------------------------
// ID Stage
//
decode_unit #(CORE, ADDRESS_BITS) ID (
        .clock         (clock), 
        .reset         (reset),  
        
        .instruction   (ifid_instruction), 
        .PC            (ifid_inst_PC),
        .extend_sel    (extend_sel),
        .write         (write), 
        .write_reg     (write_reg), 
        .write_data    (write_data), 
      
        .opcode        (opcode), 
        .funct3        (funct3), 
        .funct7        (funct7),
        .rs1_data      (rs1_data), 
        .rs2_data      (rs2_data), 
        .rd            (rd), 
 
        .extend_imm    (extend_imm),
        .branch_target (branch_target), 
        .JAL_target    (JAL_target),
        
        .report        (report)
); 

control_unit #(CORE) CU (
        .clock         (clock), 
        .reset         (reset),   
        
        .opcode        (opcode),
        .branch_op     (branch_op), 
        .memRead       (memRead), 
        .memtoReg      (), 
        .ALUOp         (ALUOp), 
        .memWrite      (memWrite), 
        .next_PC_sel   (next_PC_sel), 
        .operand_A_sel (operand_A_sel), 
        .operand_B_sel (operand_B_sel),
        .extend_sel    (extend_sel),        
        .regWrite      (regWrite), 
        
        .report        (report)
);

//////////////////////
// Hazard Detection //
//////////////////////
//
// Stall:
assign rs1 = ifid_instruction[19:15];
assign rs2 = ifid_instruction[24:20];

assign stall = (((rs1 == idex_rd) & idex_memRead & (idex_rd != 5'd0)) |
                ((rs2 == idex_rd) & idex_memRead & (idex_rd != 5'd0))) & ~flush;

always @ (posedge clock) begin : idex
  if (reset) begin
    idex_rs1_data      <= 32'd0; 
    idex_rs2_data      <= 32'd0;
    idex_rd            <= 5'd0;  
    idex_funct7        <= 7'd0; 
    idex_funct3        <= 3'd0;
    idex_extend_imm    <= 32'd0;
    idex_memRead       <= 1'd0;
    idex_memWrite      <= 1'd0;
    idex_ALUOp         <= 3'd1;
    idex_branch_op     <= 1'd0;
    idex_inst_PC       <= {ADDRESS_BITS{1'd0}};
    idex_operand_A_sel <= 2'd0; 
    idex_operand_B_sel <= 1'd1;
    idex_branch_target <= {ADDRESS_BITS{1'd0}};
    idex_regWrite      <= 1'd1;
    idex_rs1           <= 5'd0;
    idex_rs2           <= 5'd0;
    idex_JAL_target    <= {ADDRESS_BITS{1'd0}};
    idex_next_PC_sel   <= 2'd0;
    idex_predict_taken     <= 1'd0;
  end else begin
    if (flush || stall ) begin
      idex_rs1_data      <= 32'd0; 
      idex_rs2_data      <= 32'd0;
      idex_rd            <= 5'd0;  
      idex_funct7        <= 7'd0; 
      idex_funct3        <= 3'd0;
      idex_extend_imm    <= 32'd0;
      idex_memRead       <= 1'd0;
      idex_memWrite      <= 1'd0;
      idex_ALUOp         <= 3'd1;
      idex_branch_op     <= 1'd0;
      idex_inst_PC       <= {ADDRESS_BITS{1'd0}};
      idex_operand_A_sel <= 2'd0; 
      idex_operand_B_sel <= 1'd1;
      idex_branch_target <= {ADDRESS_BITS{1'd0}};
      idex_regWrite      <= 1'd1;
      idex_rs1           <= 5'd0;
      idex_rs2           <= 5'd0;
      idex_JAL_target    <= {ADDRESS_BITS{1'd0}};
      idex_next_PC_sel   <= 2'd0;
      idex_predict_taken     <= 1'd0;
   end else begin
      idex_rs1_data      <= rs1_data; 
      idex_rs2_data      <= rs2_data;
      idex_rd            <= rd;  
      idex_funct7        <= funct7; 
      idex_funct3        <= funct3;
      idex_extend_imm    <= extend_imm;
      idex_memRead       <= memRead;
      idex_memWrite      <= memWrite;
      idex_ALUOp         <= ALUOp;
      idex_branch_op     <= branch_op;
      idex_inst_PC       <= ifid_inst_PC;
      idex_operand_A_sel <= operand_A_sel; 
      idex_operand_B_sel <= operand_B_sel;
      idex_branch_target <= branch_target;
      idex_regWrite      <= regWrite;
      idex_rs1           <= rs1;
      idex_rs2           <= rs2;
      idex_JAL_target    <= JAL_target;
      idex_next_PC_sel   <= next_PC_sel;
      idex_predict_taken     <= ifid_predict_taken;
    end
  end
end

// ----------------------------------------------------------------------------
// EX Stage
//
execution_unit #(CORE, DATA_WIDTH, ADDRESS_BITS) EU (
        .clock         (clock), 
        .reset         (reset), 
        
        .ALU_Operation (idex_ALUOp), 
        .funct3        (idex_funct3), 
        .funct7        (idex_funct7),
        .branch_op     (idex_branch_op),
        .PC            (idex_inst_PC), 
        .ALU_ASrc      (idex_operand_A_sel),
        .ALU_BSrc      (idex_operand_B_sel),
        .regRead_1     (fwdd_regRead_1), 
        .regRead_2     (fwdd_regRead_2), 
        .extend        (idex_extend_imm), 
        .ALU_result    (ALU_result), 
        .zero          (), 
        .branch        (branch),
        .ALU_branch    (ALU_branch),
        .JALR_target   (JALR_target),
        
        .report        (report)
);

always @ (posedge clock) begin : exmem
  if (reset) begin
    exmem_ALU_result    <= {DATA_WIDTH{1'd0}};
    exmem_rd            <= 5'd0;
    exmem_regWrite      <= 1'd1;
    exmem_memRead       <= 1'd0;
    exmem_memWrite      <= 1'd0;
    exmem_rs2_data      <= 32'd0;
    exmem_branch        <= 1'd0;
    exmem_JAL_target    <= {ADDRESS_BITS{1'd0}};
    exmem_JALR_target   <= {ADDRESS_BITS{1'd0}};
    exmem_branch_target <= {ADDRESS_BITS{1'd0}}; 
    exmem_next_PC_sel   <= 2'd0;
    exmem_inst_PC       <= {ADDRESS_BITS{1'd0}};
    exmem_branch_op     <= 1'd0;
    exmem_ALU_branch    <= 1'd0;
    exmem_predict_taken     <= 1'd0;
  end else begin // if (reset)
   if (flush) begin
      exmem_ALU_result    <= {DATA_WIDTH{1'd0}};
      exmem_rd            <= 5'd0;
      exmem_regWrite      <= 1'd1;
      exmem_memRead       <= 1'd0;
      exmem_memWrite      <= 1'd0;
      exmem_rs2_data      <= 32'd0;
      exmem_branch        <= 1'd0;
      exmem_JAL_target    <= {ADDRESS_BITS{1'd0}};
      exmem_JALR_target   <= {ADDRESS_BITS{1'd0}};
      exmem_branch_target <= {ADDRESS_BITS{1'd0}}; 
      exmem_next_PC_sel   <= 2'd0;
      exmem_inst_PC       <= {ADDRESS_BITS{1'd0}};
      exmem_branch_op     <= 1'd0;
      exmem_ALU_branch    <= 1'd0;
      exmem_predict_taken     <= 1'd0;
   end else begin
      exmem_ALU_result    <= ALU_result;
      exmem_rd            <= idex_rd;
      exmem_regWrite      <= idex_regWrite;
      exmem_memRead       <= idex_memRead;
      exmem_memWrite      <= idex_memWrite;
      exmem_rs2_data      <= fwdd_regRead_2;
      exmem_branch        <= branch;
      exmem_next_PC_sel   <= idex_next_PC_sel;
      exmem_JAL_target    <= idex_JAL_target;
      exmem_JALR_target   <= JALR_target;
      exmem_branch_target <= idex_branch_target; 
      exmem_inst_PC       <= idex_inst_PC;
      exmem_branch_op     <= idex_branch_op;
      exmem_ALU_branch    <= ALU_branch;
      exmem_predict_taken     <= idex_predict_taken;
    end // else: !if(flush)
  end
end

always @* begin
  if (exmem_next_PC_sel[1]) begin
    if (exmem_next_PC_sel[0]) begin
      // JALR
      flush = 1'b1;
    end else begin
      // JAL
      if (exmem_predict_taken) begin
        flush = 1'b0;
      end else begin
        flush = 1'b1;
      end
    end // else: !if(exmem_next_PC_sel[0])
  end else begin
    if (exmem_next_PC_sel == 2'd1) begin
      flush = exmem_branch ^ exmem_predict_taken;
    end else begin
      flush = 1'b0;
    end
  end
end
  
/////////////////////
// Forwarding Unit //
/////////////////////
//
always @* begin : fwdA
  if (exmem_regWrite && (exmem_rd == idex_rs1) && (exmem_rd != 5'd0)) begin
    fwdd_regRead_1 = exmem_ALU_result;
  end else begin
    if (memwb_regWrite && (memwb_rd != 5'd0) && 
        (memwb_rd == idex_rs1)) begin
      fwdd_regRead_1 = write_data;
    end else begin
      fwdd_regRead_1 = idex_rs1_data;
    end
  end
end


always @* begin : fwdB
  if (exmem_regWrite && (exmem_rd == idex_rs2) && (exmem_rd != 5'd0)) begin
    fwdd_regRead_2 = exmem_ALU_result;
  end else begin
    if (memwb_regWrite && (memwb_rd != 5'd0) && 
        (memwb_rd == idex_rs2)) begin
      fwdd_regRead_2 = write_data;
    end else begin
      fwdd_regRead_2 = idex_rs2_data;
    end
  end
end

// ----------------------------------------------------------------------------
// MEM Stage
//
memory_unit #(CORE, DATA_WIDTH, INDEX_BITS, OFFSET_BITS, ADDRESS_BITS) MU (
        .clock      (clock), 
        .reset      (reset), 
        
        .load       (exmem_memRead), 
        .store      (exmem_memWrite),
        .address    (exmem_ALU_result[ADDRESS_BITS-1:0]), 
        .store_data (exmem_rs2_data),
        .data_addr  (), 
        .load_data  (memory_data),
        .valid      (),
        .ready      (),
        
        .report     (report)
); 

always @ (posedge clock) begin : memwb
  if (reset) begin
    memwb_load_data   <= {DATA_WIDTH{1'd0}};
    memwb_rd          <= 5'd0;
    memwb_regWrite    <= 1'd1;
    memwb_memRead     <= 1'd0;
    memwb_ALU_result  <= {DATA_WIDTH{1'd0}};
  end else begin
    memwb_load_data   <= memory_data;
    memwb_rd          <= exmem_rd;
    memwb_regWrite    <= exmem_regWrite;
    memwb_memRead     <= exmem_memRead;
    memwb_ALU_result  <= exmem_ALU_result;   
  end
end

// ----------------------------------------------------------------------------
// WB Stage
//
writeback_unit #(CORE, DATA_WIDTH) WB (
        .clock       (clock), 
        .reset       (reset),   
        
        .opWrite     (memwb_regWrite),
        .opSel       (memwb_memRead),
        .opReg       (memwb_rd), 
        .ALU_Result  (memwb_ALU_result), 
        .memory_data (memwb_load_data), 
        .write       (write), 
        .write_reg   (write_reg), 
        .write_data  (write_data), 
        
        .report(report)
); 

// Registers s1-s11 [$9,$x18-$x27] are saved across calls ... Using s1-s9 [$9,x18-x25] for final results
always @ (posedge clock) begin : results        
         if (write && (((write_reg >= 5'd18) && (write_reg <= 5'd25))|| (write_reg == 5'd9)))  begin
              to_peripheral       <= 2'd0;
              to_peripheral_data  <= write_data; 
              to_peripheral_valid <= 1'd1;
              $display (" Core [%d] Register [%d] Value = %d", CORE, write_reg, write_data);
         end else begin
           to_peripheral_valid <= 1'd0;
         end
end
    
endmodule
