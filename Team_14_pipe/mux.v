module mux(
    input [63:0]a, b, 
    input sel,
    output[63:0] out
);
    assign out = sel? b:a;
endmodule