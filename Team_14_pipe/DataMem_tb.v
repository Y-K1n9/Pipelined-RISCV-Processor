`timescale 1ns/1ps
`include "DataMem.v"

module DataMem_tb;
    reg clk, reset, MemRead, MemWrite;
    reg [9:0] address;
    reg [63:0] write_data;
    wire [63:0] read_data;
    integer pass_count = 0, total_tests = 4;
    integer file_handle;

    DataMem uut(.clk(clk), .reset(reset), .MemRead(MemRead), .MemWrite(MemWrite),
                .address(address), .write_data(write_data), .read_data(read_data));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task run_test;
        input [4:0] test_number;
        input [9:0] addr;
        input [63:0] wdata, exp_read_data;
        begin
            // Write
            MemWrite = 1; MemRead = 0;
            address = addr; write_data = wdata;
            // following line of code tells simulation to
            // stop till the next clock positive edge is seen,
            // so that the inputs asserted to the data memory can
            // be first written in the writing cycle
            // and then the read logic is started after waiting 
            // for #1 delay after the clk posedge.. so that after 
            // writing we can let the data be written in memory
            // in stable manner....
            @(posedge clk); #1;
            // Read
            // if we exclude #1 after @(posedge clk),
            // we can still get same functionality by writing:
            // @(posedge clk);
            // MemWrite <= 0; MemRead <= 1;
            // address <= addr;
            // This non blocking assignment happens only
            // after the delay element has waited and
            // safely stabilized.
            MemWrite = 0; MemRead = 1;
            address = addr; #1;
            $display("Test %0d: wrote %016h to addr=%0d, read back=%016h",
                     test_number, wdata, addr, read_data);
            if (read_data === exp_read_data) begin
                pass_count = pass_count + 1;
                $fdisplay(file_handle, "Test %0d, Status: PASS", test_number);
            end else begin
                $fdisplay(file_handle, "Test %0d, Status: FAIL (exp_read_data %016h got %016h)",
                          test_number, exp_read_data, read_data);
                $display("Expected: read_data=%016h", exp_read_data);
                $display("Got:      read_data=%016h\n", read_data);
            end
        end
    endtask

    initial begin
        file_handle = $fopen("DataMem_results.txt", "w");
        if (file_handle == 0) begin
            $display("Error: Could not open file.");
            $finish;
        end
        $dumpfile("DataMem_tb.vcd");
        $dumpvars(0, DataMem_tb);
        pass_count=0;

        reset = 1; MemRead = 0; MemWrite = 0;
        @(posedge clk); #1; reset = 0;

        run_test(1, 10'd10, 64'h000000000000000F, 64'h000000000000000F); // store/load 15
        run_test(2, 10'd20, 64'hA5A5A5A55A5A5A5A, 64'hA5A5A5A55A5A5A5A); // Alternating bit pattern
        run_test(3, 10'd100, 64'hFFFFFFFFFFFFFFFF, 64'hFFFFFFFFFFFFFFFF); // all ones
        run_test(4, 10'd0, 64'd0, 64'd0); // zero value

        $display("Passed %0d/%0d tests", pass_count, total_tests);
        $fdisplay(file_handle, "Passed %0d/%0d tests", pass_count, total_tests);
        $fclose(file_handle);
        #10; $finish;
    end
endmodule

