module ALUControl(
    input[1:0] ALUOp,
    input[3:0] instr,
    output reg [3:0] out
);

always@(*) begin
    casez({ALUOp, instr})
        // only for ld and sd instructions
        // as well as for 
        // addi(we still have to do addition only)
        // ALUOp is 00
        6'b00zzzz: out = 4'b0010;
        // only for beq instruction
        // ALUOp is 01
        6'b01zzzz: out = 4'b0110;
        // for remaining R-type instructions
        // ALUOp is 10 and we need the out to be
        // dependent on both funct7 and funct3 i.e. instr
        // the concatenation of 30th bit of funct7
        // (which is 1 only if operation is that of sub)...
        // add
        6'b100000: out = 4'b0010;
        // sub
        6'b101000: out = 4'b0110;
        // and
        6'b100111: out = 4'b0000;
        // or
        6'b100110: out = 4'b0001;
    endcase
end

endmodule