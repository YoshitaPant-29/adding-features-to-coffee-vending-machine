`timescale 1ns / 1ps

module tb_coffee_machine_extended;
    reg clk;
    reg reset;
    reg [1:0] coin_in;
    reg coin_inserted;
    reg milk_available;
    reg coffee_available;
    reg cancel;

    wire dispense;
    wire [3:0] change;
    wire [3:0] refund;
    wire ready;
    wire error_no_supply;
    wire [3:0] balance;

    coffee_machine_extended dut (
        .clk(clk),
        .reset(reset),
        .coin_in(coin_in),
        .coin_inserted(coin_inserted),
        .milk_available(milk_available),
        .coffee_available(coffee_available),
        .cancel(cancel),
        .dispense(dispense),
        .change(change),
        .refund(refund),
        .ready(ready),
        .error_no_supply(error_no_supply),
        .balance(balance)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    initial begin
        $dumpfile("coffee_ext.vcd");
        $dumpvars(0, tb_coffee_machine_extended);

        // Scenario 1: power-on and supplies OK, exact payment
        reset = 1; coin_in = 0; coin_inserted = 0;
        milk_available = 1; coffee_available = 1; cancel = 0;
        #12; reset = 0;
        #50; // wait for power on + check

        // Insert coins summing to 7: 2 + 2 + 3
        coin_in = 2'b10; coin_inserted = 1; #10; coin_inserted = 0; #10; // +2
        coin_in = 2'b10; coin_inserted = 1; #10; coin_inserted = 0; #10; // +2 =4
        coin_in = 2'b11; coin_inserted = 1; #10; coin_inserted = 0; #10; // +3 =7

        #30; // allow dispense

        // Scenario 2: overpayment (3+3+3=9)
        coin_in = 2'b11; coin_inserted = 1; #10; coin_inserted = 0; #10; //3
        coin_in = 2'b11; coin_inserted = 1; #10; coin_inserted = 0; #10; //6
        coin_in = 2'b11; coin_inserted = 1; #10; coin_inserted = 0; #10; //9

        #30;

        // Scenario 3: insufficient then timeout refund (insert 2, wait)
        coin_in = 2'b01; coin_inserted = 1; #10; coin_inserted = 0; #10; // +1
        #200; // no more coins -> triggers insufficient (timeout)

        #30;

        // Scenario 4: supply missing
        milk_available = 0; coffee_available = 1;
        #20;
        // try inserting coin
        coin_in = 2'b11; coin_inserted = 1; #10; coin_inserted = 0; #10;

        #50;
        // restore supply
        milk_available = 1; coffee_available = 1;
        #30;

        $display("Testbench done.");
        $finish;
    end

endmodule
