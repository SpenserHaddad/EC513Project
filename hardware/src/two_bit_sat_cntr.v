module two_bit_sat_cntr (
  input  clock, 
  input  reset,  
  input  branch_op,
  input  ALU_branch,
  output take_branch
);

  localparam [1:0] SNT = 2'b00;
  localparam [1:0] WNT = 2'b01;
  localparam [1:0] WT  = 2'b10;
  localparam [1:0] ST  = 2'b11;
 

  reg [1:0] satc;
  reg [1:0] nxt_satc;
  
  always @ (posedge clock) begin : satc_seq
    if (reset) begin
      satc <= SNT;
    end else begin
      satc <= nxt_satc;
    end
  end

  always @* begin : satc_cmb
    if (branch_op) begin
      // Only update if there was a branch operation
      case (satc)
        SNT : begin
          if (ALU_branch) begin
            nxt_satc = WNT;
          end else begin
            nxt_satc = SNT;
          end
        end
        WNT : begin
          if (ALU_branch) begin
            nxt_satc = WT;
          end else begin
            nxt_satc = SNT;
          end
        end
        WT : begin
          if (ALU_branch) begin
            nxt_satc = ST;
          end else begin
            nxt_satc = WNT;
          end
        end
        ST : begin
          if (ALU_branch) begin
            nxt_satc = ST;
          end else begin
            nxt_satc = WT;
          end
        end
      endcase
    end else begin
      // If there was no branch operation, do not update state
      nxt_satc = satc;
    end
  end

  assign take_branch = satc[1];
endmodule // two_bit_sat_cntr
