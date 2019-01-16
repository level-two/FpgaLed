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

module ctrl_logic_img #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32)
(
    input                   reset,
    input                   clk,

    // Master
    output [ADDR_WIDTH-1:0] wbm_address,
    output [DATA_WIDTH-1:0] wbm_writedata,
    input  [DATA_WIDTH-1:0] wbm_readdata,
    output                  wbm_strobe,
    output                  wbm_cycle,
    output                  wbm_write,
    input                   wbm_ack,
    
    // control signals
    input [DATA_WIDTH-1:0]  img_buf_id,
    input                   img_rcvd,

    // Signals from contorll logic
    output [DATA_WIDTH-1:0] display_image_buf_id,
    output                  display_image,
    input                   display_image_done
);

    `include "globals.vh"

    localparam ST_IDLE       = 0;
    localparam ST_REL_BUF    = 1;
    localparam ST_SET_BUF    = 2;


    reg [1:0] state, next_state;

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
                if (img_rcvd) begin
                    next_state = buf_valid ? ST_REL_BUF : ST_SET_BUF;
                end
            end
            ST_REL_BUF: begin
                if (wbm_ack) begin
                    next_state = ST_SET_BUF;
                end
            end
            ST_SET_BUF: begin
                next_state = ST_IDLE;
            end
            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end


    // store next buf id
    reg [DATA_WIDTH-1:0] next_buf_id;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            next_buf_id <= 0;
        end
        else if (img_rcvd) begin
            next_buf_id <= img_buf_id;
        end
    end


    // buf id and buf update
    reg [DATA_WIDTH-1:0] cur_buf_id;
    reg buf_valid;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cur_buf_id <= 0;
            buf_valid <= 0; 
        end
        else if (state == ST_SET_BUF) begin
            cur_buf_id <= next_buf_id;
            buf_valid <= 1; 
        end
    end

    // Display image
    assign display_image_buf_id = cur_buf_id;
    assign display_image = buf_valid & frame_timer_fired;

    // Wishbone signals
    assign wbm_address   = `BUF_MANAGER_BASE_ADDR;
    assign wbm_write     = 1;
    assign wbm_writedata = cur_buf_id; // buf_id for release
    assign wbm_cycle     = buf_valid & (state == ST_REL_BUF);
    assign wbm_strobe    = buf_valid & (state == ST_REL_BUF);
    

    // Delay timer
    reg [DATA_WIDTH-1:0] frame_timer;
    wire frame_timer_fired = (frame_timer == `FRAME_TIME);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            frame_timer <= 0;
        end
        else if (frame_timer_fired) begin
            frame_timer <= 0;
        end
        else begin
            frame_timer <= frame_timer + 1;
        end
    end

endmodule
