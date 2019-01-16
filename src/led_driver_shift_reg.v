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

module led_driver_shift_reg #(parameter DATA_WIDTH = 32, parameter SHIFT_WIDTH = 32)
(
    input  clk,
    input  reset,

    input  [DATA_WIDTH-1:0] data_in,
    input  load,
    input  next_bit,
    output bit_val,
    output last_bit
);

    `include "globals.vh"

    localparam SHIFT_WIDTH_NBITS = clogb2(SHIFT_WIDTH) + 1;

    reg [SHIFT_WIDTH_NBITS-1:0] cnt;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt <= 0;
        end
        else begin
            if (load) begin
                cnt <= SHIFT_WIDTH-1;
            end
            else if (next_bit) begin
                cnt <= cnt - 1;
            end
        end
    end 

    assign last_bit = (cnt == 0);

    reg [DATA_WIDTH-1:0] data;
    assign bit_val = data[cnt];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data <= 0;
        end
        else begin
            if (load) begin
                data <= data_in;
            end
        end
    end 

endmodule
