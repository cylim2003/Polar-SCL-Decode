`timescale 1ns / 1ps

module tb_TOP();
reg sysclk;
reg sysres;
reg [7:0] LLR;
wire [7:0] U;
wire COMPLETED;
initial begin 
    sysclk <= 1'b0;
    sysres <= 1'b0;
    LLR <= 8'd1;
    #20
    sysres <= 1'b1;
    #80
    LLR <= LLR + 1'b1;
    #40
    LLR <= LLR + 1'b1;
    #40
    LLR <= LLR + 1'b1;
    #40
    LLR <= LLR + 1'b1;
    #40
    LLR <= LLR + 1'b1;
    #40
    LLR <= LLR + 1'b1;
    #40
    LLR <= LLR + 1'b1;
end

always #20 sysclk <= ~ sysclk;
    

Polar_TopV2 Polar_TopV2_inst(
    .sysclk(sysclk),
    .sysres(sysres),
    .LLR(LLR),
    .U(U),
    .COMPLETED(COMPLETED)
    );
endmodule
