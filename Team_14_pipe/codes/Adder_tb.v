`timescale 1ns/1ps
`include "Adder.v"

module Adder_tb;
    reg [63:0] a, b;
    wire [63:0] res;
    integer pass_count = 0, total_tests = 4;
    integer file_handle;

    Adder uut(.a(a), .b(b), .res(res));

    task run_test;
        input [4:0] test_number;
        input [63:0] test_a, test_b, expected;
        begin
            a = test_a; 
            b = test_b; 
            #10;
            $display("Test %0d: %016h + %016h = %016h", test_number, test_a, test_b, res);
            if (res === expected) begin
                pass_count = pass_count + 1;
                $fdisplay(file_handle, "Test %0d, Status: PASS", test_number);
            end else begin
                $fdisplay(file_handle, "Test %0d, Status: FAIL (expected %016h got %016h)",
                        test_number, expected, res);
                $display("Expected: res=%016h", expected);
                $display("Got:      res=%016h\n", res);
            end
        end
    endtask


    initial begin
        file_handle = $fopen("Adder_results.txt", "w");
        if (file_handle == 0) begin 
            $display("Error: Could not open file.");
            $finish;
        end
        $dumpfile("Adder_tb.vcd");
        $dumpvars(0, Adder_tb);

        run_test(1, 64'd0, 64'd4, 64'd4);    // PC reset + 4
        run_test(2, 64'd100, 64'd4, 64'd104);  // normal PC+4
        run_test(3, 64'd20, 64'hFFFFFFFFFFFFFFF8, 64'd12);   // PC + negative branch (-8)
        run_test(4, 64'hFFFFFFFFFFFFFFFF, 64'd1, 64'd0);    // overflow wraps to 0

        $display("Passed %0d/%0d tests", pass_count, total_tests);
        $fdisplay(file_handle, "Passed %0d/%0d tests", pass_count, total_tests);
        $fclose(file_handle);
        #10; $finish;
    end
endmodule
