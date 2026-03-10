module BranchForwardingUnit(
    input EXMEMRegWrite, MEMWBRegWrite,
    input [4:0] EXMEMrd, MEMWBrd,
    input [4:0] IFIDrs1, IFIDrs2,
    output reg [1:0] ForwardCompA, ForwardCompB
);
    always@(*) begin
        // ForwardCompA (for rs1 of branch instruction in ID stage)
        if(EXMEMRegWrite && EXMEMrd != 5'b00000 && EXMEMrd == IFIDrs1) begin
            ForwardCompA = 2'b10; // forward from EX/MEM
        end
        else if(MEMWBRegWrite && MEMWBrd != 5'b00000 && MEMWBrd == IFIDrs1) begin
            ForwardCompA = 2'b01; // forward from MEM/WB
        end
        else begin
            ForwardCompA = 2'b00; // no forwarding
        end

        // ForwardCompB (for rs2 of branch instruction in ID stage)
        if(EXMEMRegWrite && EXMEMrd != 5'b00000 && EXMEMrd == IFIDrs2) begin
            ForwardCompB = 2'b10; // forward from EX/MEM
        end
        else if(MEMWBRegWrite && MEMWBrd != 5'b00000 && MEMWBrd == IFIDrs2) begin
            ForwardCompB = 2'b01; // forward from MEM/WB
        end
        else begin
            ForwardCompB = 2'b00; // no forwarding
        end
    end
endmodule
