`timescale 1ns / 1ps

module SCL_TopV1#(
    localparam S_IDLE = 2'd0,
    localparam S_WRITE = 2'd1,
    localparam S_READ = 2'd2,
    localparam IDLE = 3'b0,
    localparam READ = 3'b1,
    localparam JUDGE = 3'd2,
    localparam BSort = 3'd3,
    localparam SoftCopy = 3'd4,
    localparam PSupdate = 3'd5,
    localparam Next = 3'd6,

    // localparam  = 2'd2,
    localparam STAGES = 10,
    parameter N= 1024
)(
    input wire sysclk,
    input wire sysres,
    input wire [7:0] LLR,
    // output reg [N-1:0] U,
    output reg [1:0] dout,
    output reg COMPLETED,
    output wire [1:0] readComplete
    );

reg [7:0] din[1:0];
reg [1:0] CONTROL_DELAY1;
reg [1:0] CONTROL_DELAY2;
reg [1:0] CONTROL_DELAY3;
reg [1:0] CONTROL_DELAY4;
reg [10:0] i; //max 1024
reg [4:0] s; //max 10 
reg [7:0] L_a[1:0];
reg [7:0] L_b[1:0];
wire [1:0] U_feedback;
wire sel_g;
wire signed [7:0] L_out[1:0];
reg [1:0] CONTROL [0:STAGES];
wire [1:0] DONE [0:STAGES];
wire [7:0] douta [0:STAGES][1:0];
wire [7:0] doutb [0:STAGES][1:0];
integer x;
integer k;
reg readEn;     
reg writeEn;    
reg doneWriting;
wire isUpdating[1:0]; 
assign sel_g = (i>>s)&1;
reg tempU[1:0];
reg DELAY;
reg [4:0] s_next;
wire Qcheck;
reg en_Q;
// reg [STAGES-1:0] RamPath[1:0]; //

reg [1:0] splitPath;

reg [31:0] path_matrix [3:0];
reg [1:0] PathMother; //save current path's mother path 
reg [10:0] ipath[1:0]; //save i when path changed 
wire [31:0] pathInputdouta[1:0];
wire [31:0] pathInputdoutb[1:0];
wire [31:0] pathOutputdouta[1:0]; // cross module partialsum output for sharing info
wire [31:0] pathOutputdoutb[1:0]; //
wire [31:0] crossTempUOutput[1:0];
wire [31:0] crossTempUInput[1:0];
reg [4:0] path_max_stage[1:0]; // to check which LLR to use (mother or current)

assign pathInputdouta[0] = pathOutputdouta[1];
assign pathInputdoutb[0] = pathOutputdoutb[1];
assign pathInputdouta[1] = pathOutputdouta[0];
assign pathInputdoutb[1] = pathOutputdoutb[0];
assign crossTempUInput[0] = crossTempUOutput[1];
assign crossTempUInput[1] = crossTempUOutput[0];

reg BS_en;
wire [1:0] index0;
wire [1:0] index1;
reg [1:0] tempIndex[1:0];
wire BS_Updating;


wire [8:0] llr_abs[1:0];
assign llr_abs[0] = (L_out[0][7]) ? -{L_out[0][7], L_out[0]} : {1'b0, L_out[0]}; 
assign llr_abs[1] = (L_out[1][7]) ? -{L_out[1][7], L_out[1]} : {1'b0, L_out[1]}; 

reg [2:0] STATE;
genvar z;
generate
    for (z = 0; z < STAGES; z = z + 1) begin : RAM_GEN
        LLR_RAM #(   
            .STAGE(z)
        )LLR_RAM_PATH_1(
            .sysclk(sysclk),
            .sysres(sysres),
            .CONTROL(CONTROL[z+1]), // 0 = IDLE, 01 = WRITE, 10 = READ
            .din(din[0]),
            .douta(douta[z+1][0]),
            .doutb(doutb[z+1][0]),
            .DONE(DONE[z+1][0])
        );
        LLR_RAM #(   
            .STAGE(z)
        )LLR_RAM_PATH_2(
            .sysclk(sysclk),
            .sysres(sysres),
            .CONTROL(CONTROL[z+1]), // 0 = IDLE, 01 = WRITE, 10 = READ
            .din(din[1]),
            .douta(douta[z+1][1]),
            .doutb(doutb[z+1][1]),
            .DONE(DONE[z+1][1])
        );
    end
endgenerate

genvar v;
generate 
    for (v = 0; v <= 1; v = v + 1) begin : PE_GEN
        Polar_PE Polar_PE_inst(
            .sysclk(sysclk),
            .sysres(sysres),
            .L_a(L_a[v]),
            .L_b(L_b[v]),
            .U_feedback(U_feedback[v]),
            .sel_g(sel_g),
            .L_out(L_out[v])
        );
    end
endgenerate

genvar t;
generate
    for (t = 0; t<= 1; t = t+1) begin: PS_GEN
        Partial_SumV3 #(
            .N(N),
            .STAGES(STAGES)
        ) PartialSum_inst(
            .sysclk(sysclk),
            .sysres(sysres),
            .i(i),
            .s(s),
            .U_input(tempU[t]),
            .readEn(readEn),
            .writeEn(writeEn),
            .COMPLETED(COMPLETED),
            .ipath(ipath[t]),
            .crossTempU(crossTempUInput[t]),
            .pathInputdouta(pathInputdouta[t]),
            .pathInputdoutb(pathInputdoutb[t]),
            .pathOutputdouta(pathOutputdouta[t]),
            .pathOutputdoutb(pathOutputdoutb[t]),
            .tempU(crossTempUOutput[t]),
            .isUpdating(isUpdating[t]), 
            .readComplete(readComplete[t]),
            .U_feedback(U_feedback[t])
            );
    end
endgenerate


always @(posedge sysclk or negedge sysres) begin
    if (sysres == 1'b0) begin
        i<= 11'b0;
        s<= STAGES;
        for (x = 0; x <= 1; x = x +1) begin
            din[x] <= 8'd0;
            tempU[x] <= 1'b0;
            L_a[x] <= 8'b0;
            L_b[x] <= 8'b0;
            path_max_stage[x]<= 1'b0;
            tempIndex[x] <= 2'b0+x;
        end
        for(x=0; x<= 3;x= x+1)begin
            path_matrix[x] <= 32'b0;
            ipath[x] <= 1'b0;
        end
        writeEn <= 1'b0;
        readEn <= 1'b0;
        s_next <= 1'b0;
        COMPLETED <= 1'b0;
        for(x=0;x<=STAGES;x=x+1) begin
            CONTROL[x] <= S_IDLE;
        end
        CONTROL_DELAY1 <= 2'b0;
        CONTROL_DELAY2 <= 2'b0;
        CONTROL_DELAY3 <= 2'b0;
        CONTROL_DELAY4 <= 2'b0;
        doneWriting <= 1'b0;
        en_Q <= 1'b1;
        BS_en<= 1'b0;
        STATE <= READ;
        splitPath<= 1'b0;
        PathMother <= 2'b0;
    end
    else if (COMPLETED == 1'b0) begin
        case (s)
            STAGES: begin
                if (DONE[s][0] == 1'b1 && DONE[s][1] == 1'b1) begin
                    s <= s -1'b1;
                    CONTROL[s] <= S_IDLE;
                    CONTROL_DELAY1 <= S_IDLE;
                    CONTROL_DELAY2 <= S_IDLE;
                    CONTROL_DELAY3 <= S_IDLE;
                    CONTROL_DELAY4 <= S_IDLE;
                    writeEn <= 1'b0;
                    readEn <= 1'b0;
                    for (x = 0; x <= 1; x = x +1) begin
                        din[x] <= 8'd0;
                        if (s > path_max_stage[x]) begin
                            path_max_stage[x] <= s;
                        end
                    end
                end
                else begin
                    CONTROL[s] <= S_WRITE;
                    for (x = 0; x <= 1; x = x +1) begin
                        din[x] <= LLR;
                    end
                end
            end
            0: begin
                case (STATE)
                    READ: begin
                        if(CONTROL_DELAY2 == S_WRITE) begin //T0-> readPS T1 -> wait T2 -> Read LLr T3 wait T4 -> write LLR
                            CONTROL[s+1] <= S_READ;
                        end
                        CONTROL_DELAY4 <= CONTROL_DELAY3;
                        if (CONTROL_DELAY3 == S_WRITE) begin
                            STATE <= JUDGE;
                        end
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
                        for (x = 0; x <= 1; x = x + 1 )begin 
                            L_a[x] <= douta[s+1][x];
                            L_b[x] <= doutb[s+1][x];
                        end
                    end
                    JUDGE: begin
                        if (isUpdating[0] == 1'b0 && isUpdating[1] == 1'b0 && writeEn == 1'b0 && doneWriting == 1'b0) begin
                            readEn <= 1'b0;
                            if (readEn == 1'b0) begin
                                STATE <= BSort;
                                BS_en <= 1'b1;
                                // writeEn <= 1'b1;
                                // U[i] <= (L_out < 0)?1'b1:1'b0;
                                if(Qcheck == 1'b0) begin    //all pathmatrix penalty
                                    for (x = 0; x <= 1; x = x +1) begin
                                        tempU[x] <= 1'b0;
                                        if(L_out[x] <0) begin 
                                            path_matrix[x] <= path_matrix[x] + llr_abs[x];
                                            path_matrix[x+2] <= path_matrix[x+2] + llr_abs[x];
                                        end
                                    end
                                end
                                else begin
                                    for (x = 0; x <= 1; x = x +1) begin
                                        tempU[x] <= (L_out[x] < 0)?1'b1:1'b0;
                                        path_matrix[x+2]<= path_matrix[x] + llr_abs[x];
                                    end
                                    tempIndex[0] <= index0;
                                    tempIndex[1] <= index1;
                                    if(splitPath == 1'b0) begin
                                        path_matrix[1] <= path_matrix[1] + llr_abs[1];
                                    end
                                end
                            end
                        end
                    end
                    BSort: begin
                        if(BS_en == 1'b1) begin
                            if(Qcheck == 1 && splitPath == 1'b0) begin
                                ipath[1] <= i;
                                tempU[1] <= ~tempU[0];
                                path_max_stage[1] <= s;
                                PathMother[1] <= 1'b0;
                                splitPath <= 1'b1;
                            end
                            // if(i==511 ) begin
                            //     ipath[1] <= i;
                            //     // tempU[0] <= ~tempU[0];
                            //     path_max_stage[1] <= s;
                            //     tempU[1] <= ~tempU[0];
                            // end
                            // if(i==912 ) begin
                            //     ipath[1] <= i;
                            //     // tempU[0] <= ~tempU[0];
                            //     path_max_stage[1] <= s;
                            //     tempU[1] <= tempU[0];
                            // end
                            BS_en <= 1'b0;
                        end
                        if (BS_en == 1'b0 && BS_Updating== 1'b0) begin
                            if (Qcheck == 1'b1) begin
                                STATE <= SoftCopy;   
                            end
                            else begin
                                writeEn <= 1'b1;
                                STATE<= PSupdate;
                            end
                            // if(splitPath <= 1'b1) begin
                            //     STATE <= PSupdate;
                            // end
                            // else begin
                            //     STATE <= SoftCopy;   
                            // end
                        end
                    end
                    SoftCopy: begin
                        if(tempIndex[0] != 1'b0) begin
                            ipath[0] <= i;
                            path_matrix[0] <= path_matrix[index0];
                            tempU[0] <= ~tempU[0]; 
                            path_max_stage[0] <= s;
                        end
                        if(tempIndex[1]!= 1'b1) begin
                            ipath[1] <= i;
                            path_matrix[1] <= path_matrix[index1];
                            tempU[1] <= ~tempU[(index1 - 2)]; //problem right here....
                            path_max_stage[1] <= s;
                        end
                        writeEn <= 1'b1;
                        STATE <= PSupdate;
                    end
                    PSupdate: begin
                        if (writeEn == 1'b1) begin
                            writeEn <= 1'b0;
                            doneWriting <= 1'b1;
                        end
                        else if (isUpdating[0]==1'b0 && isUpdating[1] == 1'b0 & doneWriting == 1'b1 )begin
                            s<= s_next;
                            i <= i+1'b1;
                            CONTROL_DELAY1 <= S_IDLE;
                            CONTROL_DELAY2 <= S_IDLE;
                            CONTROL_DELAY3 <= S_IDLE;
                            CONTROL_DELAY4 <= S_IDLE;
                            doneWriting <= 1'b0;
                            STATE <= READ;
                        end
                        CONTROL[1] <= S_IDLE;
                    end
                    // Next: begin

                    // end
                endcase
            end
        
            default: begin
                if(i== N) begin
                    COMPLETED <= 1'b1;
                    s <= 1'bz;
                    i<= 1'bz;
                end
                else if (DONE[s][0] == 1'b1 && DONE[s][1] == 1'b1) begin 
                    doneWriting <= 1'b0;
                    CONTROL[s+1]<= S_IDLE;
                    CONTROL[s] <= S_IDLE;
                    CONTROL_DELAY1 <= S_IDLE;
                    CONTROL_DELAY2 <= S_IDLE;
                    CONTROL_DELAY3 <= S_IDLE;
                    CONTROL_DELAY4 <= S_IDLE;
                    for (x = 0; x <= 1; x = x +1) begin
                        din[x] <= 8'd0;
                        if(s > path_max_stage[x])begin
                            path_max_stage[x] <= s;
                        end
                    end
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

                    for (x = 0; x <= 1; x = x + 1 )begin
                        if(path_max_stage[x] < s) begin
                            L_a[x] <= douta[s+1][PathMother[x]];
                            L_b[x] <= doutb[s+1][PathMother[x]];
                        end
                        else begin
                            L_a[x] <= douta[s+1][x];
                            L_b[x] <= doutb[s+1][x];
                        end
                    end
                    for (x = 0; x <= 1; x = x +1) begin
                        din[x] <= L_out[x];
                    end
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
    else if (COMPLETED==1'b1 && readComplete[0] == 1'b0 && readComplete[1] == 1'b0) begin
        DELAY <= 1'b1;
        if (DELAY == 1'b1) begin
            dout <= U_feedback;
        end
        else begin
            dout <= 1'b0;
        end
    end
    else begin
        dout<= 1'b0;
    end
end

blk_mem_gen_1 Q_sequence (
  .clka(sysclk),    // input wire clka
  .ena(en_Q),      // input wire ena
  .addra(i),  // input wire [9 : 0] addra
  .douta(Qcheck)  // output wire [0 : 0] douta
);

BitonicSort BitonicSort_inst(
    .sysclk(sysclk),
    .sysres(sysres),
    .BS_en(BS_en),
    .path_matrix0(path_matrix[0]),
    .path_matrix1(path_matrix[1]),
    .path_matrix2(path_matrix[2]),
    .path_matrix3(path_matrix[3]),
    .index0(index0),
    .index1(index1),
    .BS_Updating(BS_Updating)
    );
endmodule
