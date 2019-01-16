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

`timescale 1ns/1ps

module tb_wb_spi();
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;

    reg reset;
    reg clk;

    // dut ins
    reg [ADDR_WIDTH-1:0] wbs_address;
    reg [DATA_WIDTH-1:0] wbs_writedata;
    reg wbs_strobe;
    reg wbs_cycle;
    reg wbs_write;

    // dut outs
    wire wbs_ack;
    wire [DATA_WIDTH-1:0] wbs_readdata;

    // vars
    reg  mosi;
    reg  ss;
    reg  sclk;
    wire miso;
    
    wire spi_done;


    // dut
    wb_spi #(ADDR_WIDTH, DATA_WIDTH) dut
    (
        .reset(reset),
        .clk(clk),

        // Wishbone signals
        .wbs_address(wbs_address),
        .wbs_writedata(wbs_writedata),
        .wbs_readdata(wbs_readdata),
        .wbs_strobe(wbs_strobe),
        .wbs_cycle(wbs_cycle),
        .wbs_write(wbs_write),
        .wbs_ack(wbs_ack),

        // SPI SIGNALS
        .mosi(mosi),
        .ss(ss), 
        .sclk(sclk),
        .miso(miso),

        .spi_done(spi_done)
    );


    always begin
        #3;
        clk <= ~clk;
    end

    /*
    initial begin
        mosi <= 0;
        ss <= 0;
        sclk <= 0;

        repeat (200) @(posedge clk);

        repeat (5) begin
            mosi <= 0;
            ss <= 1;
            sclk <= 0;

            @(posedge clk);
            ss <= 0;

            repeat (8) begin
                mosi <= $random() % 2;
                sclk <= 1;
                #13;
                sclk <= 0;
                #13;
            end
        end

    end
    */

    initial begin
            clk <= 0;
            reset <= 1;
            wbs_address <= 0;
            wbs_writedata <= 0;
            wbs_strobe <= 0;
            wbs_cycle <= 0;
            wbs_write <= 0;

            mosi <= 0;
            ss <= 1;
            sclk <= 1;

        repeat (100) @(posedge clk);
            reset <= 0;


        repeat (2) begin

            // SPI DATA
            @(posedge clk);
            ss <= 0;
            repeat (8) begin
                mosi <= $random() % 2;
                sclk <= 0;
                #13;
                sclk <= 1;
                #13;
            end
            ss <= 1;
            #25;


            // READ RECEIVED DATA
            @(posedge clk);
            wbs_address <= 0;
            wbs_writedata <= 0;
            wbs_write <= 0;
            wbs_strobe <= 1;
            wbs_cycle <= 1;

            @(posedge clk);
            wbs_strobe <= 0;
            wbs_cycle <= 0;
        end

        repeat (4) begin
            // SEND DATA WHICH WILL BE TRANSMITTED TO SPI
            @(posedge clk);
            wbs_address <= 0;
            wbs_writedata <= $random() % 256;
            wbs_write <= 1;

            wbs_strobe <= 1;
            wbs_cycle <= 1;

            @(posedge clk);
            wbs_strobe <= 0;
            wbs_cycle <= 0;


            // SEND SPI
            @(posedge clk);
            ss <= 0;
            repeat (8) begin
                mosi <= $random() % 2;
                sclk <= 0;
                #13;
                sclk <= 1;
                #13;
            end
            ss <= 1;
            #25;


            // READ RECEIVED DATA
            @(posedge clk);
            wbs_address <= 0;
            wbs_writedata <= 0;
            wbs_write <= 0;
            wbs_strobe <= 1;
            wbs_cycle <= 1;

            @(posedge clk);
            wbs_strobe <= 0;
            wbs_cycle <= 0;
        end


        #100;
    end

endmodule
