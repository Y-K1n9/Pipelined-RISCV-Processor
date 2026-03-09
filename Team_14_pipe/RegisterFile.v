module reg64bit(
    input clk, reset, write_enable,
    input [63:0] in,
    output reg [63:0] out
);
    always@(posedge clk) begin
        if(reset)
            out <= 64'h0000;
        else if(write_enable)// if the clk edge is positive
        // and write enable is high, we write values else
        // we latch
            out <= in;
    end
endmodule

module demux1x2(
    input in,
    input sel,
    output [1:0] out
);
    assign out[0] = ~sel?in:0;
    assign out[1] = sel?in:0;
endmodule

module demux1x32(
    input in,
    input [4:0] sel,
    output [31:0] out// 2d vectors not allowed in
    // port decl..
);
    wire [1:0] tt4;
    wire [3:0] tt3;
    wire [7:0] tt2;
    wire [15:0] tt1;
    
    generate
        genvar i;
        for(i=0;i<1;i=i+1) begin: myloopdemux0
            demux1x2 d0(in, sel[4], tt4);
        end
        for(i=0;i<2;i=i+1) begin: myloopdemux1
            demux1x2 d1(tt4[i], sel[3], tt3[(2*i)+1:2*i]);
        end
        for(i=0;i<4;i=i+1) begin: myloopdemux2
            demux1x2 d2(tt3[i], sel[2], tt2[(2*i)+1:2*i]);
        end
        for(i=0;i<8;i=i+1) begin: myloopdemux3
            demux1x2 d3(tt2[i], sel[1], tt1[(2*i)+1:2*i]);
        end
        for(i=0;i<16;i=i+1) begin: myloopdemux4
            demux1x2 d4(tt1[i], sel[0], out[(2*i)+1:2*i]);
        end
    endgenerate

endmodule

module RegisterFile(
    input clk, reset, reg_write_en,
    input [4:0] read_reg1, read_reg2, write_reg,
    input [63:0] write_data,
    output [63:0] read_data1, read_data2
);
wire [63:0] inp[31:0];
wire [63:0] outp[31:0];
// hardwiring x0 as a constant 0 register
assign outp[0] = 64'b0;


// reading: bypass write_data when writing to the same register (write-before-read)
// This fixes the 3-cycle-ago hazard where the WB stage's synchronous write hasn't
// physically committed to outp[] yet when the ID stage reads the same register.
assign read_data1 = (reg_write_en && write_reg == read_reg1 && read_reg1 != 5'b0) ? write_data : outp[read_reg1];
assign read_data2 = (reg_write_en && write_reg == read_reg2 && read_reg2 != 5'b0) ? write_data : outp[read_reg2];

// // reading:
// assign read_data1 = outp[read_reg1];
// assign read_data2 = outp[read_reg2];


// writing
wire [31:0] writeen;
demux1x32 d(reg_write_en, write_reg, writeen);

generate
    genvar i;
    for(i=0;i<32;i=i+1) begin: loopRegFile
        assign inp[i] = write_data;
        if(i!=0) begin
            reg64bit x(.clk(clk), .reset(reset), .write_enable(writeen[i]), .in(inp[i]), .out(outp[i]));
        end
    end
endgenerate

endmodule