`timescale 1ns/1ps
`include "ALUControl.v"

module ALUControl_tb;
    reg [1:0] ALUOp;
    reg [3:0] instr;
    wire [3:0] out;
    integer pass_count = 0, total_tests = 6;
    integer file_handle;

    ALUControl uut(.ALUOp(ALUOp), .instr(instr), .out(out));

    task run_test;
        input [4:0] test_number;
        input [1:0] test_ALUOp;
        input [3:0] test_instr, expected;
        begin
            ALUOp = test_ALUOp;
            instr = test_instr;
            #10;
            $display("Test %0d: ALUOp=%b instr=%b -> out=%b", test_number, test_ALUOp, test_instr, out);
            if (out === expected) begin
                pass_count = pass_count + 1;
                $fdisplay(file_handle, "Test %0d, Status: PASS", test_number);
            end else begin
                $fdisplay(file_handle, "Test %0d, Status: FAIL (expected %b got %b)", test_number, expected, out);
                $display("Expected: out=%b", expected);
                $display("Got:      out=%b\n", out);
            end
        end
    endtask

    initial begin
        file_handle = $fopen("ALUControl_results.txt", "w");
        if (file_handle == 0) begin
            $display("Error: Could not open file.");
            $finish;
        end
        $dumpfile("ALUControl_tb.vcd");
        $dumpvars(0, ALUControl_tb);
        pass_count = 0;
        // ALUOp=00 -> ADD (ld, sd, addi)->immediates I, S, SB-types
        run_test(1, 2'b00, 4'b0000, 4'b0010);
        // ALUOp=01 -> SUB (beq)
        run_test(2, 2'b01, 4'b0000, 4'b0110);
        // ALUOp=10, funct={0,000} -> ADD (add)
        run_test(3, 2'b10, 4'b0000, 4'b0010);
        // ALUOp=10, funct={1,000} -> SUB (sub)
        run_test(4, 2'b10, 4'b1000, 4'b0110);
        // ALUOp=10, funct={0,111} -> AND
        run_test(5, 2'b10, 4'b0111, 4'b0000);
        // ALUOp=10, funct={0,110} -> OR
        run_test(6, 2'b10, 4'b0110, 4'b0001);

        $display("Passed %0d/%0d tests", pass_count, total_tests);
        $fdisplay(file_handle, "Passed %0d/%0d tests", pass_count, total_tests);
        $fclose(file_handle);
        #10; $finish;
    end
endmodule

