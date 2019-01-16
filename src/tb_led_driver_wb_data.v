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

module tb_led_driver_wb_data ();
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter CLK_PER = 10;

    reg reset;
    reg clk;

    // Wishbone signals
    // dut ins
    wire [ADDR_WIDTH-1:0] wbm_address;
    wire [DATA_WIDTH-1:0] wbm_writedata;
    wire wbm_strobe;
    wire wbm_cycle;
    wire wbm_write;

    // dut outs
    wire wbm_ack;
    wire [DATA_WIDTH-1:0] wbm_readdata;


    // control signals
    reg [DATA_WIDTH-1:0] buf_id;
    reg wb_request_first_word;
    reg wb_request_next_word;
    wire wb_recieved_new_word;
    wire [DATA_WIDTH-1:0] wb_received_word;

    mem #(ADDR_WIDTH, DATA_WIDTH) wb_mem(
        .reset(reset),
        .clk(clk),

        // Wishbone signals
        .wbm_address(wbm_address),
        .wbm_writedata(wbm_writedata),
        .wbm_readdata(wbm_readdata),
        .wbm_strobe(wbm_strobe),
        .wbm_cycle(wbm_cycle),
        .wbm_write(wbm_write),
        .wbm_ack(wbm_ack)
    );


    led_driver_wb_data #(ADDR_WIDTH, DATA_WIDTH) dut
    (
        .reset(reset),
        .clk(clk),

        // Wishbone master signals
        .wbm_address(wbm_address),
        .wbm_writedata(wbm_writedata),
        .wbm_readdata(wbm_readdata),
        .wbm_strobe(wbm_strobe),
        .wbm_cycle(wbm_cycle),
        .wbm_write(wbm_write),
        .wbm_ack(wbm_ack),

        // control signals
        .buf_id(buf_id),
        .wb_request_first_word(wb_request_first_word),
        .wb_request_next_word(wb_request_next_word),
        .wb_recieved_new_word(wb_recieved_new_word),
        .wb_received_word(wb_received_word)
    );




    always begin
        #(CLK_PER/2);
        clk <= ~clk;
    end

    initial begin
        clk <= 0;
        reset <= 1;

        buf_id <= 0;
        wb_request_first_word <= 0;
        wb_request_next_word <= 0;
        

        repeat (100) @(posedge clk);
        reset <= 0;
        repeat (100) @(posedge clk);

        repeat (5) begin
            buf_id <= 0;
            wb_request_first_word <= 1;

            @(posedge clk); 
            wb_request_first_word <= 0;

            while (~wb_recieved_new_word) @(posedge clk);

            repeat (10) begin
                wb_request_next_word <= 1;

                @(posedge clk); 
                wb_request_next_word <= 0;

                while (~wb_recieved_new_word) @(posedge clk);
            end

            repeat (3) @(posedge clk);

        end
            
        
        #100;
    end

endmodule
