`timescale 1ns/1ps
`include "processor.v"

module seq_tb;

    reg clk;
    reg reset;
    integer i, outputFile;

    // Instantiate UUT
    processor uut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer clockCycles = 1;
    integer running = 0;
    initial begin
        reset = 1;
        @(posedge clk); #1;// we wait for 1st posedge of clk and then disassert reset...
        reset = 0;
        wait(uut.Instruction == 32'h00000000);

        $display("\n==== REGISTER FILE CONTENTS ====");
        for (i = 0; i < 32; i = i + 1) begin
            $display("x%0d = %016h", i, uut.RF1.outp[i]);
        end
        outputFile = $fopen("register_file.txt", "w");
        
        if(outputFile) begin
            for (i = 0; i < 32; i = i + 1) begin
                $fwrite(outputFile, "%016h\n", uut.RF1.outp[i]);
            end
            $fwrite(outputFile,"%0d", clockCycles);
            $fclose(outputFile);
        end else begin
            $display("Couldn't open file");
        end
        $display("%0d",clockCycles);
        $finish;
    end
    always@(posedge clk or posedge reset) begin
        if(reset) begin
            clockCycles <= 1;
            running <= 0;
        end
        else begin
            running <= 1;
            clockCycles <= clockCycles+1;
        end
    end
endmodule