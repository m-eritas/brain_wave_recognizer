#pragma once                 // avoids duplicate inclusion
#include <ap_int.h>          // gives ap_int / ap_uint types

// ──────────────────────────────────────────────────────────────
// Top-level HLS function you’re synthesising.
// Keep the signature EXACTLY the same as in brainwave_recognizer.cpp
// ──────────────────────────────────────────────────────────────
void brainwave_recognizer(
    ap_int<16>  sample,      // one input sample (Q2.14)
    ap_uint<3>  band_sel,    // 0-4  → which coefficient set
    ap_uint<2>  sens_sel,    // 0-2  → threshold level
    bool&       flag_out     // goes high when burst detected
);
