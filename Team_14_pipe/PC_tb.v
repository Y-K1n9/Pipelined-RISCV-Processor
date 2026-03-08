`timescale 1ns/1ps
`include "PC.v"

module PC_tb;
    reg clk, reset;
    reg [63:0] pc_in;
    wire [63:0] pc_out;
    integer pass_count = 0, total_tests = 4;
    integer file_handle;

    PC uut(.clk(clk), .reset(reset), .pc_in(pc_in), .pc_out(pc_out));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task run_test;
        input [4:0] test_number;
        input [63:0] test_pc_in, exp_pc_out;
        input test_reset;
        begin
            reset = test_reset; pc_in = test_pc_in;
            // we assert the values of inputs to this PC register
            // and wait till the net posedge of clk aand after a small delay
            // #1, we observe the outputs of the uut, if they match the
            // expected values, then TC->pass else fail
            @(posedge clk); #1;
            $display("Test %0d: reset=%b pc_in=%016h -> pc_out=%016h",
                     test_number, test_reset, test_pc_in, pc_out);
            if (pc_out === exp_pc_out) begin
                pass_count = pass_count + 1;
                $fdisplay(file_handle, "Test %0d, Status: PASS", test_number);
            end else begin
                $fdisplay(file_handle, "Test %0d, Status: FAIL (expected %016h got %016h)",
                          test_number, exp_pc_out, pc_out);
                $display("Expected: pc_out=%016h", exp_pc_out);
                $display("Got:      pc_out=%016h\n", pc_out);
            end
        end
    endtask

    initial begin
        file_handle = $fopen("PC_results.txt", "w");
        if (file_handle == 0) begin
            $display("Error: Could not open file.");
            $finish;
        end
        
        $dumpfile("PC_tb.vcd");
        $dumpvars(0, PC_tb);
        pass_count = 0;

        run_test(1, 64'd0, 64'd0, 1); // reset asserted and then other tc's run
        run_test(2, 64'd4, 64'd4, 0); // normal advance
        run_test(3, 64'd8, 64'd8, 0); // normal advance
        run_test(4, 64'd100, 64'd0, 1); // reset overrides pc_in

        $display("Passed %0d/%0d tests", pass_count, total_tests);
        $fdisplay(file_handle, "Passed %0d/%0d tests", pass_count, total_tests);
        $fclose(file_handle);
        #10; $finish;
    end
endmodule