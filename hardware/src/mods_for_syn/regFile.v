/** @module : regFile
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
 */

// Parameterized register file
module regFile #(parameter REG_DATA_WIDTH = 32, REG_SEL_BITS = 5) (
                clock, reset, read_sel1, read_sel2,
                wEn, write_sel, write_data, 
                read_data1, read_data2
);

input clock, reset, wEn; 
input [REG_DATA_WIDTH-1:0] write_data;
input [REG_SEL_BITS-1:0] read_sel1, read_sel2, write_sel;
output[REG_DATA_WIDTH-1:0] read_data1; 
output[REG_DATA_WIDTH-1:0] read_data2; 

wire CENB = ~(wEn & (write_sel != 0));
  
rf2p32x32 u_rf2p32x320 (
  .CLKA(clock),
  .CENA(1'b0),
  .AA(read_sel1),
  .QA(read_data1),
  .EMAA(3'b000),
  .CLKB(clock),
  .CENB(CENB),
  .AB(write_sel),
  .DB(write_data),
  .EMAB(3'b000),
  .RET1N(1'b1),
  .COLLDISN(1'b0)
);

rf2p32x32 u_rf2p32x321 (
  .CLKA(clock),
  .CENA(1'b0),
  .AA(read_sel2),
  .QA(read_data2),
  .EMAA(3'b000),
  .CLKB(clock),
  .CENB(CENB),
  .AB(write_sel),
  .DB(write_data),
  .EMAB(3'b000),
  .RET1N(1'b1),
  .COLLDISN(1'b0)
);


endmodule
