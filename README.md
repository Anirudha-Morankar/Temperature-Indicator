# Digital Thermometer Range Detector — FPGA Project

A Verilog-based digital logic circuit implemented on an FPGA Zynq-7000 family (Blackboard development board) that detects when a digitized temperature reading falls within the range of **62.5°C to 72.5°C**, lighting up an LED as the output indicator.

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Project Overview](#2-project-overview)
3. [How the Problem Was Addressed](#3-how-the-problem-was-addressed)
4. [K-Map Simplification](#4-k-map-simplification)
5. [Verilog Implementation & XDC Constraints](#5-verilog-implementation--xdc-constraints)
6. [Testbench](#6-testbench)
7. [Skills Demonstrated](#7-skills-demonstrated)

---

## 1. Problem Statement

A digital thermometer produces a continuously varying voltage signal between **0 V and 5 V**, where:
- **0 V** → 0°C
- **5 V** → 100°C

This analog signal is digitized using an **8-bit Analog-to-Digital Converter (ADC)**, producing a binary number proportional to the temperature:
- `00000000` → 0°C
- `11111111` → 100°C

Each binary step represents a temperature increment of **100/255 ≈ 0.392°C**.

**Task:** Design a combinational logic circuit that outputs a **logic HIGH** signal whenever the temperature is **greater than 62.5°C but less than 72.5°C**. The circuit is implemented on a Blackboard FPGA board, where:
- **8 slide switches** emulate the 8-bit ADC output
- **1 LED** lights up when the temperature is within the desired range

---

## 2. Project Overview

The design follows the complete FPGA development workflow:

1. Identify the binary range corresponding to 62.5°C–72.5°C using Excel (`DEC2BIN()`)
2. Analyze bit patterns and reduce the problem using K-maps
3. Derive a minimized Boolean expression
4. Implement the circuit in **Verilog HDL**
5. Simulate with a testbench in **Vivado Simulator**
6. Map I/O to physical FPGA pins using the **XDC constraints file**
7. Generate a **bitstream** and program the Blackboard
8. Verify hardware behavior using switches and LED

---

## 3. How the Problem Was Addressed

### 3.1 Voltage-to-Temperature Mapping

The ADC linearly maps the 0–5 V range into 256 discrete binary values (0–255). The relationship is:

```
Temperature (°C) = ADC_decimal × (100 / 255)
```

So:
- 0 V → ADC = 0 → 0°C
- 5 V → ADC = 255 → 100°C
- Each 1-bit increment → 100/255 ≈ **0.3922°C**

### 3.2 Temperature Corresponding to Each Switch Value

The table below shows how each switch (ADC decimal value) maps to a temperature. A spreadsheet was used to generate all 256 values using Excel's `DEC2BIN()` function. A representative extract is shown:

| Switch (Decimal) | Binary     | Temperature (°C) |
|-----------------|------------|------------------|
| 0               | `00000000` | 0.0000           |
| 1               | `00000001` | 0.3922           |
| 2               | `00000010` | 0.7843           |
| 3               | `00000011` | 1.1765           |
| 4               | `00000100` | 1.5686           |
| 5               | `00000101` | 1.9608           |
| 6               | `00000110` | 2.3529           |
| 7               | `00000111` | 2.7451           |
| ...             | ...        | ...              |
| 254             | `11111110` | 99.6078          |
| 255             | `11111111` | 100.0000         |

> The full 256-row table is available in `docs/temperature_table.xlsx`.

### 3.3 Finding the Binary Range for Logic HIGH Output

The target temperature range is **> 62.5°C and < 72.5°C**. Converting the boundary temperatures to ADC decimal values:

```
62.5°C → ADC = 62.5 × (255 / 100) = 159.375  → first integer above = 160
72.5°C → ADC = 72.5 × (255 / 100) = 184.875  → last integer below  = 184
```

**Active range: decimal 160 to 184 (inclusive)**

The LED output is HIGH for exactly **25 binary values** (160 through 184):

| Decimal | Binary     | Temperature (°C) | Output |
|---------|------------|-----------------|--------|
| 159     | `10011111` | 62.35           | LOW    |
| **160** | **`10100000`** | **62.75**   | **HIGH** |
| 161     | `10100001` | 63.14           | HIGH   |
| 162     | `10100010` | 63.53           | HIGH   |
| 163     | `10100011` | 63.92           | HIGH   |
| 164     | `10100100` | 64.31           | HIGH   |
| 165     | `10100101` | 64.71           | HIGH   |
| 166     | `10100110` | 65.10           | HIGH   |
| 167     | `10100111` | 65.49           | HIGH   |
| 168     | `10101000` | 65.88           | HIGH   |
| 169     | `10101001` | 66.27           | HIGH   |
| 170     | `10101010` | 66.67           | HIGH   |
| 171     | `10101011` | 67.06           | HIGH   |
| 172     | `10101100` | 67.45           | HIGH   |
| 173     | `10101101` | 67.84           | HIGH   |
| 174     | `10101110` | 68.24           | HIGH   |
| 175     | `10101111` | 68.63           | HIGH   |
| 176     | `10110000` | 69.02           | HIGH   |
| 177     | `10110001` | 69.41           | HIGH   |
| 178     | `10110010` | 69.80           | HIGH   |
| 179     | `10110011` | 70.20           | HIGH   |
| 180     | `10110100` | 70.59           | HIGH   |
| 181     | `10110101` | 70.98           | HIGH   |
| 182     | `10110110` | 71.37           | HIGH   |
| 183     | `10110111` | 71.76           | HIGH   |
| **184** | **`10111000`** | **72.16**   | **HIGH** |
| 185     | `10111001` | 72.55           | LOW    |

### 3.4 Understanding the Bit Pattern

Examining the binary values from 160 to 184 reveals a structural pattern in the upper bits:

```
160 = 1 0 1 0 0 0 0 0
161 = 1 0 1 0 0 0 0 1
...
175 = 1 0 1 0 1 1 1 1
176 = 1 0 1 1 0 0 0 0
...
184 = 1 0 1 1 1 0 0 0
      ^ ^ ^
      A7 A6 A5  ← Always 1, 0, 1 for the entire active range
```

**Key observations:**

- **Bits A7, A6, A5 = `1, 0, 1`** for every value in the active range — this eliminates 3 of the 8 bits from K-map consideration, since these three must always be `101`.
- **Bit A4** splits the range into two sub-groups:
  - **A4 = 0** → decimal 160–175: lower nibble `A3A2A1A0` spans `0000` to `1111` — **all 16 values are HIGH**
  - **A4 = 1** → decimal 176–184: lower nibble spans `0000` to `1000` — only **9 of 16 values are HIGH**
- This allows the K-map to be built using only **4 inputs (A3, A2, A1, A0)**, drawn separately for A4=0 and A4=1.

---

## 4. K-Map Simplification

The top 3 bits (A7=1, A6=0, A5=1) are a fixed precondition. The K-maps below use bits **A3, A2, A1, A0** as variables, and are drawn separately for **A4 = 0** and **A4 = 1**.

Bit labeling (MSB to LSB):

```
Bit position:  A7  A6  A5  A4  A3  A2  A1  A0
               [7] [6] [5] [4] [3] [2] [1] [0]
```

---

### K-Map 1: A4 = 0 (Decimal 160–175)

When A4 = 0, all 16 combinations of A3A2A1A0 produce values in the active range → **all cells = 1**.

K-map axes use Gray code ordering: `00, 01, 11, 10`

| A3A2 \ A1A0 | 00 | 01 | 11 | 10 |
|:-----------:|:--:|:--:|:--:|:--:|
| **00**      | 1  | 1  | 1  | 1  |
| **01**      | 1  | 1  | 1  | 1  |
| **11**      | 1  | 1  | 1  | 1  |
| **10**      | 1  | 1  | 1  | 1  |

**All 16 cells = 1** → The entire group is covered by a single term.

**Simplified expression for A4 = 0:**
```
K1 = 1   (output is always HIGH when A7A6A5A4 = 1010)
~A4    (A4 is 0 and the k-map index values are 1)
```

---

### K-Map 2: A4 = 1 (Decimal 176–191, only 176–184 are HIGH)

When A4 = 1, the active values are 176–184, corresponding to lower nibble values 0 (`0000`) through 8 (`1000`). Values 9 (`1001`) through 15 (`1111`) are outside the range → **those cells = 0**.

Cell values (decimal offset from 176):

| Lower nibble | Decimal | In range? | Cell value |
|---|---|---|---|
| `0000` (0) | 176 | YES | 1 |
| `0001` (1) | 177 | YES | 1 |
| `0010` (2) | 178 | YES | 1 |
| `0011` (3) | 179 | YES | 1 |
| `0100` (4) | 180 | YES | 1 |
| `0101` (5) | 181 | YES | 1 |
| `0110` (6) | 182 | YES | 1 |
| `0111` (7) | 183 | YES | 1 |
| `1000` (8) | 184 | YES | 1 |
| `1001` (9) | 185 | NO  | 0 |
| `1010` (10)| 186 | NO  | 0 |
| `1011` (11)| 187 | NO  | 0 |
| `1100` (12)| 188 | NO  | 0 |
| `1101` (13)| 189 | NO  | 0 |
| `1110` (14)| 190 | NO  | 0 |
| `1111` (15)| 191 | NO  | 0 |

**K-Map (A4 = 1):**

| A3A2 \ A1A0 | 00 | 01 | 11 | 10 |
|:-----------:|:--:|:--:|:--:|:--:|
| **00**      | 1  | 1  | 1  | 1  |
| **01**      | 1  | 1  | 1  | 1  |
| **11**      | 0  | 0  | 0  | 0  |
| **10**      | 1  | 0  | 0  | 0  |

**Grouping the 1-cells:**

- **Group 1 (8-cell):** All cells where A3=0 (rows `00` and `01`) → covers minterms 0,1,2,3,4,5,6,7
  - Simplified term: **A3'** (A3 = 0, A2/A1/A0 don't care)
- **Group 2 (1-cell):** Cell A3A2A1A0 = `1000` (minterm 8, decimal 184)
  - Simplified term: **A2'·A1'·A0'**

**Simplified expression for A4 = 1:**
```
K2 = A3' + (A2'·A1'·A0')
```

---

### Final Boolean Expression

Combining both K-maps with the fixed precondition (A7=1, A6=0, A5=1):

```
OUTPUT = A7 · A6' · A5 · [ A4' + A3' + A2'·A1'·A0' ]
```
Where A7 is the MSB and A0 is the LSB.

---

## 5. Verilog Implementation & XDC Constraints

### Top-Level Module (`thermometer_detector.v`)

```
verilog
module thermometer_detector(
    input [7:0] A,
    output [0:0] led
);

    assign led[0] = A[7] & ~A[6] & A[5] &(~A[4] |~A[3] |(~A[2] & ~A[1] & ~A[0]));

endmodule
```

### XDC Constraints File (`blackboard.xdc`)

The XDC file maps Verilog port names to physical FPGA pins on the Blackboard board:

> Pin assignments should be verified against the official Blackboard XDC reference file for your board revision.

### Bitstream Generation & Programming

1. **Synthesis** → `Flow → Run Synthesis`
2. **Implementation** → `Flow → Run Implementation`
3. **Bitstream** → `Flow → Generate Bitstream`
4. **Program the Board:**
   - Connect Blackboard via UART Port
   - `Flow → Open Hardware Manager → Open Target → Auto Connect`
   - Click **Program Device**

---


### Running the Simulation in Vivado

1. Add `thermometer_detector.v` and `thermometer_detector_tb.v` to the Vivado project
2. Set `thermometer_detector_tb` as the **Simulation Top** module
3. Go to `Flow → Run Simulation → Run Behavioral Simulation`
4. In the waveform viewer, observe that `led_out` is HIGH **only** for ADC values 160–184
5. Confirm boundary transitions at values 159→160 (OFF→ON) and 184→185 (ON→OFF)

---

## 6. Skills Demonstrated

| Skill | Application in This Project |
|---|---|
| **Verilog HDL** | Designed the combinational logic module using structural Boolean `assign` statements derived from K-map analysis |
| **K-Map Simplification** | Used Karnaugh maps to minimize a 4-variable Boolean function, split by the A4 bit to reduce complexity |
| **Vivado Design Suite** | Created and managed the full Vivado project including source files, simulation sets, and implementation runs |
| **Vivado Simulation (xsim)** | Wrote and executed a complete Verilog testbench; verified functional correctness via waveform analysis |
| **Vivado XDC File** | Authored the physical constraint file to map design ports to slide switches and LED pins on the Blackboard |
| **Bitstream Generation** | Ran synthesis, implementation, and bitstream generation through the Vivado flow for FPGA programming |
| **FPGA Hardware Hands-On** | Programmed and tested the Blackboard FPGA board using physical switches to emulate ADC input |
| **Excel for Digital Design** | Used `DEC2BIN()` and scaled formulas to build a full 256-row truth table for range identification |

---

## Project Structure

```
fpga-thermometer-range-detector/
├── src/
│   ├── thermometer_detector.v        # Top-level RTL Verilog module
│   └── thermometer_detector_tb.v     # Simulation testbench
├── constraints/
│   └── blackboard.xdc                # Vivado XDC pin constraints
├── docs/
│   └── temperature_table.xlsx        # Excel truth table (DEC2BIN mapping)
└── README.md
```

---

