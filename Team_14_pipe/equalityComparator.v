module equalityComparator(
    input [63:0] a,b,
    output equal
);
    assign equal = a==b;
endmodule