`timescale 1ns/1ps
`include "ImmGen.v"

module ImmGen_tb;
    reg [31:0] Instruction;
    wire [63:0] immediate;
    integer pass_count = 0, total_tests = 4;
    integer file_handle;

    ImmGen uut(.Instruction(Instruction), .immediate(immediate));

    task run_test;
        input [4:0] test_number;
        input [31:0] instr;
        input [63:0] exp_immediate;
        begin
            Instruction = instr; #10;
            $display("Test %0d: instr=%h -> imm=%016h", test_number, instr, immediate);
            if (immediate === exp_immediate) begin
                pass_count = pass_count + 1;
                $fdisplay(file_handle, "Test %0d, Status: PASS", test_number);
            end else begin
                $fdisplay(file_handle, "Test %0d, Status: FAIL (expected %016h got %016h)",
                          test_number, exp_immediate, immediate);
                $display("Expected: immediate=%016h", exp_immediate);
                $display("Got:      immediate=%016h\n", immediate);
            end
        end
    endtask

    initial begin
        file_handle = $fopen("ImmGen_results.txt", "w");
        if (file_handle == 0) begin
            $display("Error: Could not open file.");
            $finish;
        end
        $dumpfile("ImmGen_tb.vcd");
        $dumpvars(0, ImmGen_tb);
        pass_count = 0;
        // addi x1, x0, 5 -> imm = 5
        run_test(1, 32'h00500093, 64'h0000000000000005);
        // addi x1, x0, -1 -> imm = -1 (sign extended)
        run_test(2, 32'hFFF00093, 64'hFFFFFFFFFFFFFFFF);
        // sd x1, 8(x2) -> imm = 8
        run_test(3, 32'h00113423, 64'h0000000000000008);
        // beq x1, x2, 8 -> imm = 8 
        // (ImmGen gives half-offset, ShiftLeft1 doubles it)
        run_test(4, 32'h00208463, 64'h0000000000000004);

        $display("Passed %0d/%0d tests", pass_count, total_tests);
        $fdisplay(file_handle, "Passed %0d/%0d tests", pass_count, total_tests);
        $fclose(file_handle);
        #10; $finish;
    end
endmodule

