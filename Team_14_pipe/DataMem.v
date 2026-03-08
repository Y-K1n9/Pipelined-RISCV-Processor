module DataMem(
    input clk, reset, MemRead, MemWrite,
    input [9:0] address,
    input [63:0] write_data,
    output reg [63:0] read_data
);

reg [7:0] Memory[1023:0];

initial begin
    for(integer i = 0;i<1024;i=i+1) begin
        Memory[i] = 8'h00;
    end
end

always@(posedge clk) begin
    if(reset) begin
        read_data <= 64'h0000000000000000;
    end
    else if(MemWrite) begin // writing:
        Memory[address] <= write_data[63:56];
        Memory[address+1] <= write_data[55:48];
        Memory[address+2] <= write_data[47:40];
        Memory[address+3] <= write_data[39:32];
        Memory[address+4] <= write_data[31:24];
        Memory[address+5] <= write_data[23:16];
        Memory[address+6] <= write_data[15:8];
        Memory[address+7] <= write_data[7:0];
    end
end
always@(*) begin
    if(MemRead) begin // reading:
        read_data = {Memory[address], Memory[address+1], 
                    Memory[address+2], Memory[address+3], 
                    Memory[address+4], Memory[address+5], 
                    Memory[address+6], Memory[address+7]};
    end
end
// following not allowed since in one line of assign, we cannot access
// more than one address of an unpacked array
// assign read_data = {Memory[address], Memory[address+5'd1], Memory[address+5'd2], Memory[address+5'd3], Memory[address+5'd4], Memory[address+5'd5], Memory[address+5'd6], Memory[address+5'd7]};

endmodule