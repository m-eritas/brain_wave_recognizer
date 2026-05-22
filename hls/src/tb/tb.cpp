#include <ap_int.h>
#include <math.h>

#include "brainwave_recognizer.hpp"


int main() {
    bool flag = false;

    // 128-sample alpha burst (8-Hz sine, full-scale 0.5)
    for (int n = 0; n < 256; ++n) {
        float   f = /*0.5f* */ std::sin(2.0f * M_PI * 8 * n / 128);  // alpha wave
        ap_int<16> x = (ap_int<16>)(f * (1 << 14));              // Q2.14
        brainwave_recognizer(x, 2 /*alpha*/, 1 /*medium*/, flag);
    }
    
    return 0;
}
