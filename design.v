`timescale 1ns / 1ps

module coffee_machine_extended (
    input          clk,
    input          reset,             // active-high
    input  [1:0]   coin_in,           // 01=1,10=2,11=3
    input          coin_inserted,     // pulse per coin
    input          milk_available,
    input          coffee_available,
    input          cancel,            // user cancels / wants refund

    output reg     dispense,          // coffee out
    output reg [3:0] change,          // change back
    output reg [3:0] refund,          // refund on insufficient/cancel
    output reg     ready,             // machine ready after power-on & supplies ok
    output reg     error_no_supply,   // supply missing
    output reg [3:0] balance          // current total inserted
);

    // Price constant
    localparam PRICE = 4'd7;
    localparam TIMEOUT_LIMIT = 4'd8; // cycles of inactivity before insufficient

    // States
    localparam POWER_ON       = 3'd0;
    localparam CHECK_SUPPLIES = 3'd1;
    localparam IDLE           = 3'd2;
    localparam COUNTING       = 3'd3;
    localparam INSUFFICIENT   = 3'd4;
    localparam DISPENSE       = 3'd5;
    localparam ERROR          = 3'd6;

    reg [2:0] state, next_state;
    reg [3:0] timeout_cnt;
    reg [3:0] power_on_cnt;

    // Decode coin value
    wire [3:0] coin_value = (coin_in == 2'b01) ? 4'd1 :
                            (coin_in == 2'b10) ? 4'd2 :
                            (coin_in == 2'b11) ? 4'd3 : 4'd0;

    // Sequential state and counters
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state          <= POWER_ON;
            balance        <= 0;
            timeout_cnt    <= 0;
            power_on_cnt   <= 0;
            dispense       <= 0;
            change         <= 0;
            refund         <= 0;
            ready          <= 0;
            error_no_supply<= 0;
        end else begin
            state <= next_state;

            // default outputs off unless set in state logic
            dispense <= 0;
            change   <= 0;
            refund   <= 0;

            case (state)
                POWER_ON: begin
                    power_on_cnt <= power_on_cnt + 1;
                    if (power_on_cnt >= 4) begin
                        // done with power-on delay
                    end
                end

                CHECK_SUPPLIES: begin
                    // nothing to accumulate here
                end

                IDLE: begin
                    balance <= 0;
                    timeout_cnt <= 0;
                end

                COUNTING: begin
                    if (coin_inserted && coin_value > 0) begin
                        balance <= balance + coin_value;
                        timeout_cnt <= 0;
                    end else begin
                        timeout_cnt <= timeout_cnt + 1;
                    end
                end

                INSUFFICIENT: begin
                    refund <= balance;
                    balance <= 0;
                    timeout_cnt <= 0;
                end

                DISPENSE: begin
                    dispense <= 1;
                    if (balance >= PRICE)
                        change <= balance - PRICE;
                    balance <= 0;
                    timeout_cnt <= 0;
                end

                ERROR: begin
                    // could refund leftover if any
                    if (balance > 0) begin
                        refund <= balance;
                        balance <= 0;
                    end
                end
            endcase
        end
    end

    // Next-state logic
    always @(*) begin
        // defaults
        next_state = state;
        ready = 0;
        error_no_supply = 0;

        case (state)
            POWER_ON: begin
                if (power_on_cnt >= 4)
                    next_state = CHECK_SUPPLIES;
            end

            CHECK_SUPPLIES: begin
                if (milk_available && coffee_available) begin
                    ready = 1;
                    next_state = IDLE;
                end else begin
                    error_no_supply = 1;
                    next_state = ERROR;
                end
            end

            IDLE: begin
                if (coin_inserted && coin_value > 0)
                    next_state = COUNTING;
            end

            COUNTING: begin
                if (!milk_available || !coffee_available) begin
                    next_state = ERROR;
                end else if (balance >= PRICE) begin
                    next_state = DISPENSE;
                end else if (cancel) begin
                    next_state = INSUFFICIENT;
                end else if (timeout_cnt >= TIMEOUT_LIMIT && balance > 0) begin
                    next_state = INSUFFICIENT;
                end
            end

            INSUFFICIENT: begin
                next_state = IDLE;
            end

            DISPENSE: begin
                next_state = IDLE;
            end

            ERROR: begin
                // after error, go to CHECK again to retry
                if (milk_available && coffee_available)
                    next_state = CHECK_SUPPLIES;
            end
        endcase
    end

endmodule
