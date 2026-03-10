`timescale 1ns/1ps
`include "RegisterFile.v"

module RegisterFile_tb;
// since we need to vary inputs and not vary
// outputs directly, testbench acts like a multimeter
// where we can measure the outputs of ckt like
// thus wire for outputs, reg for inputs....
    reg clk, reset, reg_write_en;
    reg [4:0] read_reg1, read_reg2, write_reg;
    reg [63:0] write_data;
    wire [63:0] read_data1, read_data2;
    integer pass_count = 0, total_tests = 6;
    integer file_handle;

    RegisterFile uut(.clk(clk), .reset(reset), .reg_write_en(reg_write_en),
                     .read_reg1(read_reg1), .read_reg2(read_reg2),
                     .write_reg(write_reg), .write_data(write_data),
                     .read_data1(read_data1), .read_data2(read_data2));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task run_test;
        input [4:0] test_number;
        input [4:0] wreg, rreg1, rreg2;
        input [63:0] wdata, exp_read_data1, exp_read_data2;
        input write_en;
        begin
            reg_write_en = write_en; write_reg = wreg;
            write_data = wdata; read_reg1 = rreg1; read_reg2 = rreg2;
            @(posedge clk); #1;
            $display("Test %0d: write x%0d=%016h write_en=%b -> read_data1=%016h, read_data2=%016h",
                     test_number, wreg, wdata, write_en, read_data1, read_data2);
            if (read_data1 === exp_read_data1 && read_data2 === exp_read_data2) begin
                pass_count = pass_count + 1;
                $fdisplay(file_handle, "Test %0d, Status: PASS", test_number);
            end else begin
                $fdisplay(file_handle, "Test %0d, Status: FAIL", test_number);
                $display("Expected: read_data1=%016h, read_data2=%016h", exp_read_data1, exp_read_data2);
                $display("Got:      read_data1=%016h, read_data2=%016h\n", read_data1, read_data2);
            end
        end
    endtask

    initial begin
        file_handle = $fopen("RegisterFile_results.txt", "w");
        if (file_handle == 0) begin $display("Error: Could not open file."); $finish; 
        end
        
        $dumpfile("RegisterFile_tb.vcd");
        $dumpvars(0, RegisterFile_tb);
        pass_count=0;

        reset = 1; reg_write_en = 0;
        @(posedge clk); #1; reset = 0;

        // Verify x0 is strictly hardwired to 0 even if we try to write to it
        run_test(1, 5'd0, 5'd0, 5'd0, 64'hFFFFFFFFFFFFFFFF, 64'd0, 64'd0, 1);

        // (Read-After-Write) - Write to x1, read x1 and x0 simultaneously
        run_test(2, 5'd1, 5'd1, 5'd0, 64'h5555AAAA5555AAAA, 64'h5555AAAA5555AAAA, 64'd0, 1);

        // Write Disable - Attempt to overwrite x1 
        // with new data while writeen is low
        // it should still return the value from prev. testcase
        run_test(3, 5'd1, 5'd1, 5'd1, 64'h1111222233334444, 64'h5555AAAA5555AAAA, 64'h5555AAAA5555AAAA, 0);

        // Boundary Registers - test the highest address (x31) and bit-flipping pattern
        run_test(4, 5'd31, 5'd31, 5'd1, 64'hA5A55A5AA5A55A5A, 64'hA5A55A5AA5A55A5A, 64'h5555AAAA5555AAAA, 1);

        // Dual Port Test - Read two different previously written registers (x31 and x1) 
        // while writing to a third (x2). Verifies no cross-talk between ports.
        run_test(5, 5'd2, 5'd31, 5'd1, 64'h1234567890ABCDEF, 64'hA5A55A5AA5A55A5A, 64'h5555AAAA5555AAAA, 1);

        // Sign Extension/Large Value - Ensure no truncation on 64-bit boundaries
        run_test(6, 5'd5, 5'd5, 5'd2, 64'h8000000000000000, 64'h8000000000000000, 64'h1234567890ABCDEF, 1);

        $display("Passed %0d/%0d tests", pass_count, total_tests);
        $fdisplay(file_handle, "Passed %0d/%0d tests", pass_count, total_tests);
        $fclose(file_handle);
        #10; $finish;
    end
endmodule

