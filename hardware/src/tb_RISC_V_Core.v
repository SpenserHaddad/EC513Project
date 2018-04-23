/** @module : tb_RISC_V_Core
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

module tb_RISC_V_Core(); 
 
localparam ADDRESS_BITS = 32'd20;
localparam DATA_WIDTH   = 32'd32;

reg          clock, reset, start; 
reg   [19:0] prog_address; 
reg          report; // performance reporting
reg [80*8:1] rom_filename;
reg   [31:0] clock_cycles;

wire   [DATA_WIDTH-1:0] instruction;
wire   [DATA_WIDTH-1:0] ifid_instruction;
reg    [DATA_WIDTH-1:0] idex_instruction;
reg    [DATA_WIDTH-1:0] exmem_instruction;
reg    [DATA_WIDTH-1:0] memwb_instruction;

wire [ADDRESS_BITS-1:0] inst_PC;  
wire [ADDRESS_BITS-1:0] ifid_inst_PC;  
wire [ADDRESS_BITS-1:0] idex_inst_PC;  
reg  [ADDRESS_BITS-1:0] exmem_inst_PC;  
reg  [ADDRESS_BITS-1:0] memwb_inst_PC;  


// module RISC_V_Core #(parameter CORE = 0, DATA_WIDTH = 32, INDEX_BITS = 6, OFFSET_BITS = 3, ADDRESS_BITS = 20)
RISC_V_Core CORE (
                .clock(clock), 
                .reset(reset), 
                .start(start), 
                .prog_address(prog_address), 
                .report(report)
); 

// Clock generator
always #1 clock = ~clock;

initial begin
  if (!$value$plusargs("ROM_FILE=%s", rom_filename)) begin
    $display("NO ROM_FILE specified. Exiting simulation");
    $finish;
  end
  $readmemh({"../software/applications/binaries/", rom_filename, ".mem"}, CORE.IF.i_mem_interface.RAM.sram);

  clock  = 0;
  reset  = 1;
  report = 0;
  prog_address = 'h0;         
  repeat (1) @ (posedge clock);
  repeat (1) @ (posedge clock);

  reset = 0;
  start = 1; 
  repeat (1) @ (posedge clock);

  start = 0; 
  repeat (1) @ (posedge clock); 
end

always @(posedge clock) begin
  if (reset) begin
    clock_cycles <= 32'd0;
  end else begin
    clock_cycles <= clock_cycles+1;
  end
end

// ----------------------------------------------------------------------------
// PC and Instruction Pipelining for debug:
//
assign instruction      = CORE.instruction;
assign inst_PC          = CORE.inst_PC;

assign ifid_instruction = CORE.ifid_instruction;
assign ifid_inst_PC     = CORE.ifid_inst_PC;

always @ (posedge clock) begin : idex
  if (reset) begin
    idex_instruction <= 32'h00000013;
  end else begin
    if (CORE.flush || CORE.stall ) begin
      idex_instruction <= 32'h00000013;
    end else begin
      idex_instruction <= ifid_instruction;
    end
  end
end

assign idex_inst_PC = CORE.idex_inst_PC;

always @ (posedge clock) begin : exmem
  if (reset) begin
    exmem_instruction <= 32'h00000013;
    exmem_inst_PC     <= {ADDRESS_BITS{1'd0}};
  end else begin // if (reset)
   if (CORE.flush) begin
     exmem_inst_PC     <= {ADDRESS_BITS{1'd0}};
     exmem_instruction <= 32'h00000013;
   end else begin
      exmem_inst_PC       <= idex_inst_PC;
      exmem_instruction   <= idex_instruction;
    end // else: !if(flush)
  end
end

always @ (posedge clock) begin : memwb
  if (reset) begin
    memwb_inst_PC     <= {ADDRESS_BITS{1'd0}};
    memwb_instruction <= 32'h00000013;
  end else begin
    memwb_inst_PC     <= exmem_inst_PC;
    memwb_instruction <= exmem_instruction;
  end
end
 
// ----------------------------------------------------------------------------
// End-of-Simulation Snooping:
//
always @(negedge clock) begin
  //$display("PC is: %0h", CORE.inst_PC);
  if (memwb_inst_PC == 32'h000000b0) begin
    $display("Test Completed after %0d clock cycles", clock_cycles);
    $finish;
  end
end

endmodule
