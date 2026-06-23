from scipy.signal import firwin
import numpy as np

FS = 128          # MUST match brainwave_recognizer.cpp assumption
N_TAPS = 32
SCALE = 1 << 14   # Q2.14

bands = {
    "Delta": (0.5, 4.0),    # Very narrow — expect leakage with only 32 taps
    "Theta": (4.0, 8.0),
    "Alpha": (8.0, 12.0),
    "Beta":  (12.0, 30.0),
    "Gamma": (30.0, 62.0),
}

for name, (lo, hi) in bands.items():
    c = firwin(N_TAPS, [lo, hi], pass_zero=False, fs=FS, window='hamming')
    q = np.round(c * SCALE).astype(int)
    # Verify range
    assert q.max() <= 32767 and q.min() >= -32768, f"{name} coefficients overflow ap_int<16>"
    print(f"  /* {name} {lo}–{hi} Hz */ {{")
    vals = ', '.join(f"{v:6d}" for v in q)
    print(f"    {vals} }},")