`define IMEM_SIZE 4096 // macro
module instruction_mem(
    input clk, reset, 
    input [63:0] addr,
    output [31:0] instr
);
reg [7:0] InstrMemory[`IMEM_SIZE-1:0];
integer i = 0;
integer file;
initial begin
    file = $fopen("instructions.txt", "r");
    while($fscanf(file, "%h", InstrMemory[i]) == 1) begin
        i = i+1;
    end
    for(i = i;i<4096;i=i+1) begin
        InstrMemory[i] = 8'h00;
    end
    $fclose(file);
end
// always@(posedge clk) begin
//     if(reset) begin: ifresetinstrMem
//         instr <= 32'h00000000;
//     end
// end
localparam MAX_VALID_ADDR = `IMEM_SIZE - 4;
// a simple check that makes sure that if the address passed to the 
// instruction_mem block is <= 4092, we'll consider it, else we'll 
// pass on an end condition Instruction==32'h00000000 ...
assign instr = (addr<=MAX_VALID_ADDR)?{InstrMemory[addr], InstrMemory[addr+1], InstrMemory[addr+2], InstrMemory[addr+3]} : 32'h00000000;
endmodule