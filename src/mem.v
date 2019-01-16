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

module mem (
      input reset,
      input clk,

      // Wishbone signals
      input  [ADDR_WIDTH-1:0] wbs_address,
      input  [DATA_WIDTH-1:0] wbs_writedata,
      output [DATA_WIDTH-1:0] wbs_readdata,
      input  wbs_strobe,
      input  wbs_cycle,
      input  wbs_write,
      output wbs_ack
    );

    `include "globals.vh"

    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;

    reg read_ack;
    reg write_ack;

    wire component_write;
    wire component_read;
    wire component_trans;
    wire [ADDR_WIDTH-1:0] component_addr;
    wire [DATA_WIDTH-1:0] component_write_data;
    wire [DATA_WIDTH-1:0] component_read_data;


    assign component_trans = wbs_strobe & wbs_cycle;
    assign component_write = component_trans & wbs_write;
    assign wbs_ack = (read_ack | write_ack) & component_trans;


    always @(posedge clk or posedge reset) begin
        if (reset) begin 
            write_ack = 1'h0;
        end else begin
            write_ack = component_write ? 1'h1 : 1'h0;
        end
    end


    assign component_read = component_trans & ~wbs_write;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            read_ack = 0;
        end else begin
            read_ack = component_read;
        end
    end

    assign wbs_readdata = component_read_data;
    assign component_addr = addr_without_base(wbs_address);
    assign component_write_data = wbs_writedata;

    mem_ip_16k mem_ip_16k 
    (
        .clka (clk                  ), // input clka
        .wea  ({4{component_write}} ), // input [3:0]  wea
        .addra(component_addr       ), // input [31:0] addra
        .dina (component_write_data ), // input [31:0] dina
        .douta(component_read_data  )  // output[31:0] douta
    );

endmodule
