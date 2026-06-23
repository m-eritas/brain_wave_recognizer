#include <ap_int.h>
#include <stdio.h>

/*******************************************************************
    Brain-wave recognizer with assumed sampling-rate: 128 Sa/s (smallest clean sample rate that supports signals up to ~62 Hz)
*******************************************************************/

#define N 32        
#define SHIFT 14    // Q2.14 fractional bits; 1.0 is represented as 1 << 14

// Five 32-tap band-pass FIR coefficient sets, quantized to Q2.14.
// Fs = 128 Hz, so Nyquist = 64 Hz and Gamma is limited to 30-62 Hz.

static const ap_int<16> filter_coeffs[5][N] = {
  /* 0 : Delta 0.5-4 Hz */ {
        -12,-3,11,37,82,152,249,374,524,691,866,1039,1196,1327,1420,1469,1469,1420,1327,1196,1039,866,691,524,374,249,152,82,37,11,-3,-12},
  /* 1 : Theta 4-8 Hz */  {
        -16,-55,-120,-223,-361,-514,-642,-699,-638,-429,-72,402,933,1440,1837,2055,2055,1837,1440,933,402,-72,-429,-638,-699,-642,-514,-361,-223,-120,-55,-16},
  /* 2 : Alpha 8-12 Hz */  {
        26,87,168,256,298,219,-33,-446,-915,-1268,-1326,-983,-265,652,1500,2008,2008,1500,652,-265,-983,-1326,-1268,-915,-446,-33,219,298,256,168,87,26},
  /* 3 : Beta 12-30 Hz */ {
        -28,-6,-6,-88,-142,50,337,261,-16,255,748,-127,-2353,-2951,102,3946,3946,102,-2951,-2353,-127,748,255,-16,261,337,50,-142,-88,-6,-6,-28},
  /* 4 : Gamma 30-62 Hz */ {
        19,-14,-50,52,52,40,-332,208,101,501,-1290,541,-50,2924,-6114,3413,3413,-6114,2924,-50,541,-1290,501,101,208,-332,40,52,52,-50,-14,19}
};

// Raw Q2.14 thresholds. Higher threshold = harder detection.
static const ap_int<16> threshold_table[3] = {
    (ap_int<16>) (0.10 * (1<<SHIFT) + 0.5),   // low  => 0.10FS
    (ap_int<16>) (0.18 * (1<<SHIFT) + 0.5),   // mid  => 0.18FS
    (ap_int<16>) (0.25 * (1<<SHIFT) + 0.5)    // high => 0.25FS
};

void brainwave_recognizer(
    ap_int<16> sample,          // one input sample
    bool sample_valid,          // true only when sample is a new EEG sample
    ap_uint<3> band_sel,        // 0-4 => coefficient choice
    ap_uint<2> threshold_sel,   // 0-2 => low/mid/high threshold selection
    bool &flag_out,             // true when sustained band power is detected
    ap_uint<18> &env_out,       // current envelope value, scaled by IIR gain
    ap_uint<18> &threshold_out  // threshold value in same scale as env_out
){
    #pragma HLS INTERFACE ap_none  port=sample
    #pragma HLS INTERFACE ap_none port=sample_valid
    #pragma HLS INTERFACE ap_none  port=band_sel
    #pragma HLS INTERFACE ap_none  port=threshold_sel
    #pragma HLS INTERFACE ap_none  port=flag_out
    #pragma HLS INTERFACE ap_none port=env_out
    #pragma HLS INTERFACE ap_none port=threshold_out
    #pragma HLS INTERFACE ap_ctrl_none port=return
    #pragma HLS PIPELINE II=1

    static ap_int<16> x_reg[N]; 
    static ap_uint<18> env = 0;
    static ap_uint<8> counter = 0;

    ap_uint<3> safe_band = (band_sel > 4) ? ap_uint<3>(4) : band_sel;
    ap_uint<2> safe_threshold = (threshold_sel > 2) ? ap_uint<2>(2) : threshold_sel;

    // Thresholding
    const ap_uint<18> threshold_env = (ap_uint<18>)(threshold_table[safe_threshold]) << 3;
    // Low:  1638 x 8 = 13,104
    // Mid:  2949 x 8 = 23,592
    // High: 4096 x 8 = 32,768

    if (!sample_valid) {
        flag_out = (counter >= 40);
        env_out = env;
        threshold_out = threshold_env;
        return;
    }

    /*  Shift register: newest valid sample goes into x_reg[0],
        older samples move toward higher indices. */ 

    for (int i = N - 1; i > 0; i--) {
        #pragma HLS UNROLL
        x_reg[i] = x_reg[i - 1];
    }
    x_reg[0] = sample;

    // Get the filter coefficients for selected band
    const ap_int<16> *selected_coeffs = filter_coeffs[safe_band]; 

    // MAC over updated x_reg
    ap_int<36> acc = 0;
    for (int i = 0; i < N; i++) {
        #pragma HLS UNROLL
        acc += x_reg[i] * selected_coeffs[i];
    }

    ap_int<16> trunc = acc >> SHIFT;
    
    // Rectify (magnitude)
    ap_uint<16> mag = (trunc < 0) ? (ap_uint<16>)(-trunc) : (ap_uint<16>)trunc;

    // 1-pole IIR envelope
    env = env - (env >> 3) + mag;       // this form has DC gain 8, so threshold_env is threshold_q214 << 3.

    if (env > threshold_env) {
        if (counter < 255) counter++;
    } else if (counter > 0) {
        counter--;
    }

    flag_out = (counter >= 40);
    env_out = env;
    threshold_out = threshold_env;

    #ifdef HLS_DEBUG_PRINT
    printf("valid=%d sample=%d env=%u threshold=%u counter=%u flag=%d\n",
       (int)sample_valid,
       sample.to_int(),
       env.to_uint(),
       threshold_env.to_uint(),
       counter.to_uint(),
       (int)flag_out);
    #endif
}
