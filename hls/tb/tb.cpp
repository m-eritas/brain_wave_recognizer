#include <ap_int.h>
#include <math.h>
#include <assert.h>

#include "../src/brainwave_recognizer.hpp"

int main() {
    const float PI = 3.14159265358979323846f;
    
    bool flag = false;
    bool dummy = false;

    ap_uint<18> env_out = 0;
    ap_uint<18> threshold_out = 0;

    // TEST 1: 256-sample alpha burst: 10 Hz sine, half-scale amplitude - should DETECT
    for (int n = 0; n < 256; ++n) {
        float f = 0.5f * sinf(2.0f * PI * 10.0f * n / 128.0f); // 10 Hz - centre of alpha band
        ap_int<16> x = (ap_int<16>)(f * (1 << 14));
        brainwave_recognizer(x, true, 2 /*alpha*/, 1 /*medium*/, flag, env_out, threshold_out);
    }

    assert((threshold_out != 0 && env_out != 0) && "threshold_out and env_out are zero");
    assert(flag == true && "alpha burst not detected - check coefficients and threshold" );

    // TEST 1.5 sample_valid = false must hold detector state.
    ap_uint<18> env_before = env_out;
    ap_uint<18> threshold_before = threshold_out;
    bool flag_before = flag;

    for (int n = 0; n < 20; ++n) {
        ap_int<16> fake_sample = (n % 2 == 0)
            ? ap_int<16>(8192)
            : ap_int<16>(-8192);

        brainwave_recognizer(fake_sample, false, 2 /*alpha*/, 1 /*medium*/, flag, env_out, threshold_out);
    }

    assert(env_out == env_before && "env_out changed while sample_valid was false");
    assert(threshold_out == threshold_before && "threshold_out changed even though threshold_sel stayed the same");
    assert(flag == flag_before && "flag_out changed while sample_valid was false");

    // Reset static internal state by running 400 zero samples
    flag = false;
    for (int n = 0; n < 400; ++n) {
        brainwave_recognizer(ap_int<16>(0), true, 2, 1, dummy, env_out, threshold_out);
    }

    // TEST 2: 256-sample beta burst: 20 Hz sine into the alpha filter - should NOT DETECT
    for (int n = 0; n < 256; ++n) {
        float f = 0.5f * sinf(2.0f * PI * 20.0f * n / 128.0f);
        ap_int<16> x = (ap_int<16>)(f * (1 << 14));
        brainwave_recognizer(x, true, 2 /*alpha*/, 1 /*medium*/, flag, env_out, threshold_out);
    }

    assert(threshold_out != 0 && "threshold_out is zero");
    assert(flag == false && "20 Hz beta triggered alpha detector - filter is wrong");
    
    return 0;
}
