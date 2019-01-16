// -----------------------------------------------------------------------------
//    Copyright (C) 2016 Yauheni Lychkouski.
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
// -----------------------------------------------------------------------------

module wb_spi #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32)
(
    input      reset,
    input      clk,

    // SPI SIGNALS
    input      mosi,
    input      ss, 
    input      sclk,
    output     miso,

    // WB Slave
    input      [ADDR_WIDTH-1:0] wbs_address,
    input      [DATA_WIDTH-1:0] wbs_writedata,
    output reg [DATA_WIDTH-1:0] wbs_readdata,
    input      wbs_strobe,
    input      wbs_cycle,
    input      wbs_write,
    output     wbs_ack,

    output     spi_done
);

    `include "globals.vh"

    wire       spi_msb_first = 1;
    reg        spi_txen;
    reg  [7:0] spi_txdata;
    wire [7:0] spi_rxdata;

    spi_slave spi_slave(
        .reset(reset),

        .ss(ss),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),

        .msb_first(spi_msb_first),
        .txen(spi_txen),
        .txdata(spi_txdata),
        .rxdata(spi_rxdata),
        .done(spi_slave_done)
    );

    reg done;
    reg done_dly;
    always @(posedge clk or posedge reset) begin
        if (reset) begin 
            done     <= 0;
            done_dly <= 0;
        end else begin
            done     <= spi_slave_done;
            done_dly <= done;
        end
    end
    assign spi_done = done & ~done_dly;


    // Wishbone
    wire component_trans = wbs_strobe & wbs_cycle;
    wire component_write = component_trans & wbs_write;
    wire component_read  = component_trans & ~wbs_write;


    reg strobe_dly;
    always @(posedge clk or posedge reset) begin
        if (reset) begin 
            strobe_dly <= 1'h0;
        end else begin
            strobe_dly <= wbs_strobe;
        end
    end
    assign wbs_ack = wbs_strobe & strobe_dly;


    // 
    always @(posedge clk or posedge reset) begin
        if (reset) begin 
            wbs_readdata <= 0;
        end 
        else if (component_read) begin
            wbs_readdata <= {24'b0, spi_rxdata};
        end
    end


    always @(posedge clk or posedge reset) begin
        if (reset) begin 
            spi_txen   <= 0;
            spi_txdata <= 0;
        end 
        else if (component_write) begin
            spi_txen   <= 1;
            spi_txdata <= wbs_writedata[7:0];
        end
        else if (spi_done) begin
            spi_txen   <= 0;
        end
    end

endmodule
