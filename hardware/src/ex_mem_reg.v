// Execute / Memory Pipeline Register
module ex_mem_reg_unit #(parameter CORE = 0, DATA_WIDTH=32, ADDRESS_BITS=20)(
    clock, reset,

    ex_memRead, ex_memWrite,
    ex_regWrite,
    ex_ALU_result,

    mem_load, mem_store,
    mem_address,
    mem_store_data,
    mem_ALU_result
);

input clock, reset;
input ex_memRead, ex_memWrite;
input ex_regWrite;
input ex_ALU_result;

output mem_load, mem_store;
output [ADDRESS_BITS-1:0] mem_address;
output [DATA_WIDTH-1:0] mem_store_data;
