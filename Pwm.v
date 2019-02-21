//
// Generate a pWM signal.
// The primary counter is clocked by the clk signal.
// When the counter reaches tc, it resets back to zero.
// If the counter is less than t0, the output is high.
//

module pwm #(parameter WIDTH=16) (
    input clk,
    input rst,
    input [WIDTH-1:0] tc,  // Terminal count for counter
    input [WIDTH-1:0] t0,  // Time to turn off output
    output reg out
  );
  
  // Counter PWM is based on
  reg [WIDTH-1:0] M_counter;
  
  // Increment counter and set output
  always @(posedge clk) 
  begin
   
    if (M_counter == tc)
      begin
        M_counter <= 0;
      end
    else
      begin
        M_counter <= M_counter + 1'h1;
      end  
    
    if (M_counter < t0)
      out = 1;
    else
      out = 0;
        
    
    if (rst == 1'b1) 
      begin
        M_counter <= 1'h0;
      end 
    
    
  end
  
  
endmodule
