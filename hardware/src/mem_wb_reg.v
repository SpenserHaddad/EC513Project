// Execute / Memory Pipeline Register
module ex_mem_reg_unit #(parameter CORE = 0, DATA_WIDTH=32, ADDRESS_BITS=20)(
    clock, reset,

    mem_regWrite,
    mem_memRead,
    mem_rd,
    mem_memory_data,
    mem_ALU_result,
    wb_write,
    wb_write_reg,
    wb_write_data,

    wb_regWrite,
    wb_memRead,
    wb_rd,
    wb_memory_data,
    wb_ALU_result,
    mem_write,
    mem_write_reg,
    mem_write_data
);

input clock, reset;

input mem_regWrite;
input mem_memRead;
input [4:0] mem_rd;
input [DATA_WIDTH-1:0] mem_memory_data;
input [DATA_WIDTH-1:0] mem_ALU_result;
input wb_write;
input [4:0] wb_write_reg;
input [DATA_WIDTH-1:0] wb_write_data;

output reg wb_regWrite;
output reg wb_memRead;
output reg [4:0] wb_rd;
output reg [DATA_WIDTH-1:0] wb_memory_data;
output reg [DATA_WIDTH-1:0] wb_ALU_result;
output reg mem_write;
output reg [4:0] mem_write_reg;
output reg [DATA_WIDTH-1:0] mem_write_data;

always @(posedge clock) begin
    wb_regWrite <= mem_regWrite;
    wb_memRead <= mem_memRead;
    wb_rd <= mem_rd;
    wb_memory_data <= mem_memory_data;
    wb_ALU_result <= mem_ALU_result;
    mem_write <= wb_write;
    mem_write_reg <= wb_write_reg;
    mem_write_data <= wb_write_data;
end
endmodule
