`timescale 1ns/1ps

module coffee_machine (
    input  logic       clk,
    input  logic       reset,        // async active-high reset
    input  logic [1:0] coin_in,       // 01=₹1, 10=₹2, 11=₹3
    input  logic       coin_inserted,
    input  logic       power_on,
    input  logic       milk_present,
    output logic       dispense,
    output logic [3:0] change
);

    // ---------------- FSM STATE DEFINITION ----------------
    typedef enum logic [2:0] {
        IDLE,
        COUNTING,
        DISPENSE,
        NO_MILK,
        REFUND
    } state_t;

    state_t state, next_state;

    logic [3:0] total;
    logic [3:0] timeout_counter;

    localparam PRICE = 4'd7;

    // ---------------- COIN DECODER ----------------
    logic [3:0] coin_value;
    always_comb begin
        case (coin_in)
            2'b01: coin_value = 4'd1;
            2'b10: coin_value = 4'd2;
            2'b11: coin_value = 4'd3;
            default: coin_value = 4'd0;
        endcase
    end

    logic [3:0] next_total;
    assign next_total = (coin_inserted && coin_value > 0) ?
                         total + coin_value : total;

    // ---------------- STATE REGISTER ----------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            total <= 0;
            timeout_counter <= 0;
        end else begin
            state <= next_state;

            if (state == IDLE && power_on && coin_inserted && coin_value > 0) begin
                total <= coin_value;
                timeout_counter <= 0;
            end
            else if (state == COUNTING && power_on && coin_inserted && coin_value > 0) begin
                total <= next_total;
                timeout_counter <= 0;
            end
            else if (state == DISPENSE) begin
                total <= (total >= PRICE) ? (total - PRICE) : 0;
                timeout_counter <= 0;
            end
            else if (state == COUNTING && !coin_inserted) begin
                if (timeout_counter < 4)
                    timeout_counter <= timeout_counter + 1;
            end
            else if (state inside {REFUND, NO_MILK}) begin
                total <= 0;
                timeout_counter <= 0;
            end
        end
    end

    // ---------------- NEXT STATE + OUTPUT LOGIC ----------------
    always_comb begin
        next_state = state;
        dispense   = 0;
        change     = 0;

        case (state)
            IDLE: begin
                if (power_on && coin_inserted && coin_value > 0)
                    next_state = COUNTING;
            end

            COUNTING: begin
                if (!power_on && total > 0)
                    next_state = REFUND;
                else if (!milk_present && next_total >= PRICE)
                    next_state = NO_MILK;
                else if (coin_inserted && next_total >= PRICE)
                    next_state = DISPENSE;
                else if (timeout_counter >= 3 && total > 0)
                    next_state = REFUND;
            end

            DISPENSE: begin
                dispense = 1;
                change   = (total > PRICE) ? (total - PRICE) : 0;
                next_state = IDLE;
            end

            NO_MILK: begin
                change = total;
                next_state = IDLE;
            end

            REFUND: begin
                change = total;
                next_state = IDLE;
            end
        endcase
    end

    // ---------------- DESIGN ASSERTIONS ----------------

    // No X in state
    
    assert property (@(posedge clk)
    !$isunknown(state))
    else $error("X detected in FSM state");

    assert property (@(posedge clk)
        dispense |-> (total >= PRICE && milk_present))
        else $error("Illegal dispense");

endmodule
