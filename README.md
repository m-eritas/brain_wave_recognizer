# Brain-Wave Recognizer

FPGA/HLS project for real-time EEG-like band detection on the Nexys 4 DDR board.

The design generates synthetic EEG-like input samples, filters them with a Vitis HLS FIR-based band detector, and displays the result on a VGA dashboard. A PWM audio output is also generated when the selected band is detected.

## Target

* Board: Nexys 4 DDR
* FPGA part: `xc7a100tcsg324-1`
* Toolchain: Vitis HLS 2024.1 / Vivado 2024.1
* Main clock input: 100 MHz board clock
* Internal display/system clock: 25 MHz from Clocking Wizard
* Logical EEG sample rate: 128 Hz

## Main features

* 32-tap FIR band-pass filtering in Vitis HLS
* Five selectable EEG-like bands: Delta, Theta, Alpha, Beta, Gamma
* `sample_valid` input so the HLS detector updates only at the logical EEG sample rate
* Envelope extraction and threshold comparison
* VGA dashboard with:

  * detection-status banner
  * envelope bar
  * threshold marker
  * raw input waveform plot
* PWM audio sonification when detection is active
* HLS C simulation and C/RTL co-simulation testbench
* RTL simulations for the signal generator, VGA display, and PWM audio block

## Supported bands

| Selector | Band  | Test frequency | Approximate band range |
| -------: | ----- | -------------: | ---------------------- |
|        0 | Delta |           2 Hz | 0.5–4 Hz               |
|        1 | Theta |           6 Hz | 4–8 Hz                 |
|        2 | Alpha |          10 Hz | 8–12 Hz                |
|        3 | Beta  |          20 Hz | 12–30 Hz               |
|        4 | Gamma |          40 Hz | 30–62 Hz               |

The sample rate is 128 Hz, so the Nyquist frequency is 64 Hz. For this reason, the Gamma band is limited to 30–62 Hz in this project.

## Demo configuration

The default demo configuration is Alpha detection:

| Signal          | Value | Meaning                                             |
| --------------- | ----: | --------------------------------------------------- |
| `mode`          |   `3` | test signal generator outputs 10 Hz Alpha-like sine |
| `band_sel`      |   `2` | HLS detector selects Alpha FIR coefficients         |
| `threshold_sel` |   `1` | medium detection threshold                          |

Expected behavior:

* VGA top banner turns bright green when Alpha is detected.
* Envelope bar rises above the threshold marker.
* Waveform plot shows the synthetic input signal.
* `audio_pwm` outputs an audible tone while detection is active.

## Repository structure

```text
hls/
  src/
    brainwave_recognizer.cpp
    brainwave_recognizer.hpp
  tb/
    tb.cpp
  run_csim.tcl
  run_csynth.tcl
  run_cosim.tcl
  run_export_ip.tcl

rtl/
  demo/
    test_signal_generator.vhd
    tb_test_signal_generator.vhd
  vga/
    waveform_buffer.vhd
    vga_display.vhd
    tb_vga_display.vhd
  audio/
    pwm_audio.vhd
    tb_pwm_audio.vhd

vivado/
  constraints/
    constraints.xdc

tools/
  generate_coefficients.py
  verify_coefficients.py

extras/
  hls/
  simulation/
  vivado/
  NEXYS4 DDR Full Contraints.xdc
```

## Main modules

### `brainwave_recognizer`

Vitis HLS top function. It receives one signed Q2.14 input sample and updates its internal FIR/envelope state only when `sample_valid = true`.

Outputs:

* `flag_out`: asserted after sustained envelope activity above threshold
* `env_out`: current envelope value
* `threshold_out`: selected threshold in the same scale as `env_out`

### `test_signal_generator`

VHDL module that generates synthetic EEG-like sine waves at 128 Hz. It outputs a one-clock `sample_valid` pulse for each logical EEG sample.

### `vga_display`

VHDL VGA dashboard. It generates 640×480 VGA timing and draws the detector state graphically. The current version does not render text; it uses colors, bars, and waveform geometry.

### `waveform_buffer`

Circular buffer used by the VGA display to store recent input samples as screen Y coordinates.

### `pwm_audio`

PWM-based audio sonification block. When `wave_detect = 1`, it emits a tone whose frequency depends on `band_sel`.

## HLS build and verification

From the `hls/` folder:

```powershell
& "C:\Xilinx\Vitis_HLS\2024.1\bin\vitis_hls.bat" -f .\run_csim.tcl
& "C:\Xilinx\Vitis_HLS\2024.1\bin\vitis_hls.bat" -f .\run_csynth.tcl
& "C:\Xilinx\Vitis_HLS\2024.1\bin\vitis_hls.bat" -f .\run_cosim.tcl
& "C:\Xilinx\Vitis_HLS\2024.1\bin\vitis_hls.bat" -f .\run_export_ip.tcl
```

Expected results:

* C simulation passes all detector tests.
* C/RTL co-simulation finishes with `PASS`.
* HLS synthesis meets the 10 ns target.
* Exported IP contains the current ports: `sample_valid`, `threshold_sel`, `env_out`, and `threshold_out`.

## Vivado implementation summary

The Vivado design connects:

```text
test_signal_generator
    -> brainwave_recognizer
        -> vga_display
        -> pwm_audio
```

The 25 MHz Clocking Wizard output drives the signal generator, HLS detector, VGA display, and PWM audio block.

Post-implementation timing passes in the provided proof reports. The final bitstream is included in `extras/vivado/` as proof of implementation.

## Proof artifacts

Verification artifacts are stored in `extras/`:

* HLS C simulation, C synthesis, C/RTL co-simulation, and IP export logs
* RTL simulation logs and waveform screenshots
* Vivado utilization, timing, power, DRC, IO, and clock reports
* Implemented bitstream
* Block design screenshot and generated wrapper/design files

See `extras/README.md` for details.

## Notes and limitations

* This is an educational FPGA/HLS project, not a medical EEG device.
* The input is synthetic EEG-like test data, not a real analog EEG front-end.
* VGA output is graphical only; no font/text renderer is implemented.
* PWM audio is a sonification of the detection result, not raw EEG audio.
