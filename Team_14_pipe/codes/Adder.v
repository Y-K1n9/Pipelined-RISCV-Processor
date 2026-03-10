module AdderFourBitAdder(
    input [3:0] a,b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] carry;
    wire [3:0] g;
    wire [3:0] temps;
    wire [3:0] p;
    generate
        genvar i;
        // for(i = 0; i < $bits(a); i = i+1) begin: myloop <-- didn't work
        for(i = 0; i < 4; i = i+1) begin: myloop
            or oo (p[i], a[i], b[i]);
            and aa (g[i], a[i], b[i]);
            if(i == 0) begin: ifstatement
                xor xxor (temps[0], a[0], b[0]);
                xor xor_gate (sum[0],cin,temps[0]);
            end
            else begin: elsestatement
                xor xxor (temps[i], a[i], b[i]);
                xor xor_gate (sum[i],carry[i-1],temps[i]); 
            end
        end
    endgenerate
    // carry[0] = g0 + p0cin
        // p0cin
        wire p0cin;
        and a0 (p0cin, p[0], cin);
        or o0 (carry[0], g[0], p0cin);
    // carry[1] = g1 + p1g0 + p1p0cin
        /// p1g0
        wire p1g0;
        and a1 (p1g0,p[1], g[0]);
        /// p1p0cin
        wire p1p0, p1p0cin;
        and aa1 (p1p0,p[1], p[0]);
        and aaa1 (p1p0cin, p1p0, cin);
        // carry
        wire p1g0_p1p0cin;
        or o1 (p1g0_p1p0cin, p1g0, p1p0cin);
        or oo1 (carry[1], g[1], p1g0_p1p0cin);
    // carry[2] = g2 + p2g1 +p2p1g0 + p2p1p0cin
        /// p2g1
        wire p2g1;
        and a2 (p2g1,p[2], g[1]);
        /// p2p1g0
        wire p2p1, p2p1g0;
        and aa2 (p2p1,p[2], p[1]);
        and aaa2 (p2p1g0,g[0], p2p1);
        /// p2p1p0cin
        wire p2p1p0, p2p1p0cin;
        and aaaa2 (p2p1p0,p[0], p2p1);
        and aaaaa2 (p2p1p0cin,cin, p2p1p0);
        // carry
        wire p2p1g0_p2p1p0cin, p2g1_p2p1g0_p2p1p0cin;
        or o2 (p2p1g0_p2p1p0cin, p2p1g0, p2p1p0cin);
        or oo2 (p2g1_p2p1g0_p2p1p0cin, p2g1, p2p1g0_p2p1p0cin);
        or ooo2 (carry[2], g[2], p2g1_p2p1g0_p2p1p0cin);
    // carry[3] = g3 + p3g2 + p3p2g1 + p3p2p1g0 + p3p2p1p0cin
        /// p3g2
        wire p3g2;
        and a3 (p3g2,p[3], g[2]);
        /// 
        wire p3p2g1, p3p2;
        and aa3 (p3p2, p[3], p[2]);
        and aaa3 (p3p2g1, p3p2, g[1]);
        /// p3p2p1g0
        wire p3p2p1g0, p3p2p1;
        and aaaa3 (p3p2p1, p3p2, p[1]);
        and aaaaa3 (p3p2p1g0, p3p2p1, g[0]);
        /// p3p2p1p0cin
        wire p3p2p1p0, p3p2p1p0cin;
        and aaaaaa3 (p3p2p1p0, p3p2p1, p[0]);
        and aaaaaaa3 (p3p2p1p0cin, p3p2p1p0, cin);
        // carry
        wire p3p2p1g0_p3p2p1p0cin, p3p2g1_p3p2p1g0_p3p2p1p0cin, p3g2_p3p2g1_p3p2p1g0_p3p2p1p0cin;
        or o3 (p3p2p1g0_p3p2p1p0cin, p3p2p1g0, p3p2p1p0cin);
        or oo3 (p3p2g1_p3p2p1g0_p3p2p1p0cin, p3p2g1, p3p2p1g0_p3p2p1p0cin);
        or ooo3 (p3g2_p3p2g1_p3p2p1g0_p3p2p1p0cin, p3g2, p3p2g1_p3p2p1g0_p3p2p1p0cin); 
        or oooo3 (carry[3], g[3], p3g2_p3p2g1_p3p2p1g0_p3p2p1p0cin); 
    assign cout = carry[3];
endmodule

module Adder(
    input [63:0] a,b,
    output [63:0] res
);
// carry in for this adder will be set to 0;
    wire [15:0]carrys;
    generate
        genvar i;
        for(i=0;i<16;i=i+1) begin: myloop
            if(i == 0) begin
                AdderFourBitAdder fadd(.a(a[3:0]), .b(b[3:0]), .cin(1'b0), .cout(carrys[0]), .sum(res[3:0]));
            end
            else begin
                AdderFourBitAdder fadd(.a(a[4*i + 3:4*i]), .b(b[4*i + 3:4*i]), .cin(carrys[i-1]), .cout(carrys[i]), .sum(res[4*i + 3:4*i]));
            end
        end
    endgenerate
endmodule