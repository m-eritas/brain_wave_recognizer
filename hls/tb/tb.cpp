#include <ap_int.h>
#include <math.h>

#include "d:/Files/UniTrento/advanced/brain_wave_recognizer/hls/src/brainwave_recognizer.hpp"


int main() {
    bool flag = false;
    bool dummy = false;

    // 128-sample alpha burst (8-Hz sine, full-scale 0.5)
    for (int n = 0; n < 256; ++n) {
        float f = std::sin(2.0f * M_PI * 10 * n / 128);  // 10 Hz — centre of alpha band
        ap_int<16> x = (ap_int<16>)(f * (1 << 14));
        brainwave_recognizer(x, 2, 1, flag);
    }
    assert(flag == true && "Alpha burst not detected — check FIR coefficients and threshold");
    return 0;

    // Reset static internal state by running 64 zero samples
    for (int n = 0; n < 64; ++n) {
        brainwave_recognizer(ap_int<16>(0), 2, 1, dummy);
    }

    // Test 2: 20 Hz sine into the alpha filter — should NOT detect
    bool flag_negative = false;
        for (int n = 0; n < 256; ++n) {
            float f = 0.5f * std::sin(2.0f * M_PI * 20.0f * n / 128.0f);
            ap_int<16> x = (ap_int<16>)(f * (1 << 14));
            brainwave_recognizer(x, 2 /*alpha*/, 1 /*medium*/, flag_negative);
        }
    assert(flag_negative == false && "20 Hz beta triggered alpha detector — filter is wrong");

    return 0;
}
