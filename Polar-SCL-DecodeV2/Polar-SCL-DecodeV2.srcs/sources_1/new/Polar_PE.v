`timescale 1ns / 1ps
module Polar_PE(
    input wire sysclk,
    input wire sysres,
    input wire signed [7:0] L_a,
    input wire signed [7:0] L_b,
    input wire U_0,
    input wire sel_g,
    output wire signed [7:0] L_out
    );

// wire [7:0] abs_a = (L_a[7]) ? -L_a : L_a; //make it abs
// wire [7:0] abs_b = (L_b[7]) ? -L_b : L_b;
// wire [7:0] min_abs = (abs_a < abs_b) ? abs_a : abs_b; // find the minimum

wire [8:0] abs_a = (L_a[7]) ? -{L_a[7], L_a} : {1'b0, L_a}; 
wire [8:0] abs_b = (L_b[7]) ? -{L_b[7], L_b} : {1'b0, L_b};
wire [8:0] min_abs_9 = (abs_a < abs_b) ? abs_a : abs_b;

// wire signed [7:0] f_result = (L_a[7] ^ L_b[7]) ? -min_abs : min_abs;
wire signed [7:0] f_result = (L_a[7] ^ L_b[7]) ? 
                  ((min_abs_9 == 9'd128) ? -8'sd128 : -min_abs_9[7:0]) : 
                  ((min_abs_9 == 9'd128) ? 8'sd127  : min_abs_9[7:0]);

wire signed [8:0] g_temp = (U_0 == 1'b1) ? (L_b - L_a) : (L_b + L_a);

wire signed [7:0] g_result;

assign g_result = (g_temp > 9'sd127)  ? 8'sd127 : 
                  (g_temp < -9'sd128) ? 8'sd128 : 
                  g_temp[7:0];
assign L_out = (sel_g == 1'b0)? f_result:g_result;


endmodule
