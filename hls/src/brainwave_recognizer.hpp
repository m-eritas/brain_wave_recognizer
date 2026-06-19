#pragma once                    // avoids duplicate inclusion
#include <ap_int.h>             // provides ap_int / ap_uint types

/*******************************************************************
    Top-level HLS function header
    Keep the signature EXACTLY the same as in brainwave_recognizer.cpp
*******************************************************************/

void brainwave_recognizer(
    ap_int<16> sample,          // one input sample
    bool sample_valid,          // true only when sample is a new EEG sample
    ap_uint<3> band_sel,        // 0-4 => coefficient choice
    ap_uint<2> threshold_sel,   // 0-2 => low/mid/high threshold selection
    bool &flag_out,             // true when sustained band power is detected
    ap_uint<18> &env_out,       // current envelope value, scaled by IIR gain
    ap_uint<18> &threshold_out  // threshold value in same scale as env_out
);
