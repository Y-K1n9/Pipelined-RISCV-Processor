module ForwardingUnit(
    input EXMEMRegWrite, MEMWBRegWrite,
    input[4:0] EXMEMrd, EXMEMrs2Addr, MEMWBrd,
    input[4:0] IDEXrs1Addr, IDEXrs2Addr,
    output reg [1:0] ForwardA, ForwardB,
    output reg Forward_sd
);
    always@(*)begin
        // ForwardA
        if(EXMEMrd==IDEXrs1Addr&&EXMEMrd!=5'b00000&&EXMEMRegWrite==1'b1) begin
            ForwardA = 2'b10;
        end
        else if(MEMWBrd==IDEXrs1Addr&&MEMWBrd!=5'b00000&&MEMWBRegWrite==1'b1) begin
            ForwardA = 2'b01;
        end
        else begin
            ForwardA = 2'b00;
        end
        // ForwardB
        if(EXMEMrd==IDEXrs2Addr&&EXMEMrd!=5'b00000&&EXMEMRegWrite==1'b1) begin
            ForwardB = 2'b10;
        end
        else if(MEMWBrd==IDEXrs2Addr&&MEMWBrd!=5'b00000&&MEMWBRegWrite==1'b1) begin
            ForwardB = 2'b01;
        end
        else begin
            ForwardB = 2'b00;
        end
        // Forward_sd -> BONUS
        if(MEMWBrd==EXMEMrs2Addr&&MEMWBrd!=5'b00000&&MEMWBRegWrite==1) begin
            Forward_sd = 1'b1;
        end
        else begin
            Forward_sd = 1'b0;
        end
    end

endmodule