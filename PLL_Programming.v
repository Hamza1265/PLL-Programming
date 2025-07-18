module Design (
    input wire clk,
    input wire rst,
    input wire trigger,
    output reg busy,
    output reg le,
    output reg clk_out,
    output reg mosi,
    output reg ss,
    output reg [15:0] outt             // 16-bit output to pins
);

    // PLL internal
    reg [5:0] bit_cnt;
    reg [31:0] shift_reg;
    reg [2:0] state;
    reg [31:0] reg_array [0:5];
    reg [2:0] index;
    reg [2:0] write_count;
    reg reg1;
    

  

    localparam IDLE = 0, LOAD = 1, SHIFT = 2, PULSE = 3, DONE = 4;


    // ===========================
    // Main FSM for PLL control
    // ===========================
    always @(posedge clk) begin
        if (rst) begin
            le <= 0;
            busy <= 0;
            ss <= 1;
            mosi <= 0;
            write_count <= 0;
            state <= IDLE;
            index <= 0;
            reg1 <= 1;

            reg_array[5] <= 32'h580005;
            reg_array[4] <= 32'h9C803C;
            reg_array[3] <= 32'h00004B3;
            reg_array[2] <= 32'h19008E42;
            reg_array[1] <= 32'h8008011;
            reg_array[0] <= 32'h000000;
        end else begin
            case (state)
                IDLE: begin
                    le <= 0;
                    busy <= 0;
                    if (trigger && (write_count < 6)) begin
                        index <= 5;
                        busy <= 1;
                        ss <= 0;
                        state <= LOAD;
                    end 
                    else if (write_count >= 6) begin
                        reg1 <= 1;
                        end
                end

                LOAD: begin
                    state <= SHIFT;
                end

                SHIFT: begin
                    mosi <= shift_reg[31];
                    if (bit_cnt == 0 && clk_out == 0) begin
                        state <= PULSE;
                    end
                end

                PULSE: begin
                    le <= 1;
                    ss <= 1;
                    busy <= 0;
                    state <= DONE;
                end

                DONE: begin
                    le <= 0;
                    write_count <= write_count + 1;
                    if (index == 0) begin
                        state <= IDLE;
                    end else begin
                        index <= index - 1;
                        busy <= 1;
                        ss <= 0;
                        state <= LOAD;
                    end
                end
            endcase
        end
    end

    // Shift logic on negedge
    always @(negedge clk) begin
        if (rst) begin
            clk_out <= 0;
            shift_reg <= 0;
            bit_cnt <= 0;
        end else begin
            case (state)
                LOAD: begin
                    shift_reg <= reg_array[index];
                    bit_cnt <= 32;
                    clk_out <= 0;
                end

                SHIFT: begin
                    clk_out <= ~clk_out;
                    if (clk_out == 1) begin
                        shift_reg <= {shift_reg[30:0], 1'b0};
                        if (bit_cnt > 0)
                            bit_cnt <= bit_cnt - 1;
                    end
                end

                default: begin
                    clk_out <= 0;
                end
            endcase
        end
    end

