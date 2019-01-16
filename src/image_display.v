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

module image_display #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32)
(
    input                       reset,
    input                       clk,

    // Master
    output reg [ADDR_WIDTH-1:0] wbm_address,
    output reg [DATA_WIDTH-1:0] wbm_writedata,
    input      [DATA_WIDTH-1:0] wbm_readdata,
    output reg                  wbm_strobe,
    output reg                  wbm_cycle,
    output reg                  wbm_write,
    input                       wbm_ack,
    
    // control signals
    input                       display_image,
    input      [DATA_WIDTH-1:0] display_image_buf_id,
    output                      display_image_done,


    // Signals from contorll logic
    output     [DATA_WIDTH-1:0] led_tx_buf_id,
    output                      led_tx,
    input                       led_tx_done
);

    `include "globals.vh"

    localparam ST_IDLE            = 0;
    localparam ST_ALLOC_BUF       = 1;
    localparam ST_INIT_COUNTERS   = 2;
    localparam ST_UPD_COUNTERS    = 3;
    localparam ST_FILL_LED_COL_RD = 4;
    localparam ST_LED_COL_RD_DONE = 5;
    localparam ST_FILL_LED_COL_WR = 6;
    localparam ST_LED_COL_WR_DONE = 7;
    localparam ST_SEND_LED_COL    = 8;
    localparam ST_DELAY           = 9;
    localparam ST_RELEASE_BUF     = 10;
    localparam ST_DONE            = 11;


    reg [3:0] state, next_state;

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
                if (display_image) begin
                    next_state = ST_ALLOC_BUF;
                end
            end
            ST_ALLOC_BUF: begin
                if (wbm_ack) begin
                    next_state = ST_INIT_COUNTERS;
                end
            end
            ST_INIT_COUNTERS: begin
                next_state = ST_FILL_LED_COL_RD;
            end
            ST_UPD_COUNTERS: begin
                // We need check last_col because at last iteration in ST_UPD_COUNTERS state counters are yet not switched
                // and just skip read image pixels
                next_state = ((last_col & last_row) | blank_col) ? ST_FILL_LED_COL_WR : ST_FILL_LED_COL_RD;
            end
            ST_FILL_LED_COL_RD: begin
                if (wbm_ack) begin
                    next_state = ST_LED_COL_RD_DONE;
                end
            end
            ST_LED_COL_RD_DONE: begin
                next_state = ST_FILL_LED_COL_WR;
            end
            ST_FILL_LED_COL_WR: begin
                if (wbm_ack) begin
                    next_state = ST_LED_COL_WR_DONE;
                end
            end
            ST_LED_COL_WR_DONE: begin
                next_state = last_row ? ST_SEND_LED_COL : ST_UPD_COUNTERS;
            end
            ST_SEND_LED_COL: begin
                if (led_tx_done) begin
                    next_state = blank_col ? ST_RELEASE_BUF : ST_DELAY;
                end
            end
            ST_DELAY: begin
                if (dly_done) begin
                    next_state = ST_UPD_COUNTERS;
                end
            end
            ST_RELEASE_BUF: begin
                if (wbm_ack) begin
                    next_state = ST_DONE;
                end
            end
            ST_DONE: begin
                next_state = ST_IDLE;
            end
            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end


    assign display_image_done = (state == ST_DONE);


    // buf id and buf display_image
    reg [DATA_WIDTH-1:0] led_buf_id;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            led_buf_id <= 0;
        end
        else if ((state == ST_ALLOC_BUF) && wbm_ack) begin
            led_buf_id <= wbm_readdata;
        end
    end


    // Led TX
    assign led_tx_buf_id = led_buf_id;
    assign led_tx        = (state == ST_SEND_LED_COL);


    // Wishbone signals
    always @(*) begin
        case (state)
            ST_ALLOC_BUF: begin
                wbm_address   = `BUF_MANAGER_BASE_ADDR;
                wbm_write     = 0;
                wbm_writedata = 0;
                wbm_cycle     = 1;
                wbm_strobe    = 1;
            end
            ST_RELEASE_BUF: begin
                wbm_address   = `BUF_MANAGER_BASE_ADDR;
                wbm_write     = 1;
                wbm_writedata = led_buf_id;
                wbm_cycle     = 1;
                wbm_strobe    = 1;
            end
            ST_FILL_LED_COL_RD: begin
                wbm_address   = img_pixel_addr;
                wbm_write     = 0;
                wbm_writedata = 0;
                wbm_cycle     = 1;
                wbm_strobe    = 1;
            end
            ST_FILL_LED_COL_WR: begin
                wbm_address   = led_pixel_addr;
                wbm_write     = 1;
                wbm_writedata = blank_col ? 0 : led_pixel_val_decoded;
                wbm_cycle     = 1;
                wbm_strobe    = 1;
            end
            default: begin
                wbm_address   = 0;
                wbm_write     = 0;
                wbm_writedata = 0;
                wbm_cycle     = 0;
                wbm_strobe    = 0;
            end
        endcase
    end


    // Img pixel decoding
    reg [DATA_WIDTH-1:0] led_pixel_val_decoded;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            led_pixel_val_decoded <= 0;
        end
        else if ((state == ST_FILL_LED_COL_RD) & wbm_ack) begin
            led_pixel_val_decoded[23:16] <= wbm_readdata[15:8];
            led_pixel_val_decoded[15:8]  <= wbm_readdata[23:16];
            led_pixel_val_decoded[7:0]   <= wbm_readdata[7:0];
        end
    end


    // Counters
    reg [ADDR_WIDTH-1:0] row_cnt;
    reg [ADDR_WIDTH-1:0] col_cnt;
    reg [ADDR_WIDTH-1:0] img_pixel_addr;
    reg [ADDR_WIDTH-1:0] img_pixel_next_col_addr;
    reg [ADDR_WIDTH-1:0] led_pixel_addr;

    wire last_row = (row_cnt == `IMG_HEIGHT-1);
    wire last_col = (col_cnt == `IMG_WIDTH-1);
    wire blank_col = (col_cnt == `IMG_WIDTH);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            row_cnt                 <= 0;
            col_cnt                 <= 0;
            img_pixel_addr          <= 0;
            img_pixel_next_col_addr <= 0;
            led_pixel_addr          <= 0;
        end
        else if (state == ST_INIT_COUNTERS) begin
            row_cnt                 <= 0;
            col_cnt                 <= 0;
            img_pixel_addr          <= addr_for_buf_id(display_image_buf_id);
            img_pixel_next_col_addr <= addr_for_buf_id(display_image_buf_id) + DATA_WIDTH/8;
            led_pixel_addr          <= addr_for_buf_id(led_buf_id);
        end
        else if (state == ST_UPD_COUNTERS) begin
            if (row_cnt == `IMG_HEIGHT-1) begin
                row_cnt                 <= 0;
                col_cnt                 <= col_cnt + 1;
                img_pixel_addr          <= img_pixel_next_col_addr;
                img_pixel_next_col_addr <= img_pixel_next_col_addr + DATA_WIDTH/8;
                led_pixel_addr          <= addr_for_buf_id(led_buf_id);
            end
            else begin
                row_cnt                 <= row_cnt + 1;
                img_pixel_addr          <= img_pixel_addr + `IMG_WIDTH*DATA_WIDTH/8;
                led_pixel_addr          <= led_pixel_addr + DATA_WIDTH/8;
            end
        end
    end
    
    // Delay 
    reg [DATA_WIDTH-1:0] dly_cnt;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dly_cnt <= 0;
        end
        else if (state == ST_DELAY) begin
            dly_cnt <= dly_cnt + 1;
        end
        else begin
            dly_cnt <= 0;
        end
    end
    wire dly_done = (dly_cnt == `COLUMN_TIME);

endmodule
