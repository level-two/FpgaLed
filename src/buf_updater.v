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

module buf_updater #(parameter ADDR_WIDTH = 16, parameter DATA_WIDTH = 32)
(
    input      reset,
    input      clk,

    // Wishbone master signals - for memory access
    output reg [ADDR_WIDTH-1:0] wbm_address,
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

    // simple rainbow effect

    // Basic colors
    // Format: GRB
    localparam NUM_COLORS = 7;
    localparam NUM_SEMICOLORS = 16;


    localparam ST_IDLE                  = 0;
    localparam ST_INIT                  = 1;
    localparam ST_GEN_NEXT_COLOR        = 2;
    localparam ST_SEND_COLOR            = 3;
    localparam ST_COLOR_SENT            = 4;
    localparam ST_DONE                  = 5;


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
                if (update_buf) next_state = ST_INIT;
            end
            ST_INIT: begin
                next_state = ST_SEND_COLOR;
            end
            ST_SEND_COLOR: begin
                if (wbm_ack) next_state = ST_COLOR_SENT;
            end
            ST_COLOR_SENT: begin
                if (leds_count == `LEDS_NUM) next_state = ST_DONE;
                else next_state = ST_GEN_NEXT_COLOR;
            end
            ST_GEN_NEXT_COLOR: begin
                next_state = ST_SEND_COLOR;
            end
            ST_DONE: begin
                if (~update_buf) next_state = ST_IDLE;
            end
            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end

    assign buf_updated = (state == ST_DONE);


    // Color generator
    wire initial_dir [0:2]         = {1'b1,  1'b1,  1'b0};
    wire [7:0] initial_color [0:2] = {8'h00, 8'h80, 8'hff};

    reg [7:0] first_color [0:2];
    reg first_dir[0:2];

    reg [7:0] color[0:2];
    reg dir[0:2];

    genvar i;
    generate
    for (i=0; i<3; i=i+1) begin : color_gen
        always @(posedge clk or posedge reset) begin
            if (reset) begin
                first_color[i] <= initial_color[i];
                first_dir[i]   <= initial_dir[i];
                color[i]       <= 0;
                dir[i]         <= 0;
            end
            else begin
                if (state == ST_INIT) begin
                    color[i] <= first_color[i];
                    dir[i] <= first_dir[i];

                    // update initial values
                    if (first_dir[i]) first_color[i] <= first_color[i] + 1;
                    else              first_color[i] <= first_color[i] - 1;

                    if (first_color[i] == 1)          first_dir[i] <= 1;
                    else if (first_color[i] == 8'hfe) first_dir[i] <= 0;
                end
                else if (state == ST_GEN_NEXT_COLOR) begin
                    if (dir[i]) color[i] <= color[i] + 1;
                    else        color[i] <= color[i] - 1;

                    if (color[i] == 1)          dir[i] <= 1;
                    else if (color[i] == 8'hfe) dir[i] <= 0;
                end
            end
        end
    end
    endgenerate


    // Wishbone master
    assign wbm_strobe    = (state == ST_SEND_COLOR);
    assign wbm_cycle     = (state == ST_SEND_COLOR);
    assign wbm_write     = 1;
    assign wbm_writedata = {color[2], color[1], color[0]};

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wbm_address <= 0;
        end
        else begin
            if (state == ST_INIT) begin
                wbm_address <= addr_for_buf_id(buf_id);
            end
            else if (state == ST_COLOR_SENT) begin
                wbm_address <= wbm_address + (DATA_WIDTH/8);
            end
        end
    end


    // LEDS counter
    reg [9:0] leds_count;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            leds_count <= 0;
        end
        else begin
            if (state == ST_INIT) begin
                leds_count <= 1;
            end
            else if (state == ST_COLOR_SENT) begin
                leds_count <= leds_count + 1;
            end
        end
    end
endmodule
