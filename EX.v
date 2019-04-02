module EX(clk, 
          rst, 
          OpCode, Funct, instruction,  // ADDED 03/29 19:17
          PCImm, Jump, 
          RegDst,
          SESel, 
          PC_added,
          Alu1,
          ALUSrc2,
          Alu_ch,
          writeRegSel,
          ALU_output, 
          // OF, 
          PC_ch,
          PC_brj);

    input clk, rst;
    input [15:0] instruction;
    input [15:0] PC_added;
    input PCImm;
    // Need to be wired to 
    input [4:0]OpCode;
    input [15:0] Alu1;
    input [1:0] Funct;
    input Jump;
    input [1:0]RegDst;

    input ALUSrc2;
    input [15:0] Alu_ch;
    input [2:0]SESel;

    // output OF;
    output [15:0] PC_brj;
    output [15:0] ALU_output;
    output [2:0] writeRegSel;
    output PC_ch;

    wire [15:0] Alu2; // ADDED 03/30
    wire [15:0] Imm;
    wire Asrc,Bsrc,invA,invB,cin,number_select, Z, N;
    wire [2:0] op;
    wire [1:0] ALU_select, flag_type;

// Wires for PC
   wire Brc, Brc_cond, Brc_cfm;
   wire [15:0] Operand;

   wire cout;
   wire [15:0] pc_ch_result;

// ALU select source logic
// ALU control
// ALU instantiation
// PC_brj

ALU_CTRL alu_ctl (
                   .aluop(OpCode), .func(Funct),
                   .Asrc(Asrc), .Bsrc(Bsrc), .invA(invA), .invB(invB),
                   .op(op), .cin(cin), .number_select(number_select),
                   .ALU_select(ALU_select), .flag_type(flag_type)
                  );

proj_ALU ALU (
                .ALU_data1(Alu1), .ALU_data2(Alu2), 
                .invA(invA), .invB(invB), 
                .cin(cin), .Asrc(Asrc), .Bsrc(Bsrc), 
                .number_select(number_select), .op(op), 
                .ALU_select(ALU_select), .flag_type(flag_type), 
                //Output
                .ALU_output(ALU_output), .Z(Z), .N(N) //.of(OF)
              );

assign Alu2 = ALUSrc2 ? Alu_ch: Imm;

// immidiate select logic
assign Imm = (SESel == 3'b000) ? {11'h000, instruction[4:0]}:
             (SESel == 3'b001) ? {8'h00, instruction[7:0]}:
             (SESel[2:1] == 2'b01) ? { {11{instruction[4]}}, instruction[4:0]}:
             (SESel[2:1] == 2'b10) ? { {8{instruction[7]}},  instruction[7:0]}:
             (SESel[2:1] == 2'b11) ? { {5{instruction[10]}}, instruction[10:0]}:
             16'h0000;

// register source mux selection
assign writeRegSel = (RegDst == 2'b00) ? instruction[4:2]:
                      (RegDst == 2'b01) ? instruction[7:5]:
                      (RegDst == 2'b10) ? instruction[10:8]:
                      (RegDst == 2'b11) ? 3'b111: 
                      0; 

// Branch Condition Logic Calculation
assign Brc = (OpCode[4:2]==3'b011);

assign Brc_cond = (OpCode[1:0] == 2'b00) ? ~Z:
                  (OpCode[1:0] == 2'b01) ? Z:
                  (OpCode[1:0] == 2'b10) ? N:
                  (OpCode[1:0] == 2'b11) ? ~N:
                  0;  

assign Brc_cfm = Brc & Brc_cond;

// Whether PC would be added to IMM
assign PC_ch = (Brc_cfm | PCImm |Jump); 

assign Operand = (Jump)  ? Alu1: 
                 PC_added;

rca_16b pc_adder(.A(Imm), .B(Operand), .C_in(1'b0), .S(pc_ch_result), .C_out(cout));

// Final PC_brj output
assign PC_brj =  (PC_ch) ? pc_ch_result : PC_added;

endmodule
