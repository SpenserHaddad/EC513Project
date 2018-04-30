module dpDirectMappedL2 (
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
  // Interface to/from L1 Port 0 //
  /////////////////////////////////
  //
  addrFromL1P0,   // (I) Address from L1 port 0
  enableFromL1P0, // (I) Enable from L1 port 0
  writeFromL1P0,  // (I) Transaction direction from L1 port 0 (0:read, 1:write)
  dataFromL1P0,   // (I) Data from L1 port 0
  dataToL1P0,     // (O) Data to L1 port 0
  readyToL1P0,    // (O) Ready indicator to L1 port 0

  /////////////////////////////////
  // Interface to/from L1 Port 1 //
  /////////////////////////////////
  //
  addrFromL1P1,   // (I) Address from L1 port 1
  enableFromL1P1, // (I) Enable from L1 port 1
  writeFromL1P1,  // (I) Transaction direction from L1 port 1 (0:read, 1:write)
  dataFromL1P1,   // (I) Data from L1 port 1
  dataToL1P1,     // (O) Data to L1 port 1
  readyToL1P1,    // (O) Ready indicator to L1 port 1

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
  // Interface to/from L1 Port 0 //
  /////////////////////////////////
  //
  input      [31:0] addrFromL1P0;
  input             enableFromL1P0;
  input             writeFromL1P0;
  input      [31:0] dataFromL1P0;
  output     [31:0] dataToL1P0;
  output            readyToL1P0;

  /////////////////////////////////
  // Interface to/from L1 Port 1 //
  /////////////////////////////////
  //
  input      [31:0] addrFromL1P1;
  input             enableFromL1P1;
  input             writeFromL1P1;
  input      [31:0] dataFromL1P1;
  output     [31:0] dataToL1P1;
  output            readyToL1P1;

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
  wire [IBITS-1:0]  bIndexP0; // Block index
  wire [BBITS-1:0]  bAddrP0;  // Block address 
  wire [TBITS-1:0]  bTagP0;   // Block Tag 

  wire [IBITS-1:0]  bIndexP1; // Block index
  wire [BBITS-1:0]  bAddrP1;  // Block address 
  wire [TBITS-1:0]  bTagP1;   // Block Tag 

  reg [BSIZE-1:0]     [31:0] dataMem [NBLKS-1:0];
  reg                        vldMem  [NBLKS-1:0];
  reg            [TBITS-1:0] tagMem  [NBLKS-1:0];

  reg [BSIZE-1:0]     [31:0] nxtDataMem [NBLKS-1:0];
  reg                        nxtVldMem  [NBLKS-1:0];
  reg            [TBITS-1:0] nxtTagMem  [NBLKS-1:0];  

  wire addrEq;

  wire llDriverP;

  // --------------------------------------------------------------------------
  // Address Processing
  //
  assign bIndexP0 = addrFromL1P0[2+IBITS-1:2];
  assign bAddrP0  = addrFromL1P0[2+IBITS+BBITS-1:2+IBITS];
  assign bTagP0   = addrFromL1P0[31:32-TBITS];  

  assign bIndexP1 = addrFromL1P1[2+IBITS-1:2];
  assign bAddrP1  = addrFromL1P1[2+IBITS+BBITS-1:2+IBITS];
  assign bTagP1   = addrFromL1P1[31:32-TBITS];  

  assign addrEq = (addrFromL1P0 == addrFromL1P1);

  // --------------------------------------------------------------------------
  // Block Validation:
  //   1) Invalidate on reset.
  //   2) Once it's determined that there is an access to L2, that block will
  //      be valid. Assume that the L1 will interact with the status
  //      signals provided by this module to hold its address (and data)
  //      constant until a ready is detected.
  //   3) If there's address contention, let P0 win because we are assuming that
  //      P1 will be held off until there is no address contention
  //
  always @(posedge clock or posedge reset) begin : vld_seq
    if (reset) begin
      vldMem <= {NBLKS{1'b0}};
    end else begin
      vldMem <= nxtVldMem;
    end
  end
  
  always @* begin : vld_cmb
    nxtVldMem = vldMem; // default - retain all values not @ bAddrP0 or bAddrP1

    case ({enableFromL1P0, enableFromL1P1, addrEq})
      3'b000, 3'b001 : begin
        // No access to L2, update nothing
        nxtVldMem[bAddrP0] = vldMem[bAddrP0];
        nxtVldMem[bAddrP1] = vldMem[bAddrP1];
      end
      3'b100, 3'b101, 3'b111 : begin
        // Allow P0 to win access if it is accessing L2 regardless of
        // whether contention exists or not.
        nxtVldMem[bAddrP0] = 1'b1;
      end
      3'b010, 3'b011 : begin
        // Only allow P1 to access L2 if there is no address contention
        nxtVldMem[bAddrP1] = 1'b1;
      end
      3'b110 : begin
        // Allow both P0 and P1 to access L2 if there is no address contention
        nxtVldMem[bAddrP0] = 1'b1;
        nxtVldMem[bAddrP1] = 1'b1;
      end
    endcase // case ({enableFromL1P0, enableFromL1P1, addrEq})
  end // block: vld_cmb
       
  // --------------------------------------------------------------------------
  // Block Validation:
  //   1) Once it's determined that there is an access to L2, that block will
  //      be valid. Assume that the L1 will interact with the status
  //      signals provided by this module to hold its address (and data)
  //      constant until a ready is detected.
  //   2) If there's address contention, let P0 win because we are assuming that
  //      P1 will be held off until there is no address contention
  //
  always @(posedge clock) begin : tag_seq
    tagMem <= nxtTagMem;
  end
  
  always @* begin : tag_cmb
    nxtTagMem = tagMem; // default - retain all values not @ bAddrP0 or bAddrP1

    case ({enableFromL1P0, enableFromL1P1, addrEq})
      3'b000, 3'b001 : begin
        // No access to L2, update nothing
        nxtTagMem[bAddrP0] = tagMem[bAddrP0];
        nxtTagMem[bAddrP1] = tagMem[bAddrP1];
      end
      3'b100, 3'b101, 3'b111 : begin
        // Allow P0 to win access if it is accessing L2 regardless of
        // whether contention exists or not.
        nxtTagMem[bAddrP0] = bTagP0;
      end
      3'b010, 3'b011 : begin
        // Only allow P1 to access L2 if there is no address contention
        nxtTagMem[bAddrP1] = bTagP1;
      end
      3'b110 : begin
        // Allow both P0 and P1 to access L2 if there is no address contention
        nxtTagMem[bAddrP0] = bTagP0;
        nxtTagMem[bAddrP1] = bTagP1;
      end
    endcase // case ({enableFromL1P0, enableFromL1P1, addrEq})
  end // block: tag_cmb
       
  // --------------------------------------------------------------------------
  // Block Data Management:
  //
  // 1) Once it's determined that there is an access to L1, check if it's a
  //    read or a write:
  //      o If it's a write update the value.
  //      o If it's a read check if it's a hit or a miss:
  //         - If it's a hit there is no need to update it.
  //         - If it's a miss, wait until the lower-level memory provides valid
  //           data.
  // 2) Assume that the processor will interact with the status signals
  //    provided by this module to hold its address (and data) constant until a
  //    ready is detected.
  // 3) If there's address contention, let P0 win because we are assuming that
  //    P1 will be held off until there is no address contention
  // 4) There is only one lower-level memory access port. If both P0 and P1
  //    write or cause a read miss, service P0. P1 should be serviced later if
  //    the assumption in 2 holds
  //
  always @(posedge clock) begin : data_seq
    dataMem <= nxtDataMem;
  end
  
  always @* begin : data_cmb
    nxtDataMem = dataMem; // default - retain all values not @ bAddrP0 or bAddrP1

    case ({enableFromL1P0, enableFromL1P1, addrEq})
      3'b000, 3'b001 : begin
        // No access to L2, update nothing
        nxtDataMem[bAddrP0] = dataMem[bAddrP0];
        nxtDataMem[bAddrP1] = dataMem[bAddrP1];
      end
      3'b100, 3'b101, 3'b111 : begin
        // Allow P0 to win access if it is accessing L2 regardless of
        // whether contention exists or not.
        if (writeFromL1P0) begin
          nxtDataMem[bAddrP0] = dataFromL1P0;
        end else begin
          if (missP0 && enableToLl && readyFromLl) begin
            nxtDataMem[bAddrP0] = dataFromLl;
          end
        end  
      end
      3'b010, 3'b011 : begin
        // Only allow P1 to access L2 if there is no address contention
        if (writeFromL1P1) begin
          nxtDataMem[bAddrP1] = dataFromL1P1;
        end else begin
          if (missP1 && enableToLl && readyFromLl) begin
            nxtDataMem[bAddrP1] = dataFromLl;
          end
        end  
      end
      3'b110 : begin
        // Allow both P0 and P1 to access L2 if there is no address contention
        case ({writeFromL1P0, writeFromL1P1})
          2'b11, 2'b10: begin
            // Allow P0 to win regardless if there is contention for the
            // lower-level memory
            nxtDataMem[bAddrP0] = dataFromL1P0;
          end
          2'b01 : begin
            // Only allow P1 to write if there is no contention for the lower-
            // level memory
            if (!missP0) begin
              nxtDataMem[bAddrP1] = dataFromL1P1;
            end else begin
              if (enableToLl && readyFromLl) begin
                nxtDataMem[bAddrP0] = dataFromLl;
              end
            end
          end
          2'b00 : begin
            if (missP0) begin
              if (enableToLl && readyFromLl) begin
                nxtDataMem[bAddrP0] = dataFromLl;
              end
            end else begin
              if (missP1) begin
                if (enableToLl && readyFromLl) begin
                  nxtDataMem[bAddrP1] = dataFromLl;
                end
              end
            end // else: !if(missP0)
          end
        endcase // case ({writeFromL1P0, writeFromL1P1})
      end // case: 3'b110
    endcase // case ({enableFromL1P0, enableFromL1P1, addrEq})
  end // block: data_cmb
  
  // --------------------------------------------------------------------------
  // L1 Memory Interface:
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

  assign dataToL1P0 = dataMem[bAddrP0][bIndexP0];
  assign dataToL1P1 = dataMem[bAddrP1][bIndexP1];

  ///////////
  // Ready //
  ///////////
  //
  always @* begin : l1p0_rdy
    case (arbState)
      SERVEP0 : begin
        

  // --------------------------------------------------------------------------
  // Lower-Level Memory Interface:
  //
  assign addrToLl   = (arbState) ? addrFromL1P1       : addrFromL1P0;
  assign writeToLl  = (arbState) ? writeFromL1P1      : writeFromL1P0;
  assign dataToLl   = (arbState) ? dataFromL1P1       : dataFromL1P0;
  assign enableToLl = (arbState) ? enableFromL1P1ToLl : enableFromL1P0ToLl;

  // --------------------------------------------------------------------------
  // Control/Status:
  //
  ////////////////////
  // Miss Detection //
  ////////////////////
  //
  assign missP0 = ~(tagMem[bAddrP0] == btagP0);
  assign missP1 = ~(tagMem[bAddrP1] == btagP1);

  /////////////////
  // Arbiter FSM //
  /////////////////
  //
  // Need to arbitrate between ports when contention exists. Contention exists
  // when L1P0 wants to write or causes a read miss and at the same time L1P1
  // writes or causes a read miss.
  //
  // When contention is detected, wait until P0 is serviced, the move into a
  // state that waits until P1 is serviced
  
  always @(posedge clock or posedge reset) begin : arb_seq
    if (reset) begin
      arbState <= SERVEP0;
    end else begin
      arbState <= nxtArbState;
    end
  end

  always @* begin : arb_cmb
    case (arbState)
      SERVEP0 : begin
        if (enableFromL1P0 && (writeFromL1P0 || missP0)
        
        if (enableFromL1P0 & enableFromL1P1) begin
          if((writeFromL1P0 || missP0) && (writeFromL1P1 || missP1)) begin
            if (readyFromLl) begin
                nxtArbState = SERVEP1;
            end else begin
              nxtArbState = SERVEP0;
            end
          end else begin
            nxtArbState = SERVEP0;
          end
        end else begin // if (enableFromL1P0 & enableFromL1P1)
            nxtArbState = SERVEP0;
        end // else: !if(enableFromL1P0 & enableFromL1P1)
      end // case: SERVEP0

      MISS : begin
        if (

      
      SERVEP1 : begin
        if (readyFromLl) begin
          nxtArbState = SERVEP0;
        end else begin
          nxtArbState = SERVEP1;
        end
      end
    endcase // case (arbState)
  end // block: arb_cmb
  
endmodule // dpDirectMappedL2
