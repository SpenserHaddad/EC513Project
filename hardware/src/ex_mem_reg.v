// Execute / Memory Pipeline Register
module ex_mem_reg_unit #(parameter CORE = 0, DATA_WIDTH=32, ADDRESS_BITS=20)(
    clock, reset,

    ex_memRead,
    ex_regWrite,
    ex_ALU_result,
    ex_rs2_data,
    ex_rd,
    mem_write,
    mem_write_reg,
    mem_write_data,

    mem_load,
    mem_store,
    mem_ALU_result,
    mem_store_data,
    mem_rd,
    ex_write,
    ex_write_reg,
    ex_write_data
);

input clock, reset;

input ex_memRead;
input ex_memWrite;
input ex_regWrite;
input [DATA_WIDTH-1:0] ex_ALU_result;
input [DATA_WIDTH-1:0] ex_rs2_data;
input [4:0] ex_rd;
input mem_write;
input [4:0] mem_write_reg;
input [DATA_WIDTH-1:0] mem_write_data;

output mem_load;
output mem_store;
output mem_regWrite;
output [DATA_WIDTH-1:0] mem_ALU_result;
output [DATA_WIDTH-1:0] mem_rs2_data;
output [4:0] mem_rd;
output ex_write;
output [4:0] ex_write_reg;
output [DATA_WIDTH-1:0] ex_write_data;

always @(posedge clock) begin
    mem_load <= ex_memRead;
    mem_store <= ex_memWrite;
    mem_regWrite <= ex_regWrite;
    mem_ALU_result <= ex_ALU_result;
    mem_rs2_data <= ex_rs2_data;
    mem_rd <= ex_rd;
    ex_write <= mem_write;
    ex_write_reg <= mem_write_reg;
    ex_write_data <= mem_write_data;
end