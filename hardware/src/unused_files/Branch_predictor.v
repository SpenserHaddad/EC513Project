module Branch_predictor (branch_op, Predict, clock, rst, taken);

input      	branch_op;
input           clock, rst;
input           taken;
output          Predict;
reg [1:0]       state;

always @ (posedge clock) 
begin 

    if (rst)
    begin
        state <= 2'b00;
    end

    else
    begin
        if (branch_op)
        begin
            if (taken)
            begin
                if (state < 2'b11)
                begin
                    state <= state + 2'b01;
                end
                else
                begin
                    state <= state;
                end
            end
       

		else
		begin
		    if (state > 2'b00)
		    begin
		        state <= state - 2'b01;
		    end
		    else
		    begin
		        state <= state;
		    end
		end
	    end
	end


end
    assign Predict = state[1];

endmodule
