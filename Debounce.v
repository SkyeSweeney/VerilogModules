//
// Debounce an input
// The sample rate should be 8 times faster than the amount of switch bounce.
// If you have 20ms of bounce (50Hz), the clock should be 50*8 or 400 Hz
// The sample rate is set by a divider of the input clock.


module debounce #(parameter DIV=50_000_000/50/8) (
    input  wire noisy,
    input  wire clk, 
    input  wire rst,
    output reg  clean);

    reg [7:0]  shift;
    reg [16:0] cnt;

    always @ (posedge clk)
      begin

        // In reset, assume input is low
        if (rst == 1)
          begin
            shift <= 8'b00000000;
            clean <= 1'b0;
            cnt   <= 0;
          end

        // Increment counter
        cnt <= cnt + 1'b1;

        // At proper count
        if (cnt >= DIV)
          begin

            // Reset counter
            cnt <= 0;

            // Shift in the raw signal
            shift <= {shift[6:0],noisy};

            // If we have 8 consecutive high values
            if (shift == 8'b1111_1111)
              begin
                // Output is high
                clean <= 1;
              end

            // If we have 8 consecutive low values
            else if (shift == 8'b0000_0000)
              begin
                // Output is low
                clean <= 0;
              end
         
            // Some mixed combination of high and low
            else
              begin
                // Keep previous condition
                clean <= clean;
              end
          end
      end

endmodule
