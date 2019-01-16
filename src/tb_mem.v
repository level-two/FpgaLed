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

module tb_mem ();
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;

    reg reset;
    reg clk;

    // Wishbone signals
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
    reg [ADDR_WIDTH-1:0] addr;

    mem #(ADDR_WIDTH, DATA_WIDTH) dut(
        .reset(reset),
        .clk(clk),

        // Wishbone signals
        .wbs_address(wbs_address),
        .wbs_writedata(wbs_writedata),
        .wbs_readdata(wbs_readdata),
        .wbs_strobe(wbs_strobe),
        .wbs_cycle(wbs_cycle),
        .wbs_write(wbs_write),
        .wbs_ack(wbs_ack)
    );

    always begin
        #1;
        clk <= ~clk;
    end

    initial begin
            clk <= 0;
            reset <= 1;
            wbs_address <= 0;
            wbs_writedata <= 0;
            wbs_strobe <= 0;
            wbs_cycle <= 0;
            wbs_write <= 0;

        repeat (100) @(posedge clk);
            reset <= 0;
        repeat (100) @(posedge clk)

        for (addr=0; addr < 1024; addr = addr+1) begin
            @(posedge clk);
            wbs_address <= addr;
            wbs_writedata <= {DATA_WIDTH{1'b1}} - addr;
            wbs_write <= 1;
            wbs_strobe <= 1;
            wbs_cycle <= 1;

            @(posedge clk);
            wbs_strobe <= 0;
            wbs_cycle <= 0;
        end

        for (addr=0; addr < 1024; addr = addr+1) begin
            @(posedge clk);
            wbs_address <= addr;
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
