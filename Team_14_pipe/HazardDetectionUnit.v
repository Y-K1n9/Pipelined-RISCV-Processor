module HazardDetectionUnit(
    input IDEXMemRead,
    input IDEXRegWrite,
    input EXMEMMemRead,
    input [4:0] EXMEMrd,
    input [31:0] Instruction, IDEXIR,
    output reg PCWrite, IFIDEnable, Bubble
);
    wire [4:0] IDEXrd = IDEXIR[11:7];
    wire [4:0] rs1 = Instruction[19:15];
    wire [4:0] rs2 = Instruction[24:20];
    wire isBEQ = (Instruction[6:0] == 7'b1100011);

    always@(*) begin
        // default: no stall
        PCWrite = 1'b1;
        IFIDEnable = 1'b1;
        Bubble = 1'b0;

        if(isBEQ) begin
            // beq needs rs1 and rs2 at comparator in ID stage
            //
            // Case 1: N-1 (IDEX) writes a register that beq reads
            //   - non-load: 1 stall, then forward from EX/MEM
            //   - load: 1st of 2 stalls; 2nd stall triggered by Case 2
            //     after the load moves to EXMEM on next cycle
            if(IDEXRegWrite && IDEXrd != 5'b00000 &&
               (IDEXrd == rs1 || IDEXrd == rs2)) begin
                PCWrite = 1'b0;
                IFIDEnable = 1'b0;
                Bubble = 1'b1;
            end
            // Case 2: N-2 (EXMEM) is a load writing a register beq reads
            //   - 1 stall, then forward from MEM/WB
            //   - also naturally handles 2nd stall for N-1 load
            else if(EXMEMMemRead && EXMEMrd != 5'b00000 &&
                    (EXMEMrd == rs1 || EXMEMrd == rs2)) begin
                PCWrite = 1'b0;
                IFIDEnable = 1'b0;
                Bubble = 1'b1;
            end
        end
        else begin
            // Load-use hazard for non-beq instructions
            if(Instruction[6:0] == 7'b0000011 || Instruction[6:0] == 7'b0010011) begin
                // ld, addi (I-type): only rs1 is a source register
                if(IDEXMemRead && IDEXrd != 5'b00000 && IDEXrd == rs1) begin
                    PCWrite = 1'b0;
                    IFIDEnable = 1'b0;
                    Bubble = 1'b1;
                end
            end
            else begin
                // R-type, sd: both rs1 and rs2 are source registers
                if(IDEXMemRead && IDEXrd != 5'b00000 &&
                   (IDEXrd == rs1 || IDEXrd == rs2)) begin
                    PCWrite = 1'b0;
                    IFIDEnable = 1'b0;
                    Bubble = 1'b1;
                end
            end
        end
    end
endmodule