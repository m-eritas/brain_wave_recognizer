import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import freqz

FS = 128
SCALE = 1 << 14  # Q2.14

bands = {
    "Delta  (0.5-4 Hz)":  
    [
      -12, -3, 11, 37, 82, 152, 249, 374,
      524, 691, 866, 1039, 1196, 1327, 1420, 1469, 1469,
      1420, 1327, 1196, 1039,  866, 691, 524, 374, 249,
      152,  82,  37,  11,  -3, -12
      ],
    "Theta  (4-8 Hz)":    
    [
      -16, -55, -120, -223, -361, -514, -642, -699, -638,
      -429, -72, 402, 933, 1440, 1837, 2055, 2055,
      1837, 1440, 933, 402, -72, -429, -638, -699, -642, -514, -361, -223,
      -120, -55, -16
      ],
    "Alpha  (8-12 Hz)":   
    [  
      26, 87, 168, 256, 298, 219, -33, -446, -915,
      -1268, -1326, -983, -265, 652, 1500, 2008, 2008, 1500,
      652, -265, -983,  -1326,  -1268, -915, -446, -33, 219,
      298, 256, 168, 87, 26
    ],
    "Beta   (12-30 Hz)":  
    [
      -28, -6, -6, -88, -142, 50, 337,
      261, -16, 255, 748, -127, -2353, -2951, 102,
      3946, 3946, 102, -2951, -2353, -127, 748, 255, -16, 261, 337,
       50, -142, -88, -6, -6, -28
    ],
    "Gamma  (30-62 Hz)": 
    [
      19, -14, -50, 52, 52, 40, -332, 208,
      101, 501, -1290, 541, -50, 2924, -6114, 3413, 3413,
      -6114, 2924, -50,  541, -1290, 501, 101,
      208, -332, 40, 52, 52, -50, -14, 19 
    ],
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