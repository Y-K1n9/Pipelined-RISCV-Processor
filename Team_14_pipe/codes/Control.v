module Control(
    input [6:0] instr,// opcode
    output reg Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite,
    output reg [1:0] ALUOp
);

always@(*) begin
    Branch = 1'b0;
    MemRead = 1'b0;
    MemtoReg = 1'b0;
    ALUOp = 2'b00;
    MemWrite = 1'b0;
    ALUSrc = 1'b0;
    RegWrite = 1'b0;
    case(instr)
        7'b0110011: begin // R Type
            Branch = 1'b0;
            MemRead = 1'b0;
            MemtoReg = 1'b0;
            ALUOp = 2'b10;
            MemWrite = 1'b0;
            ALUSrc = 1'b0;
            RegWrite = 1'b1;
        end
        7'b0000011: begin // ld
            Branch = 1'b0;
            MemRead = 1'b1;
            MemtoReg = 1'b1;
            ALUOp = 2'b00;
            MemWrite = 1'b0;
            ALUSrc = 1'b1;
            RegWrite = 1'b1;
        end
        7'b0100011: begin // sd
            Branch = 1'b0;
            MemRead = 1'b0;
            MemtoReg = 1'b0; // don't care since 
            //regWrite already 0
            ALUOp = 2'b00;
            MemWrite = 1'b1;
            ALUSrc = 1'b1;
            RegWrite = 1'b0;
        end
        7'b1100011: begin // beq
            Branch = 1'b1;
            MemRead = 1'b0;
            MemtoReg = 1'b0;// don't care
            // since regWrite already 0
            ALUOp = 2'b01;
            MemWrite = 1'b0;
            ALUSrc = 1'b0;
            RegWrite = 1'b0;
        end
        7'b0010011: begin // addi/I-Type
            Branch = 1'b0;
            MemRead = 1'b0;
            MemtoReg = 1'b0;
            ALUOp = 2'b00;
            MemWrite = 1'b0;
            ALUSrc = 1'b1;
            RegWrite = 1'b1;
        end
    endcase
end

endmodule