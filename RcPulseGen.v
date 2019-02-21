//
// Generates teh signal needed for an RC servo.
//
// The signal is a a pulse between 1.0 and 2.0 ms.
// This pulse occurs every 20ms.
// This is clocked from the system clock.
// The input is a 16 bit value representing the number of
// microseconds the signal is high. It needs to be in the
// range of 1000 to 2000 counts.
//

module RcPulseGen #(parameter SYS_CLK=50000000) (
    input clk,
    input rst,
    input [15:0] pw,  // Pulse width in usec
    output reg out
  );
  
  // Counter PWM is based on
  // We take the system clock and break it downn such that each
  // tick is one microseconds.
  // With a system clock of 50MHz, 50,000,000 * 0.000001 is 50.
  // That means 50 system clocks is one microsecond.
  
  reg [5:0] M_div;     // ln(50)/ln(2) = 6
  reg [14:0] M_usec;   // ln(20000)/ln(2) = 15
  reg [15:0] val;
  
  // Increment counter and set output
  always @(posedge clk) 
  begin
  
    M_div <= M_div + 1;
    if (M_div >= 50)
    begin
    
      // Here we are running at 1usec per tick
      M_div <= 0;
      
      M_usec <= M_usec + 1;
      if (M_usec > 20000)
        begin
          M_usec <= 0;
        end 
      
      // Limit the input to 1000-2000
      if (pw < 1000)
        begin
          val <= 1000;
        end
      else if (pw > 2000)
        begin
          val <= 2000;
        end
      else
        begin
          val <= pw;
        end
      
      if (M_usec < val)
        begin
          out <= 1;
        end
      else
        begin
          out <= 0;
        end
      
    end
    
    if (rst == 1'b1) 
      begin
        M_div <= 0;
        M_usec <= 0;
      end 
    
    
  end
  
  
endmodule

