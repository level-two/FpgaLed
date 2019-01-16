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

module tb_ctrl_logic();
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter NBUFS = 13;

    reg reset;
    reg clk;

    wire [ADDR_WIDTH-1:0] wb_address;
    wire [DATA_WIDTH-1:0] wb_writedata;
    wire [DATA_WIDTH-1:0] wb_readdata;
    wire wb_strobe;
    wire wb_cycle;
    wire wb_write;
    wire wb_ack;

    // control signals
    wire [DATA_WIDTH-1:0] update_buf_id;
    wire update_buf;
    reg  buf_updated;

    // Signals from contorll logic
    wire [DATA_WIDTH-1:0] led_tx_buf_id;
    wire led_tx;
    reg  led_tx_done;


    // dut
    buf_manager #(ADDR_WIDTH, DATA_WIDTH, NBUFS) buf_man
    (
        .reset(reset),
        .clk(clk),

        // Wishbone signals
        .wbs_address(wb_address),
        .wbs_writedata(wb_writedata),
        .wbs_readdata(wb_readdata),
        .wbs_strobe(wb_strobe),
        .wbs_cycle(wb_cycle),
        .wbs_write(wb_write),
        .wbs_ack(wb_ack)
    );

    ctrl_logic #(ADDR_WIDTH, DATA_WIDTH) dut
    (
        .reset(reset),
        .clk(clk),

        .wbm_address(wb_address),
        .wbm_writedata(wb_writedata),
        .wbm_readdata(wb_readdata),
        .wbm_strobe(wb_strobe),
        .wbm_cycle(wb_cycle),
        .wbm_write(wb_write),
        .wbm_ack(wb_ack),
        
        .update_buf_id(update_buf_id),
        .update_buf(update_buf),
        .buf_updated(buf_updated),

        .led_tx_buf_id(led_tx_buf_id),
        .led_tx(led_tx),
        .led_tx_done(led_tx_done)
    );


    always begin
        #1;
        clk <= ~clk;
    end

    initial begin
            clk <= 0;
            reset <= 1;
            buf_updated <= 0;
            led_tx_done <= 0;

        repeat (100) @(posedge clk);
            reset <= 0;

        repeat (200) @(posedge clk);
            buf_updated <= 1;
        @(posedge clk);
            buf_updated <= 0;
    end

endmodule
