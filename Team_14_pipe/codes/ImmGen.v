module ImmGen(
    input [31:0] Instruction,
    output reg [63:0] immediate
);
always@(*)begin
    immediate = 64'h0000000000000000;
    // ImmGen only deals with the opcode
    casez(Instruction[6:0])
        7'b00z0011: begin
            // ld and addi
            immediate = {{52{Instruction[31]}}, Instruction[31:20]};
        end
        7'b0100011: begin
            // sd
            immediate = {{52{Instruction[31]}}, Instruction[31:25], Instruction[11:7]};
        end
        7'b1100011: begin
            // beq
            immediate = {{53{Instruction[31]}}, Instruction[7], Instruction[30:25], Instruction[11:8]};
        end
    endcase
end
endmodule