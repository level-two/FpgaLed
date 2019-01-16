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

module buf_updater_squares #(parameter ADDR_WIDTH = 16, parameter DATA_WIDTH = 32)
(
    input      reset,
    input      clk,

    // Wishbone master signals - for memory access
    output     [ADDR_WIDTH-1:0] wbm_address,
    output     [DATA_WIDTH-1:0] wbm_writedata,
    input      [DATA_WIDTH-1:0] wbm_readdata,
    output     wbm_strobe,
    output     wbm_cycle,
    output     wbm_write,
    input      wbm_ack,

    // control signals
    input      [DATA_WIDTH-1:0] buf_id,
    input      update_buf,
    output     buf_updated
);

    `include "globals.vh"

    localparam ST_IDLE            = 0;
    localparam ST_INIT_COUNTERS   = 1;
    localparam ST_UPDATE_COUNTERS = 2;
    localparam ST_SEND_COLOR      = 3;
    localparam ST_COLOR_SENT      = 4;
    localparam ST_DONE            = 5;

    reg [2:0] state, next_state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= ST_IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            ST_IDLE: begin
                if (update_buf) next_state = ST_INIT_COUNTERS;
            end
            ST_INIT_COUNTERS: begin
                next_state = ST_SEND_COLOR;
            end
            ST_UPDATE_COUNTERS: begin
                next_state = ST_SEND_COLOR;
            end
            ST_SEND_COLOR: begin
                if (wbm_ack) next_state = ST_COLOR_SENT;
            end
            ST_COLOR_SENT: begin
                next_state = (last_row & last_col) ? ST_DONE : ST_UPDATE_COUNTERS;
            end
            ST_DONE: begin
                next_state = ST_IDLE;
            end
            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end

    assign buf_updated = (state == ST_DONE);

    // Wishbone master
    assign wbm_strobe    = (state == ST_SEND_COLOR);
    assign wbm_cycle     = (state == ST_SEND_COLOR);
    assign wbm_write     = 1;
    assign wbm_writedata = color;
    assign wbm_address   = img_pixel_addr;


    // Color generator
    wire [31:0] color = last_col ? 32'b0 : 
       {   8'b0,
           5'b0, {3{col_cnt[1] ^ row_cnt[1]}},
           5'b0, {3{col_cnt[1] ^ row_cnt[1]}},
           5'b0, {3{col_cnt[1] ^ row_cnt[1]}} };

    // Counters
    reg [ADDR_WIDTH-1:0] row_cnt;
    reg [ADDR_WIDTH-1:0] col_cnt;
    reg [ADDR_WIDTH-1:0] img_pixel_addr;

    wire last_row = (row_cnt == `IMG_HEIGHT-1);
    wire last_col = (col_cnt == `IMG_WIDTH-1);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            row_cnt        <= 0;
            col_cnt        <= 0;
            img_pixel_addr <= 0;
        end
        else if (state == ST_INIT_COUNTERS) begin
            row_cnt        <= 0;
            col_cnt        <= 0;
            img_pixel_addr <= addr_for_buf_id(buf_id);
        end
        else if (state == ST_UPDATE_COUNTERS) begin
            img_pixel_addr <= img_pixel_addr + DATA_WIDTH/8;
            
            if (col_cnt != `IMG_WIDTH-1) begin
                col_cnt    <= col_cnt + 1;
            end
            else begin
                col_cnt    <= 0;
                row_cnt    <= row_cnt + 1;
            end
        end
    end


endmodule
