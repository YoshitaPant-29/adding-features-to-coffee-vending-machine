# coffee-vending-machine with Verification plans
📌 Overview

This project implements a Coffee Vending Machine in Verilog with verification using a self-checking testbench.
It supports multiple payment scenarios, refund on timeout, and resource availability checks (like milk).
The design demonstrates FSM (Finite State Machine) based hardware design, assertions, and test-driven verification.

⚙️ Features

✅ FSM-based coffee machine controller
✅ Accepts coins and validates payments
✅ Refunds extra coins or on timeout
✅ Handles back-to-back orders
✅ Resource check (milk availability)
✅ Assertions for safety checks

Assertions Used

Immediate assertions for payment validity
Concurrent assertions for FSM safety

🎯 Learning Outcomes
Sign Scope
- 5 FSM states (IDLE, COUNTING, DISPENSE, NO_MILK, REFUND).
- 3 coin inputs (₹1/₹2/₹3).
- Coffee price = ₹7.

Verification
- Wrote 6 directed test scenarios (power-off, exact pay, overpay, back-to-back, no milk, refund on timeout).
- Simulated 50+ clock cycles per test, validating all state transitions.
- Used assertions to ensure coin validity, FSM safety, and correct refunds.
Results

✅ Verified 100% state coverage (all 5 states exercised in simulation).
✅ Verified 100% functional scenarios (all payment/refund/milk cases tested).
- Generated VCD waveforms as proof of correctness.

FSM design in SystemVerilog
- Writing self-checking testbenches
- Using immediate + concurrent assertions
- Simulation & waveform analysis
