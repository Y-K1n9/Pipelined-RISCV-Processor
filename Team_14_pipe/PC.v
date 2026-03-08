module PC(
    input clk, reset,
    input [63:0] pc_in,
    output reg [63:0] pc_out
);
    always@(posedge clk) begin
        if(reset)
            pc_out <= 64'h0000;
        else
            pc_out <= pc_in;
    end
endmodule
