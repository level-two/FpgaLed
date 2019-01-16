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

module ctrl_logic #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32)
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
    output [DATA_WIDTH-1:0] update_buf_id,
    output                  update_buf,
    input                   buf_updated,

    // Signals from contorll logic
    output [DATA_WIDTH-1:0] image_buf_id,
    output                  display_image,
    input                   display_image_done
);

    `include "globals.vh"

    localparam LED_SEND_DLY  = 10000000; 
    localparam INIT_DLY      = 100; 

    localparam ST_IDLE       = 0;
    localparam ST_INIT       = 1;
    localparam ST_ALLOC_B1   = 2;
    localparam ST_UPD_B1     = 3;

    localparam ST_ALLOC_B2   = 4;
    localparam ST_DISP1_UPD2 = 5;
    localparam ST_DELAY      = 6;
    localparam ST_RELEASE_B1 = 7;
    localparam ST_LD_B1_B2   = 8;


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
                next_state = ST_INIT;
            end
            ST_INIT: begin
                if (delay_done) begin
                    next_state = ST_ALLOC_B1;
                end
            end
            ST_ALLOC_B1: begin
                if (wbm_ack) begin
                    next_state = ST_UPD_B1;
                end
            end
            ST_UPD_B1: begin
                if (buf_updated) begin
                    next_state = ST_ALLOC_B2;
                end
            end
            ST_ALLOC_B2: begin
                if (wbm_ack) begin
                    next_state = ST_DISP1_UPD2;
                end
            end
            ST_DISP1_UPD2: begin
                if (display_image_done) begin
                    next_state = ST_DELAY;
                end
            end
            ST_DELAY: begin
                if (delay_done) begin
                    next_state = ST_RELEASE_B1;
                end
            end
            ST_RELEASE_B1: begin
                if (wbm_ack) begin
                    next_state = ST_LD_B1_B2;
                end
            end
            ST_LD_B1_B2: begin
                next_state = ST_ALLOC_B2;
            end
            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end

    // buf id and buf update
    reg [DATA_WIDTH-1:0] buf_id_1;
    reg [DATA_WIDTH-1:0] buf_id_2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            buf_id_1 <= 0;
            buf_id_2 <= 0;
        end
        else begin
            if (state == ST_ALLOC_B1 && wbm_ack) begin
                buf_id_1 <= wbm_readdata;
            end
            else if (state == ST_ALLOC_B2 && wbm_ack) begin
                buf_id_2 <= wbm_readdata;
            end
            else if (state == ST_LD_B1_B2) begin
                buf_id_1 <= buf_id_2;
            end
        end
    end

    assign update_buf    = (state == ST_UPD_B1) | (state == ST_DISP1_UPD2);
    assign update_buf_id = (state == ST_UPD_B1) ? buf_id_1 : buf_id_2;

    // Display image
    assign image_buf_id  = buf_id_1;
    assign display_image = (state == ST_DISP1_UPD2);

    // Wishbone signals
    assign wbm_address   = `BUF_MANAGER_BASE_ADDR;
    assign wbm_write     = (state == ST_RELEASE_B1);
    assign wbm_writedata = buf_id_1; // buf_id for release
    assign wbm_cycle     = (state == ST_ALLOC_B1) | (state == ST_ALLOC_B2) | (state == ST_RELEASE_B1);
    assign wbm_strobe    = (state == ST_ALLOC_B1) | (state == ST_ALLOC_B2) | (state == ST_RELEASE_B1);
    

    // Delay timer
    reg [DATA_WIDTH-1:0] dly_timer;
    wire delay_done = ((state == ST_DELAY) & (dly_timer == LED_SEND_DLY)) |
                      ((state == ST_INIT)  & (dly_timer == INIT_DLY));

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dly_timer <= 0;
        end
        else begin
            if ((state == ST_INIT) | (state == ST_DELAY)) begin
                dly_timer <= dly_timer + 1;
            end
            else begin
                dly_timer <= 0;
            end
        end
    end

endmodule
