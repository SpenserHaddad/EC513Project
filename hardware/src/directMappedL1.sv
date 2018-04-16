module directMappedL1 (
  // --------------------------------------------------------------------------
  // Module Port Arguments
  //
  ///////////////////////
  // Clocks and Resets //
  ///////////////////////
  //
  clock, // (I) Clock
  reset, // (I) Reset, active-high

  /////////////////////////////////
  // Interface to/from Processor //
  /////////////////////////////////
  //
  addrFromProc,   // (I) Address from processor
  enableFromProc, // (I) Enable from processor
  writeFromProc,  // (I) Transaction direction from processor (0:read, 1:write)
  dataFromProc,   // (I) Data from processor
  dataToProc,     // (O) Data to processor
  readyToProc,    // (O) Ready indicator to processor

  //////////////////////////////////////////
  // Interface to/from Lower-Level Memory //
  //////////////////////////////////////////
  //
  addrToLl,    // (O) Address to lower-level memory
  enableToLl,  // (O) Enable to lower-level memory
  writeToLl,   // (O) Transaction direction to lower-level (0:read, 1:write)
  dataToLl,    // (O) Data to lower-level memory
  dataFromLl,  // (I) Data from lower-level memory
  readyFromLl  // (I) Ready indicator from lower-level memory  
  );

  // --------------------------------------------------------------------------
  // Module Parameters / Localparams
  //
  //////////////////
  // Cache Sizing //
  //////////////////
  //
  parameter  BSIZE = 32'd8;            // Number of 32-bit words in a block
  localparam IBITS = $clog2(BSIZE);    // Number of address bits to index into a block

  parameter  NBLKS = 32'd1024;         // Number of blocks
  localparam BBITS = $clog2(NBLKS);    // Number of bits to address a block

  localparam TBITS = 32'd32-(IBITS+BBITS); // Number of tag bits

  //////////////////
  // FSM Encoding //
  //////////////////
  //
  localparam [0:0] RDY    = 1'b1;
  localparam [0:0] NOTRDY = 1'b0;
  
  // --------------------------------------------------------------------------
  // Module IO Declarations
  //
  ///////////////////////
  // Clocks and Resets //
  ///////////////////////
  //
  input             clock;
  input             reset;

  /////////////////////////////////
  // Interface to/from Processor //
  /////////////////////////////////
  //
  input      [31:0] addrFromProc;
  input             enableFromProc;
  input             writeFromProc;
  input      [31:0] dataFromProc;
  output     [31:0] dataToProc;
  output            readyToProc;

  //////////////////////////////////////////
  // Interface to/from Lower-Level Memory //
  //////////////////////////////////////////
  //
  output     [31:0] addrToLl;
  output            enableToLl;
  output            writeToLl;
  output     [31:0] dataToLl;
  input      [31:0] dataFromLl;
  input             readyFromLl;

  // --------------------------------------------------------------------------
  // Internal Signal Declarations
  //
  //////////////
  // Cacheing //
  //////////////
  //
  wire [IBITS-1:0]  bIndex; // Block index
  wire [BBITS-1:0]  bAddr;  // Block address 
  wire [TBITS-1:0]  bTag;   // Block Tag 

  reg [BSIZE-1:0]     [31:0] dataMem [NBLKS-1:0];
  reg                        vldMem  [NBLKS-1:0];
  reg            [TBITS-1:0] tagMem  [NBLKS-1:0];

  reg [BSIZE-1:0]     [31:0] nxtDataMem [NBLKS-1:0];
  reg                        nxtVldMem  [NBLKS-1:0];
  reg            [TBITS-1:0] nxtTagMem  [NBLKS-1:0];

  /////////////////
  // FSM Control //
  /////////////////
  //
  wire miss;
  reg nxt_fsm_state;
  reg fsm_state;
  
  // --------------------------------------------------------------------------
  // Address Breakdown
  //
  assign bIndex = addrFromProc[2+IBITS-1:2];
  assign bAddr  = addrFromProc[2+IBITS+BBITS-1:2+IBITS];
  assign bTag   = addrFromProc[31:32-TBITS];  

  // --------------------------------------------------------------------------
  // Block Validation:
  //   1) Invalidate on reset.
  //   2) Once it's determined that there is an access to L1, that block will
  //      be valid. Assume that the processor will interact with the status
  //      signals provided by this module to hold its address (and data)
  //      constant until a ready is detected.
  //
  always @(posedge clock or posedge reset) begin : vld_seq
    if (reset) begin
      vldMem <= {NBLKS{1'b0}};
    end else begin
      vldMem <= nxtVldMem;
    end
  end
  
  always @* begin : vld_cmb
    nxtVldMem        = vldMem; // default - reatin all values not @ bAddr
    if (enableFromProc) begin
      nxtVldMem[bAddr] = 1'b1;   // validate block @ bAddr
    end
  end

  // --------------------------------------------------------------------------
  // Block Tagging:
  // Once it's determined that there is an access to L1, tag that block.
  // Assume that the processor will interact with the status signals provided
  // by this module to hold its address (and data) constant until a ready is
  // detected.
  //
  always @(posedge clock) begin : tag_seq
    tagMem <= nxtTagMem;
  end
  
  always @* begin : tag_cmb
    nxtTagMem     = tagMem; // default - retain all values not @ bAddr
    if (enableFromProc) begin
      tagMem[bAddr] = bTag;   // update tag @ bAddr
    end
  end

  // --------------------------------------------------------------------------
  // Block Data Management:
  //
  // Once it's determined that there is an access to L1, check if it's a read
  // or a write:
  //  o If it's a write update the value.
  //  o If it's a read check if it's a hit or a miss:
  //     - If it's a hit there is no need to update it.
  //     - If it's a miss, wait until the lower-level memory provides valid data.
  // Assume that the processor will interact with the status signals provided
  // by this module to hold its address (and data) constant until a ready is
  // detected.
  //
  always @(posedge clock or posedge reset) begin : data_seq
    if (reset) begin
      dataMem <= {NBLKS{1'b0}};
    end else begin
      dataMem <= nxtDataMem;
    end
  end
  
  always @* begin : data_cmb
    nxtDataMem = dataMem; // default - retain all values not @ bAddr
    if (enableFromProc) begin
      if (writeFromProc) begin
        dataMem[bAddr][bIndex] = dataFromProc;
      end else begin
        if (miss && enableToLl && readyFromLl) begin
          dataMem[bAddr][bIndex] = dataFromLl;
        end
      end
    end
  end

  // --------------------------------------------------------------------------
  // Processor Interface:
  //
  ///////////////
  // Read Data //
  ///////////////
  //
  // Always generate read data from address. Count on FSM to validate the read
  // data.
  //
  // Assume that the processor will interact with the status signals provided
  // by this module to hold its address (and data) constant until a ready is
  // detected.

  assign dataToProc = dataMem[bAddr][bIndex];

  ///////////
  // Ready //
  ///////////
  //
  assign readyToProc = fsm_state ? ~miss : 1'b0;

  // --------------------------------------------------------------------------
  // Lower-Level Memory Interface:
  //
  assign addrToLl   = addrFromProc;
  assign writeToLl  = writeFromProc;
  assign dataToLl   = dataFromProc;

  assign enableToLl = ~fsm_state;

  // --------------------------------------------------------------------------
  // Control/Status FSM:
  //
  assign miss = ~(tagMem[bAddr] == bTag) & enableFromProc;
  
  always @(posedge clock or posedge reset) begin : fsm_seq
    if (reset) begin
      fsm_state <= RDY;
    end else begin
      fsm_state <= nxt_fsm_state;
    end
  end

  always @* begin : fsm_cmb
    case (fsm_state)
      RDY : begin
        if (miss) begin
          nxt_fsm_state = NOTRDY;
        end else begin
          nxt_fsm_state = RDY;
        end
      end
      NOTRDY : begin
        if (readyFromLl) begin
          nxt_fsm_state = RDY;
        end else begin
          nxt_fsm_state = NOTRDY;
        end
      end
    endcase // case (fsm_state)
  end // block: fsm_cmb
  
    
  
endmodule // directMappedL1
