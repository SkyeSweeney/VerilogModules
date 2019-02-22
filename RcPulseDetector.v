
module RcPulseDetector(input i_signal,
                       input i_clk,
                       input i_rst,
                       output reg [15:0] o_pulseWidth);

    reg [15:0] upCnt;
    reg [15:0] dnCnt;
    reg        lastSignal;
    reg [5:0]  div;

    always@(posedge i_clk) 
      begin
      
        // Drop clock so each tick is a usec
        div <= div + 1;
        if (div > 50)
        begin
          div <= 0;
          
          // At this point each pass is a micro second

          // If signal is high
          if (i_signal == 1)
          begin
          
            // Increment time signal has been high
            upCnt <= upCnt + 1;
            dnCnt <= 0;

            // If it is been up too long
            if (upCnt > 2000 * 2)
            begin
              o_pulseWidth <= 16'hffff;
            end
            
          end

          // If signal is low
          if (i_signal == 0)
          begin

            // If the signal just dropped low
            if (lastSignal == 1)
              begin
                o_pulseWidth <= upCnt;
              end
              
            dnCnt <= dnCnt + 1;
            upCnt <= 0;
            
            // If the signal has been down for too long
            if (dnCnt > 20000*2)
            begin
              o_pulseWidth <= 0;
            end
          end

          lastSignal <= i_signal;
          
        end  

        // If in reset        
        if (i_rst == 1)
        begin
          div          <= 0;
          lastSignal   <= 0;
          upCnt        <= 0;
          dnCnt        <= 0;
          o_pulseWidth <= 0;
        end

  end

endmodule
