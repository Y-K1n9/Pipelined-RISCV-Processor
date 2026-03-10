#!/usr/bin/env python3
"""Decode instructions.txt hex bytes into RISC-V assembly and trace expected register values."""

def decode():
    with open('instructions.txt') as f:
        hexbytes = [line.strip() for line in f if line.strip()]

    instrs = []
    for i in range(0, len(hexbytes), 4):
        if i+3 < len(hexbytes):
            word = hexbytes[i] + hexbytes[i+1] + hexbytes[i+2] + hexbytes[i+3]
            instrs.append(word)

    print("=== INSTRUCTION DECODE ===")
    for idx, instr in enumerate(instrs):
        addr = idx * 4
        val = int(instr, 16)
        opcode = val & 0x7f
        rd = (val >> 7) & 0x1f
        funct3 = (val >> 12) & 0x7
        rs1 = (val >> 15) & 0x1f
        rs2 = (val >> 20) & 0x1f
        funct7 = (val >> 25) & 0x7f

        desc = ''
        if opcode == 0x33:
            if funct7 == 0 and funct3 == 0: desc = f'add x{rd}, x{rs1}, x{rs2}'
            elif funct7 == 0x20 and funct3 == 0: desc = f'sub x{rd}, x{rs1}, x{rs2}'
            elif funct7 == 0 and funct3 == 7: desc = f'and x{rd}, x{rs1}, x{rs2}'
            elif funct7 == 0 and funct3 == 6: desc = f'or x{rd}, x{rs1}, x{rs2}'
            else: desc = f'R-type f7={funct7} f3={funct3} rd=x{rd} rs1=x{rs1} rs2=x{rs2}'
        elif opcode == 0x13:
            imm = val >> 20
            if imm >= 2048: imm -= 4096
            desc = f'addi x{rd}, x{rs1}, {imm}'
        elif opcode == 0x03:
            imm = val >> 20
            if imm >= 2048: imm -= 4096
            desc = f'ld x{rd}, {imm}(x{rs1})'
        elif opcode == 0x23:
            imm = ((val >> 25) << 5) | ((val >> 7) & 0x1f)
            if imm >= 2048: imm -= 4096
            desc = f'sd x{rs2}, {imm}(x{rs1})'
        elif opcode == 0x63:
            imm12 = (val >> 31) & 1
            imm10_5 = (val >> 25) & 0x3f
            imm4_1 = (val >> 8) & 0xf
            imm11 = (val >> 7) & 1
            imm = (imm12 << 12) | (imm11 << 11) | (imm10_5 << 5) | (imm4_1 << 1)
            if imm >= 2048: imm -= 4096
            desc = f'beq x{rs1}, x{rs2}, {imm}'
        else:
            desc = f'unknown opcode={opcode:#x}'

        print(f'  PC={addr:3d} (0x{addr:03x}): 0x{instr}  {desc}')

def trace():
    """Trace the program execution and compute expected register file values."""
    with open('instructions.txt') as f:
        hexbytes = [line.strip() for line in f if line.strip()]

    instrs = []
    for i in range(0, len(hexbytes), 4):
        if i+3 < len(hexbytes):
            word = hexbytes[i] + hexbytes[i+1] + hexbytes[i+2] + hexbytes[i+3]
            instrs.append(int(word, 16))

    MASK64 = (1 << 64) - 1
    regs = [0] * 32
    mem = [0] * 1024  # byte addressable
    pc = 0
    max_steps = 500

    def sext64(val):
        """Sign extend to 64-bit Python int."""
        val = val & MASK64
        if val >= (1 << 63):
            return val - (1 << 64)
        return val

    print("\n=== EXECUTION TRACE ===")
    for step in range(max_steps):
        idx = pc // 4
        if idx >= len(instrs):
            print(f"  Step {step}: PC={pc} -> out of bounds, halting")
            break

        val = instrs[idx]
        if val == 0:
            print(f"  Step {step}: PC={pc} -> NOP (0x00000000), halting")
            break

        opcode = val & 0x7f
        rd = (val >> 7) & 0x1f
        funct3 = (val >> 12) & 0x7
        rs1 = (val >> 15) & 0x1f
        rs2 = (val >> 20) & 0x1f
        funct7 = (val >> 25) & 0x7f

        desc = ''
        next_pc = pc + 4

        if opcode == 0x33:  # R-type
            a = sext64(regs[rs1])
            b = sext64(regs[rs2])
            if funct7 == 0 and funct3 == 0:
                result = (a + b) & MASK64
                desc = f'add x{rd}, x{rs1}, x{rs2}  ; x{rd} = {sext64(result)}'
            elif funct7 == 0x20 and funct3 == 0:
                result = (a - b) & MASK64
                desc = f'sub x{rd}, x{rs1}, x{rs2}  ; x{rd} = {sext64(result)}'
            elif funct7 == 0 and funct3 == 7:
                result = (regs[rs1] & regs[rs2]) & MASK64
                desc = f'and x{rd}, x{rs1}, x{rs2}  ; x{rd} = {sext64(result)}'
            elif funct7 == 0 and funct3 == 6:
                result = (regs[rs1] | regs[rs2]) & MASK64
                desc = f'or x{rd}, x{rs1}, x{rs2}  ; x{rd} = {sext64(result)}'
            else:
                result = 0
                desc = f'R-type unknown'
            if rd != 0:
                regs[rd] = result & MASK64

        elif opcode == 0x13:  # addi
            imm = val >> 20
            if imm >= 2048: imm -= 4096
            a = sext64(regs[rs1])
            result = (a + imm) & MASK64
            desc = f'addi x{rd}, x{rs1}, {imm}  ; x{rd} = {sext64(result)}'
            if rd != 0:
                regs[rd] = result & MASK64

        elif opcode == 0x03:  # ld
            imm = val >> 20
            if imm >= 2048: imm -= 4096
            addr_val = (sext64(regs[rs1]) + imm) & MASK64
            addr_int = addr_val & 0x3FF  # 10-bit address
            # Read 8 bytes big-endian
            data = 0
            for j in range(8):
                data = (data << 8) | mem[addr_int + j]
            desc = f'ld x{rd}, {imm}(x{rs1})  ; addr={addr_int}, x{rd} = 0x{data:016x} ({sext64(data)})'
            if rd != 0:
                regs[rd] = data & MASK64

        elif opcode == 0x23:  # sd
            imm = ((val >> 25) << 5) | ((val >> 7) & 0x1f)
            if imm >= 2048: imm -= 4096
            addr_val = (sext64(regs[rs1]) + imm) & MASK64
            addr_int = addr_val & 0x3FF
            data = regs[rs2] & MASK64
            # Write 8 bytes big-endian
            mem[addr_int + 0] = (data >> 56) & 0xFF
            mem[addr_int + 1] = (data >> 48) & 0xFF
            mem[addr_int + 2] = (data >> 40) & 0xFF
            mem[addr_int + 3] = (data >> 32) & 0xFF
            mem[addr_int + 4] = (data >> 24) & 0xFF
            mem[addr_int + 5] = (data >> 16) & 0xFF
            mem[addr_int + 6] = (data >> 8) & 0xFF
            mem[addr_int + 7] = data & 0xFF
            desc = f'sd x{rs2}, {imm}(x{rs1})  ; addr={addr_int}, val=0x{data:016x}'

        elif opcode == 0x63:  # beq
            imm12 = (val >> 31) & 1
            imm10_5 = (val >> 25) & 0x3f
            imm4_1 = (val >> 8) & 0xf
            imm11 = (val >> 7) & 1
            imm = (imm12 << 12) | (imm11 << 11) | (imm10_5 << 5) | (imm4_1 << 1)
            if imm >= 2048: imm -= 4096
            taken = regs[rs1] == regs[rs2]
            desc = f'beq x{rs1}, x{rs2}, {imm}  ; x{rs1}=0x{regs[rs1]:016x}, x{rs2}=0x{regs[rs2]:016x}, {"TAKEN" if taken else "NOT TAKEN"}'
            if taken:
                next_pc = pc + imm

        print(f'  Step {step:2d}: PC={pc:3d}  {desc}')
        pc = next_pc

    print("\n=== EXPECTED REGISTER FILE ===")
    for i in range(32):
        print(f'  x{i:2d} = {regs[i]:016x}')

    print("\n=== ACTUAL REGISTER FILE (from register_file.txt) ===")
    with open('register_file.txt') as f:
        lines = [l.strip() for l in f if l.strip()]
    
    cycle_count = lines[-1] if len(lines) == 33 else "?"
    reg_lines = lines[:32]
    
    mismatches = []
    for i in range(32):
        actual = int(reg_lines[i], 16)
        expected = regs[i]
        match = "OK" if actual == expected else "MISMATCH"
        if actual != expected:
            mismatches.append(i)
        print(f'  x{i:2d}: expected={expected:016x}  actual={actual:016x}  {match}')
    
    print(f"\n  Cycle count: {cycle_count}")
    if mismatches:
        print(f"\n  MISMATCHES in registers: {mismatches}")
    else:
        print("\n  ALL REGISTERS MATCH!")

if __name__ == '__main__':
    decode()
    trace()
