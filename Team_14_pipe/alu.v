`include "addOps.v"
`include "andOps.v"
`include "orOps.v"
`include "sllOps.v"
`include "sltOps.v"
`include "sltuOps.v"
`include "sraOps.v"
`include "srlOps.v"
`include "subOps.v"
`include "xorOps.v"
module alu_64_bit(
    input [63:0]a,
    input [63:0]b,
    input [3:0]opcode,
    output reg [63:0]result, 
    output reg cout, carry_flag, overflow_flag, zero_flag
);
    wire [63:0]result1[9:0];
    wire overflow_flag1, overflow_flag2, overflow_flag3, overflow_flag4, overflow_flag5, overflow_flag6, overflow_flag7, overflow_flag8, overflow_flag9, overflow_flag10;
    wire carry_flag1, carry_flag2, carry_flag3, carry_flag4, carry_flag5, carry_flag6, carry_flag7, carry_flag8, carry_flag9, carry_flag10;
    wire cout1, cout2, cout3, cout4, cout5, cout6, cout7, cout8, cout9, cout10;
    wire zero_flag1, zero_flag2, zero_flag3, zero_flag4, zero_flag5, zero_flag6, zero_flag7, zero_flag8, zero_flag9, zero_flag10;
    addOps add1(.a(a),.b(b),.res(result1[0]),.overflow_flag(overflow_flag1),.carry_flag(carry_flag1),.cout(cout1), .zero_flag(zero_flag1));
    sllOps sll1(.a(a),.sig(b),.res(result1[1]),.overflow_flag(overflow_flag2),.carry_flag(carry_flag2),.cout(cout2), .zero_flag(zero_flag2));
    sltOps slt1(.a(a),.b(b),.res(result1[2]),.overflow_flag(overflow_flag3),.carry_flag(carry_flag3),.cout(cout3), .zero_flag(zero_flag3));
    sltuOps sltu1(.a(a),.b(b),.res(result1[3]),.overflow_flag(overflow_flag4),.carry_flag(carry_flag4),.cout(cout4), .zero_flag(zero_flag4));
    xorOps xor1(.a(a),.b(b),.res(result1[4]),.overflow_flag(overflow_flag5),.carry_flag(carry_flag5),.cout(cout5), .zero_flag(zero_flag5));
    srlOps srl1(.a(a),.sig(b),.res(result1[5]),.overflow_flag(overflow_flag6),.carry_flag(carry_flag6),.cout(cout6), .zero_flag(zero_flag6));
    orOps or1(.a(a),.b(b),.res(result1[6]),.overflow_flag(overflow_flag7),.carry_flag(carry_flag7),.cout(cout7), .zero_flag(zero_flag7));
    andOps and1(.a(a),.b(b),.res(result1[7]),.overflow_flag(overflow_flag8),.carry_flag(carry_flag8),.cout(cout8), .zero_flag(zero_flag8));
    subOps sub1(.a(a), .b(b), .res(result1[8]), .overflow_flag(overflow_flag9), .cout(cout9), .carry_flag(carry_flag9), .zero_flag(zero_flag9));
    sraOps sra1(.a(a),.sig(b),.res(result1[9]),.overflow_flag(overflow_flag10),.carry_flag(carry_flag10),.cout(cout10), .zero_flag(zero_flag10));
    
always@(*) begin
    result = 64'b0;
    overflow_flag = 1'b0;
    carry_flag = 1'b0;
    cout = 1'b0;
    zero_flag = 1'b0;
    case(opcode)
        4'b0000: begin
            result = result1[7];
            overflow_flag = overflow_flag8;
            carry_flag = carry_flag8;
            cout = cout8;
            zero_flag = zero_flag8;
        end
        4'b0001: begin
            result = result1[6];
            overflow_flag = overflow_flag7;
            carry_flag = carry_flag7;
            cout = cout7;
            zero_flag = zero_flag7;
        end
        4'b0010: begin
            result = result1[0];
            overflow_flag = overflow_flag1;
            carry_flag = carry_flag1;
            cout = cout1;
            zero_flag = zero_flag1;
        end
        4'b0110: begin
            result = result1[8];
            overflow_flag = overflow_flag9;
            carry_flag = carry_flag9;
            cout = cout9;
            zero_flag = zero_flag9;
        end
    endcase
end

endmodule