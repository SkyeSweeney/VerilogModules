
module RcPulseDetector(input i_signal,
                       input i_clk,
                       input i_rst,
                       output [15:0] o_pulseWidth);

    reg [15:0] upCnt;
    reg [15:0] dnCnt;
    reg        lastSignal;

    always@(posedge clk) 
      begin

        if (i_rst == 1)
        begin
          lastSignal   <= 0;
          upCnt        <= 0;
          dnCnt        <= 0;
          o_pulseWidth <= 0;
        end

        // If signal is high
        if (i_signal == 1)
        begin
          upCnt <= upCnt + 1;

          // If it is been up too long
          if (upCnt > 100000 * 2)
          begin
            o_pulseWidth <= 16'hffff;
          end
          dnCnt <= 0;
        end

        // If signal is low
        if (i_signal == 0)
        begin

          // If the signal just dropped
          if (lastSignal == 1)
          begin
            o_pulseWidth = upCnt;
          end

          dnCnt <= dnCnt + 1;
          if (dnCnt > 1000000*2)
          begin
            o_pulseWidth = 0;
          end
          upCnt <= 0;
        end

        lastSignal <= i_signal;

endmodule
