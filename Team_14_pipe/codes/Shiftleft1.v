module ShiftLeft1(
    input [63:0]a,
    output [63:0]res
);
    assign res = {a[62:0], 1'b0};
endmodule