`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////////
    
module SpiMasterXfer (
    input            clk,
    input            rst,
    input            xfer_en,
    input            miso,
    input  [7:0]     tx_data,
    output reg       busy,
    output reg       mosi,
    output reg       sclk,
    output reg [7:0] rx_data
  );
  
    parameter s_idle  = 4'h0;
    parameter s_setup = 4'h1;
    parameter s_read  = 4'h2;
    parameter s_check = 4'h3;
    
    // Assumes base clock of 50Mhz and and spi clock of 2Mhz
    // The time between edges is twice the clock rate
    parameter CLOCKS = 50_000_000/2_000_000/2;
  

    reg [7:0] cnt;
    reg [7:0] tgt;
    reg [3:0] state;   // Big enough to enumerate all states
    reg [3:0] bitCnt;  // bit enough to count to 8
    reg [7:0] tx;
    reg [7:0] rx;

    
    // Run state machine to clock out/in bits
    always @(posedge clk) 
    begin
    
        // Deal with reset
        if (rst)
        begin
          cnt  <= 0;
          state <= s_idle;
        end
    
        // Increment counter
        cnt <= cnt + 8'h1;
        
        case (state)
        
        //******************************************
        // Waiting for xfer_en to go high
        //******************************************
        s_idle:
        begin

            // In idle the clock is high and we are not busy        
            busy   <= 0;
            sclk   <= 1;
            
            // On a transfer request
            if (xfer_en)
            begin
            
                // Caputure the user's input
                tx <= tx_data;
                
                // Reset the receive accumulator
                rx <= 8'h0;

                // reset bits to clock out                
                bitCnt <= 4'h8;
            
                // Indicate we are busy
                busy  <= 1;
                
                // Set up for next state
                cnt   <= 0;
                state <= s_setup;
                
            end
        end
            
        //******************************************
        // On falling edge of sclk, setup MOSI data    
        //******************************************
        s_setup:
        begin
        
          // If another SCLK has passed
          if (cnt >= CLOCKS)
          begin
          
            // If we have clocked out all the bits
            if (bitCnt == 0)
            begin
              
                // If we have, capture the accumulated received value
                rx_data <= rx;
                  
                // Return to Idle state
                state <= s_idle;
                
            end
            else
            begin

              // Set up the next bit to trasmit          
              mosi <= tx[7];
              
              // Expose the next bit to transmit for next pass
              tx <= {tx[6:0], 1'h1};
              
              // Lower the clock
              sclk <= 0;
              
              // Set up for next state
              cnt   <= 0;
              state <= s_read;
              
            end  
          end  
        end
            
        //******************************************
        // On rising edge of sclk, read MISO    
        //******************************************
        s_read:
        begin
        
          // If the right time has come for rising edge
          if (cnt >= CLOCKS)
          begin
          
            // Pull up clock
            sclk <= 1;
            
            // Shift in the value of MISO
            rx <= {rx[6:0], miso};
            
            // Decrement the bit count
            bitCnt <= bitCnt - 1'h1;
                
            // Return to setup
            cnt   <= 0;
            state <= s_setup;
            
          end
          
        end
          
        //******************************************
        // Should not get here!    
        //******************************************
        default:
            state <= s_idle;        
        endcase
        
    end  // end always on risign clk

endmodule
