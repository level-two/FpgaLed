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

module tb_wb_nic ();
    `include "globals.vh"

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter CLK_PER = 10;

    reg reset;
    reg clk;

    reg  [ADDR_WIDTH-1:0] ctrl_wbm_address;
    reg  [DATA_WIDTH-1:0] ctrl_wbm_writedata;
    wire [DATA_WIDTH-1:0] ctrl_wbm_readdata;
    reg                   ctrl_wbm_strobe;
    reg                   ctrl_wbm_cycle;
    reg                   ctrl_wbm_write;
    wire                  ctrl_wbm_ack;

    reg  [ADDR_WIDTH-1:0] ldrv_wbm_address;
    reg  [DATA_WIDTH-1:0] ldrv_wbm_writedata;
    wire [DATA_WIDTH-1:0] ldrv_wbm_readdata;
    reg                   ldrv_wbm_strobe;
    reg                   ldrv_wbm_cycle;
    reg                   ldrv_wbm_write;
    wire                  ldrv_wbm_ack;

    reg  [ADDR_WIDTH-1:0] bupd_wbm_address;
    reg  [DATA_WIDTH-1:0] bupd_wbm_writedata;
    wire [DATA_WIDTH-1:0] bupd_wbm_readdata;
    reg                   bupd_wbm_strobe;
    reg                   bupd_wbm_cycle;
    reg                   bupd_wbm_write;
    wire                  bupd_wbm_ack;

    wire [ADDR_WIDTH-1:0] bmgr_wbs_address;
    wire [DATA_WIDTH-1:0] bmgr_wbs_writedata;
    reg  [DATA_WIDTH-1:0] bmgr_wbs_readdata;
    wire                  bmgr_wbs_strobe;
    wire                  bmgr_wbs_cycle;
    wire                  bmgr_wbs_write;
    reg                   bmgr_wbs_ack;

    wire [ADDR_WIDTH-1:0] mem_wbs_address;
    wire [DATA_WIDTH-1:0] mem_wbs_writedata;
    reg  [DATA_WIDTH-1:0] mem_wbs_readdata;
    wire                  mem_wbs_strobe;
    wire                  mem_wbs_cycle;
    wire                  mem_wbs_write;
    reg                   mem_wbs_ack;


    wb_nic #(ADDR_WIDTH, DATA_WIDTH) dut
    (
        .reset(reset),
        .clk(clk),

        .ctrl_wbm_address(ctrl_wbm_address),
        .ctrl_wbm_writedata(ctrl_wbm_writedata),
        .ctrl_wbm_readdata(ctrl_wbm_readdata),
        .ctrl_wbm_strobe(ctrl_wbm_strobe),
        .ctrl_wbm_cycle(ctrl_wbm_cycle),
        .ctrl_wbm_write(ctrl_wbm_write),
        .ctrl_wbm_ack(ctrl_wbm_ack),

        
        .ldrv_wbm_address(ldrv_wbm_address),
        .ldrv_wbm_writedata(ldrv_wbm_writedata),
        .ldrv_wbm_readdata(ldrv_wbm_readdata),
        .ldrv_wbm_strobe(ldrv_wbm_strobe),
        .ldrv_wbm_cycle(ldrv_wbm_cycle),
        .ldrv_wbm_write(ldrv_wbm_write),
        .ldrv_wbm_ack(ldrv_wbm_ack),

        .bupd_wbm_address(bupd_wbm_address),
        .bupd_wbm_writedata(bupd_wbm_writedata),
        .bupd_wbm_readdata(bupd_wbm_readdata),
        .bupd_wbm_strobe(bupd_wbm_strobe),
        .bupd_wbm_cycle(bupd_wbm_cycle),
        .bupd_wbm_write(bupd_wbm_write),
        .bupd_wbm_ack(bupd_wbm_ack),

        
        .bmgr_wbs_address(bmgr_wbs_address),
        .bmgr_wbs_writedata(bmgr_wbs_writedata),
        .bmgr_wbs_readdata(bmgr_wbs_readdata),
        .bmgr_wbs_strobe(bmgr_wbs_strobe),
        .bmgr_wbs_cycle(bmgr_wbs_cycle),
        .bmgr_wbs_write(bmgr_wbs_write),
        .bmgr_wbs_ack(bmgr_wbs_ack),

        .mem_wbs_address(mem_wbs_address),
        .mem_wbs_writedata(mem_wbs_writedata),
        .mem_wbs_readdata(mem_wbs_readdata),
        .mem_wbs_strobe(mem_wbs_strobe),
        .mem_wbs_cycle(mem_wbs_cycle),
        .mem_wbs_write(mem_wbs_write),
        .mem_wbs_ack(mem_wbs_ack)
    );


    always begin
        #(CLK_PER/2);
        clk <= ~clk;
    end

    initial begin
        clk <= 0;
        reset <= 1;

        ctrl_wbm_address    <= 0;
        ctrl_wbm_writedata  <= 0;
        ctrl_wbm_strobe     <= 0;
        ctrl_wbm_cycle      <= 0;
        ctrl_wbm_write      <= 0;

        ldrv_wbm_address    <= 0;
        ldrv_wbm_writedata  <= 0;
        ldrv_wbm_strobe     <= 0;
        ldrv_wbm_cycle      <= 0;
        ldrv_wbm_write      <= 0;

        bupd_wbm_address    <= 0;
        bupd_wbm_writedata  <= 0;
        bupd_wbm_strobe     <= 0;
        bupd_wbm_cycle      <= 0;
        bupd_wbm_write      <= 0;

        bmgr_wbs_readdata   <= 0;
        bmgr_wbs_ack        <= 0;

        mem_wbs_readdata    <= 0;
        mem_wbs_ack         <= 0;


        repeat (100) @(posedge clk);
        reset <= 0;
        repeat (100) @(posedge clk);

        repeat (5) begin
            ldrv_wbm_address    <= `BUF_MANAGER_BASE_ADDR;
            ldrv_wbm_writedata  <= 0;
            ldrv_wbm_strobe     <= 1;
            ldrv_wbm_cycle      <= 1;
            ldrv_wbm_write      <= 0;

            while (~(bmgr_wbs_cycle & bmgr_wbs_strobe)) @(posedge clk);

            bmgr_wbs_readdata   <= 'hdeadbeef;
            bmgr_wbs_ack        <= 1;

            @(posedge clk);

            bmgr_wbs_readdata   <= 0;
            bmgr_wbs_ack        <= 0;

            while (~ldrv_wbs_ack) @(posedge clk);

            ldrv_wbm_address    <= 0;
            ldrv_wbm_writedata  <= 0;
            ldrv_wbm_strobe     <= 0;
            ldrv_wbm_cycle      <= 0;
            ldrv_wbm_write      <= 0;

            repeat (3) @(posedge clk);
        end
            
        repeat (100) @(posedge clk);

        repeat (5) begin
            ctrl_wbm_address    <= `BUF_MANAGER_BASE_ADDR;
            ctrl_wbm_writedata  <= 0;
            ctrl_wbm_strobe     <= 1;
            ctrl_wbm_cycle      <= 1;
            ctrl_wbm_write      <= 0;

            while (~(bmgr_wbs_cycle & bmgr_wbs_strobe)) @(posedge clk);

            bmgr_wbs_readdata   <= 'hdeadbeef;
            bmgr_wbs_ack        <= 1;

            @(posedge clk);

            bmgr_wbs_readdata   <= 0;
            bmgr_wbs_ack        <= 0;

            while (~ctrl_wbs_ack) @(posedge clk);

            ctrl_wbm_address    <= 0;
            ctrl_wbm_writedata  <= 0;
            ctrl_wbm_strobe     <= 0;
            ctrl_wbm_cycle      <= 0;
            ctrl_wbm_write      <= 0;

            repeat (3) @(posedge clk);
        end
            
        repeat (100) @(posedge clk);
        
        repeat (5) begin
            bupd_wbm_address    <= `MEM_BASE_ADDR;
            bupd_wbm_writedata  <= 0;
            bupd_wbm_strobe     <= 1;
            bupd_wbm_cycle      <= 1;
            bupd_wbm_write      <= 0;

            while (~(mem_wbs_cycle & mem_wbs_strobe)) @(posedge clk);

            mem_wbs_readdata   <= 'hdeadbeef;
            mem_wbs_ack        <= 1;

            @(posedge clk);

            mem_wbs_readdata   <= 0;
            mem_wbs_ack        <= 0;

            while (~bupd_wbs_ack) @(posedge clk);

            bupd_wbm_address    <= 0;
            bupd_wbm_writedata  <= 0;
            bupd_wbm_strobe     <= 0;
            bupd_wbm_cycle      <= 0;
            bupd_wbm_write      <= 0;

            repeat (3) @(posedge clk);
        end
    end

endmodule
