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

module arb_rr #(parameter PORTS_NUM = 4)
(
    input reset,
    input clk,

    input  [PORTS_NUM-1:0] req,
    output [PORTS_NUM-1:0] gnt
);

    reg [PORTS_NUM-1:0] rr_cnt;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rr_cnt <= 1;
        end
        else begin
            if (gnt == 0) begin
                rr_cnt <= {rr_cnt[PORTS_NUM-2:0], rr_cnt[PORTS_NUM-1]};
            end
        end
    end

    assign gnt = req & rr_cnt;
endmodule
