//
// This routine will toggle the output (blink).
// This input clock is clk
// The output will be on for 2^(width-1) clocks.
//

module blinker #(parameter CLOCKS_PER_PERIOD = 50_000_000)
  ( input clk,
    input rst,
    output reg blink
  );

  parameter CLOCKS_PER_EDGE = CLOCKS_PER_PERIOD/2;
  parameter WIDTH = $clog2(CLOCKS_PER_EDGE);
    
  reg [WIDTH-1:0] M_counter;
  
  // Handle reset on clock edge
  always @(posedge clk) begin
  
    M_counter <= M_counter + 1'h1;
    if (M_counter >= CLOCKS_PER_EDGE)
    begin
        M_counter <= 0;
        blink = ~blink;
    end
    
    if (rst == 1'b1) begin
      M_counter <= 0;
    end
    
  end
  
endmodule
