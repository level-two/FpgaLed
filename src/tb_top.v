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

module tb_top();
    `include "globals.vh"

    reg CLK_50M;
    wire [0:0] PMOD4;

    // vars
    reg  mosi;
    reg  ss;
    reg  sclk;
    wire miso;

    top dut
    (
        .CLK_50M(CLK_50M),
        .PMOD4(PMOD4),

        // SPI SIGNALS
        .SYS_SPI_MOSI(mosi),
        .SYS_SPI_MISO(miso),
        .SYS_SPI_SCK(sclk),
        .RP_SPI_CE0N(ss)
    );


    always begin
        #10;
        CLK_50M <= ~CLK_50M;
    end

    initial begin
            CLK_50M <= 0;
            mosi <= 0;
            ss <= 1;
            sclk <= 1;

        repeat (100) @(posedge CLK_50M);

        repeat (3 * `IMG_WIDTH * `IMG_HEIGHT) begin
            // SPI DATA
            @(posedge CLK_50M);
            ss <= 0;
            repeat (8) begin
                mosi <= $random() % 2;
                sclk <= 0;
                #301;
                sclk <= 1;
                #301;
            end
            ss <= 1;
            #25;
        end

    end

endmodule
