// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

module tb;

    reg clk, reset, test, milk_present;
    reg [1:0] coin_in;
    reg coin_inserted;
    wire dispense;
    wire [3:0] change;

    // Instantiate DUT
    coffee_machine dut (
        .clk(clk),
        .reset(reset),
        .coin_in(coin_in),
        .coin_inserted(coin_inserted),
        .test(test),
        .milk_present(milk_present),
        .dispense(dispense),
        .change(change)
    );

    // Clock generation
    always #5 clk = ~clk;

    // VCD dump for waveform viewing
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
    end

    // Print signals dynamically
    always @(posedge clk) begin
        if (coin_inserted || dispense || change > 0)
            $display("Time=%0t | Coin=%0d | Dispense=%b | Change=%0d | Total=%0d",
                      $time, coin_in, dispense, change, dut.total);
    end

    initial begin
        // Initialize
        clk = 0; reset = 1; test = 0; milk_present = 1;
        coin_in = 0; coin_inserted = 0;
        #10 reset = 0;

        // ---- Test 1: Power OFF
        $display("[TEST 1] Power OFF");
        test = 0; coin_in = 2'b11; coin_inserted = 1; #10;
        coin_inserted = 0; #10;

        // ---- Test 2: Exact payment 7
        $display("[TEST 2] Exact Payment 7");
        test = 1;
        coin_in = 2'b11; coin_inserted = 1; #10;  // 3
        coin_inserted = 0; #10;
        coin_in = 2'b10; coin_inserted = 1; #10;  // 2 -> total=5
        coin_inserted = 0; #10;
        coin_in = 2'b10; coin_inserted = 1; #10;  // 2 -> total=7
        coin_inserted = 0; #10;

        // ---- Test 3: Overpayment 9
        $display("[TEST 3] Overpayment 9");
        coin_in = 2'b11; coin_inserted = 1; #10; // 3
        coin_inserted = 0; #10;
        coin_in = 2'b11; coin_inserted = 1; #10; // 3 -> total=6
        coin_inserted = 0; #10;
        coin_in = 2'b11; coin_inserted = 1; #10; // 3 -> total=9
        coin_inserted = 0; #10;

        // ---- Test 4: Back-to-back orders
        $display("[TEST 4] Back-to-back orders");
        coin_in = 2'b11; coin_inserted = 1; #10; // 3
        coin_inserted = 0; #10;
        coin_in = 2'b11; coin_inserted = 1; #10; // 3
        coin_inserted = 0; #10;
        coin_in = 2'b01; coin_inserted = 1; #10; // 1 -> total=7
        coin_inserted = 0; #10;

        // ---- Test 5: No milk
        $display("[TEST 5] No milk");
        milk_present = 0;
        coin_in = 2'b11; coin_inserted = 1; #10;
        coin_inserted = 0; #10;
        milk_present = 1;

        // ---- Test 6: Refund on timeout
        $display("[TEST 6] Refund on timeout (6 rupees)");
        coin_in = 2'b11; coin_inserted = 1; #10; // 3
        coin_inserted = 0; #10;
        coin_in = 2'b10; coin_inserted = 1; #10; // 2 -> total=5
        coin_inserted = 0; #10;
        coin_in = 2'b01; coin_inserted = 1; #10; // 1 -> total=6
        coin_inserted = 0; #10;
        #30; // wait timeout cycles

        $display("All tests completed");
        $finish;
    end

endmodule
