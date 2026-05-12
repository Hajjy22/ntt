`timescale 1ns/1ps

module tb_ntt_8;

    reg clk, rst_n, start;
    reg [4:0] in [0:7];
    reg [4:0] exp [0:7];

    wire done;
    wire [4:0] out0, out1, out2, out3, out4, out5, out6, out7;

    ntt_8 dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .in0(in[0]), .in1(in[1]), .in2(in[2]), .in3(in[3]),
        .in4(in[4]), .in5(in[5]), .in6(in[6]), .in7(in[7]),
        .done(done),
        .out0(out0), .out1(out1), .out2(out2), .out3(out3),
        .out4(out4), .out5(out5), .out6(out6), .out7(out7)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count;
    integer fail_count;

    task run_test(input [255:0] in_file, input [255:0] exp_file);
        begin
            $readmemh(in_file, in);
            $readmemh(exp_file, exp);

            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            wait(done);
            @(posedge clk);

            $display("  Input:    %0d %0d %0d %0d %0d %0d %0d %0d",
                      in[0], in[1], in[2], in[3],
                      in[4], in[5], in[6], in[7]);
            $display("  Output:   %0d %0d %0d %0d %0d %0d %0d %0d",
                      out0, out1, out2, out3,
                      out4, out5, out6, out7);
            $display("  Expected: %0d %0d %0d %0d %0d %0d %0d %0d",
                      exp[0], exp[1], exp[2], exp[3],
                      exp[4], exp[5], exp[6], exp[7]);

            if (out0===exp[0] && out1===exp[1] && out2===exp[2] && out3===exp[3] &&
                out4===exp[4] && out5===exp[5] && out6===exp[6] && out7===exp[7]) begin
                $display("  Result:   PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("  Result:   FAIL");
                fail_count = fail_count + 1;
            end
            $display("");
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        rst_n = 0; start = 0;
        #20;
        rst_n = 1;
        #10;

        $display("");
        $display("========================================");
        $display(" NTT-8 Testbench  (n=8, q=17, w=9)");
        $display("========================================");
        $display("");

        $display("--- Test 0 ---");
        run_test("data/input_0.txt", "data/expected_0.txt");

        $display("--- Test 1 ---");
        run_test("data/input_1.txt", "data/expected_1.txt");

        $display("========================================");
        $display(" %0d passed, %0d failed", pass_count, fail_count);
        $display("========================================");

        $finish;
    end

    initial begin
        $dumpfile("sim/ntt.vcd");
        $dumpvars(0, tb_ntt_8);
    end

endmodule
