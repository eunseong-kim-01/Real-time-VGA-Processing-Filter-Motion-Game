
`timescale 1ns / 1ps

module ChromaKey (
    input  logic         clk,
    input  logic         reset,       
    input  logic [3:0]   i_red,
    input  logic [3:0]   i_green,
    input  logic [3:0]   i_blue,
    input  logic [9:0]   x_pixel,
    input  logic [9:0]   y_pixel,
    input  logic         DE,          
    output logic [3:0]   red_port,
    output logic [3:0]   green_port,
    output logic [3:0]   blue_port
);

    parameter logic [3:0] G_THRESHOLD    = 4'd10; // G component must be at least this value (0-15)
    parameter logic [3:0] DIFF_THRESHOLD = 4'd4;  // G must be at least this much greater than R and B
    
    logic [11:0] rgb;             // Input RGB 4:4:4
    logic [11:0] rgb_o;           // Output RGB 4:4:4
    logic [16:0] image_addr;      // Background image address (320*240 = 76800, needs 17 bits)
    logic [15:0] bg_image_data;   // 16-bit data read from BG ROM
    logic [11:0] bg_rgb;          // Background RGB 4:4:4
    logic DE_1;                   // Clipped Data Enable signal
    logic chroma_en;              // Global chroma key enable

    logic [3:0] r_in, g_in, b_in;
    logic is_chroma_key_pixel;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            chroma_en <= 1'b0;  
        else
            chroma_en <= 1'b1;  
    end

    assign rgb = {i_red, i_green, i_blue};

    assign bg_rgb = {
        bg_image_data[15:12], // Red from bit 15 down to 12
        bg_image_data[10:7],  // Green from bit 10 down to 7
        bg_image_data[4:1]    // Blue from bit 4 down to 1 (This seems unusual, check BG format)
    };
    
    assign r_in = i_red;
    assign g_in = i_green;
    assign b_in = i_blue;

    assign is_chroma_key_pixel = (g_in >= G_THRESHOLD) && 
                                 ((g_in - r_in) >= DIFF_THRESHOLD) && 
                                 ((g_in - b_in) >= DIFF_THRESHOLD);

    assign rgb_o = (chroma_en && is_chroma_key_pixel)
                  ? bg_rgb : rgb;

    assign image_addr = 320 * (239 - y_pixel) + x_pixel;

    assign DE_1 = (x_pixel < 640 && y_pixel <   480) ? DE : 1'b0;

    assign {red_port, green_port, blue_port} = DE_1 ? rgb_o : 12'b0;

    bg_image_rom U_BG_ROM (
        .clk(clk),
        .addr(image_addr),
        .data(bg_image_data)
    );

endmodule


module bg_image_rom (
    input  logic         clk,
    input  logic [16:0]  addr,
    output logic [15:0]  data
);
    // 320 * 240 = 76800 entries
    logic [15:0] rom[0:320*240-1]; 

    initial begin
        $readmemh("Background_1.mem", rom); 
        //$readmemh("Lenna_3.mem", rom); 
    end

    always_ff @(posedge clk) begin
        data <= rom[addr]; 
    end

endmodule