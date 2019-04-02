module IF(clk, 
        rst, 
        WEn, 
        instr_en, 
        DMemDump, 
        PCSrc, 
        hazard, 
        PC_brj, 
        instr_data, 
        instruction_fb, 
        PC_added_fb,
        instruction, 
        PC_incr);

input clk, rst;
input WEn, instr_en;    // enables
input PCSrc;
input hazard;
input [15:0] PC_brj;
input [15:0] instr_data, instruction_fb, PC_added_fb;// unused???

output [15:0] instruction;//instruction out of memory
output DMemDump;

wire [15:0] PC_value;  // output pc value
wire [15:0] instr_addr; // input into instruction
wire [15:0] PC_added;
wire [15:0] instruction_out, PC_added_out;
wire createdump;       // dump signal

wire cout;

output [15:0] PC_incr;
//wire instr_wr :???
assign instr_wr = 1'b0;
assign PC_incr = PC_added;

// decalre a PC register
register PC(.clk(clk), .rst(rst), .data(PC_value), .WEn(WEn), .data_out(instr_addr)); // WEn?
memory2c iMem(.data_out(instruction_out), .data_in(instr_data), .addr(instr_addr), .enable(instr_en), 
                .wr(instr_wr), .createdump(createdump), .clk(clk), .rst(rst));

rca_16b pc_adder(.A(instr_addr), .B(16'h0002), .C_in(1'b0), .S(PC_added_out), .C_out(cout));

assign instruction = (hazard)? instruction_fb : instruction_out; // NOP: 16'h 0800
// increment PC
assign PC_added = (hazard)? PC_added_fb : PC_added_out;

// assign PC_added_out =  instr_addr + 2;

// PCsrc = 1: choose from branched/jumped source ; else pc+2
assign PC_value = (rst)? 0:  
                  (PCSrc)? PC_brj : 
                  (createdump|hazard)? instr_addr: 
                   PC_added_out;

assign createdump = !(|(instruction[15:11])) ? 1'b1: 1'b0; // HALT
assign DMemDump = createdump;

endmodule
