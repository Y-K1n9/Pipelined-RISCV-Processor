module PC(
    input clk, reset, enable,
    input [63:0] pc_in,
    output reg [63:0] pc_out
);
    always@(posedge clk) begin
        if(reset) begin
            pc_out <= 64'h0000;
        end
        else begin
            if(enable)
                pc_out <= pc_in;
            else
                pc_out <= pc_out;
        end
    end
endmodule
