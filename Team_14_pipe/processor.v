`include "Adder.v"
`include "alu.v"
`include "ALUControl.v"
`include "Control.v"
`include "DataMem.v"
`include "ImmGen.v"
`include "instruction_mem.v"
`include "mux.v"
`include "PC.v"
`include "RegisterFile.v"
`include "Shiftleft1.v"
`include "equalityComparator.v"
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
///////////////////////////////////


alu_64_bit alu1(
    .a(IDEXrs1), .b(immRegOut),
    .opcode(ALUControlSig), .result(ALUresult), 
    .cout(), .carry_flag(), // useless
    .overflow_flag(), // useless
    .zero_flag() // no use of ALU zero flag now
);



// EX/MEM regis...
reg [63:0] EXMEMALUResult;
// rs2 value read from register mem,
// it stores value to be written into 
// the memory in case of load
reg [63:0] EXMEMrs2;
// rd passed till MEM/WB register
reg [4:0] EXMEMrd;
// mem
reg EXMEMMemRead;
reg EXMEMMemWrite;
// wb
reg EXMEMRegWrite;
reg EXMEMMemtoReg;


DataMem DM1(
    .clk(clk), .reset(reset),
    .MemRead(EXMEMMemRead), .MemWrite(EXMEMMemWrite),
    .address(EXMEMALUResult[9:0]), .write_data(EXMEMrs2),
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

PC PC1(
    .clk(clk), .reset(reset),
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
mux ALUSource(
    .a(IDEXrs2), .b(IDEXImm), .sel(IDEXALUSrc),
    .out(immRegOut)
);

mux RegWriteBack(
    .a(MEMWBALUResult), .b(MEMWBReadData), .sel(MEMWBMemtoReg),
    .out(write_back)
);

equalityComparator comp1(
    .a(rs1), .b(rs2), .equal(rs1EqualRs2)
);




always@(posedge clk) begin
    if(!reset) begin
        // IF/ID
        IFIDPC<=pc_out;
        IFIDIR<=IMEMOut;
        // ID/EX
        IDEXMemRead<=MemRead;
        IDEXMemWrite<=MemWrite;
        IDEXALUOp<=ALUOp;
        IDEXALUSrc<=ALUSrc;
        IDEXMemtoReg<=MemtoReg;
        IDEXRegWrite<=RegWrite;
        IDEXrs1<=rs1;
        IDEXrs2<=rs2;
        IDEXImm<=immediate;
        IDEXIR<=Instruction;
        // EX/MEM
        EXMEMMemRead<=IDEXMemRead;
        EXMEMMemWrite<=IDEXMemWrite;
        EXMEMALUResult<=ALUresult;
        EXMEMMemtoReg<=IDEXMemtoReg;
        EXMEMRegWrite<=IDEXRegWrite;
        EXMEMrs2<=IDEXrs2;
        EXMEMrd<=IDEXIR[11:7];
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
    end
end


endmodule