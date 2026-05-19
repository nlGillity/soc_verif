module i2c_slave (
    input wire clk,                // Системный тактовый сигнал
    input wire rst_n,              // Сброс (активный низкий)
    input wire scl_io,             // Линия SCL
    inout wire sda_io              // Линия SDA
);

    // Параметры устройства
    parameter SLAVE_ADDR = 7'h34;  // Адрес I2C слейва
    parameter MEMORY_DEPTH = 4;  // Количество ячеек памяти
    parameter [MEMORY_DEPTH-1:0][7:0] DEFAULT_MEMORY[2] = '{'{8'hCA,8'hFE,8'hCA,8'hFE}, '{8'hDE,8'hAD,8'hBE,8'hEF}};

    // Режим работы SDA (1 – вход, 0 – выход)
    reg sda_dir;
    assign sda_io = (sda_dir == 1'b0) ? sda_out : 1'bz;

    // Внутренние сигналы
    reg sda_out;
    reg [MEMORY_DEPTH-1:0][7:0] memory [0:1]; // Память слейва
    reg [7:0] addr_reg;                  // Регистр адреса
    reg [3:0] bit_cnt;                   // Счетчик бит
    reg [3:0] mem_cnt;
    reg [2:0] state;                     // Состояние автомата
    reg [1:0] message_state;
    reg stop;

    // Состояния автомата
    localparam IDLE           = 3'd0; // Ожидание стартового сигнала
    localparam SLAVE_ADDRESS  = 3'd1; // Принятие адреса
    localparam REGISTER       = 3'd2; // Прием адреса/регистра
    localparam SEND_DATA      = 3'd3; // Передача или прием данных
    localparam STOP           = 3'd4; // Завершение передачи
    localparam SEND_END       = 3'd5;

    // DETECT low->high FOR STOP CMD
    reg [3:0] stop_clk = 0;
    reg [1:0] prev_sda = 0;
    reg [1:0] was_scl = 0;
    always @(posedge clk) begin
        if (stop == 1) begin
            if (sda_io == 0) begin
                stop <= 0;
                state <= IDLE;
            end
        end else begin 
            if (stop_clk < 6) begin
                stop_clk <= stop_clk + 1;
                if (prev_sda == 0 && was_scl && sda_io == 1 && scl_io == 1) begin
                    stop <= 1;
                end else begin 
                    stop <= 0;
                end
            end else begin
                was_scl  <= scl_io;
                prev_sda <= sda_io;
                stop_clk <= 0;
            end
        end
    end

    always @(posedge scl_io or negedge rst_n) begin
        if (!rst_n) begin
            // Сброс всех регистров
            sda_out <= 1'b1;
            sda_dir <= 1'b1; // SDA изначально вход
            addr_reg <= 8'd0;
            bit_cnt <= 4'd0;
            mem_cnt <= 4'd0;
            state <= IDLE;

            // Инициализация памяти
            for (int j = 0; j < 2; j++) begin
                for (int i = 0; i < MEMORY_DEPTH; i++) begin
                    memory[j][i] <= DEFAULT_MEMORY[j][i];
                end
            end
        end else begin
            case (state)
                IDLE: begin
                    if (scl_io && !sda_io && stop == 0) begin
                            bit_cnt <= 4'd0;
                            mem_cnt <= 4'd0;
                            addr_reg <= 0;
                            sda_dir <= 1;
                            state <= SLAVE_ADDRESS;
                    end
                end

                SLAVE_ADDRESS: begin
                    if (bit_cnt < 7) begin
                        addr_reg[6-bit_cnt] <= sda_io; // Чтение адреса по битам
                        bit_cnt <= bit_cnt + 1;
                    end else if (bit_cnt == 7) begin
                        if (addr_reg == SLAVE_ADDR) begin
                            state <= REGISTER;
                        end else if (addr_reg == (SLAVE_ADDR | 1'b1)) begin
                            state <= SEND_DATA;
                        end else begin
                            state <= STOP;
                        end
                        bit_cnt <= 4'd0;
                    end
                end

                REGISTER: begin
                    if (bit_cnt < 8) begin
                        addr_reg[7-bit_cnt] <= sda_io; // Чтение адреса по битам
                        bit_cnt <= bit_cnt + 1;
                    end else begin
                        bit_cnt <= 0;
                        message_state <= addr_reg;
                        state <= IDLE;
                    end
                end

                SEND_DATA: begin
                    sda_dir <= 0;
                    if (bit_cnt < 8 && mem_cnt < MEMORY_DEPTH) begin
                        sda_out <= memory[message_state][3-mem_cnt][7-bit_cnt];
                        bit_cnt <= bit_cnt + 1;
                    end else if (mem_cnt < MEMORY_DEPTH) begin
                        bit_cnt <= 0;
                        mem_cnt <= mem_cnt + 1;
                    end else begin
                        bit_cnt <= 0;
                        mem_cnt <= 0;
                        sda_out <= 0;
                        state <= SEND_END;
                    end
                end

                SEND_END: begin
                    sda_dir <= 0;
                    if (bit_cnt < 8) begin
                        sda_out <= 0;
                        bit_cnt <= bit_cnt + 1;
                    end else begin
                        sda_dir <= 1;
                        state <= IDLE;
                    end
                end
                

                STOP: begin
                    if (scl_io && sda_io) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule