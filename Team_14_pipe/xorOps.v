module xorOps(
    input [63:0]a, b,
    output [63:0]res,
    output cout, carry_flag, overflow_flag, zero_flag
);
    generate
        genvar i;
        for(i=0;i<=63;i=i+1) begin: myloop
            xor aTemp (res[i], a[i], b[i]);
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