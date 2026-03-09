`include "Adder.v"
`include "alu.v"
`include "ALUControl.v"
`include "Control.v"
`include "DataMem.v"
`include "ImmGen.v"
`include "instruction_mem.v"
`include "mux.v"
`include "mux4x2.v"
`include "PC.v"
`include "RegisterFile.v"
`include "Shiftleft1.v"
`include "equalityComparator.v"
`include "ForwardingUnit.v"
`include "HazardDetectionUnit.v"
`include "BranchForwardingUnit.v"
module processor(
    input clk, reset
);

// control signals
wire Branch, MemRead;
wire MemtoReg, MemWrite;
wire RegWrite, ALUSrc;
wire [1:0] ALUOp;
//********
// Comparator output (previously ALU zero flag)
wire rs1EqualRs2;
//********

wire [3:0]ALUControlSig;

// IF/ID registers...
reg [31:0] IFIDIR;
reg [63:0] IFIDPC;

wire [31:0] Instruction;
assign Instruction = IFIDIR;

wire [63:0] rs2, rs1;

wire[63:0] write_back;

wire [63:0]read_data;
wire [63:0]shiftLeftOut;

// MEM/WB regis...
reg [63:0] MEMWBReadData;
// for R type.
reg [63:0] MEMWBALUResult;
// destin reg for R type, addi(I-typ), ld
reg [4:0] MEMWBrd;
// wb
reg MEMWBRegWrite;
reg MEMWBMemtoReg;

RegisterFile RF1(
    .clk(clk), .reset(reset), .reg_write_en(MEMWBRegWrite),
    .read_reg1(Instruction[19:15]),
    .read_reg2(Instruction[24:20]),
    .write_reg(MEMWBrd),
    .write_data(write_back),
    .read_data1(rs1), .read_data2(rs2)
);

wire[63:0] immRegOut;
wire[63:0] ALUresult;


// ID/EX regist...
// control sig
// ex
reg [1:0] IDEXALUOp;
reg IDEXALUSrc;
// mem
reg IDEXMemRead;
reg IDEXMemWrite;
// wb
reg IDEXMemtoReg;
reg IDEXRegWrite;
// readreg1
reg [63:0] IDEXrs1;
// readreg2
reg [63:0] IDEXrs2;
// Immediate
reg [63:0] IDEXImm;
// Instruction
reg [31:0] IDEXIR;
// in data forwarding logic, we pass rs1 and rs2 address
reg [4:0] IDEXrs1Addr;
reg [4:0] IDEXrs2Addr;
///////////////////////////////////





// EX/MEM regis...
reg [63:0] EXMEMALUResult;
// rs2 value read from register mem,
// it stores value to be written into 
// the memory in case of load
reg [63:0] EXMEMrs2;
reg [4:0] EXMEMrs2Addr;
// rd passed till MEM/WB register
reg [4:0] EXMEMrd;
// mem
reg EXMEMMemRead;
reg EXMEMMemWrite;
// wb
reg EXMEMRegWrite;
reg EXMEMMemtoReg;


wire [1:0] ForwardA, ForwardB;
wire Forward_sd;

ForwardingUnit FU1(
    .EXMEMRegWrite(EXMEMRegWrite), .MEMWBRegWrite(MEMWBRegWrite),
    .EXMEMrd(EXMEMrd), .EXMEMrs2Addr(EXMEMrs2Addr), .MEMWBrd(MEMWBrd),
    .IDEXrs1Addr(IDEXrs1Addr), .IDEXrs2Addr(IDEXrs2Addr),
    .ForwardA(ForwardA), .ForwardB(ForwardB),
    .Forward_sd(Forward_sd)
);

wire [63:0] sdMUXOp;

mux sdMUX(
    // write_back value will be passed
    .a(EXMEMrs2), .b(write_back), .sel(Forward_sd),
    .out(sdMUXOp)
);

wire[63:0] ALUm1Op, ALUm2Op;

mux4x2 ALUm1(
    // we pass write_back to be even more sure and not just MEMWBALUResult
    .a(IDEXrs1), .b(write_back), .c(EXMEMALUResult),
    .sel(ForwardA), .out(ALUm1Op)
);

mux4x2 ALUm2(
    // we pass write_back to be even more sure and not just MEMWBALUResult
    .a(IDEXrs2), .b(write_back), .c(EXMEMALUResult),
    .sel(ForwardB), .out(ALUm2Op)
);

alu_64_bit alu1(
    .a(ALUm1Op), .b(immRegOut),
    .opcode(ALUControlSig), .result(ALUresult), 
    .cout(), .carry_flag(), // useless
    .overflow_flag(), // useless
    .zero_flag() // no use of ALU zero flag now
);

DataMem DM1(
    .clk(clk), .reset(reset),
    .MemRead(EXMEMMemRead), .MemWrite(EXMEMMemWrite),
    .address(EXMEMALUResult[9:0]), .write_data(sdMUXOp),
    .read_data(read_data)
);

wire[63:0] immediate;

ImmGen IG1(
    .Instruction(Instruction),
    .immediate(immediate)
);

wire [31:0] IMEMOut;

instruction_mem im1(
    .clk(clk), .reset(reset), 
    .addr(pc_out),
    .instr(IMEMOut)
);


wire [3:0]ALUControlIp = {IDEXIR[30],IDEXIR[14:12]};

ALUControl ALUC1(
    .ALUOp(IDEXALUOp),
    .instr(ALUControlIp),
    .out(ALUControlSig)
);

wire [63:0] pc_in;
wire [63:0] pc_out;
wire PCWrite, Bubble, IFIDEnable;

HazardDetectionUnit HDU1(
    .IDEXMemRead(IDEXMemRead),
    .IDEXRegWrite(IDEXRegWrite),
    .EXMEMMemRead(EXMEMMemRead),
    .EXMEMrd(EXMEMrd),
    .Instruction(Instruction), .IDEXIR(IDEXIR),
    .PCWrite(PCWrite), .IFIDEnable(IFIDEnable), .Bubble(Bubble)
);

PC PC1(
    .clk(clk), .reset(reset), .enable(PCWrite), // enable added for pipelined implementation
    .pc_in(pc_in),
    .pc_out(pc_out)
);

Control Control1(
    .instr(Instruction[6:0]),// opcode
    .Branch(Branch), .MemRead(MemRead), .MemtoReg(MemtoReg),
    .MemWrite(MemWrite), .ALUSrc(ALUSrc), .RegWrite(RegWrite),
    .ALUOp(ALUOp)
);

ShiftLeft1 SL1(
    .a(immediate),
    .res(shiftLeftOut)
);

wire[63:0] pcPlus4;
wire[63:0] pcPlusImm;

Adder PC4Adder(
    .a(pc_out),.b(64'h0000000000000004),
    .res(pcPlus4)
);

Adder PCImmAdder(
    .a(shiftLeftOut),.b(IFIDPC),
    .res(pcPlusImm)
);

wire PCImmMuxInput;
and BranchAND(PCImmMuxInput, Branch, rs1EqualRs2);

mux PCSource(
    .a(pcPlus4), .b(pcPlusImm), .sel(PCImmMuxInput),
    .out(pc_in)
);

//IDEXrs2 defined above thiss...
// but we use ALUm2Op due to data forwarding
mux ALUSource(
    .a(ALUm2Op), .b(IDEXImm), .sel(IDEXALUSrc),
    .out(immRegOut)
);

mux RegWriteBack(
    .a(MEMWBALUResult), .b(MEMWBReadData), .sel(MEMWBMemtoReg),
    .out(write_back)
);

wire [1:0] ForwardCompA, ForwardCompB;
wire [63:0] compA, compB;

BranchForwardingUnit BFU1(
    .EXMEMRegWrite(EXMEMRegWrite), .MEMWBRegWrite(MEMWBRegWrite),
    .EXMEMrd(EXMEMrd), .MEMWBrd(MEMWBrd),
    .IFIDrs1(Instruction[19:15]), .IFIDrs2(Instruction[24:20]),
    .ForwardCompA(ForwardCompA), .ForwardCompB(ForwardCompB)
);

mux4x2 compMuxA(
    .a(rs1), .b(write_back), .c(EXMEMALUResult),
    .sel(ForwardCompA), .out(compA)
);

mux4x2 compMuxB(
    .a(rs2), .b(write_back), .c(EXMEMALUResult),
    .sel(ForwardCompB), .out(compB)
);

equalityComparator comp1(
    .a(compA), .b(compB), .equal(rs1EqualRs2)
);


wire IFFlush;
// PC
assign IFFlush = Branch&rs1EqualRs2;
// a mux for Bubble BM BubbleMux, it's outputs are:
reg BMIDEXMemRead;
reg BMIDEXMemWrite;
reg [1:0] BMIDEXALUOp;
reg BMIDEXALUSrc;
reg BMIDEXMemtoReg;
reg BMIDEXRegWrite;
always@(*)begin
    if(Bubble) begin // or:    if(Bubble||IFFlush) begin::: If I do if(Bubble||IFFlush) begin, then 
        BMIDEXMemRead = 1'b0;  //   the branch instruction itself will become useless
        BMIDEXMemWrite = 1'b0;
        BMIDEXALUOp = 2'b00;
        BMIDEXALUSrc = 1'b0;
        BMIDEXMemtoReg = 1'b0;
        BMIDEXRegWrite = 1'b0;
    end
    else begin
        BMIDEXMemRead = MemRead;
        BMIDEXMemWrite = MemWrite;
        BMIDEXALUOp = ALUOp;
        BMIDEXALUSrc = ALUSrc;
        BMIDEXMemtoReg = MemtoReg;
        BMIDEXRegWrite = RegWrite;
    end

end

reg [4:0] IDEXrd;
 // Always update (outside Bubble logic)
  // Always use the actual rd value

always@(posedge clk) begin
    if(!reset) begin
        // IF/ID
        if(IFIDEnable) begin
            if(IFFlush) begin
                IFIDPC<=pc_out;
                IFIDIR<=32'h00000013;
            end
            else begin
                IFIDPC<=pc_out;
                IFIDIR<=IMEMOut;
            end
        end
        else begin
            IFIDPC<=IFIDPC;
            IFIDIR<=IFIDIR;
        end

        // ID/EX
        IDEXMemRead<=BMIDEXMemRead;
        IDEXMemWrite<=BMIDEXMemWrite;
        IDEXALUOp<=BMIDEXALUOp;
        IDEXALUSrc<=BMIDEXALUSrc;
        IDEXMemtoReg<=BMIDEXMemtoReg;
        IDEXRegWrite<=BMIDEXRegWrite;
        IDEXrs1<=rs1;
        IDEXrs2<=rs2;
        IDEXImm<=immediate;
        IDEXIR<=Instruction;
        IDEXrd <= Instruction[11:7]; 
        IDEXrs1Addr<=Instruction[19:15];
        IDEXrs2Addr<=Instruction[24:20];
        // EX/MEM
        EXMEMMemRead<=IDEXMemRead;
        EXMEMMemWrite<=IDEXMemWrite;
        EXMEMALUResult<=ALUresult;
        EXMEMMemtoReg<=IDEXMemtoReg;
        EXMEMRegWrite<=IDEXRegWrite;
        EXMEMrs2<=IDEXrs2;
        EXMEMrs2Addr<=IDEXrs2Addr;
        // EXMEMrd<=IDEXIR[11:7];
        EXMEMrd <= IDEXrd;
        // MEM/WB
        MEMWBReadData<=read_data;
        MEMWBALUResult<=EXMEMALUResult;
        MEMWBrd<=EXMEMrd;
        MEMWBMemtoReg<=EXMEMMemtoReg;
        MEMWBRegWrite<=EXMEMRegWrite;
    end
    else begin
       // initialize instr fields to noop.
        IFIDIR<=32'h00000013;
        IDEXIR<=32'h00000013;
        IDEXRegWrite<=0;
        IDEXMemRead<=0;
        IDEXMemWrite<=0;
        EXMEMRegWrite<=0;
        EXMEMMemRead<=0;
        EXMEMMemWrite<=0;
        MEMWBRegWrite<=0;
    end
end


endmodule