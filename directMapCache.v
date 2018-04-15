module DirectMap(Addr,Tag,Offset,Index, Tag2,Offset2,Index2,clk, rst, L1h , L2h);

    parameter blocksize = ;
    parameter lines = ;
    parameter blocksize2 = ;
    parameter lines2 = ;
    parameter  Address = ;
    input [Address - 1:0] Addr;                                     //size of address
    input [$clog2(blocksize)-1:0] Offset;                           //L1 offset size
    input [$clog2(lines)-1:0] Index;                                //L1 Index size
    input [Address-$clog2(lines)-$clog2(blocksize)-1:0] Tag;        //L1 Tag size
    input [$clog2(blocksize2)-1:0] Offset2;                         //L2 offset size
    input [$clog2(lines2)-1:0] Index2;                              //L2 Index size
    input [Address-$clog2(lines2)-$clog2(blocksize2)-1:0] Tag2;     //L2 Tag size
    input clk,rst;
    output L1h , L2h;                                               // L1 L2 hit or miss bit


    initial
    begin

    OffMax = $clog2(blocksize)-1;                               //msb L1 offset
    IndexMax = $clog2(lines/2) + $clog2(blocksize) - 1;           //msb L1  index
    OffMax2 = $clog2(blocksize2)-1;                             //msb L2 offset
    IndexMax2 = $clog2(lines2) + $clog2(blocksize2) - 1;        //msb L2 index
    reg[Address - 1:0]memL1[lines/2 -1:0];                        //L1 instruction cache
    reg[Address - 1:0]memL1D[lines/2 -1:0];                        //L1 data cache
    reg[Address - 1:0]memL2[lines2/2 -1:0];                       //L2 cache

    end


    Tag = Addr[Address - 1: $clog2(lines)+$clog2(blocksize)];          
    Index = Addr[$clog2(lines/2)+$clog2(blocksize)-1:$clog2(blocksize)];


    if (Addr is an instruction)
        begin
        if (Tag == memL1[Index][Address - 1: $clog2(lines/2)+$clog2(blocksize)])
            begin
            L1h <= 1;
            end

        else
            begin
            L1h <=0;
            end


    else (Addr is an instruction)
        begin
        if (Tag == memL1D[Index][Address - 1: $clog2(lines/2)+$clog2(blocksize)])
            begin
            L1h <= 1;
            end

        else
            begin
            L1h <=0;
            end





    if( L1h == 0)
    begin
        Tag2 = Addr[Address - 1: $clog2(lines2)+$clog2(blocksize2)];
        Index2 = Addr[$clog2(lines2)+$clog2(blocksize2)-1:$clog2(blocksize2)];

        if (Tag2 == memL2[Index2][Address - 1: $clog2(lines2)+$clog2(blocksize2)])
            begin
            L2h <= 1;
            memL1[Index] <= Addr;
            end

        else
            begin
            L2h <= 0;
            memL2[Index2] <= memL1[index];
            memL1[index] <= Addr;
            end
    end

endModule

    
//L1h = 1 signifies hit in L1 cache and 0 means miss in L1 cache
// if there's a miss it goes to L2 . 
//if there's a hit the value in L2 is sent to L1
// if there's a  miss in L2. the current value in L1 is stored in L2 and the new value is stored in L1
