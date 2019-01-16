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

module tb_arb_rr ();
    parameter PORTS_NUM = 3;

    reg reset;
    reg clk;

    reg  [PORTS_NUM-1:0] req;
    wire [PORTS_NUM-1:0] gnt;

    arb_rr #(PORTS_NUM) dut(
        .reset(reset),
        .clk(clk),

        .req(req),
        .gnt(gnt)
    );

    always begin
        #1;
        clk <= ~clk;
    end

    initial begin
            clk <= 0;
            reset <= 1;
            req <= 0;

        repeat (100) @(posedge clk);
            reset <= 0;
        repeat (100) @(posedge clk);

        req <= 1;
        repeat (10) @(posedge clk);

        req <= 0;
        repeat (10) @(posedge clk);

        req <= 3;
        repeat (10) @(posedge clk);

        req <= 1;
        repeat (10) @(posedge clk);

        req <= 0;
        repeat (10) @(posedge clk);

        #100;
    end

endmodule
