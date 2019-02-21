//
// RC servo mux.
// If the selector signal is less than midpoint, than the output in a
// If the selector signal is more than midpoint, than the output in b
// If the selector signal is invalid, the output is a safe signal (0.5ms)
//


module rcMux(input a,    // Source A
             input b,    // Source B
             input c,    // Selector source (CH3)
             input clk,  // System clock
             input rst,  // Reset signal
             output ab); // Output signal

    reg [15:0] pw;
    reg [15:0] safeWidth = 16'h1000;   // 0.5 ms
    wire       safeSignal;

    // Instantiate the RcPulseDetector on 'c'
    RcPulseDetector(c, clk, rst, pw);

    // Instantiate a safe RxPulseGenerator
    RcPulseGen(clk, safeWidth, rst, safeSignal);

    // On system clock edges
    always @(posedge clk)
      begin

        // On reset, set the PW to invalid to force the safe signal
        if (rst == 1)
        begin
          pw = 0;
        end

        // On a stuck low selector signal
        if (pw == 0)
          begin
            ab = safeSignal;
          end

        // On a stuck high selector signal
        else if (pw == 16'hffff)
          begin
            ab <= safeSignal;
          end

        // If selector signal is less than mid point
        else if (pw <= 16'h0235)
          begin
            ab <= a;
          end

        // If selector signal is more than mid point
        else 
          begin
            ab <= b;
          end
      end

endmodule
