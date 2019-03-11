//----------------------------------------------------------------------
// This file contains the UART Transmitter.  This transmitter is able
// to transmit 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  
//
// Parameters:
//   BAUD: bits per second of output
//   CLOCK: Rate of clk
//----------------------------------------------------------------------
  
module UartTxFifo 
    #(parameter BAUD  = 115200,
      parameter CLOCK = 50000000)
    (
      input             clk,       // System clock
      input             rst,       // System reset
      input             wrEn,      // Write enable
      input [7:0]       din,       // Byte to transmit
      output            full,      // Uart FIFO is full
      output wire       txPin,     // UART pin
      output reg        busy,      // Transmitter is busy
      output wire [7:0] debug      // debug pins
    );
   
    reg        txGo;
    wire [7:0] txDout;
    reg        txRdEn;         // Read latch to FIFO
    wire       empty;
    wire       txBusy;
   
  
    //*******************************************************
    // Single Byte UART
    //*******************************************************
    uart_tx #(.BAUD(BAUD), 
              .CLOCK(CLOCK)) Uart
    (
      .clk     (clk),
      .rst     (rst),
      .wrEn    (txGo),
      .din     (txDout), 
      .busy    (txBusy),
      .txPin   (txPin),
      .debug   (debug)
    );    


    //*******************************************************
    // TX FIFO
    //*******************************************************
    fifo_generator_v9_3 fifo(
        .clk       (clk),
        .rst       (rst),
        .din       (din),  
        .wr_en     (wrEn),
        .rd_en     (txRdEn),
        .dout      (txDout),
        .full      (full),
        .empty     (empty)
    );
    
    //*******************************************************
    // FSM
    //*******************************************************
    
    parameter s_10 = 4'd0;
    parameter s_20 = 4'd1;
    parameter s_30 = 4'd2;
    parameter s_40 = 4'd3;
    
    reg [4:0] mode = s_10;
    
    always @ (posedge clk)
    begin
    
      // Manage reset
      if (rst == 1)
      begin
        mode <= s_10;
      end
    
      case (mode)
          
      s_10:
      if ((empty == 0) && (txBusy == 0))
      begin
        txRdEn <= 1;
        mode   <= s_20;
      end
      
      s_20:
      begin
        txRdEn <= 0;
        txGo   <= 1;
        mode   <= s_30;
      end
      
      s_30:
      begin
        txGo <= 0;
        mode <= s_40;
      end
      
      s_40:
      begin
        mode <= s_10;
      end

      default
        mode <= s_10;
        
      endcase
    
    end


   
endmodule

