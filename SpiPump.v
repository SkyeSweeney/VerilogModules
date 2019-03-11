`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
//
// This module is used to generate complete SPI bus transactions.
// These transactions may be single or multi byte.
// The caller must first latch in the bytes to be transmitted one at
// a time using the tx_data, tx_latch, anc clk lines.
// When the data is in place, raise the xferStart line high.
// This will caus ethe bus transaction to execute.
// During the transaction the busy signal will remain high.
// At the end of the transaction, the user can clock out the data
// using the rx_latch
//
//
////////////////////////////////////////////////////////////////////////////////
module SpiPump(
    input             clk,       // System clock
    input             rst,       // System reset
    input             xferStart, // Strobe to start transfer
    input             miso,      // MISO pin
    input  [7:0]      tx_data,   // Data to send
    input             tx_latch,  // Strobe to latch in tx data
    input             rx_latch,  // Strobe to latch out rx data
    output reg        busy,      // Pump is busy
    output wire       mosi,      // MOSI pin
    output reg        ss,        // SS pin
    output wire       sclk,      // SCKK pin
    output wire [7:0] rx_data,   // Data recieved
    output wire       tx_full,   // Transmitter is full
    output wire       rx_empty,  // Receiver is empty
    output reg  [7:0] debug      // Debug signals
    );


    
    //*******************************************************
    // RX FIFO (Holds byte comming in from acc)
    //*******************************************************
    
    wire [7:0] rx_din;
    reg        rx_wr_en;
    wire [7:0] rx_dout;
    wire       rx_full;
    
    fifo_generator_v9_3 rxfifo(
        .clk       (clk),
        .rst       (rst),
        .din       (rx_din),
        .wr_en     (rx_wr_en),
        .rd_en     (rx_latch),
        .dout      (rx_data),
        .full      (rx_full),
        .empty     (rx_empty)
    );
    
    //*******************************************************
    // TX FIFO (Holds byte to go to acc)
    //*******************************************************
    
    wire [7:0] tx_dout;
    reg        tx_rd_en;
    wire       tx_empty;
    
    fifo_generator_v9_3 txfifo(
        .clk       (clk),
        .rst       (rst),
        .din       (tx_data),  
        .wr_en     (tx_latch),
        .rd_en     (tx_rd_en),
        .dout      (tx_dout),
        .full      (tx_full),
        .empty     (tx_empty)
    );
    
    //*******************************************************
    // Single byte SPI transfer agent
    //*******************************************************
    
    wire  xbusy;
    reg   xfer_en;

    // Instantiate the basic one byte transfer routine
    SpiMasterXfer OnByte(
      .clk     (clk),
      .rst     (rst),
      .xfer_en (xfer_en),
      .miso    (miso),
      .tx_data (tx_dout), // Connect to output of TX FIFO
      .busy    (xbusy),
      .mosi    (mosi),
      .sclk    (sclk),
      .rx_data (rx_din)  // Connect to input of RX fifo
  );
  
    parameter m_idle  = 4'd0; 
    parameter m_10    = 4'd1; 
    parameter m_20    = 4'd2; 
    parameter m_30    = 4'd3; 
    parameter m_31    = 4'd4; 
    parameter m_35    = 4'd5; 
    parameter m_40    = 4'd6; 
    parameter m_50    = 4'd7; 
    parameter m_60    = 4'd8; 
    parameter m_70    = 4'd9; 
    parameter m_80    = 4'd10; 
    parameter m_90    = 4'd11; 
  
    reg [3:0] mode = m_idle;
    

    
    ////////////////////////////////////////////////////////////////////////////
    // FSM
    ////////////////////////////////////////////////////////////////////////////
    
    always @ (posedge clk)
    begin    
    
    
      case(mode)
      
      // Wait for xferStart to go high
      // At this point we assume the user has clocked in the bytes to send 
      // into the TX FIFO.
      m_idle:
      begin
        ss   <= 1;    // SS idles high
        busy <= 0;
        
        // If Transfer request
        if (xferStart == 1)
        begin
        
          // Indicate busy
          busy <= 1;
          
          // Assert Slave select
          ss   <= 0;
          
          mode <= m_20;
        end
      end
      
      // Read out byte from Tx fifo
      // This puts data at front door of transfer agent
      m_20:
      begin
        tx_rd_en <= 1;
        mode     <= m_30;
      end
        
      // Start SPI transfer
      m_30:
      begin
        tx_rd_en <= 0;
        xfer_en  <= 1;
        mode     <= m_31;
      end
      
      m_31:
      begin
        xfer_en <= 0;
        mode    <= m_35;
      end
      
      // Wait for transmitter to go busy (Need to fix!)
      m_35:
      begin
        if (xbusy == 1)
        begin
          mode <= m_40;
        end
      end
  
      // Wait for transmitter to become free  
      m_40:
      begin
        if (xbusy == 0)
        begin
          mode <= m_50;
        end
      end
        
      // Now take output of transfer agent into Rx FIFO  
      m_50:
      begin
        rx_wr_en <= 1;
        mode     <= m_60;
      end
        
      m_60:
      begin
        rx_wr_en <= 0;
        mode     <= m_70;
      end
      
      // Delay a clock to let tx_empty change state
      m_70:
      begin
        mode <= m_80;
      end
        
      // Check for more bytes to send  
      m_80:
      begin
      
        // If nothing more to send, go back to idle
        if (tx_empty == 1)
        begin
          mode <= m_idle;
        end
        else
        begin
          mode <= m_20;
        end
        
      end
      
      default:
        mode <= m_idle;
      
      endcase
 
    end

    // Route debug signals out
    always @* 
    begin
      debug[7:0] = 8'h0;
      debug[0]   = tx_latch;
      debug[1]   = tx_empty;
      debug[2]   = rx_full;
    end


endmodule
