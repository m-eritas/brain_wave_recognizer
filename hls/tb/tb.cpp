#include <ap_int.h>
#include <math.h>
#include <assert.h>

#include "../src/brainwave_recognizer.hpp"


int main() {
    const float PI = 3.14159265358979323846f;
    
    bool flag = false;
    bool dummy = false;

    // TEST 1: 256-sample alpha burst: 10 Hz sine, half-scale amplitude - should DETECT
    for (int n = 0; n < 256; ++n) {
        float f = 0.5f * sinf(2.0f * PI * 10.0f * n / 128.0f); // 10 Hz — centre of alpha band
        ap_int<16> x = (ap_int<16>)(f * (1 << 14));
        brainwave_recognizer(x, 2 /*alpha*/, 1 /*medium*/, flag);
    }
    assert(flag == true && "Alpha burst not detected — check FIR coefficients and threshold");

    // Reset static internal state by running 400 zero samples
    flag = false;
    for (int n = 0; n < 400; ++n) {
        brainwave_recognizer(ap_int<16>(0), 2, 1, dummy);
    }

    // TEST 2: 256-sample beta burst: 20 Hz sine into the alpha filter — should NOT DETECT
    for (int n = 0; n < 256; ++n) {
        float f = 0.5f * sinf(2.0f * PI * 20.0f * n / 128.0f);
        ap_int<16> x = (ap_int<16>)(f * (1 << 14));
        brainwave_recognizer(x, 2 /*alpha*/, 1 /*medium*/, flag);
    }

    assert(flag == false && "20 Hz beta triggered alpha detector — filter is wrong");
    
    return 0;
}
