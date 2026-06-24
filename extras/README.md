# Proof Artifacts and Extras

This folder contains verification and implementation artifacts for the Brain-Wave Recognizer project, as well as the Full Constraints for NEXYS 4 Board.

The artifacts are organized by verification stages:

```text
extras/
  hls/
  simulation/
  vivado/
  NEXYS4 DDR Full Constraints.xdc
```

## HLS proofs

Folder: `extras/hls/`

| File                                             | Meaning                                             |
| ------------------------------------------------ | --------------------------------------------------- |
| `01_csim_log.txt`                                | Vitis HLS C simulation log                          |
| `02_csynth_log.txt`                              | Vitis HLS synthesis command log                     |
| `03_brainwave_recognizer_csynth.rpt`             | HLS synthesis report with timing/resource estimates |
| `04_cosim_log.txt`                               | C/RTL co-simulation log                             |
| `05_brainwave_recognizer_cosim.rpt`              | C/RTL co-simulation report                          |
| `06_export_ip_log.txt`                           | HLS IP export log                                   |
| `07_brainwave_recognizer_component.xml`          | Exported HLS IP metadata                            |
| `08_xilinx_com_hls_brainwave_recognizer_1_0.zip` | Exported HLS IP archive                             |

The HLS testbench verifies:

* Alpha-band positive detection
* `sample_valid = false` hold behavior
* Rejection of a Beta-frequency signal by the Alpha filter
* Positive detection for all five supported bands
* Safe clamping of invalid selectors
* Threshold-level behavior

Key result:

```text
All HLS tests passed.
C/RTL co-simulation finished: PASS
```

## RTL simulation proofs

Folder: `extras/simulation/`

| File                                       | Meaning                                              |
| ------------------------------------------ | ---------------------------------------------------- |
| `01_tb_test_signal_generator_console.txt`  | Console log for the test signal generator simulation |
| `02_tb_test_signal_generator_waveform.png` | Waveform screenshot for the test signal generator    |
| `03_tb_vga_display_console.txt`            | Console log for the VGA display simulation           |
| `04_tb_vga_display_waveform.png`           | Waveform screenshot for the VGA display              |
| `05_tb_pwm_audio_console.txt`              | Console log for the PWM audio simulation             |
| `06_tb_pwm_audio_waveform.png`             | Waveform screenshot for the PWM audio block          |

### Test signal generator

Verifies that `sample_valid` pulses at the expected 128 Hz logical sample rate when the module is clocked at 25 MHz. Also checks that Alpha mode produces changing nonzero samples and that silence mode forces `sample_out = 0`.

Key result:

```text
tb_test_signal_generator passed: 25 MHz / 128 Hz timing and mode behavior are OK.
```

### VGA display

Verifies that the VGA display compiles with the waveform buffer, generates the expected VGA timing, blanks RGB outside the visible region, and changes the top banner color when detection is active.

Key result:

```text
tb_vga_display passed: interface, timing, blanking, and banner colour checks are OK.
```

### PWM audio

Verifies that `audio_pwm` stays silent when detection is inactive, toggles when detection is active, works for all valid band selectors, and handles an invalid selector safely.

Key result:

```text
tb_pwm_audio passed.
```

## Vivado implementation proofs

Folder: `extras/vivado/`

| File                           | Meaning                                |
| ------------------------------ | -------------------------------------- |
| `01_synth_utilization.rpt`     | Synthesis utilization report           |
| `02_synth_timing_summary.rpt`  | Synthesis timing estimate              |
| `03_impl_utilization.rpt`      | Post-implementation utilization report |
| `04_impl_timing_summary.rpt`   | Post-implementation timing report      |
| `05_impl_power.rpt`            | Post-implementation power estimate     |
| `06_impl_drc.rpt`              | Design rule check report               |
| `07_io_report.rpt`             | IO placement and pin report            |
| `08_clock_networks.rpt`        | Clock network report                   |
| `09_brain_wave_recognizer.bit` | Generated bitstream                    |
| `10_design_scheme.png`         | Block design screenshot                |
| `11_design.v`                  | Generated block design HDL             |
| `12_design_wrapper.v`          | Generated top-level wrapper            |

The most important implementation proof is `04_impl_timing_summary.rpt`. It shows that post-implementation timing is met.

Key result:

```text
All user specified timing constraints are met.
```

The IO report confirms the external mappings for:

* `sys_clk`
* `rst`
* `vga_r[3:0]`
* `vga_g[3:0]`
* `vga_b[3:0]`
* `vga_hsync`
* `vga_vsync`
* `audio_pwm`

## DRC notes

DRC report contains only warnings, but the design is still valid. In this project, the relevant warnings are optimization/configuration warnings, not functional errors.

The DSP pipelining warnings indicate that Vivado recommends more internal DSP pipeline stages. Since the final implementation timing passes, these are not blocking.

## Hardware proof

TODO
