# 8-Point NTT Hardware Accelerator
**Author: Hajjy Ismail**

Verilog implementation of a Number Theoretic Transform accelerator for polynomial multiplication in finite fields.

## Parameters

| Symbol | Value | Description |
|--------|-------|-------------|
| n | 8 | Transform size |
| q | 17 | Prime modulus |
| ω | 9 | Primitive 8th root of unity mod 17 |

## Design Explanation

This design implements an 8-point NTT over modulo q = 17 using a Gentleman-Sande DIF structure. A single butterfly unit is reused across all 3 stages. The FSM controls the stage counter, butterfly counter, address generation, twiddle selection, and writeback.

The design uses in-place memory updates to reduce storage cost. Twiddle factors are precomputed and stored in a small combinational ROM. Since q = 17 is small, the design uses simple modulo reduction, but for larger cryptographic primes Barrett or Montgomery reduction would be more appropriate.

## Architecture

```text
                    ┌─────────────────────────────────────┐
   in0..in7 ───────►│           8×5-bit Register File      │◄──── u, v writeback
   (start)          └────────┬──────────┬─────────────────┘
                             │ a        │ b
                    ┌────────▼──────────▼────────┐
                    │     BUTTERFLY UNIT          │
                    │  ┌─────┐ ┌─────┐ ┌──────┐  │
                    │  │ ADD │ │ SUB │ │ MULT │  │◄── tw (from ROM)
                    │  └──┬──┘ └──┬──┘ └──┬───┘  │
                    │     u      diff    v       │
                    └────────────────────────────┘
                                 ▲
                    ┌────────────┴────────────┐
                    │    TWIDDLE ROM (case)    │◄── stage, bfly
                    └─────────────────────────┘
                                 ▲
                    ┌────────────┴────────────┐
                    │    FSM CONTROL UNIT      │
                    │  stage_ctr  bfly_ctr     │◄── clk, rst_n, start
                    │  addr_gen   state        │───► done
                    └─────────────────────────┘
```

Iterative design using a single butterfly unit reused across 3 stages (12 clock cycles total).

**Butterfly** — Gentleman-Sande (DIF):
```
u = (a + b) mod q
v = ((a - b) · ω^k) mod q
```

**Control** — 3-state FSM: `IDLE → CALC → DONE`

**Memory** — 8×5-bit register array, in-place. Twiddle factors in combinational ROM.

## Structure

```
├── rtl/
│   └── ntt_8.v             # RTL top module
├── tb/
│   └── tb_ntt_8.v          # Testbench with automated assertions
├── data/
│   ├── input_0.txt          # Test 0: [1..8]
│   ├── expected_0.txt
│   ├── input_1.txt          # Test 1: all ones
│   └── expected_1.txt
├── sim/
│   ├── run.sh               # Linux/Mac build script
│   └── run.bat              # Windows build script
└── README.md
```

## Simulation

Requires [Icarus Verilog](http://iverilog.icarus.com/).

### Running the Simulation

```bash
# Compile and run
iverilog -o sim/ntt_sim.vvp rtl/ntt_8.v tb/tb_ntt_8.v
vvp sim/ntt_sim.vvp

# Or use the scripts
bash sim/run.sh       # Linux/Mac
sim\run.bat           # Windows
```

### Simulation Result

Command:
```bash
iverilog -o sim/ntt_sim.vvp rtl/ntt_8.v tb/tb_ntt_8.v
vvp sim/ntt_sim.vvp
```

Result:
```text
Test 0: PASS
Test 1: PASS
2 passed, 0 failed
```

## Trade-offs

| Decision | Benefit | Cost |
|----------|---------|------|
| Single butterfly | Minimal area | 12-cycle latency |
| Register array | Single-cycle access | Doesn't scale to large n |
| `%` for mod | Simple for q=17 | Needs Barrett/Montgomery for real primes |
| DIF (not DIT) | Natural input order | Requires output bit-reversal |

## Extensions

- **Inverse NTT** — use ω⁻¹, scale by n⁻¹ mod q
- **Pipelining** — register stages inside butterfly for higher Fmax
- **Larger sizes** — dual-port BRAM, parameterized counters
- **Modular multiply** — Barrett or Montgomery reduction for cryptographic primes
