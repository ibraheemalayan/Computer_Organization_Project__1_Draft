module SIMCOMP (
    clock, PC, IR, MBR, MAR, AC
);

input clock;
output PC, IR, MBR, MAR, AC;

// addresses are 8 bits
reg [7:0] PC, MAR;

// instructions are 16 bits and words are 16 bits
reg [15:0] IR, MBR, AC;

// memory is 256 byte (128 cells with 2 bytes each cell)
reg [15:0] Memory [0:127];

// register file contains 16 registers each is 16 bits
reg [15:0] Registar [0:15];

// we have 5 states so we need 3 bits
reg [2:0] state;

// opcodes
parameter load = 4'h3, add = 4'h7, store = 4'hB;

// states
parameter 
    get_instruction_addr = 0,
    fetch_instruction = 1,
    decode_instruction = 2,
    fetch_operand = 3,
    execute = 4;

initial begin
    
    // program

    // (instruction) Load R1, [30]
    // 0011 0001 00011110
    Memory [20] = 16'h311E;

    // (instruction) Add R1, [31]
    // 0111 0001 00011111
    Memory [21] = 16'h711F;

    // (instruction) Store R1, [32]
    // 1011 0001 00100000
    Memory [22] = 16'hB120;
   

    // (data) 5 at 30 / 8 at 31
    Memory [30] = 16'd5;
    Memory [31] = 16'd8;

    PC = 20;
    state = 0;
end

always @(posedge clock) begin
    case (state)

        // 0: get instruction address from PC and put it in MAR (to fetch it in next state)
        get_instruction_addr: begin
            MAR <= PC;
            state=1;
        end

        // 1: fetch instruction from memory to Instruction Registar
        fetch_instruction: begin
            // supposing that instruction has dedecated bus to IR (without going throug MBR)
            IR <= Memory [MAR];
            PC <= PC + 1; //increase program counter to point to the next instruction
            state=2;
        end

        // 2: decode instruction ( prepare to fetch operand , copy operand address from instruction to MAR)
        decode_instruction: begin
            MAR <= IR [7:0]; // copy first 8 bits from the instruction (memory address)
            state=3;
        end

        // 3: fetch operand
        fetch_operand: begin
            state=4;
            case (IR[15:12])
                load : MBR <= Memory [MAR];
                add :  MBR <= Memory [MAR];
                store : MBR <= Registar [ IR[11:8] ]; // copy Ri to MBR (prepare to copy it to memory)
            endcase
        end

        // 4: execute
        execute: begin

            // add AC to MBR
            if (IR[15:12] == add) begin
                Registar [ IR[11:8] ] <= Registar [ IR[11:8] ] + MBR;
                state = 0;
            
            // load MBR to Ri
            end else if (IR[15:12] == load) begin
                Registar [ IR[11:8] ] <= MBR;
                state = 0;

            // store MBR at MAR in Memory
            end else if (IR[15:12] == store) begin
                Memory [MAR] <= MBR;
                state = 0;
            end else begin
                state = 5; // raise some exception (unknown opcode)
            end
        end

    endcase
end

endmodule