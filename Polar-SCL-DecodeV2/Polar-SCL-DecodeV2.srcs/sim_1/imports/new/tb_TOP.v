`timescale 1ns / 1ps

module tb_TOP();
reg sysclk;
reg sysres;
wire [7:0] LLR;
// wire [7:0] U;
reg ena;
reg [10:0] ADDR;
wire COMPLETED;
wire [1:0] dout;
wire [1:0] readComplete;
wire Qseq;

initial begin 
    sysclk <= 1'b0;
    sysres <= 1'b0;
    #10
    sysres <= 1'b1;
end

always #10 sysclk <= ~ sysclk;

always @(posedge sysclk or negedge sysres) begin
    if(sysres == 1'b0) begin
        // LLR <= 1'b0;
        ena <= 1'b1;
        ADDR <= 1'b0;
    end
    else begin
        if (ADDR < 11'd1024) begin
            ADDR <= ADDR + 1'b1;
            // ena <= 1'b1;
        end
        else begin
            ADDR<= ADDR;
            ena<= 1'b0;
        end
    end
end

blk_mem_gen_0 LLR_ROM (
  .clka(sysclk),    // input wire clka
  .ena(ena),      // input wire ena
  .addra(ADDR),  // input wire [9 : 0] addra
  .douta(LLR)  // output wire [7 : 0] douta
);

blk_mem_gen_1 Q_sequence (
  .clka(sysclk),    // input wire clka
  .ena(ena),      // input wire ena
  .addra(ADDR),  // input wire [9 : 0] addra
  .douta(Qseq)  // output wire [0 : 0] douta
);
SCL_TopV1 SCL_TopV1_inst(
    .sysclk(sysclk),
    .sysres(sysres),
    .LLR(LLR),
    // .U(U),
    .COMPLETED(COMPLETED),
    .dout(dout),
    .readComplete(readComplete)
    );
endmodule
