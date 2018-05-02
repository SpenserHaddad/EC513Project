module tb_bp;
	
reg      	branch_op;
reg         	clock, rst;
reg           	taken;
wire          	Predict;
reg [1:0]       state;

Branch_predictor DUT(.branch_op(branch_op), .Predict(Predict), .clock(clock), .rst(rst), .taken(taken));

always #1 clock = ~clock;
initial
	begin
		rst = 1;
		clock = 0;
		
		#1 rst = ~rst;
		
		#1
		branch_op = 1;
		taken = 1;
		
		#1
		branch_op = 1;
		taken = 1;

		#1
		branch_op = 1;
		taken = 1;

		#1
		branch_op = 1;
		taken = 1;

		#1
		branch_op = 1;
		taken = 0;
		
		#1
		branch_op = 1;
		taken = 0;

		#1
		branch_op = 1;
		taken = 0;

		#1
		branch_op = 1;
		taken = 0;

		#1
		branch_op = 0;
		taken = 0;
		
		#1
		branch_op = 0;
		taken = 0;

		#1
		branch_op = 1;
		taken = 1;

		#1
		branch_op = 1;
		taken = 1;
		
		#2
		$finish;
	end
endmodule
