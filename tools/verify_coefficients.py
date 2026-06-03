import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import freqz

FS = 128
SCALE = 1 << 14  # Q2.14

bands = {
    "Delta  (0.5-4 Hz)":  [  -6, -14,  -1,  21,  54,  84, 100,  94,
                               62,   6, -64,-136,-202,-250,-268,-250,
                             -202,-136, -64,   6,  62,  94, 100,  84,
                               54,  21,  -1, -14,  -6,   0,   0,   0],
    "Theta  (4-8 Hz)":    [  18,  26,  33,  36,  34,  26,  10, -13,
                             -41, -70, -96,-118,-132,-135,-126,-105,
                             -72, -32,  12,  56,  95, 126, 144, 148,
                             140, 118,  88,  52,  17, -12, -31, -40],
    "Alpha  (8-12 Hz)":   [  35,  58,  96, 147, 202, 248, 274, 268,
                             222, 134,  12,-141,-314,-493,-660,-795,
                            -879,-896,-838,-704,-502,-248,  35, 331,
                             613, 857,1042,1145,1145,1042, 857, 613],
    "Beta   (12-30 Hz)":  [   9,  30,  62, 100, 137, 166, 180, 175,
                             147,  99,  33, -44,-122,-190,-239,-262,
                            -253,-216,-160, -94, -26,  37,  88, 121,
                             133, 125, 101,  69,  34,   5, -15, -24],
    "Gamma  (30-100 Hz)": [ -18,  16,  46,  63,  59,  32, -16, -73,
                            -125,-158,-161,-129, -66,  14, 103, 186,
                             249, 282, 282, 249, 186, 103,  14, -66,
                            -129,-161,-158,-125, -73, -16,  32,  63],
}

fig, axes = plt.subplots(5, 1, figsize=(10, 14))
fig.suptitle(f"FIR Frequency Responses — Fs = {FS} Hz", fontsize=14)

for ax, (name, coeffs) in zip(axes, bands.items()):
    coeffs_float = np.array(coeffs) / SCALE
    w, h = freqz(coeffs_float, worN=2048, fs=FS)
    ax.plot(w, 20 * np.log10(np.abs(h) + 1e-12))
    ax.set_title(name)
    ax.set_xlabel("Frequency (Hz)")
    ax.set_ylabel("Gain (dB)")
    ax.set_xlim(0, FS / 2)
    ax.set_ylim(-80, 5)
    ax.grid(True)
    ax.axhline(-3, color='red', linestyle='--', linewidth=0.8, label='-3 dB')
    ax.legend(fontsize=8)

plt.tight_layout()
plt.show()