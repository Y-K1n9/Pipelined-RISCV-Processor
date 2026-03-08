module HazardDetectionUnit(
    input IDEXMemRead,
    input [31:0] Instruction, IDEXIR,
    output reg PCWrite, IFIDEnable, Bubble
);
    // It would never be a false alarm since this flushing will happen only if ld is there... 
    // ld's rd == rs1 or rs2 of old instr, So essentially in the case of beq and sd (no rd) the 
    // conditional itself would not be giving false alarm... MEMRead==0, so we safely use Instruction[11:7]
    wire [4:0] IDEXrd = IDEXIR[11:7];
    always@(*)begin
        // ld is identified by the following since
        // it is only line that does MemRead = 1
        // checking if not I type(addi) or ld
        if(Instruction[6:0]!=7'b0000011&&Instruction[6:0]!=7'b0010011) begin
            // rs1:Instruction[19:15], rs1:Instruction[24:20]
            if(IDEXMemRead==1'b1&&((IDEXrd==Instruction[19:15])||(IDEXrd==Instruction[24:20]))&&IDEXrd!=5'b00000) begin
                PCWrite = 1'b0;
                IFIDEnable = 1'b0;
                Bubble = 1'b1;
                // Bubble if == 1 then MUX input of ID/EX control signals becomes 0
            end
            else begin
                PCWrite = 1'b1;
                IFIDEnable = 1'b1;
                Bubble = 1'b0;
            end
        end
        else begin
            if(IDEXMemRead==1'b1&&(IDEXrd==Instruction[19:15])&&IDEXrd!=5'b00000) begin
                PCWrite = 1'b0;
                IFIDEnable = 1'b0;
                Bubble = 1'b1;
                // Bubble if == 1 then MUX input of ID/EX control signals becomes 0
            end
            else begin
                PCWrite = 1'b1;
                IFIDEnable = 1'b1;
                Bubble = 1'b0;
            end
        end
    end
endmodule