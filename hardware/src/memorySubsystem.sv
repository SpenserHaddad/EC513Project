module memorySubsystem (
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
  readyToProc     // (O) Ready indicator to processor
  );

  // --------------------------------------------------------------------------
  // Module Parameters / Localparams
  //
  parameter  BSIZE = 32'd8;    // Number of 32-bit words in a block
  parameter  NBLKS = 32'd1024; // Number of blocks

  ///////////////////////
  // Clocks and Resets //
  ///////////////////////
  //
  input         clock;
  input         reset;

  /////////////////////////////////
  // Interface to/from Processor //
  /////////////////////////////////
  //
  input  [31:0] addrFromProc;
  input         enableFromProc;
  input         writeFromProc;
  input  [31:0] dataFromProc;
  output [31:0] dataToProc;
  output        readyToProc;

  // --------------------------------------------------------------------------
  // Internal Signal Declarations
  //
  //////////////////////////////////////////
  // Interface to/from Lower-Level Memory //
  //////////////////////////////////////////
  //
  wire [31:0] addrToLl;
  wire        enableToLl;
  wire        writeToLl;
  wire [31:0] dataToLl;
  wire [31:0] dataFromLl;
  wire        readyFromLl;

  // --------------------------------------------------------------------------
  // L1 Cache
  //
  directMappedL1 #(.BSIZE(BSIZE), .NBLKS(NBLKS)) uL1Cache (
    // Clocks and Resets
    .clock          (clock), // (I) Clock
    .reset          (reset), // (I) Reset(), active-high

    // Interface to/from Processor
    .addrFromProc   (addrFromProc),   // (I) Address from processor
    .enableFromProc (enableFromProc), // (I) Enable from processor
    .writeFromProc  (writeFromProc),  // (I) Transaction direction from processor (0:read() 1:write)
    .dataFromProc   (dataFromProc),   // (I) Data from processor
    .dataToProc     (dataToProc),     // (O) Data to processor
    .readyToProc    (readyToProc),    // (O) Ready indicator to processor

    // Interface to/from Lower-Level Memory
    .addrToLl       (addrToLl),    // (O) Address to lower-level memory
    .enableToLl     (enableToLl),  // (O) Enable to lower-level memory
    .writeToLl      (writeToLl),   // (O) Transaction direction to lower-level (0:read() 1:write)
    .dataToLl       (dataToLl),    // (O) Data to lower-level memory
    .dataFromLl     (dataFromLl),  // (I) Data from lower-level memory
    .readyFromLl    (readyFromLl)  // (I) Ready indicator from lower-level memory  
  );

  // --------------------------------------------------------------------------
  // Main Memory
  //
  BSRAM #(.CORE(32'd0), .DATA_WIDTH(32'd32), .ADDR_WIDTH(32'd32)) uMainMem ( 
    .clock        (clock),
    .reset        (reset),
    .readEnable   (enableToLl & ~writeToLl),
    .readAddress  (addrToLl),
    .readData     (dataFromLl),
    .writeEnable  (enableToLl & writeToLl),
    .writeAddress (addrToLl),
    .writeData    (dataToLl), 
    .report       (1'b0)
  );

  assign readyFromLl = 1'b1; // Main Memory is like Spongebob: Always Ready!

endmodule // memorySubsystem
