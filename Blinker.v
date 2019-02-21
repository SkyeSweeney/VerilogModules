//
// This routine will toggle the output (blink).
// This input clock is clk
// The output will be on for 2^(width-1) clocks.
//

module blinker #(parameter WIDTH=22) (
    input clk,
    input rst,
    output reg blink
  );
  
    
  reg [WIDTH-1:0] M_counter_d;
  reg [WIDTH-1:0] M_counter_q = 1'h0;
  
  // Increment counter and set output
  always @* begin
    M_counter_d = M_counter_q;
	 
    blink = M_counter_d[WIDTH-1];    
    
    M_counter_d = M_counter_q + 1'h1;
  end
  
  // Handle reset on clock edge
  always @(posedge clk) begin
    if (rst == 1'b1) begin
      M_counter_q <= 1'h0;
    end else begin
      M_counter_q <= M_counter_d;
    end
  end
  
endmodule
