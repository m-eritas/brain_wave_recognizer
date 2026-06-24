#include <ap_int.h>
#include <math.h>
#include <assert.h>
#include <stdio.h>

#include "../src/brainwave_recognizer.hpp"

static const float PI = 3.14159265358979323846f;

// Constants hardcoded, but match brainwave_recognizer.cpp.
static const ap_uint<18> THRESH_LOW_ENV  = 13104;
static const ap_uint<18> THRESH_MID_ENV  = 23592;
static const ap_uint<18> THRESH_HIGH_ENV = 32768;

// Generate one Q2.14 sine sample.
static ap_int<16> make_sine_sample(float freq_hz, int n, float amplitude) {
    float f = amplitude * sinf(2.0f * PI * freq_hz * n / 128.0f);
    return (ap_int<16>)(f * (1 << 14));
}

// Drain static state inside the HLS function.
static void drain_detector() {
    bool flag = false;
    ap_uint<18> env_out = 0;
    ap_uint<18> threshold_out = 0;

    for (int n = 0; n < 500; ++n) {
        brainwave_recognizer(ap_int<16>(0), true, 2, 1, flag, env_out, threshold_out);
    }

    assert(flag == false);
}

/*
    Run a sine burst through the detector.
    Returns the last flag/env/threshold values through references.
*/
static void run_sine_burst(
    float freq_hz,
    float amplitude,
    ap_uint<3> band_sel,
    ap_uint<2> threshold_sel,
    int samples,
    bool &flag,
    ap_uint<18> &env_out,
    ap_uint<18> &threshold_out
) {
    flag = false;
    env_out = 0;
    threshold_out = 0;

    for (int n = 0; n < samples; ++n) {
        ap_int<16> x = make_sine_sample(freq_hz, n, amplitude);

        brainwave_recognizer(x, true, band_sel, threshold_sel, flag, env_out, threshold_out);
    }
}

/*
    TEST 1: sample_valid=false freezes the detector state
*/
static void test_sample_valid_hold() {
    printf("TEST: sample_valid=false hold behavior\n");

    drain_detector();

    bool flag = false;
    ap_uint<18> env_out = 0;
    ap_uint<18> threshold_out = 0;

    // Meaningful sample through detector
    run_sine_burst(10.0f, 0.5f, 2, 1, 256, flag, env_out, threshold_out);

    assert(flag == true);
    assert(env_out != 0);
    assert(threshold_out == THRESH_MID_ENV);

    ap_uint<18> env_before = env_out;
    ap_uint<18> threshold_before = threshold_out;
    bool flag_before = flag;

    // Invalid samples should be ignored completely.
    for (int n = 0; n < 20; ++n) {
        ap_int<16> fake_sample = (n % 2 == 0)
            ? ap_int<16>(8192)
            : ap_int<16>(-8192);

        brainwave_recognizer(fake_sample, false, 2, 1, flag, env_out, threshold_out);
    }

    assert(env_out == env_before);
    assert(threshold_out == threshold_before);
    assert(flag == flag_before);

    // threshold_out should update when threshold_sel changes, even if sample_valid=false.
    brainwave_recognizer(ap_int<16>(0), false, 2, 2, flag, env_out, threshold_out);

    assert(env_out == env_before);
    assert(flag == flag_before);
    assert(threshold_out == THRESH_HIGH_ENV);

    printf("PASS: sample_valid=false hold behavior\n");
}

/*
    Test 2: basic alpha detection
*/
static void test_alpha_positive() {
    printf("TEST: alpha positive detection\n");

    drain_detector();

    bool flag = false;
    ap_uint<18> env_out = 0;
    ap_uint<18> threshold_out = 0;

    run_sine_burst(10.0f, 0.5f, 2, 1, 256, flag, env_out, threshold_out);

    assert(threshold_out == THRESH_MID_ENV);
    assert(env_out != 0);
    assert(flag == true);

    printf("PASS: alpha positive detection\n");
}

/*
    Test 3: out-of-band rejection (beta in alpha filter)
*/
static void test_beta_into_alpha_negative() {
    printf("TEST: 20 Hz beta into alpha filter should not detect\n");

    drain_detector();

    bool flag = false;
    ap_uint<18> env_out = 0;
    ap_uint<18> threshold_out = 0;

    run_sine_burst(20.0f, 0.5f, 2, 1, 256, flag, env_out, threshold_out);

    assert(threshold_out == THRESH_MID_ENV);
    assert(flag == false);

    printf("PASS: beta rejected by alpha filter\n");
}

/*
    Test 4: all five supported bands at representative center frequencies:
    0 = Delta, 2 Hz
    1 = Theta, 6 Hz
    2 = Alpha, 10 Hz
    3 = Beta, 20 Hz
    4 = Gamma, 40 Hz
*/
static void test_all_band_positive() {
    printf("TEST: all-band positive detection\n");

    const float freqs[5] = {2.0f, 6.0f, 10.0f, 20.0f, 40.0f};

    for (int band = 0; band < 5; ++band) {
        drain_detector();

        bool flag = false;
        ap_uint<18> env_out = 0;
        ap_uint<18> threshold_out = 0;

        run_sine_burst(freqs[band], 0.5f, (ap_uint<3>)band, 1, 256, flag, env_out, threshold_out);

        printf("band=%d freq=%f env=%u threshold=%u flag=%d\n",
               band,
               freqs[band],
               env_out.to_uint(),
               threshold_out.to_uint(),
               (int)flag);

        assert(threshold_out == THRESH_MID_ENV);
        assert(env_out != 0);
        assert(flag == true);
    }

    printf("PASS: all-band positive detection\n");
}

/*
    Test 5: selector clamping.
*/
static void test_invalid_selector_clamping() {
    printf("TEST: invalid selector clamping\n");

    drain_detector();

    bool flag = false;
    ap_uint<18> env_out = 0;
    ap_uint<18> threshold_out = 0;

    // threshold_sel = 3 should clamp to high threshold.
    brainwave_recognizer(ap_int<16>(0), false, 2, 3, flag, env_out, threshold_out);
    assert(threshold_out == THRESH_HIGH_ENV);

    drain_detector();

    // band_sel = 7 should clamp to Gamma.
    run_sine_burst(40.0f, 0.5f, 7, 1, 256, flag, env_out, threshold_out);

    assert(threshold_out == THRESH_MID_ENV);
    assert(flag == true);

    printf("PASS: invalid selector clamping\n");
}

/*
    Test 6: sensitivity / threshold behavior.
    With a weaker alpha signal:
        low threshold should detect
        high threshold should reject
*/
static void test_threshold_levels() {
    printf("TEST: threshold levels\n");

    bool flag = false;
    ap_uint<18> env_out = 0;
    ap_uint<18> threshold_out = 0;

    drain_detector();

    // low threshold
    run_sine_burst(10.0f, 0.25f, 2, 0, 256, flag, env_out, threshold_out);

    printf("low threshold: env=%u threshold=%u flag=%d\n",
           env_out.to_uint(),
           threshold_out.to_uint(),
           (int)flag);

    assert(threshold_out == THRESH_LOW_ENV);
    assert(flag == true);

    drain_detector();

    // high threshold
    run_sine_burst(10.0f, 0.25f, 2, 2, 256, flag, env_out, threshold_out);

    printf("high threshold: env=%u threshold=%u flag=%d\n",
           env_out.to_uint(),
           threshold_out.to_uint(),
           (int)flag);

    assert(threshold_out == THRESH_HIGH_ENV);
    assert(flag == false);

    printf("PASS: threshold levels\n");
}

int main() {
    printf("Starting HLS testbench...\n");

    drain_detector();

    test_alpha_positive();
    test_sample_valid_hold();
    test_beta_into_alpha_negative();
    test_all_band_positive();
    test_invalid_selector_clamping();
    test_threshold_levels();

    printf("All HLS tests passed.\n");

    return 0;
}
