`timescale 1ns/1ps
`include "Control.v"

module Control_tb;
    reg [6:0] instr;
    wire Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
    wire [1:0] ALUOp;
    integer pass_count = 0, total_tests = 5;
    integer file_handle;

    Control uut(.instr(instr), .Branch(Branch), .MemRead(MemRead),
                .MemtoReg(MemtoReg), .MemWrite(MemWrite), .ALUSrc(ALUSrc),
                .RegWrite(RegWrite), .ALUOp(ALUOp));

    // expected: {Branch,MemRead,MemtoReg,ALUOp,MemWrite,ALUSrc,RegWrite}
    task run_test;
        input [4:0] test_number;
        input [6:0] opcode;
        input exp_Branch, exp_MemRead, exp_MemtoReg;
        input [1:0] exp_ALUOp;
        input exp_MemWrite, exp_ALUSrc, exp_RegWrite;
        begin
            instr = opcode; #10;
            $display("Test %0d opcode=%07b: RW=%b ALUSrc=%b ALUOp=%02b Branch=%b MemR=%b MemtoReg=%b MemW=%b",
                     test_number, opcode, RegWrite, ALUSrc, ALUOp, Branch, MemRead, MemtoReg,MemWrite);
            if (Branch===exp_Branch && MemRead===exp_MemRead && MemtoReg===exp_MemtoReg &&
                ALUOp===exp_ALUOp && MemWrite===exp_MemWrite && ALUSrc===exp_ALUSrc &&
                RegWrite===exp_RegWrite) begin
                pass_count = pass_count + 1;
                $fdisplay(file_handle, "Test %0d, Status: PASS", test_number);
            end else begin
                $fdisplay(file_handle, "Test %0d, Status: FAIL", test_number);
                $display("Expected: Branch=%016h, MemRead=%b, MemtoReg=%b, MemWrite=%b, ALUSrc=%b, RegWrite=%b, ALUOp=%02b", 
                        exp_Branch, exp_MemRead,  exp_MemtoReg, exp_MemWrite, exp_ALUSrc, exp_RegWrite, exp_ALUOp);
                $display("Got:      Branch=%016h, MemRead=%b, MemtoReg=%b, MemWrite=%b, ALUSrc=%b, RegWrite=%b, ALUOp=%02b\n", 
                        Branch, MemRead,  MemtoReg, MemWrite, ALUSrc, RegWrite, ALUOp);
            end
        end
    endtask
    

    initial begin
        file_handle = $fopen("control_results.txt", "w");
        if (file_handle == 0) begin $display("Error: Could not open file."); $finish; end
        $dumpfile("Control_tb.vcd");
        $dumpvars(0, Control_tb);
        pass_count = 0;
        //        opcode       Br MR MtoR  AOp  MW  AS  RW
        run_test(1, 7'b0110011, 0, 0, 0, 2'b10, 0, 0, 1); // R-type
        run_test(2, 7'b0010011, 0, 0, 0, 2'b00, 0, 1, 1); // addi
        run_test(3, 7'b0000011, 0, 1, 1, 2'b00, 0, 1, 1); // ld
        run_test(4, 7'b0100011, 0, 0, 0, 2'b00, 1, 1, 0); // sd
        run_test(5, 7'b1100011, 1, 0, 0, 2'b01, 0, 0, 0); // beq

        $display("Passed %0d/%0d tests", pass_count, total_tests);
        $fdisplay(file_handle, "Passed %0d/%0d tests", pass_count, total_tests);
        $fclose(file_handle);
        #10; $finish;
    end
endmodule
