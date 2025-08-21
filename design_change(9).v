// Code your design here
`timescale 1ns/1ps

module coffee_machine (
    input        clk,
    input        reset,          // active-high async reset
    input  [1:0] coin_in,        // 01=1, 10=2, 11=3
    input        coin_inserted,  // pulse per coin
    input        test,           // power enable
    input        milk_present,   // 1 = milk available, 0 = out of milk
    output reg   dispense,
    output reg [3:0] change
);

    // States
    parameter IDLE      = 3'b000,
              COUNTING  = 3'b001,
              DISPENSE  = 3'b010,
              NO_MILK   = 3'b011,
              REFUND    = 3'b100;

    reg [2:0] state, next_state;
    reg [3:0] total;
    reg [3:0] timeout_counter;

    // Coin value decode
    wire [3:0] coin_value = (coin_in==2'b01)?4'd1 :
                            (coin_in==2'b10)?4'd2 :
                            (coin_in==2'b11)?4'd3 : 4'd0;

    // Pre-calculate next_total
    wire [3:0] next_total = (coin_inserted && coin_value > 0) ? (total + coin_value) : total;

    // State update
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            total <= 0;
            timeout_counter <= 0;
        end else begin
            state <= next_state;

            // Counting coins
            if (state == IDLE && test && coin_inserted && coin_value > 0) begin
                total <= coin_value;
                timeout_counter <= 0;
            end
            else if (state == COUNTING && test && coin_inserted && coin_value > 0) begin
                total <= total + coin_value;
                timeout_counter <= 0;
            end
            else if (state == DISPENSE) begin
                if (total >= 7)
                    total <= total - 7;
                else
                    total <= 0;
                timeout_counter <= 0;
            end
            else if (state == REFUND || state == NO_MILK) begin
                total <= 0;
                timeout_counter <= 0;
            end
            else if (state == COUNTING && !coin_inserted) begin
                timeout_counter <= timeout_counter + 1;
            end
        end
    end

    // Next state and outputs
    always @(*) begin
        next_state = state;
        dispense = 0;
        change = 0;

        case (state)
            IDLE: begin
                if (test && coin_inserted && coin_value > 0)
                    next_state = COUNTING;
            end

            COUNTING: begin
                if (!test && total > 0)
                    next_state = REFUND;
                else if (!test)
                    next_state = IDLE;
                else if (!milk_present && (next_total >= 7))
                    next_state = NO_MILK;
                else if (coin_inserted && coin_value > 0) begin
                    if (next_total >= 7)
                        next_state = DISPENSE;
                end
                else if (timeout_counter >= 3 && total > 0)
                    next_state = REFUND;
            end

            DISPENSE: begin
                dispense = 1;
                if (total >= 7)
                    change = total - 7;
                next_state = IDLE;
            end

            NO_MILK: begin
                dispense = 0;
                change = total;
                next_state = IDLE;
            end

            REFUND: begin
                dispense = 0;
                change = total;
                next_state = IDLE;
            end
        endcase
    end

endmodule
