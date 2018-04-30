module branch_predictor (
  // --------------------------------------------------------------------------
  // Module Port Arguments
  //
  clock, 
  reset,  

  if_inst_PC,  
  if_instruction,

  predict_taken,
  predicted_address,

  exmem_inst_PC,
  exmem_branch_op,
  exmem_ALU_branch,
  exmem_next_PC_sel,
  exmem_JAL_target,
  exmem_JALR_target,
  exmem_branch_target
);
  // --------------------------------------------------------------------------
  // Parameter / Local Parameters
  //
  parameter ADDRESS_BITS = 32'd20;
  parameter DATA_WIDTH   = 32'd20;
  

  localparam MEM_DEPTH = 32'd1 << ADDRESS_BITS;

  localparam [6:0] BRANCH = 7'b1100011;
  localparam [6:0] JALR   = 7'b1100111;
  localparam [6:0] JAL    = 7'b1101111;

  // --------------------------------------------------------------------------
  // Module IO Declarations
  //
  input                         clock; 
  input                         reset;  

  input      [ADDRESS_BITS-1:0] if_inst_PC;  
  input        [DATA_WIDTH-1:0] if_instruction;

  output reg                    predict_taken;
  output reg [ADDRESS_BITS-1:0] predicted_address;

  input      [ADDRESS_BITS-1:0] exmem_inst_PC;  
  input                         exmem_branch_op;
  input                         exmem_ALU_branch;
  input                   [1:0] exmem_next_PC_sel;
  input      [ADDRESS_BITS-1:0] exmem_JAL_target;
  input      [ADDRESS_BITS-1:0] exmem_JALR_target;
  input      [ADDRESS_BITS-1:0] exmem_branch_target; 

  // --------------------------------------------------------------------------
  // Internal Signal Declarations
  //
  reg  [DATA_WIDTH-1:0] targets     [0:MEM_DEPTH-1];
  reg  [0:MEM_DEPTH-1]  nxt_valid;
  reg  [0:MEM_DEPTH-1]  valid;
  
  wire if_jal;
  wire if_branch;

  wire tbsc_take_branch;

  wire [ADDRESS_BITS-1:0] exmem_dest; 

  // --------------------------------------------------------------------------
  // Jump / Branch Detection
  //
  assign if_jal = (if_instruction[6:0] == JAL);

  assign if_branch = (if_instruction[6:0] == BRANCH);

  // --------------------------------------------------------------------------
  // 2-Bit Saturation Counter
  //
  two_bit_sat_cntr u_tbsc (
    .clock       (clock),            // (I)
    .reset       (reset),            // (I)
    .branch_op   (exmem_branch_op),  // (I)
    .ALU_branch  (exmem_ALU_branch), // (I)
    .take_branch (tbsc_take_branch)  // (O)
  );

  // --------------------------------------------------------------------------
  // Branch Target Buffering
  //
  always @ (posedge clock) begin : btb_seq
    if (exmem_next_PC_sel == 2'b01 && exmem_ALU_branch || exmem_next_PC_sel == 2'b10) begin
      targets[exmem_inst_PC] = exmem_dest;
    end
  end
  
  assign exmem_dest = (exmem_next_PC_sel == 2'b10) ? exmem_JAL_target :
                      (exmem_next_PC_sel == 2'b11) ? exmem_JALR_target :
                      (exmem_next_PC_sel == 2'b01 && exmem_ALU_branch) ? exmem_branch_target :
                      {ADDRESS_BITS{1'b0}};

  // --------------------------------------------------------------------------
  // Branch Target Validation
  //
  always @ (posedge clock) begin : btv_seq
    if (reset) begin
      valid <= 'd0;
    end else begin
      valid <= nxt_valid;
    end
  end

  always @* begin : btv_cmb
    nxt_valid = valid; // default

    if (exmem_next_PC_sel == 2'b01 && exmem_ALU_branch || exmem_next_PC_sel == 2'b10) begin
      nxt_valid[exmem_inst_PC] = 1'b1;
    end
  end
  
  // --------------------------------------------------------------------------
  // Prediction Decision
  //
  always @* begin : final_prediction_stage
    if (valid[if_inst_PC]) begin
      if (if_branch) begin
        predict_taken     = tbsc_take_branch;
        predicted_address = targets[if_inst_PC];
      end else begin
        if (if_jal) begin
          predict_taken     = 1'b1;
          predicted_address = targets[if_inst_PC];
        end else begin
          predicted_address = if_inst_PC+4;
          predict_taken     = 1'b0;
        end
      end // else: !if(if_branch)    
    end else begin
      predict_taken     = 1'b0;
      predicted_address = if_inst_PC+4;
    end
  end // block: final_prediction_stage
endmodule // branch_predictor
