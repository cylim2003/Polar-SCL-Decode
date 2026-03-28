`timescale 1ns / 1ps

module Polar_TopV2#(
    localparam S_IDLE = 2'd0,
    localparam S_WRITE = 2'd1,
    localparam S_READ = 2'd2,
    localparam STAGES = 10,
    parameter N= 1024
)(
    input wire sysclk,
    input wire sysres,
    input wire [7:0] LLR,
    // output reg [N-1:0] U,
    output reg dout,
    output reg COMPLETED,
    output wire readComplete
    );

reg [7:0] din;
reg [1:0] CONTROL_DELAY1;
reg [1:0] CONTROL_DELAY2;
reg [1:0] CONTROL_DELAY3;
reg [1:0] CONTROL_DELAY4;
reg [10:0] i; //max 1024
reg [4:0] s; //max 10 
reg [7:0] L_a;
reg [7:0] L_b;
wire U_0;
wire sel_g;
wire signed [7:0] L_out;
reg [1:0] CONTROL [0:STAGES];
wire DONE [0:STAGES];
wire [7:0] douta [0:STAGES];
wire [7:0] doutb [0:STAGES];
integer x;
integer k;
reg readEn;     
reg writeEn;    
reg doneWriting;
wire isUpdating; 
assign sel_g = (i>>s)&1;
reg tempU;
genvar z;
reg DELAY;
reg [4:0] s_next;
wire Qcheck;
reg en_Q;
generate
    for (z = 0; z < STAGES; z = z + 1) begin : RAM_GEN
        Ram_Stage0 #(   
            .STAGE(z)
        )Ram_Stage_inst(
            .sysclk(sysclk),
            .sysres(sysres),
            .CONTROL(CONTROL[z+1]), // 0 = IDLE, 01 = WRITE, 10 = READ
            .din(din),
            .douta(douta[z+1]),
            .doutb(doutb[z+1]),
            .DONE(DONE[z+1])
        );
    end
endgenerate


always @(posedge sysclk or negedge sysres) begin
    if (sysres == 1'b0) begin
        tempU <= 1'b0;
        i<= 11'b0;
        s<= STAGES;
        din <= 8'd0;
        writeEn <= 1'b0;
        readEn <= 1'b0;
        s_next <= 1'b0;
        COMPLETED <= 1'b0;
        for(x=0;x<=STAGES;x=x+1) begin
            CONTROL[x] <= S_IDLE;
        end
        L_a <= 8'b0;
        L_b <= 8'b0;
        CONTROL_DELAY1 <= 2'b0;
        CONTROL_DELAY2 <= 2'b0;
        CONTROL_DELAY3 <= 2'b0;
        CONTROL_DELAY4 <= 2'b0;
        doneWriting <= 1'b0;
        en_Q <= 1'b1;
    end
    else if (COMPLETED == 1'b0) begin
        case (s)
            STAGES: begin
                if (DONE[s] == 1'b1) begin
                    s <= s -1'b1;
                    CONTROL[s] <= S_IDLE;
                    CONTROL_DELAY1 <= S_IDLE;
                    CONTROL_DELAY2 <= S_IDLE;
                    CONTROL_DELAY3 <= S_IDLE;
                    CONTROL_DELAY4 <= S_IDLE;
                    writeEn <= 1'b0;
                    readEn <= 1'b0;
                    din <= 8'd0;
                end
                else begin
                    CONTROL[s] <= S_WRITE;
                    din <= LLR;
                end
            end
            0: begin
                if(CONTROL_DELAY4 == S_WRITE) begin // already done reading.. now update stagePS.
                    if (isUpdating == 1'b0 && writeEn == 1'b0 && doneWriting == 1'b0) begin
                        readEn <= 1'b0;
                        if (readEn == 1'b0) begin
                            writeEn <= 1'b1;
                            // U[i] <= (L_out < 0)?1'b1:1'b0;
                            if(Qcheck == 1'b0) begin
                                tempU <= 1'b0;
                            end
                            else begin
                                tempU <= (L_out < 0)?1'b1:1'b0;
                            end
                        end
                    end
                    else if (writeEn == 1'b1) begin
                        writeEn <= 1'b0;
                        doneWriting <= 1'b1;
                    end
                    else if (isUpdating==1'b0 && doneWriting == 1'b1 )begin
                        s<= s_next;
                        i <= i+1'b1;
                        CONTROL_DELAY1 <= S_IDLE;
                        CONTROL_DELAY2 <= S_IDLE;
                        CONTROL_DELAY3 <= S_IDLE;
                        CONTROL_DELAY4 <= S_IDLE;
                        doneWriting <= 1'b0;
                    end
                    CONTROL[1] <= S_IDLE;
                end
                else begin
                    if(CONTROL_DELAY2 == S_WRITE) begin //T0-> readPS T1 -> wait T2 -> Read LLr T3 wait T4 -> write LLR
                        CONTROL[s+1] <= S_READ;
                    end
                    CONTROL_DELAY4 <= CONTROL_DELAY3;
                    CONTROL_DELAY3 <= CONTROL_DELAY2;
                    CONTROL_DELAY2 <= CONTROL_DELAY1;
                    CONTROL_DELAY1 <= S_WRITE;
                    doneWriting <=1'b0;
                    // if (sel_g == 1'b1&& CONTROL_DELAY2 == S_READ) begin
                    if (sel_g == 1'b1) begin
                        readEn <= 1'b1;
                    end
                    else begin
                        readEn <= 1'b0;
                    end
                    if(i+1 < N) begin
                        for (k = 10; k >= 0; k = k - 1) begin
                            if (!i[k]) begin 
                                s_next <= k;
                            end
                        end
                    end
                    else begin
                        s_next <= 1'b1;
                    end
                    L_a <= douta[s+1];
                    L_b <= doutb[s+1];
                end
            end
            default: begin
                if(i== N) begin
                    COMPLETED <= 1'b1;
                    s <= 1'bz;
                    i<= 1'bz;
                end
                else if (DONE[s] == 1'b1) begin 
                    doneWriting <= 1'b0;
                    CONTROL[s+1]<= S_IDLE;
                    CONTROL[s] <= S_IDLE;
                    CONTROL_DELAY1 <= S_IDLE;
                    CONTROL_DELAY2 <= S_IDLE;
                    CONTROL_DELAY3 <= S_IDLE;
                    CONTROL_DELAY4 <= S_IDLE;
                    din <= 8'b0;
                    s <= s-1'b1;
                    readEn <= 1'b0;
                    writeEn <= 1'b0;
                end
                else begin
                    if(CONTROL_DELAY2 == S_WRITE) begin //T0-> readPS T1 -> wait T2 -> Read LLr T3 wait T4 -> write LLR
                        CONTROL[s+1] <= S_READ;
                    end
                    // if (sel_g == 1'b1 && CONTROL_DELAY2 == S_WRITE) begin
                    if (sel_g == 1'b1) begin
                        readEn <= 1'b1; 
                    end
                    else begin
                        readEn <= 1'b0;
                    end
                    L_a <= douta[s+1];
                    L_b <= doutb[s+1];
                    din <= L_out;
                    CONTROL[s] <= CONTROL_DELAY4;
                    CONTROL_DELAY4 <= CONTROL_DELAY3;
                    CONTROL_DELAY3 <= CONTROL_DELAY2;
                    CONTROL_DELAY2 <= CONTROL_DELAY1;
                    CONTROL_DELAY1 <= S_WRITE;
                    doneWriting <= 1'b0;
                end
            end


        endcase
    end
end



always @(posedge sysclk or negedge sysres) begin
    if (sysres == 1'b0) begin
        dout <= 1'b0;
        DELAY <= 1'b0;
    end
    else if (COMPLETED==1'b1 && readComplete == 1'b0) begin
        DELAY <= 1'b1;
        if (DELAY == 1'b1) begin
            dout <= U_0;
        end
        else begin
            dout <= 1'b0;
        end
    end
    else begin
        dout<= 1'b0;
    end
end

// Ram_Stage3 Ram_Stage3_inst(
//     .sysclk(sysclk),
//     .sysres(sysres),
//     .CONTROL(CONTROL[3]), // 0 = IDLE, 01 = WRITE, 10 = READ
//     .din(din),
//     .douta(douta[3]),
//     .doutb(doutb[3]),
//     .DONE(DONE[3])
//     );

// Ram_Stage0 Ram_Stage0_inst(
//     .sysclk(sysclk),
//     .sysres(sysres),
//     .CONTROL(CONTROL[2]), // 0 = IDLE, 01 = WRITE, 10 = READ
//     .din(din),
//     .douta(douta[2]),
//     .doutb(doutb[2]),
//     .DONE(DONE[2])
//     );
// Ram_Stage1 Ram_Stage1_inst(
//     .sysclk(sysclk),
//     .sysres(sysres),
//     .CONTROL(CONTROL[1]), // 0 = IDLE, 01 = WRITE, 10 = READ
//     .din(din),
//     .douta(douta[1]),
//     .doutb(doutb[1]),
//     .DONE(DONE[1])
//     );


Polar_PE Polar_PE_inst(
    .sysclk(sysclk),
    .sysres(sysres),
    .L_a(L_a),
    .L_b(L_b),
    .U_0(U_0),
    .sel_g(sel_g),
    .L_out(L_out)
);
Partial_SumV3 #(
    .N(N),
    .STAGES(STAGES)
) PartialSumV3_inst(
    .sysclk(sysclk),
    .sysres(sysres),
    .i(i),
    .s(s),
    // .U_0(U[i]),
    .U_0(tempU),
    .readEn(readEn),
    .writeEn(writeEn),
    .COMPLETED(COMPLETED),
    .isUpdating(isUpdating), 
    .readComplete(readComplete),
    .U(U_0)
    );
blk_mem_gen_1 Q_sequence (
  .clka(sysclk),    // input wire clka
  .ena(en_Q),      // input wire ena
  .addra(i),  // input wire [9 : 0] addra
  .douta(Qcheck)  // output wire [0 : 0] douta
);
endmodule
