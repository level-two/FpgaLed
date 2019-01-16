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

module spi_image_rcvr #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32)
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
    
    // Signal from spi module
    input                       spi_done,

    // Signals from contorll logic
    output reg [DATA_WIDTH-1:0] img_buf_id,
    output                      img_rcvd
);

    `include "globals.vh"

    localparam ST_IDLE              = 0;
    localparam ST_ALLOC_BUF         = 1;
    localparam ST_ALLOC_BUF_DONE    = 2;
    localparam ST_GET_SPI_BYTE      = 3;
    localparam ST_GET_SPI_BYTE_DONE = 4;
    localparam ST_WRITE_PIXEL       = 5;
    localparam ST_WRITE_PIXEL_DONE  = 6;
    localparam ST_WAIT_SPI          = 7;
    localparam ST_DONE              = 8;


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
                if (spi_done) begin
                    next_state = ST_ALLOC_BUF;
                end
            end
            ST_ALLOC_BUF: begin
                if (wbm_ack) begin
                    next_state = ST_ALLOC_BUF_DONE;
                end
            end
            ST_ALLOC_BUF_DONE: begin
                next_state = ST_GET_SPI_BYTE;
            end
            ST_GET_SPI_BYTE: begin
                if (wbm_ack) begin
                    next_state = ST_GET_SPI_BYTE_DONE;
                end
            end
            ST_GET_SPI_BYTE_DONE: begin
                next_state = all_pixel_bytes ? ST_WRITE_PIXEL : ST_WAIT_SPI;
            end
            ST_WRITE_PIXEL: begin
                if (wbm_ack) begin
                    next_state = ST_WRITE_PIXEL_DONE;
                end
            end
            ST_WRITE_PIXEL_DONE: begin
                next_state = last_pixel ? ST_DONE : ST_WAIT_SPI;
            end
            ST_WAIT_SPI: begin
                if (spi_done) begin
                    next_state = ST_GET_SPI_BYTE;
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

    assign img_rcvd = (state == ST_DONE);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            img_buf_id <= 0;
        end
        else if ((state == ST_ALLOC_BUF) && wbm_ack) begin
            img_buf_id <= wbm_readdata;
        end
    end



    // Led TX

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
            ST_GET_SPI_BYTE: begin
                wbm_address   = `SPI_BASE_ADDR;
                wbm_write     = 0;
                wbm_writedata = 0;
                wbm_cycle     = 1;
                wbm_strobe    = 1;
            end
            ST_WRITE_PIXEL: begin
                wbm_address   = pixel_addr;
                wbm_write     = 1;
                wbm_writedata = pixel_val;
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
    reg [23:0] pixel_val;
    reg [1:0] pixel_byte_cnt;
    reg all_pixel_bytes;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pixel_val       <= 0;
            pixel_byte_cnt  <= 0;
            all_pixel_bytes <= 0;

        end
        else if ((state == ST_GET_SPI_BYTE) & wbm_ack) begin
            case (pixel_byte_cnt)
                0: begin pixel_val[7:0]   <= wbm_readdata[7:0]; end
                1: begin pixel_val[15:8]  <= wbm_readdata[7:0]; end
                2: begin pixel_val[23:16] <= wbm_readdata[7:0]; end
                default: begin end
            endcase

            if (pixel_byte_cnt == 2) begin
                pixel_byte_cnt  <= 0;
                all_pixel_bytes <= 1;
            end
            else begin
                pixel_byte_cnt  <= pixel_byte_cnt + 1;
                all_pixel_bytes <= 0;
            end
        end
    end


    // Counters
    reg [ADDR_WIDTH-1:0] pixel_addr;
    reg [ADDR_WIDTH-1:0] pixel_cnt;
    wire last_pixel = (pixel_cnt == `IMG_WIDTH * `IMG_HEIGHT - 1);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pixel_addr <= 0;
            pixel_cnt  <= 0;
        end
        else if ((state == ST_ALLOC_BUF) & wbm_ack)  begin
            pixel_addr <= addr_for_buf_id(wbm_readdata);
            pixel_cnt  <= 0;
        end
        else if (state == ST_WRITE_PIXEL_DONE) begin
            pixel_addr <= pixel_addr + DATA_WIDTH/8;
            pixel_cnt  <= pixel_cnt + 1;
        end
    end


endmodule
