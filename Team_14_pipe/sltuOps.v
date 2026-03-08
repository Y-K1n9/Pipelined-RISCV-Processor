module sltuComparator(
    input [3:0] a, b,
    input l, eq, g,
    output alb, aeqb, agb
);
    wire [3:0]eqbits;
    wire [3:0]greater;
    wire [3:0]lesser;
    wire [3:0]temp;
    wire [3:0]bbar;
    wire [3:0]abar;
    generate
        genvar i;
        for(i = 0;i<4;i=i+1)begin: myloop
            xor x_tt(temp[i], a[i], b[i]);
            not n_tt(eqbits[i], temp[i]);
            not n_tt1(bbar[i], b[i]);
            not n_tt2(abar[i], a[i]);
            and a_tt(greater[i], a[i], bbar[i]);
            and a_tt1(lesser[i], abar[i], b[i]);
        end
    endgenerate
    // a==b:
    and a0(aeqb, eqbits[0], eqbits[1], eqbits[2], eqbits[3], eq);
    // a>b = a3.b3' + (a3^b3)'.a2.b2' + (a3^b3)'.(a2^b2)'.a1.b1' + (a3^b3)'.(a2^b2)'.(a1^b1)'.a0.b0' + (a3^b3)'.(a2^b2)'.(a1^b1)'.(a0^b0)'.g
    wire t2, t3, t4, t5;
    and a2(t2, eqbits[3], greater[2]);
    and a3(t3, eqbits[3], eqbits[2], greater[1]);
    and a4(t4, eqbits[3], eqbits[2], eqbits[1], greater[0]);
    and a5(t5, eqbits[3], eqbits[2], eqbits[1], eqbits[0], g);
    or o1(agb, greater[3], t2, t3, t4, t5);
    // a<b = a3'.b3 + (a3^b3)'.a2'.b2 + (a3^b3)'.(a2^b2)'.a1'.b1 + (a3^b3)'.(a2^b2)'.(a1^b1)'.a0'.b0 + (a3^b3)'.(a2^b2)'.(a1^b1)'.(a0^b0)'.l
    wire tt2, tt3, tt4, tt5;
    and aa2(tt2, eqbits[3], lesser[2]);
    and aa3(tt3, eqbits[3], eqbits[2], lesser[1]);
    and aa4(tt4, eqbits[3], eqbits[2], eqbits[1], lesser[0]);
    and aa5(tt5, eqbits[3], eqbits[2], eqbits[1], eqbits[0], l);
    or oo1(alb, lesser[3], tt2, tt3, tt4, tt5);
endmodule

module sltuOps(
    input [63:0]a, b,
    output [63:0]res,
    output cout, carry_flag, overflow_flag, zero_flag
);
    wire [2:0]temps[15:0];
    generate
        genvar i;
        for(i=0;i<16;i=i+1)begin:myloop
            if(i==0)begin:ifstat
                sltuComparator cc(.a(a[i*4+3:i*4]), .b(b[i*4+3:i*4]), .l(1'b0), .eq(1'b1), .g(1'b0), .alb(temps[i][0]), .aeqb(temps[i][1]), .agb(temps[i][2]));
            end
            else begin:elsestatement
                sltuComparator cc(.a(a[i*4+3:i*4]), .b(b[i*4+3:i*4]), .l(temps[i-1][0]), .eq(temps[i-1][1]), .g(temps[i-1][2]), .alb(temps[i][0]), .aeqb(temps[i][1]), .agb(temps[i][2]));
            end
        end
    endgenerate
    assign res = {63'b0,temps[15][0]};
    assign cout = 1'b0;
    assign carry_flag = 1'b0;
    assign overflow_flag = 1'b0;
    wire [31:0]tempwire;
    wire [15:0]tempwire1;
    wire [7:0]tempwire2;
    wire [3:0]tempwire3;
    wire [1:0]tempwire4;

    generate
        genvar j;
        for(j =0 ; j<=62;j=j+2)begin:mainloop
            or nor_flag(tempwire[j/2], res[j], res[j+1]);
        end
        for(j =0 ; j<=30;j=j+2)begin:mainloop1
            or nor_flag1(tempwire1[j/2], tempwire[j], tempwire[j+1]);
        end
        for(j =0 ; j<=14;j=j+2)begin:mainloop2
            or nor_flag2(tempwire2[j/2], tempwire1[j], tempwire1[j+1]);
        end
        for(j =0 ; j<=6;j=j+2)begin:mainloop3
            or nor_flag3(tempwire3[j/2], tempwire2[j], tempwire2[j+1]);
        end
        for(j =0 ; j<=2;j=j+2)begin:mainloop4
            or nor_flag4(tempwire4[j/2], tempwire3[j], tempwire3[j+1]);
        end
    endgenerate
    nor nor1(zero_flag, tempwire4[0], tempwire4[1]);
endmodule