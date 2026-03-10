module sraMuxx(
    input i0, i1, 
    input sel,
    output out
);
    assign out = sel? i1: i0;
endmodule

module sraOps(
    input [63:0]a, sig,
    output [63:0]res,
    output cout, carry_flag, overflow_flag, zero_flag
);
    wire [63:0]outCol1;
    wire [63:0]outCol2;
    wire [63:0]outCol3;
    wire [63:0]outCol4;
    wire [63:0]outCol5;
    generate
        genvar i;
        for(i = 0;i<64;i = i+1)begin
            if(i>=63)begin:ifcondition1
                sraMuxx mt(a[i], a[63], sig[0], outCol1[i]);
            end
            else begin:elsestatement1
                sraMuxx mt(a[i], a[i+1], sig[0], outCol1[i]);
            end
            if(i>=62)begin:ifcondition2
                sraMuxx mt1(outCol1[i], a[63], sig[1], outCol2[i]);
            end
            else begin:elsestatement2
                sraMuxx mt1(outCol1[i], outCol1[i+2], sig[1], outCol2[i]);
            end
            if(i>=60)begin:ifcondition3
                sraMuxx mt2(outCol2[i], a[63], sig[2], outCol3[i]);
            end
            else begin:elsestatement3
                sraMuxx mt2(outCol2[i], outCol2[i+4], sig[2], outCol3[i]);
            end
            if(i>=56)begin:ifcondition4
                sraMuxx mt3(outCol3[i], a[63], sig[3], outCol4[i]);
            end
            else begin:elsestatement4
                sraMuxx mt3(outCol3[i], outCol3[i+8], sig[3], outCol4[i]);
            end
            if(i>=48)begin:ifcondition5
                sraMuxx mt4(outCol4[i], a[63], sig[4], outCol5[i]);
            end
            else begin:elsestatement5
                sraMuxx mt4(outCol4[i], outCol4[i+16], sig[4], outCol5[i]);
            end
            if(i>=32)begin:ifcondition6
                sraMuxx mt5(outCol5[i], a[63], sig[5], res[i]);
            end
            else begin:elsestatement6
                sraMuxx mt5(outCol5[i], outCol5[i+32], sig[5], res[i]);
            end
        end
    endgenerate
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