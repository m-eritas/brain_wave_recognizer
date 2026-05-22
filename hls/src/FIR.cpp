/*******************************************************************
  Brain-wave detector
  - Assumed sampling-rate: 128 Sa/s
*******************************************************************/


#include <ap_int.h>
#include <cstdio>


#define N 32 //Number taps (filter size)
#define SHIFT 14 // Fixed-point scale 
//Q2.14 format (1 sign, 1 int, 14 fraction) => multiply floats by 2^14)

/* (We do 1<<14 instead of 16384 directly for reading clarity 
and since compiler solves them no time penalty)
*/


/* ---------- Five band-pass for 5 brain waves (Q2.14)  ---------
0 = Delta, 1 = Theta, 2 = Alpha, 3 = Beta, 4 = Gamma
------------------------------------------------------- */

static const ap_int<16> filters[5][N] = {
  /* 0 : Delta 0.5-4 Hz  (TODO) */ {
      -6, -14, -1,  21,  54,  84, 100,  94,
      62,   6,- 64,-136,-202,-250,-268,-250,
    -202,-136,-64,   6,  62,  94, 100,  84,
      54,  21, -1,-14, -6,  0,  0,  0 },
  /* 1 : Theta 4-8 Hz   (TODO) */ {
      18,  26,  33,  36,  34,  26,  10,-13,
     -41,-70,-96,-118,-132,-135,-126,-105,
     -72,-32, 12, 56, 95,126,144,148,
     140,118, 88, 52, 17,-12,-31,-40 },
  /* 2 : Alpha 8-12 Hz */
  {  35,  58,  96, 147, 202, 248, 274, 268,
    222, 134,  12,-141,-314,-493,-660,-795,
   -879,-896,-838,-704,-502,-248,  35, 331,
    613, 857,1042,1145,1145,1042, 857, 613 },
  /* 3 : Beta 12-30 Hz  (TODO) */ {
       9,  30,  62, 100, 137, 166, 180, 175,
     147,  99,  33,-44,-122,-190,-239,-262,
    -253,-216,-160,-94,-26, 37, 88,121,
     133, 125, 101, 69, 34,   5,-15,-24 },
  /* 4 : Gamma 30-100 Hz (TODO) */ {
     -18,  16,  46,  63,  59,  32,-16,-73,
    -125,-158,-161,-129,-66, 14, 103, 186,
     249, 282, 282, 249, 186, 103,  14,-66,
    -129,-161,-158,-125,-73,-16,  32,  63 }
};


/* ---------- Three levels of sensibility (Q2.14)  ---------
0 = Low, 1 = Medium, 2 = High
------------------------------------------------------- */
static const ap_int<16> thresholders[3] = {
    /* 0.10FS? * 2.14Format + 0.5? */
    (ap_int<16>) (0.10 * (1<<SHIFT) + 0.5),   // low  ≈ 0.10·FS
    (ap_int<16>) (0.18 * (1<<SHIFT) + 0.5),   // mid  ≈ 0.18·FS
    (ap_int<16>) (0.25 * (1<<SHIFT) + 0.5)    // high ≈ 0.25·FS
};



void brainwave_recognizer(
    ap_int<16> sample,
    ap_uint<3> which_band, // 0-4 for Delta, Theta, Alpha, Beta, Gamma
    ap_uint<2> sensibility, // 0-2 for Low, Medium, High
    bool& out_wave_detected // Output signal to indicate if the brain wave is detected
){

    #pragma HLS INTERFACE ap_none  port=sample
    #pragma HLS INTERFACE ap_none  port=which_band
    #pragma HLS INTERFACE ap_none  port=sensibility
    #pragma HLS INTERFACE ap_none  port=out_wave_detected
    #pragma HLS INTERFACE ap_ctrl_none port=return
    #pragma HLS PIPELINE II=1

    static ap_int<16> x_reg[N]; 
    
    //Accumulator (16*16 => 32 (4.28) bits + accumulator ≈ 36 (8.28) !!with 32 taps)
    ap_int<36> acc = 0;

    // We "push" the value inside => convolution easier
    for (int i = N - 1; i > 0; i--) {
        #pragma HLS UNROLL
        x_reg[i] = x_reg[i - 1];
    }
    x_reg[0] = sample;

    /*
    Unrolled loop to shift the register, 
    which means combinationally in one cycle (Not pipeline)
        x_reg[31] = x_reg[30];
        x_reg[30] = x_reg[29];
        ...
        x_reg[1] = x_reg[0];
    */

    /* ------------- Convolution ------------- */
    const ap_int<16> *chosen_filter = filters[which_band]; // Get the filter coefficients for the selected band
    for (int i = 0; i < N; i++) {
        #pragma HLS UNROLL
        acc += x_reg[i] * chosen_filter[i];
    }

    ap_int<16> trunc = acc >> SHIFT;
    

    printf("trunc = %.4f\n", ((float)trunc.to_int()) / (1 << SHIFT));
    // 2.14 from Q8.28 to Q8.14 then truncated to 2.14 because of ap_int<16> type

    /*
        - A 32-element shift register (x_reg[])
        - 32 parallel multipliers
        - A pipelined adder tree (16 - 8 - 4 - 2 - 1)
        - A final right-shift (>> SHIFT) and truncation to ap_int<16>
    */




    /* ----------  Rectify (magnitude)  ---------- */
    ap_uint<16> mag = (trunc < 0) ? (ap_uint<16>)(-trunc) : (ap_uint<16>)trunc;



    /*
        ----------  1-pole IIR envelope  ---------- 
        It follows power concept but can work also with less than a full period (in this case with an implied 128 sampling rate, with 8 taps we get 8/16, which is half period)
        I say 16 because 8Hz/128Hz
    */
    static ap_uint<18> env = 0;         // extra bits to avoid overflow
    // α = 1/8  ➜  simple right shift implements (1-α)
    env = env - (env >> 3) + mag;       // y[n] = (7/8)·y[n-1] + (1/8)·mag



    /* ------------- Thresholding ------------- */
    const ap_int<16> THRESHOLD = thresholders[sensibility];
    static ap_uint<8> counter = 0;

    if (env > THRESHOLD) {
        counter++;
        printf("%i\n", counter.to_uint());
    } else {
        counter = 0;
    }

    printf("sample=%d  flag=%d\n", sample.to_int(), out_wave_detected);
    out_wave_detected = (counter >= 100);
}