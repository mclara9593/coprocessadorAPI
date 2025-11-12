module processo_imagem (
    input  wire [9:2] SW,
    input wire [9:0] bits,          // bits[9]=flag, bits[7:0]=data
    input  wire clk_50,

    output wire hsync,
    output wire vsync,
    output wire [7:0] red,
    output wire [7:0] green,
    output wire [7:0] blue,
    output wire sync,
    output wire clk,
    output wire blank,
    output wire flag_out            // Sinal de resposta para o HPS
);

    reg clk_25_reg = 0;
    
    always @(posedge clk_50) begin
        clk_25_reg <= ~clk_25_reg;
    end
    
    // --- Lógica de Reset ---
    reg [7:0] sw_prev = 0;         
    reg       auto_reset_flag = 0; 
    reg [3:0] reset_counter = 0;   
    
    wire sw_changed = (sw_prev != SW[8:2]);
    
    always @(posedge clk_25_reg) begin
        sw_prev <= SW[8:2]; 
        
        if (sw_changed) begin
            auto_reset_flag <= 1'b1;     
            reset_counter <= 4'd15;      
        end else if (reset_counter > 0) begin
            reset_counter <= reset_counter - 1;
            if (reset_counter == 1)
                auto_reset_flag <= 1'b0; 
        end
    end
    
    // <-- ALTERAÇÃO 1: Criação de dois tipos de reset ---
    // 'general_reset' apaga a imagem da memória (usado apenas pela FSM do HPS)
    wire general_reset = SW[9]; 
    // 'processing_reset' reinicia o processamento, mas mantém a imagem carregada
    wire processing_reset = SW[9] || auto_reset_flag; 
    
    // --- PLL ---
    wire clock_100; 
    wire locked; 
    pll100_0002 pll100_inst (
        .refclk   (clk_50),    
        .rst      (1'b0),
        .outclk_0 (clock_100), 
        .locked   (locked)     
    );

    // --- Sinais VGA ---
    wire [10:0] next_x;
    wire [10:0] next_y;
    reg [10:0] x_delayed;
    reg [10:0] y_delayed;

    always @(posedge clk_25_reg) begin
        x_delayed <= next_x;
        y_delayed <= next_y;
    end
    
    // --- Constantes ---
    localparam IMG_WIDTH_PEQ8  = 20;
    localparam IMG_HEIGHT_PEQ8 = 15;
    localparam IMG_WIDTH_PEQ4  = 40;
    localparam IMG_HEIGHT_PEQ4 = 30;
    localparam IMG_WIDTH_PEQ   = 80;
    localparam IMG_HEIGHT_PEQ  = 60;
    localparam IMG_WIDTH_OR    = 160;
    localparam IMG_HEIGHT_OR   = 120;
    localparam IMG_WIDTH_GRA   = 320;
    localparam IMG_HEIGHT_GRA  = 240;      
    localparam IMG_WIDTH_GRA4  = 640;
    localparam IMG_HEIGHT_GRA4 = 480;
    localparam IMG_TOTAL_PIXELS_OR = IMG_WIDTH_OR * IMG_HEIGHT_OR;

    // --- Decodificação dos sinais do HPS ---
    wire flag_in = bits[9];
    wire [7:0] data_in = bits[7:0];

    // --- Sinais Coprocessador ---
    wire        processing_done;
    wire        coproc_pixel_in_ready;
    
    wire modo_processamento_ativo = (SW[5:2] != 4'b0000);

    //================================================================
    // --- MÁQUINA DE ESTADOS PARA RECEPÇÃO DE IMAGEM DO HPS ---
    //================================================================
    localparam IDLE     = 2'b00;
    localparam WRITE    = 2'b01;
    localparam RESPONSE = 2'b10;

    reg [1:0]  hps_state = IDLE;
    reg [18:0] hps_write_addr = 0;
    reg        hps_write_enable = 0;
    reg        flag_out_reg = 0;
    reg        image_loaded = 0;

    assign flag_out = flag_out_reg;

    // <-- ALTERAÇÃO 2: Este bloco agora usa 'general_reset' ---
    // Isso garante que 'image_loaded' só seja zerado pelo SW[9], e não pela troca de algoritmo.
    always @(posedge clk_25_reg or posedge general_reset) begin
        if (general_reset) begin
            hps_state        <= IDLE;
            hps_write_addr   <= 0;
            hps_write_enable <= 0;
            flag_out_reg     <= 0;
            image_loaded     <= 0; // A imagem é "esquecida" apenas no reset geral
        end else begin
            case (hps_state)
                IDLE: begin
                    hps_write_enable <= 0;
                    flag_out_reg <= 0;
                    
                    if (flag_in && !image_loaded) begin
                        hps_state <= WRITE;
                    end
                end

                WRITE: begin
                    hps_write_enable <= 1;
                    hps_write_addr <= hps_write_addr + 1;
                    hps_state <= RESPONSE;
                    
                    if (hps_write_addr >= (IMG_TOTAL_PIXELS_OR - 1)) begin
                        image_loaded <= 1;
                    end
                end

                RESPONSE: begin
                    hps_write_enable <= 0;
                    flag_out_reg <= 1;
                    
                    if (!flag_in) begin
                        hps_state <= IDLE;
                    end
                end

                default: hps_state <= IDLE;
            endcase
        end
    end

    // --- Contador de Leitura da ROM (para coprocessador) ---
    reg [18:0] rom_addr_counter = 0;
    // <-- ALTERAÇÃO 3: Usando 'processing_reset' para reiniciar a contagem ---
    always @(posedge clk_25_reg or posedge processing_reset) begin
        if (processing_reset) begin
            rom_addr_counter <= 0;
        end else if (modo_processamento_ativo && !processing_done && rom_addr_counter < IMG_TOTAL_PIXELS_OR && coproc_pixel_in_ready) begin
            rom_addr_counter <= rom_addr_counter + 1;
        end
    end

    // --- Lógica de Endereçamento VGA ---
    reg [18:0] ram_address_read;
    wire dentro_img_peq = (x_delayed < IMG_WIDTH_PEQ) && (y_delayed < IMG_HEIGHT_PEQ);
    wire [18:0] ram_addr_peq = dentro_img_peq ? (y_delayed * IMG_WIDTH_PEQ + x_delayed) : 19'd0;
    wire dentro_img_peq4 = (x_delayed < IMG_WIDTH_PEQ4) && (y_delayed < IMG_HEIGHT_PEQ4);
    wire [18:0] ram_addr_peq4 = dentro_img_peq4 ? (y_delayed * IMG_WIDTH_PEQ4 + x_delayed) : 19'd0;
    wire dentro_img_peq8 = (x_delayed < IMG_WIDTH_PEQ8) && (y_delayed < IMG_HEIGHT_PEQ8);
    wire [18:0] ram_addr_peq8 = dentro_img_peq8 ? (y_delayed * IMG_WIDTH_PEQ8 + x_delayed) : 19'd0;
    wire dentro_img_or_display = (x_delayed < IMG_WIDTH_OR) && (y_delayed < IMG_HEIGHT_OR);
    wire [18:0] ram_addr_or = dentro_img_or_display ? (y_delayed * IMG_WIDTH_OR + x_delayed) : 19'd0;
    wire dentro_img_gra = (x_delayed < IMG_WIDTH_GRA) && (y_delayed < IMG_HEIGHT_GRA);
    wire [18:0] ram_addr_gra = dentro_img_gra ? (y_delayed * IMG_WIDTH_GRA + x_delayed) : 19'd0;
    wire dentro_img_gra4 = (x_delayed < IMG_WIDTH_GRA4) && (y_delayed < IMG_HEIGHT_GRA4);
    wire [18:0] ram_addr_gra4 = dentro_img_gra4 ? (y_delayed * IMG_WIDTH_GRA4 + x_delayed) : 19'd0;
    
    always @(*) begin
        ram_address_read = ram_addr_or; 
    
        case (SW[8:7]) 
            2'b01: begin 
                case (SW[5:2])
                    4'b0001:  ram_address_read = ram_addr_gra4;
                    default:  ram_address_read = ram_addr_or;
                endcase
            end
            
            2'b10: begin 
                case (SW[5:2])
                    4'b0001:  ram_address_read = ram_addr_gra4; 
                    default:  ram_address_read = ram_addr_or;
                endcase
            end
            
            default: begin 
                case (SW[5:2])
                    4'b0001, 4'b0010:  ram_address_read = ram_addr_gra;
                    4'b0100, 4'b1000:  ram_address_read = ram_addr_peq;
                    default:           ram_address_read = ram_addr_or;
                endcase
            end
        endcase
    end
    
    // --- Lógica de Seleção de Fonte de Dados ---
    wire [7:0] saida_rom;
    wire [18:0] address_rom;
    wire [7:0]  entrada_vga;
    reg  process_done_latch = 0;

    assign address_rom = modo_processamento_ativo ? rom_addr_counter : ram_addr_or;
    assign entrada_vga = (modo_processamento_ativo && process_done_latch) ? ram_q : saida_rom;
    
    // --- Instância da ROM ---
    wire [18:0] rom_final_address = hps_write_enable ? hps_write_addr : address_rom;
    wire        rom_write_enable = hps_write_enable;
    
    imagem rom_inst_OR (
        .address(rom_final_address),
        .clock(clock_100),
        .data(data_in),
        .wren(rom_write_enable),
        .q(saida_rom)
    );

    // --- Instância do Coprocessador ---
    wire [7:0] pixel_coproc_out;
    wire       pixel_coproc_valid;
    
    wire coproc_start_signal = modo_processamento_ativo && !process_done_latch && image_loaded; 
    
    coprocessador coprocessador_inst (
        .clk(clk_25_reg), 
        .resetn(~processing_reset), // <-- ALTERAÇÃO 4: Coprocessador reinicia com o processamento
        .start(coproc_start_signal),
        .largura_in(IMG_WIDTH_OR),
        .altura_in(IMG_HEIGHT_OR), 
        .SW(SW[5:2]), 
        .escala(SW[8:7]),
        .pixel_in(saida_rom),
        .pixel_out(pixel_coproc_out), 
        .pixel_out_valid(pixel_coproc_valid),
        .processing_done(processing_done), 
        .pixel_in_ready(coproc_pixel_in_ready)
    );

    // --- Controle da RAM de Saída ---
    reg  [18:0] pixel_write_count = 0;
    
    // <-- ALTERAÇÃO 5: Usando 'processing_reset' para reiniciar a lógica da RAM de saída ---
    always @(posedge clk_25_reg or posedge processing_reset) begin
        if (processing_reset) begin
            pixel_write_count  <= 0;
            process_done_latch <= 0;
        end else begin
            if (pixel_coproc_valid && !process_done_latch) begin
                pixel_write_count <= pixel_write_count + 1;
            end
            if (processing_done) begin
                process_done_latch <= 1'b1; 
            end
        end
    end

    wire [18:0] ram_address_write = pixel_write_count;
    wire [18:0] ram_address = process_done_latch ? ram_address_read : ram_address_write; 
    wire        escrita     = pixel_coproc_valid && !process_done_latch; 
    wire [7:0]  ram_q;
    
    // --- Instância da RAM ---
    ram_pri ram_inst (
        .address(ram_address),
        .clock(clock_100),
        .data(pixel_coproc_out),   
        .wren(escrita), 
        .q(ram_q)
    );

    // --- Instância do VGA ---
    vga_module vga_inst (
        .clock(clk_25_reg), 
        .reset(processing_reset), // <-- ALTERAÇÃO 6: VGA também usa o reset de processamento
        .color_in(entrada_vga),
        .next_x(next_x),
        .next_y(next_y), 
        .hsync(hsync), 
        .vsync(vsync), 
        .red(red), 
        .green(green),
        .blue(blue), 
        .sync(sync), 
        .clk(clk), 
        .blank(blank)
    );

endmodule