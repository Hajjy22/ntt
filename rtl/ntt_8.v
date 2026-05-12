`timescale 1ns/1ps

module ntt_8 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire [4:0] in0, in1, in2, in3, in4, in5, in6, in7,
    output reg        done,
    output reg  [4:0] out0, out1, out2, out3, out4, out5, out6, out7
);

    // Storage
    reg [4:0] mem [0:7];

    // FSM states
    localparam IDLE = 2'd0,
               CALC = 2'd1,
               DONE = 2'd2;

    reg [1:0] state;
    reg [1:0] stage;
    reg [1:0] bfly;

    // Address generation (DIF pattern)
    //   Stage 0, distance 4: (0,4)(1,5)(2,6)(3,7)
    //   Stage 1, distance 2: (0,2)(1,3)(4,6)(5,7)
    //   Stage 2, distance 1: (0,1)(2,3)(4,5)(6,7)
    wire [2:0] i0, i1;

    assign i0 = (stage == 0) ? {1'b0, bfly[1:0]}              :
                (stage == 1) ? {bfly[1], 1'b0, bfly[0]}       :
                               {bfly[1:0], 1'b0};

    assign i1 = (stage == 0) ? {1'b1, bfly[1:0]}              :
                (stage == 1) ? {bfly[1], 1'b1, bfly[0]}       :
                               {bfly[1:0], 1'b1};

    // Twiddle ROM (w=9, w^k mod 17)
    reg [4:0] tw;
    always @(*) begin
        case (stage)
            2'd0: case (bfly)
                      2'd0: tw = 5'd1;
                      2'd1: tw = 5'd9;
                      2'd2: tw = 5'd13;
                      2'd3: tw = 5'd15;
                  endcase
            2'd1: tw = bfly[0] ? 5'd13 : 5'd1;
            2'd2: tw = 5'd1;
            default: tw = 5'd1;
        endcase
    end

    // Butterfly datapath (Gentleman-Sande)
    wire [4:0] a = mem[i0];
    wire [4:0] b = mem[i1];

    wire [5:0] sum  = a + b;
    wire [4:0] u    = (sum >= 6'd17) ? (sum - 6'd17) : sum[4:0];

    wire [4:0] diff = (a >= b) ? (a - b) : (a + 5'd17 - b);
    wire [9:0] prod = diff * tw;
    wire [4:0] v    = prod % 17;

    // FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done  <= 0;
            stage <= 0;
            bfly  <= 0;
            out0  <= 0; out1 <= 0; out2 <= 0; out3 <= 0;
            out4  <= 0; out5 <= 0; out6 <= 0; out7 <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        mem[0] <= in0; mem[1] <= in1;
                        mem[2] <= in2; mem[3] <= in3;
                        mem[4] <= in4; mem[5] <= in5;
                        mem[6] <= in6; mem[7] <= in7;
                        stage <= 0;
                        bfly  <= 0;
                        state <= CALC;
                    end
                end

                CALC: begin
                    mem[i0] <= u;
                    mem[i1] <= v;
                    if (bfly == 3) begin
                        bfly <= 0;
                        if (stage == 2)
                            state <= DONE;
                        else
                            stage <= stage + 1;
                    end else begin
                        bfly <= bfly + 1;
                    end
                end

                DONE: begin
                    done <= 1;
                    // Bit-reverse permutation (3-bit)
                    out0 <= mem[0]; out1 <= mem[4];
                    out2 <= mem[2]; out3 <= mem[6];
                    out4 <= mem[1]; out5 <= mem[5];
                    out6 <= mem[3]; out7 <= mem[7];
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
