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

module tb_led_driver_data_coder();
    parameter CLK_PER = 10;

    reg reset;
    reg clk;
    reg tr_start;
    wire tr_done;
    reg tr_val;
    reg tr_end;
    wire led_data;


    // dut
    led_driver_data_coder #(CLK_PER) dut(
        .reset(reset),
        .clk(clk),

        .tr_start(tr_start),
        .tr_done(tr_done),
        .tr_val(tr_val),
        .tr_end(tr_end),
        .led_data(led_data)
    );

    always begin
        #(CLK_PER/2);
        clk <= ~clk;
    end

    initial begin
        clk <= 0;
        reset <= 1;

        tr_start <= 0;
        tr_val <= 0;
        tr_end <= 0;

        repeat (100) @(posedge clk);
            reset <= 0;

        repeat (100) @(posedge clk);

        repeat (2) begin
            // Send 0
            tr_start <= 1;
            tr_val <= 0;
            tr_end <= 0;

            @(posedge clk);
            tr_start <= 0;

            @(posedge tr_done);

            repeat (10) @(posedge clk);

            // Send 1
            tr_start <= 1;
            tr_val <= 1;
            tr_end <= 0;

            @(posedge clk);
            tr_start <= 0;

            @(posedge tr_done);

            repeat (10) @(posedge clk);

            // Send End
            tr_start <= 1;
            tr_val <= 0;
            tr_end <= 1;

            @(posedge clk);
            tr_start <= 0;

            @(posedge tr_done);

            repeat (10) @(posedge clk);
        end

        #100;
    end

endmodule
