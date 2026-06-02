`timescale 1ns/1ps

module tb;

    reg clk, reset, power_on, milk_present;
    reg [1:0] coin_in;
    reg coin_inserted;
    wire dispense;
    wire [3:0] change;

    // Instantiate DUT — fixed: power_on mapped to .test port
    coffee_machine dut (
        .clk(clk),
        .reset(reset),
        .coin_in(coin_in),
        .coin_inserted(coin_inserted),
        .test(power_on),        // FIXED: was .power_on(power_on)
        .milk_present(milk_present),
        .dispense(dispense),
        .change(change)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Immediate assertion — coin value must be non-zero when inserted
    always @(posedge clk) begin
        if (coin_inserted) begin
            assert (coin_in != 2'b00)
            else $error("Invalid coin inserted!");
        end
    end

    // Concurrent assertions
    // No dispense without sufficient payment
    assert property (@(posedge clk)
        dispense |-> (dut.total >= 7))
        else $error("TB: Dispense without enough money");

    // No dispense without milk
    assert property (@(posedge clk)
        !dut.milk_present |-> !dispense)
        else $error("Dispense happened without milk!");

    // Change correctness
    assert property (@(posedge clk)
        dispense |-> (change == (dut.total > 7 ? dut.total - 7 : 0)))
        else $error("TB: Incorrect change");

    // Timeout must trigger refund
    assert property (@(posedge clk)
        (dut.state == dut.COUNTING && dut.timeout_counter >= 3)
        |=> dut.state == dut.REFUND)
        else $error("TB: Timeout did not refund");

    // VCD dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
    end

    // Dynamic display
    always @(posedge clk) begin
        if (coin_inserted || dispense || change > 0)
            $display("Time=%0t | Coin=%0d | Dispense=%b | Change=%0d | Total=%0d",
                      $time, coin_in, dispense, change, dut.total);
    end

    initial begin
        // Initialize
        clk = 0; reset = 1; power_on = 0; milk_present = 1;
        coin_in = 0; coin_inserted = 0;
        #10 reset = 0;

        // ---- Test 1: Power OFF
        $display("[TEST 1] Power OFF - coin inserted but machine off");
        power_on = 0; coin_in = 2'b11; coin_inserted = 1; #10;
        coin_inserted = 0; #10;

        // ---- Test 2: Exact payment 7
        $display("[TEST 2] Exact Payment 7 rupees");
        power_on = 1;
        coin_in = 2'b11; coin_inserted = 1; #10;  // +3 = 3
        coin_inserted = 0; #10;
        coin_in = 2'b10; coin_inserted = 1; #10;  // +2 = 5
        coin_inserted = 0; #10;
        coin_in = 2'b10; coin_inserted = 1; #10;  // +2 = 7 → DISPENSE
        coin_inserted = 0; #10;

        // ---- Test 3: Overpayment 9
        $display("[TEST 3] Overpayment 9 rupees - expect change=2");
        coin_in = 2'b11; coin_inserted = 1; #10;  // +3 = 3
        coin_inserted = 0; #10;
        coin_in = 2'b11; coin_inserted = 1; #10;  // +3 = 6
        coin_inserted = 0; #10;
        coin_in = 2'b11; coin_inserted = 1; #10;  // +3 = 9 → DISPENSE, change=2
        coin_inserted = 0; #10;

        // ---- Test 4: Back-to-back orders
        $display("[TEST 4] Back-to-back orders");
        coin_in = 2'b11; coin_inserted = 1; #10;  // +3 = 3
        coin_inserted = 0; #10;
        coin_in = 2'b11; coin_inserted = 1; #10;  // +3 = 6
        coin_inserted = 0; #10;
        coin_in = 2'b01; coin_inserted = 1; #10;  // +1 = 7 → DISPENSE
        coin_inserted = 0; #10;

        // ---- Test 5: No milk
        $display("[TEST 5] No milk - expect NO_MILK state, full refund");
        milk_present = 0;
        coin_in = 2'b11; coin_inserted = 1; #10;  // +3
        coin_inserted = 0; #10;
        coin_in = 2'b11; coin_inserted = 1; #10;  // +3 = 6
        coin_inserted = 0; #10;
        coin_in = 2'b01; coin_inserted = 1; #10;  // +1 = 7 → NO_MILK, change=7
        coin_inserted = 0; #10;
        milk_present = 1;

        // ---- Test 6: Refund on timeout
        $display("[TEST 6] Refund on timeout - 6 rupees inserted, no more coins");
        coin_in = 2'b11; coin_inserted = 1; #10;  // +3 = 3
        coin_inserted = 0; #10;
        coin_in = 2'b10; coin_inserted = 1; #10;  // +2 = 5
        coin_inserted = 0; #10;
        coin_in = 2'b01; coin_inserted = 1; #10;  // +1 = 6
        coin_inserted = 0; #10;
        #30; // wait for timeout_counter >= 3 → REFUND, change=6

        $display("All 6 tests completed");
        $finish;
    end

endmodule
