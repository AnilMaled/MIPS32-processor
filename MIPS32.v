// pipe_MIPS32.v  (like RISCK processor)
// Behavioral pipelined MIPS32 (as in the uploaded lecture slides)
// Two-phase clock interface: clk1, clk2

module pipe_MIPS32 (clk1, clk2);
    input clk1, clk2;     

  reg [31:0] PC, IF_ID_IR, IF_ID_NPC;
  reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
  reg [2:0]  ID_EX_type, EX_MEM_type, MEM_WB_type;
  reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
  reg  EX_MEM_cond;
  reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;

  reg [31:0] Reg [0:31];   //mem initiation
  reg [31:0] Mem [0:1023]; // Data + instruction memory 

  //    Opcodes 
  parameter ADD = 6'b000000;
  parameter SUB = 6'b000001;
  parameter ANDOP = 6'b000010; 
  parameter OROP = 6'b000011;
  parameter SLT = 6'b000100;
  parameter MUL= 6'b000101;
  parameter HLT= 6'b111111;

  parameter LW = 6'b001000;
  parameter SW = 6'b001001;
  parameter ADDI = 6'b001010;
  parameter SUBI = 6'b001011;
  parameter SLTI = 6'b001100;
  parameter BNEQZ = 6'b001101;
  parameter BEQZ = 6'b001110;
  parameter J = 6'b010000; 

  // Stage-type encoding
  parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011,
            BRANCH = 3'b100, HALT = 3'b101;

  reg HALTED;//after HLT completes (WB stage)
  reg TAKEN_BRANCH;// To disable writes after branch decision

  // IF stage (posedge clk1)
  always @(posedge clk1)
    if (HALTED == 0) begin
      if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) ||
          ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0))) begin
        // branch taken
        IF_ID_IR<= #2 Mem[EX_MEM_ALUOut];
        TAKEN_BRANCH<= #2 1'b1;
         IF_ID_NPC<= #2 EX_MEM_ALUOut + 1;
          PC<= #2 EX_MEM_ALUOut + 1;
      end else begin
             IF_ID_IR <= #2 Mem[PC];
                 IF_ID_NPC <= #2 PC + 1;
               PC <= #2 PC + 1;
      end
    end

  // ID stage 
  always @(posedge clk2)
    if (HALTED == 0) begin
      // Read registers (rs = bits[25:21], rt = bits[20:16])
      if (IF_ID_IR[25:21] == 5'b00000) ID_EX_A <= 0;
      else ID_EX_A <= #2 Reg[IF_ID_IR[25:21]];

      if (IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= 0;

        else ID_EX_B <= #2 Reg[IF_ID_IR[20:16]];

      ID_EX_NPC <= #2 IF_ID_NPC;
      ID_EX_IR <= #2 IF_ID_IR;
      ID_EX_Imm <= #2 {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]}; // sign-extend

      
      case (IF_ID_IR[31:26])
        ADD, SUB, ANDOP, OROP, SLT, MUL: ID_EX_type <= #2 RR_ALU;
        ADDI, SUBI, SLTI: ID_EX_type <= #2 RM_ALU;
        LW: ID_EX_type <= #2 LOAD;
        SW: ID_EX_type <= #2 STORE;
        BNEQZ, BEQZ:ID_EX_type <= #2 BRANCH;
        HLT: ID_EX_type <= #2 HALT;
        default: ID_EX_type <= #2 HALT; // invalid opcode => HALT
      endcase
    end

  // EX stage (posedge clk1)
  always @(posedge clk1)
    if (HALTED == 0) begin
      EX_MEM_type <= #2 ID_EX_type;
      EX_MEM_IR   <= #2 ID_EX_IR;
      TAKEN_BRANCH <= #2 0;

      case (ID_EX_type)
        RR_ALU: begin
          case (ID_EX_IR[31:26])
            ADD:EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B;
            SUB: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B;
            ANDOP:EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;
            OROP:EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;
            SLT: EX_MEM_ALUOut <= #2 (ID_EX_A < ID_EX_B);
            MUL: EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;
            default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
          endcase
        end

        RM_ALU:
         begin
          case (ID_EX_IR[31:26])
            ADDI: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
            SUBI:  EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;
            SLTI:EX_MEM_ALUOut <= #2 (ID_EX_A < ID_EX_Imm);
            default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
          endcase
        end

        LOAD, STORE: 
        begin
          EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm; // effective address
          EX_MEM_B   <= #2 ID_EX_B;   // data to store for STORE
        end

        BRANCH: begin
          EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm;    // branch target
          EX_MEM_cond   <= #2 (ID_EX_A == 0);
        end

        default: begin
          EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
          EX_MEM_B <= #2 32'hxxxxxxxx;
        end
      endcase
    end

  // MEM stage (posedge clk2)
  always @(posedge clk2)
    if (HALTED == 0) begin
      MEM_WB_type <= EX_MEM_type;
      MEM_WB_IR   <= #2 EX_MEM_IR;

      case (EX_MEM_type)
        RR_ALU, RM_ALU:
          MEM_WB_ALUOut <= #2 EX_MEM_ALUOut;

        LOAD:
          MEM_WB_LMD <= #2 Mem[EX_MEM_ALUOut];

        STORE:
          if (TAKEN_BRANCH == 0) // disable write on taken branch
            Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B;
      endcase
    end

  // WB stage (posedge clk1)
  always @(posedge clk1) begin
    if (TAKEN_BRANCH == 0) begin // disable writes if branch taken
      case (MEM_WB_type)
        RR_ALU: Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut; // rd
        RM_ALU: Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut; // rt
        LOAD:  Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD;    // rt
        HALT:  HALTED <= #2 1'b1;
      endcase
    end
  end

endmodule
 