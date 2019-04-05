//----------------------------------------------------------------------
// This file contains the UART Transmitter.  This transmitter is able
// to transmit 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  
//
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87
//----------------------------------------------------------------------
  
module uart_tx 
  #(parameter BAUD  = 115_200,
    parameter CLOCK = 50_000_000)
  (
   input            clk,        // System clock
   input            rst,        // System reset
   input            wrEn,       // Data valid (go!)
   input [7:0]      din,        // Byte to transmit
   output reg       busy,       // Uart busy when high
   output reg       txPin,      // UART pin
   output reg [7:0] debug
   );
   
  parameter CLKS_PER_BIT = (CLOCK/BAUD);
  parameter WIDTH = $clog2(CLKS_PER_BIT);  // Num bits to hold CLKS_PER_BIT
  
  parameter s_IDLE         = 3'b000;
  parameter s_TX_START_BIT = 3'b001;
  parameter s_TX_DATA_BITS = 3'b010;
  parameter s_TX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;
  
   
  reg [2:0]          r_SM_Main     = 0;
  reg [WIDTH-1:0]    r_Clock_Count = 0;
  reg [2:0]          r_Bit_Index   = 0;
  reg [7:0]          r_Tx_Data     = 0;
  
  reg                txBusy;

     
  always @(posedge clk)
    begin
    
      busy <= txBusy;
    
      if (rst)
      begin
        r_SM_Main <= s_IDLE;
      end
       
      case (r_SM_Main)
        s_IDLE :
          begin
            txPin         <= 1'b1;    // Drive Line High for Idle
            r_Clock_Count <= 0;       // Clock counter for baudrate divider
            r_Bit_Index   <= 0;       // Set number of bits transmitted
            txBusy        <= 1'b0;    // Not busy
            
             
            // If we are told the data is now valid to transmit 
            if (wrEn == 1'b1)
              begin
                txBusy    <= 1'b1;            // Indicate we are busy
                r_Tx_Data <= din;            // Make copy of transmit data
                r_SM_Main <= s_TX_START_BIT;  // Set new mode
              end
            else
              r_SM_Main <= s_IDLE;
          end // case: s_IDLE
         
         
        // Send out Start Bit. Start bit = 0
        s_TX_START_BIT :
          begin
          
            txPin <= 1'b0;  // Drop pin low for start bit
             
            // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1'h1;
                r_SM_Main     <= s_TX_START_BIT;
              end
            else
              begin
                r_Clock_Count <= 0;
                r_SM_Main     <= s_TX_DATA_BITS;
              end
          end // case: s_TX_START_BIT
         
         
        // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
        s_TX_DATA_BITS :
          begin
            txPin <= r_Tx_Data[r_Bit_Index];  // Drive pin for next bit
             
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1'h1;
                r_SM_Main     <= s_TX_DATA_BITS;
              end
            else
              begin
                r_Clock_Count <= 0;
                 
                // Check if we have sent out all bits
                if (r_Bit_Index < 7)
                  begin
                    r_Bit_Index <= r_Bit_Index + 1'h1;
                    r_SM_Main   <= s_TX_DATA_BITS;
                  end
                else
                  begin
                    r_Bit_Index <= 0;
                    r_SM_Main   <= s_TX_STOP_BIT;
                  end
              end
          end // case: s_TX_DATA_BITS
         
         
        // Send out Stop bit.  Stop bit = 1
        s_TX_STOP_BIT :
          begin
            txPin <= 1'b1;
             
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1'h1;
                r_SM_Main     <= s_TX_STOP_BIT;
              end
            else
              begin
                r_Clock_Count <= 0;
                r_SM_Main     <= s_CLEANUP;
              end
          end // case: s_Tx_STOP_BIT
         
         
        // Stay here 1 clock
        s_CLEANUP :
          begin
            r_SM_Main <= s_IDLE;
          end
         
         
        default :
          r_SM_Main <= s_IDLE;
         
      endcase
    end
    
    always @* 
    begin
      debug     = 8'hff;
    end  
    
   
endmodule

