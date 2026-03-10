module mux4x2(
    input [63:0] a, b, c, 
    input [1:0] sel,
    output reg [63:0] out
);
    always@(*) begin
        case(sel)
            2'b00:out = a;
            2'b01:out = b;
            2'b10:out = c;
            2'b11:out = 64'h0000000000000000;
        endcase
    end
endmodule