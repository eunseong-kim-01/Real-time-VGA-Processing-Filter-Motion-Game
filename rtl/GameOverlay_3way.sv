// `timescale 1ns / 1ps

// module GameOverlay_4way (
//     input logic       DE,    // Data Enable signal for VGA
//     input logic [9:0] x,     // Current pixel X coordinate
//     input logic [9:0] y,     // Current pixel Y coordinate

//     // FSM State Input
//     input logic [2:0] fsm_state,
    
//     // Game Data Inputs
//     input logic [1:0] region,       // 0:LT, 1:RT, 2:LB, 3:RB
//     input logic [1:0] result_type,  // 0:None, 1:Success, 2:Fail
//     input logic [2:0] round_cnt,    // Current round number
//     input logic [4:0] round_result, // Bitmask results
//     input logic [2:0] score,        // Total score count

//     // Final VGA RGB Output
//     output logic [3:0] r,
//     output logic [3:0] g,
//     output logic [3:0] b,
//     output logic overlay_en // '1' if overlay is active
// );

//     //==========================================================
//     // 🎨 Arcade Neon Color Palette
//     //==========================================================
//     localparam [3:0] C_BLACK        = 4'h0;
//     localparam [3:0] C_WHITE        = 4'hF; 
//     localparam [3:0] C_NEON_RED     = 4'hF; 
//     localparam [3:0] C_NEON_GREEN   = 4'hE; 
//     localparam [3:0] C_NEON_BLUE    = 4'hF; 
//     localparam [3:0] C_NEON_YELLOW  = 4'hE; 
//     localparam [3:0] C_NEON_CYAN    = 4'hD; 
//     localparam [3:0] C_NEON_MAGENTA = 4'hD; 
    
//     localparam [3:0] C_DARK_BG      = 4'h1; 
//     localparam [3:0] C_HUD_BG       = 4'h0; 

//     //==========================================================
//     // 🔤 8x8 Bitmap Font Definition
//     //==========================================================
//     function automatic [7:0] font_row(input [7:0] ascii, input [2:0] row);
//         unique case (ascii)
//             // --- Numbers ---
//             "0": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "1": case(row) 0:return 8'h10; 1:return 8'h30; 2:return 8'h10; 3:return 8'h10; 4:return 8'h10; 5:return 8'h10; 6:return 8'h38; default:return 0; endcase
//             "2": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h02; 3:return 8'h0C; 4:return 8'h30; 5:return 8'h40; 6:return 8'h7E; default:return 0; endcase
//             "3": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h02; 3:return 8'h1C; 4:return 8'h02; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "4": case(row) 0:return 8'h0C; 1:return 8'h14; 2:return 8'h24; 3:return 8'h44; 4:return 8'h7E; 5:return 8'h04; 6:return 8'h04; default:return 0; endcase
//             "5": case(row) 0:return 8'h7E; 1:return 8'h40; 2:return 8'h7C; 3:return 8'h02; 4:return 8'h02; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "6": case(row) 0:return 8'h3C; 1:return 8'h40; 2:return 8'h7C; 3:return 8'h42; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "8": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h3C; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
            
//             // --- Alphabets ---
//             "A": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7E; 4:return 8'h42; 5:return 8'h42; 6:return 8'h42; default:return 0; endcase
//             "B": case(row) 0:return 8'h7C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7C; 4:return 8'h42; 5:return 8'h42; 6:return 8'h7C; default:return 0; endcase
//             "C": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h40; 3:return 8'h40; 4:return 8'h40; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "D": case(row) 0:return 8'h78; 1:return 8'h44; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h44; 6:return 8'h78; default:return 0; endcase
//             "E": case(row) 0:return 8'h7E; 1:return 8'h40; 2:return 8'h40; 3:return 8'h7C; 4:return 8'h40; 5:return 8'h40; 6:return 8'h7E; default:return 0; endcase
//             "F": case(row) 0:return 8'h7E; 1:return 8'h40; 2:return 8'h40; 3:return 8'h7C; 4:return 8'h40; 5:return 8'h40; 6:return 8'h40; default:return 0; endcase
//             "G": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h40; 3:return 8'h4E; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "H": case(row) 0:return 8'h42; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7E; 4:return 8'h42; 5:return 8'h42; 6:return 8'h42; default:return 0; endcase
//             "I": case(row) 0:return 8'h7E; 1:return 8'h18; 2:return 8'h18; 3:return 8'h18; 4:return 8'h18; 5:return 8'h18; 6:return 8'h7E; default:return 0; endcase
//             "L": case(row) 0:return 8'h40; 1:return 8'h40; 2:return 8'h40; 3:return 8'h40; 4:return 8'h40; 5:return 8'h40; 6:return 8'h7E; default:return 0; endcase
//             "M": case(row) 0:return 8'hC3; 1:return 8'hA5; 2:return 8'h99; 3:return 8'h99; 4:return 8'h81; 5:return 8'h81; 6:return 8'h81; default:return 0; endcase
//             "N": case(row) 0:return 8'h42; 1:return 8'h62; 2:return 8'h52; 3:return 8'h4A; 4:return 8'h46; 5:return 8'h42; 6:return 8'h42; default:return 0; endcase
//             "O": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "P": case(row) 0:return 8'h7C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7C; 4:return 8'h40; 5:return 8'h40; 6:return 8'h40; default:return 0; endcase
//             "R": case(row) 0:return 8'h7C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7C; 4:return 8'h50; 5:return 8'h48; 6:return 8'h44; default:return 0; endcase
//             "S": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h40; 3:return 8'h3C; 4:return 8'h02; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "T": case(row) 0:return 8'h7E; 1:return 8'h18; 2:return 8'h18; 3:return 8'h18; 4:return 8'h18; 5:return 8'h18; 6:return 8'h18; default:return 0; endcase
//             "U": case(row) 0:return 8'h42; 1:return 8'h42; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "V": case(row) 0:return 8'h42; 1:return 8'h42; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h24; 6:return 8'h18; default:return 0; endcase
//             "W": case(row) 0:return 8'h81; 1:return 8'h81; 2:return 8'h81; 3:return 8'h99; 4:return 8'h99; 5:return 8'hA5; 6:return 8'hC3; default:return 0; endcase
//             "Y": case(row) 0:return 8'h42; 1:return 8'h42; 2:return 8'h42; 3:return 8'h3C; 4:return 8'h18; 5:return 8'h18; 6:return 8'h18; default:return 0; endcase
            
//             // --- Symbols ---
//             "?": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h02; 3:return 8'h1C; 4:return 8'h10; 5:return 8'h00; 6:return 8'h10; default:return 0; endcase
//             ":": case(row) 0:return 0;    1:return 8'h18; 2:return 8'h18; 3:return 0;    4:return 8'h18; 5:return 8'h18; 6:return 0;    default:return 0; endcase
//             "/": case(row) 0:return 8'h02; 1:return 8'h04; 2:return 8'h08; 3:return 8'h10; 4:return 8'h20; 5:return 8'h40; 6:return 8'h80; default:return 0; endcase
//             "!": case(row) 0:return 8'h18; 1:return 8'h18; 2:return 8'h18; 3:return 8'h18; 4:return 8'h00; 5:return 8'h00; 6:return 8'h18; default:return 0; endcase
//             "'": case(row) 0:return 8'h18; 1:return 8'h18; 2:return 8'h10; 3:return 0;    4:return 0;    5:return 0;    6:return 0;    default:return 0; endcase

//             default: font_row = 8'h00;
//         endcase
//     endfunction

//     //==========================================================
//     // 🛠️ Graphic Helper Functions
//     //==========================================================
//     function automatic logic in_rect(input [9:0] l, r, t, b);
//         in_rect = (x >= l && x < r && y >= t && y < b);
//     endfunction

//     function automatic logic on_border_thick(input [9:0] l, r, t, b, input [3:0] thickness);
//         logic outer, inner;
//         outer = (x >= l && x < r && y >= t && y < b);
//         inner = (x >= l+thickness && x < r-thickness && y >= t+thickness && y < b-thickness);
//         on_border_thick = outer && !inner;
//     endfunction

//     function automatic logic draw_char(input [7:0] ascii, input [9:0] px, input [9:0] py);
//         logic [7:0] row_bits;
//         if (x >= px && x < px + 8 && y >= py && y < py + 8) begin
//             row_bits  = font_row(ascii, y - py);
//             draw_char = row_bits[7-(x-px)];
//         end else begin
//             draw_char = 1'b0;
//         end
//     endfunction

//     //==========================================================
//     // 📝 String Helper Functions
//     //==========================================================
    
//     // "LET'S PLAY GAME" (Moved to Y=20 for Top HUD)
//     function automatic logic draw_str_LETS_PLAY_HUD();
//         logic h; h=0;
//         // Center X ~ 260, Y fixed at 20 (inside 50px top bar)
//         h |= draw_char("L", 260, 20); h |= draw_char("E", 268, 20); h |= draw_char("T", 276, 20); 
//         h |= draw_char("'", 284, 20); h |= draw_char("S", 292, 20);
        
//         /* Space */
        
//         h |= draw_char("P", 308, 20); h |= draw_char("L", 316, 20); h |= draw_char("A", 324, 20); h |= draw_char("Y", 332, 20);
        
//         /* Space */
        
//         h |= draw_char("G", 348, 20); h |= draw_char("A", 356, 20); h |= draw_char("M", 364, 20); h |= draw_char("E", 372, 20);
//         return h;
//     endfunction

//     // "GET READY!" (Center Screen)
//     function automatic logic draw_str_GET_READY();
//         logic h; h=0;
//         h |= draw_char("G", 280, 236); h |= draw_char("E", 288, 236); h |= draw_char("T", 296, 236);
//         h |= draw_char("R", 312, 236); h |= draw_char("E", 320, 236); h |= draw_char("A", 328, 236);
//         h |= draw_char("D", 336, 236); h |= draw_char("Y", 344, 236); h |= draw_char("!", 352, 236);
//         return h;
//     endfunction

//     // "ROUND: X / 5" (Top Left in HUD)
//     function automatic logic draw_hud_round(input [2:0] rnd);
//         logic h; h=0;
//         h |= draw_char("R", 20, 16); h |= draw_char("O", 28, 16); h |= draw_char("U", 36, 16);
//         h |= draw_char("N", 44, 16); h |= draw_char("D", 52, 16); h |= draw_char(":", 60, 16);
//         case(rnd)
//             0: h |= draw_char("1", 76, 16); 1: h |= draw_char("2", 76, 16); 2: h |= draw_char("3", 76, 16);
//             3: h |= draw_char("4", 76, 16); 4: h |= draw_char("5", 76, 16); default: h |= draw_char("?", 76, 16);
//         endcase
//         h |= draw_char("/", 92, 16); h |= draw_char("5", 108, 16);
//         return h;
//     endfunction

//     // "TOTAL SCORE: XXX" (Top Right in HUD)
//     function automatic logic draw_hud_score(input [2:0] sc);
//         logic h; h=0;
//         h |= draw_char("T", 450, 16); h |= draw_char("O", 458, 16); h |= draw_char("T", 466, 16);
//         h |= draw_char("A", 474, 16); h |= draw_char("L", 482, 16); 
//         h |= draw_char("S", 498, 16); h |= draw_char("C", 506, 16); h |= draw_char("O", 514, 16);
//         h |= draw_char("R", 522, 16); h |= draw_char("E", 530, 16); h |= draw_char(":", 538, 16);
        
//         unique case(sc)
//             3'd0: begin h |= draw_char("0", 562, 16); h |= draw_char("0", 570, 16); end
//             3'd1: begin h |= draw_char("2", 562, 16); h |= draw_char("0", 570, 16); end
//             3'd2: begin h |= draw_char("4", 562, 16); h |= draw_char("0", 570, 16); end
//             3'd3: begin h |= draw_char("6", 562, 16); h |= draw_char("0", 570, 16); end
//             3'd4: begin h |= draw_char("8", 562, 16); h |= draw_char("0", 570, 16); end
//             3'd5: begin h |= draw_char("1", 554, 16); h |= draw_char("0", 562, 16); h |= draw_char("0", 570, 16); end
//             default: begin h |= draw_char("0", 562, 16); h |= draw_char("0", 570, 16); end
//         endcase
//         return h;
//     endfunction

//     // Instructions
//     function automatic logic draw_instruction_full(input [1:0] region_idx);
//         logic h; h=0;
//         unique case (region_idx)
//             2'd0: begin h |= draw_char("L", 288, 236); h |= draw_char("E", 296, 236); h |= draw_char("F", 304, 236); h |= draw_char("T", 312, 236); /*Space*/ h |= draw_char("T", 328, 236); h |= draw_char("O", 336, 236); h |= draw_char("P", 344, 236); end
//             2'd1: begin h |= draw_char("R", 284, 236); h |= draw_char("I", 292, 236); h |= draw_char("G", 300, 236); h |= draw_char("H", 308, 236); h |= draw_char("T", 316, 236); /*Space*/ h |= draw_char("T", 332, 236); h |= draw_char("O", 340, 236); h |= draw_char("P", 348, 236); end
//             2'd2: begin h |= draw_char("L", 276, 236); h |= draw_char("E", 284, 236); h |= draw_char("F", 292, 236); h |= draw_char("T", 300, 236); /*Space*/ h |= draw_char("B", 316, 236); h |= draw_char("O", 324, 236); h |= draw_char("T", 332, 236); h |= draw_char("T", 340, 236); h |= draw_char("O", 348, 236); h |= draw_char("M", 356, 236); end
//             2'd3: begin h |= draw_char("R", 272, 236); h |= draw_char("I", 280, 236); h |= draw_char("G", 288, 236); h |= draw_char("H", 296, 236); h |= draw_char("T", 304, 236); /*Space*/ h |= draw_char("B", 320, 236); h |= draw_char("O", 328, 236); h |= draw_char("T", 336, 236); h |= draw_char("T", 344, 236); h |= draw_char("O", 352, 236); h |= draw_char("M", 360, 236); end
//         endcase
//         return h;
//     endfunction

//     // "PASS" / "FAIL"
//     function automatic logic draw_str_RESULT_FULL(input [1:0] res_type);
//         logic h; h=0;
//         if (res_type == 2'b01) begin 
//              h |= draw_char("P", 304, 236); h |= draw_char("A", 312, 236); 
//              h |= draw_char("S", 320, 236); h |= draw_char("S", 328, 236);
//         end else begin 
//              h |= draw_char("F", 304, 236); h |= draw_char("A", 312, 236); 
//              h |= draw_char("I", 320, 236); h |= draw_char("L", 328, 236);
//         end
//         return h;
//     endfunction

//     // "FINAL RESULTS"
//     function automatic logic draw_str_FINAL_RESULTS();
//         logic h; h=0;
//         h |= draw_char("F", 268, 140); h |= draw_char("I", 276, 140); h |= draw_char("N", 284, 140); h |= draw_char("A", 292, 140); h |= draw_char("L", 300, 140);
//         h |= draw_char("R", 324, 140); h |= draw_char("E", 332, 140); h |= draw_char("S", 340, 140); h |= draw_char("U", 348, 140); h |= draw_char("L", 356, 140); h |= draw_char("T", 364, 140); h |= draw_char("S", 372, 140);
//         return h;
//     endfunction

//     // "ROUND X : PASS"
//     function automatic logic draw_row_result_full(input [2:0] rnd_idx, input pass, input [9:0] py);
//         logic h; h=0;
//         h |= draw_char("R", 264, py); h |= draw_char("O", 272, py); h |= draw_char("U", 280, py); h |= draw_char("N", 288, py); h |= draw_char("D", 296, py);
//         case(rnd_idx)
//             0: h |= draw_char("1", 312, py); 1: h |= draw_char("2", 312, py); 2: h |= draw_char("3", 312, py);
//             3: h |= draw_char("4", 312, py); 4: h |= draw_char("5", 312, py);
//         endcase
//         h |= draw_char(":", 328, py);
        
//         if(pass) begin
//             h |= draw_char("P", 352, py); h |= draw_char("A", 360, py); h |= draw_char("S", 368, py); h |= draw_char("S", 376, py);
//         end else begin
//             h |= draw_char("F", 352, py); h |= draw_char("A", 360, py); h |= draw_char("I", 368, py); h |= draw_char("L", 376, py);
//         end
//         return h;
//     endfunction

//     // "TOTAL SCORE : XXX"
//     function automatic logic draw_str_FINAL_SCORE_SUM(input [2:0] sc, input [9:0] py);
//         logic h; h=0;
//         h |= draw_char("T", 240, py); h |= draw_char("O", 248, py); h |= draw_char("T", 256, py); h |= draw_char("A", 264, py); h |= draw_char("L", 272, py); 
//         h |= draw_char("S", 288, py); h |= draw_char("C", 296, py); h |= draw_char("O", 304, py); h |= draw_char("R", 312, py); h |= draw_char("E", 320, py); 
//         h |= draw_char(":", 336, py);

//         unique case (sc)
//             3'd0: begin h |= draw_char("0", 360, py); h |= draw_char("0", 368, py); end
//             3'd1: begin h |= draw_char("2", 360, py); h |= draw_char("0", 368, py); end
//             3'd2: begin h |= draw_char("4", 360, py); h |= draw_char("0", 368, py); end
//             3'd3: begin h |= draw_char("6", 360, py); h |= draw_char("0", 368, py); end
//             3'd4: begin h |= draw_char("8", 360, py); h |= draw_char("0", 368, py); end
//             3'd5: begin h |= draw_char("1", 352, py); h |= draw_char("0", 360, py); h |= draw_char("0", 368, py); end
//         endcase
//         return h;
//     endfunction

//     //==========================================================
//     // 🕹️ Main Design Logic
//     //==========================================================
//     logic box_main_center, box_top_hud, box_instruction;
//     logic box_scoreboard; 
//     logic box_border_wrap; 
    
//     logic border_main_outer, border_main_inner;
//     logic border_inst_outer, border_inst_inner;
//     logic border_score_outer, border_score_inner; 
//     logic scanline_effect;
    
//     // Border thickness constants
//     localparam TOP_HUD_HEIGHT = 50;
//     localparam WRAP_THICKNESS = 8; 

//     assign box_main_center  = in_rect(160, 480, 180, 300); 
//     assign border_main_outer = on_border_thick(160, 480, 180, 300, 4'd3);
//     assign border_main_inner = on_border_thick(163, 477, 183, 297, 4'd3);

//     assign box_scoreboard   = in_rect(120, 520, 100, 420);
//     assign border_score_outer = on_border_thick(120, 520, 100, 420, 4'd3);
//     assign border_score_inner = on_border_thick(123, 517, 103, 417, 4'd3);

//     assign box_top_hud      = in_rect(0, 640, 0, TOP_HUD_HEIGHT);

//     // Wrapper Border (Left, Right, Bottom)
//     assign box_border_wrap  = (x < WRAP_THICKNESS) || (x >= 640 - WRAP_THICKNESS) || (y >= 480 - WRAP_THICKNESS);

//     assign box_instruction  = in_rect(180, 460, 210, 270);
//     assign border_inst_outer = on_border_thick(180, 460, 210, 270, 4'd3);
//     assign border_inst_inner = on_border_thick(183, 457, 213, 267, 4'd3);

//     assign scanline_effect = y[1];

//     always_comb begin
//         overlay_en = 0;
//         r = 0; g = 0; b = 0;

//         if (DE) begin
            
//             // --- 1. Global Border & HUD Background ---
//             if (box_top_hud || box_border_wrap) begin
//                 overlay_en = 1;
//                 // Neon line at the bottom of the top HUD
//                 if (box_top_hud && y >= (TOP_HUD_HEIGHT - 3)) begin 
//                     r=0; g=C_NEON_CYAN; b=C_NEON_CYAN; 
//                 end else begin 
//                     r=C_HUD_BG; g=C_HUD_BG; b=C_HUD_BG; // Pure Black
//                 end
//             end

//             // --- 2. Top Bar Text Logic (Separated for persistence) ---
//             if (box_top_hud) begin
//                 if (fsm_state == 3'b000) begin
//                     // State: IDLE -> Show "LET'S PLAY GAME" in Top Bar
//                     if (draw_str_LETS_PLAY_HUD()) begin
//                         overlay_en = 1; 
//                         if (y[3]) begin r=C_NEON_MAGENTA; g=C_WHITE; b=C_NEON_MAGENTA; end
//                         else      begin r=C_WHITE; g=C_NEON_CYAN; b=C_NEON_CYAN; end
//                     end
//                 end else begin
//                     // State: READY, PLAY, RESULT, SCOREBOARD -> Show Score/Round continuously
//                     if (draw_hud_round(round_cnt)) begin
//                         overlay_en=1; r=C_NEON_CYAN; g=C_NEON_CYAN; b=C_WHITE;
//                     end
//                     if (draw_hud_score(score)) begin
//                         overlay_en=1; r=C_NEON_YELLOW; g=C_NEON_YELLOW; b=C_WHITE;
//                     end
//                 end
//             end

//             // --- 3. Main Game State Graphics ---
//             unique case (fsm_state)
//                 // IDLE (000) - Just background (Text handled above)
//                 3'b000: begin
//                     // "LET'S PLAY GAME" is now handled in the HUD block above
//                 end

//                 // READY (001) - Center Box "GET READY"
//                 3'b001: begin
//                     if (box_main_center) begin
//                         overlay_en = 1;
//                         if (border_main_outer)      begin r=0; g=C_NEON_CYAN; b=C_NEON_CYAN; end
//                         else if (border_main_inner) begin r=C_NEON_MAGENTA; g=0; b=C_NEON_MAGENTA; end
//                         else begin r=C_DARK_BG; g=C_DARK_BG; b=(scanline_effect ? 4'h3 : 4'h5); end
//                     end
//                     if (draw_str_GET_READY()) begin
//                         overlay_en = 1; r=C_NEON_YELLOW; g=C_NEON_YELLOW; b=0;
//                     end
//                 end

//                 // PLAY (010)
//                 3'b010: begin
//                     if (on_border_thick(170, 190, 125, 145, 4'd4) || 
//                         on_border_thick(450, 470, 125, 145, 4'd4) || 
//                         on_border_thick(170, 190, 335, 355, 4'd4) || 
//                         on_border_thick(450, 470, 335, 355, 4'd4))  
//                     begin
//                         overlay_en = 1; r = C_WHITE; g = C_WHITE; b = C_WHITE;
//                     end
//                     else if (box_instruction) begin
//                         overlay_en = 1;
//                         if (border_inst_outer || border_inst_inner) begin
//                             if (region[0] == 0) begin r=0; g=C_NEON_CYAN; b=C_NEON_CYAN; end
//                             else begin r=C_NEON_MAGENTA; g=0; b=C_NEON_MAGENTA; end
//                         end else begin
//                             r=C_DARK_BG; g=C_DARK_BG; b=(scanline_effect ? 4'h2 : 4'h4);
//                         end
//                     end
                    
//                     if (draw_instruction_full(region)) begin
//                         overlay_en=1;
//                         if (region[0] == 0) begin r=C_WHITE; g=C_NEON_CYAN; b=C_NEON_CYAN; end
//                         else begin r=C_NEON_MAGENTA; g=C_WHITE; b=C_NEON_MAGENTA; end
//                     end
//                 end

//                 // ROUND END (011) - PASS/FAIL Box
//                 3'b011: begin
//                     if (box_main_center) begin
//                         overlay_en = 1;
//                         if (result_type == 2'b01) begin 
//                             if (border_main_outer)      begin r=0; g=C_NEON_GREEN; b=0; end
//                             else if (border_main_inner) begin r=C_WHITE; g=C_WHITE; b=C_WHITE; end
//                             else begin r=0; g=(scanline_effect ? 4'h4 : 4'h6); b=0; end
//                         end else begin 
//                             if (border_main_outer)      begin r=C_NEON_RED; g=0; b=0; end
//                             else if (border_main_inner) begin r=C_NEON_YELLOW; g=C_NEON_YELLOW; b=0; end
//                             else begin r=(scanline_effect ? 4'h4 : 4'h6); g=0; b=0; end
//                         end
//                     end
//                     if (draw_str_RESULT_FULL(result_type)) begin
//                         overlay_en = 1;
//                         if (result_type == 2'b01) begin r=C_WHITE; g=C_NEON_GREEN; b=C_NEON_GREEN; end
//                         else begin r=C_NEON_RED; g=C_WHITE; b=C_NEON_MAGENTA; end
//                     end
//                 end

//                 // SCOREBOARD (100)
//                 3'b100: begin
//                     if (box_scoreboard) begin
//                         overlay_en = 1;
//                         if (border_score_outer || border_score_inner) begin
//                             r=C_WHITE; g=C_WHITE; b=C_WHITE;
//                         end else begin
//                             if ((y - 180) % 30 == 0) begin r=0; g=4'h4; b=4'h8; end 
//                             else begin r=0; g=0; b=(scanline_effect ? 4'h2 : 4'h4); end
//                         end
//                     end
                    
//                     if (draw_str_FINAL_RESULTS()) begin
//                         overlay_en=1; r=C_NEON_YELLOW; g=C_NEON_YELLOW; b=0;
//                     end
                    
//                     for (int i=0; i<5; i++) begin
//                         if (draw_row_result_full(i[2:0], round_result[i], 200 + i*30)) begin
//                             overlay_en=1;
//                             if(round_result[i]) begin r=0; g=C_NEON_GREEN; b=0; end
//                             else begin r=C_NEON_RED; g=0; b=0; end
//                         end
//                     end

//                     if (draw_str_FINAL_SCORE_SUM(score, 380)) begin
//                         overlay_en=1; r=C_NEON_CYAN; g=C_NEON_CYAN; b=C_WHITE; 
//                     end
//                 end

//                 default: begin end
//             endcase
//         end
//     end

// endmodule































// `timescale 1ns / 1ps

// module GameOverlay_4way (
//     input logic       DE,    // Data Enable signal for VGA
//     input logic [9:0] x,     // Current pixel X coordinate
//     input logic [9:0] y,     // Current pixel Y coordinate

//     // FSM State Input
//     input logic [2:0] fsm_state,
    
//     // Game Data Inputs
//     input logic [1:0] region,       // 0:LT, 1:RT, 2:LB, 3:RB
//     input logic [1:0] result_type,  // 0:None, 1:Success, 2:Fail
//     input logic [2:0] round_cnt,    // Current round number
//     input logic [4:0] round_result, // Bitmask results
//     input logic [2:0] score,        // Total score count

//     // Final VGA RGB Output
//     output logic [3:0] r,
//     output logic [3:0] g,
//     output logic [3:0] b,
//     output logic overlay_en // '1' if overlay is active
// );

//     //==========================================================
//     // 🎨 Arcade Neon Color Palette
//     //==========================================================
//     localparam [3:0] C_BLACK        = 4'h0;
//     localparam [3:0] C_WHITE        = 4'hF; 
//     localparam [3:0] C_NEON_RED     = 4'hF; 
//     localparam [3:0] C_NEON_GREEN   = 4'hE; 
//     localparam [3:0] C_NEON_BLUE    = 4'hF; 
//     localparam [3:0] C_NEON_YELLOW  = 4'hE; 
//     localparam [3:0] C_NEON_CYAN    = 4'hD; 
//     localparam [3:0] C_NEON_MAGENTA = 4'hD; 
    
//     localparam [3:0] C_DARK_BG      = 4'h1; 
//     localparam [3:0] C_HUD_BG       = 4'h0; 

//     //==========================================================
//     // 🔤 8x8 Bitmap Font Definition
//     //==========================================================
//     function automatic [7:0] font_row(input [7:0] ascii, input [2:0] row);
//         unique case (ascii)
//             // --- Numbers ---
//             "0": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "1": case(row) 0:return 8'h10; 1:return 8'h30; 2:return 8'h10; 3:return 8'h10; 4:return 8'h10; 5:return 8'h10; 6:return 8'h38; default:return 0; endcase
//             "2": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h02; 3:return 8'h0C; 4:return 8'h30; 5:return 8'h40; 6:return 8'h7E; default:return 0; endcase
//             "3": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h02; 3:return 8'h1C; 4:return 8'h02; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "4": case(row) 0:return 8'h0C; 1:return 8'h14; 2:return 8'h24; 3:return 8'h44; 4:return 8'h7E; 5:return 8'h04; 6:return 8'h04; default:return 0; endcase
//             "5": case(row) 0:return 8'h7E; 1:return 8'h40; 2:return 8'h7C; 3:return 8'h02; 4:return 8'h02; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "6": case(row) 0:return 8'h3C; 1:return 8'h40; 2:return 8'h7C; 3:return 8'h42; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "8": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h3C; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
            
//             // --- Alphabets ---
//             "A": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7E; 4:return 8'h42; 5:return 8'h42; 6:return 8'h42; default:return 0; endcase
//             "B": case(row) 0:return 8'h7C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7C; 4:return 8'h42; 5:return 8'h42; 6:return 8'h7C; default:return 0; endcase
//             "C": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h40; 3:return 8'h40; 4:return 8'h40; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "D": case(row) 0:return 8'h78; 1:return 8'h44; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h44; 6:return 8'h78; default:return 0; endcase
//             "E": case(row) 0:return 8'h7E; 1:return 8'h40; 2:return 8'h40; 3:return 8'h7C; 4:return 8'h40; 5:return 8'h40; 6:return 8'h7E; default:return 0; endcase
//             "F": case(row) 0:return 8'h7E; 1:return 8'h40; 2:return 8'h40; 3:return 8'h7C; 4:return 8'h40; 5:return 8'h40; 6:return 8'h40; default:return 0; endcase
//             "G": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h40; 3:return 8'h4E; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "H": case(row) 0:return 8'h42; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7E; 4:return 8'h42; 5:return 8'h42; 6:return 8'h42; default:return 0; endcase
//             "I": case(row) 0:return 8'h7E; 1:return 8'h18; 2:return 8'h18; 3:return 8'h18; 4:return 8'h18; 5:return 8'h18; 6:return 8'h7E; default:return 0; endcase
//             "L": case(row) 0:return 8'h40; 1:return 8'h40; 2:return 8'h40; 3:return 8'h40; 4:return 8'h40; 5:return 8'h40; 6:return 8'h7E; default:return 0; endcase
//             "M": case(row) 0:return 8'hC3; 1:return 8'hA5; 2:return 8'h99; 3:return 8'h99; 4:return 8'h81; 5:return 8'h81; 6:return 8'h81; default:return 0; endcase
//             "N": case(row) 0:return 8'h42; 1:return 8'h62; 2:return 8'h52; 3:return 8'h4A; 4:return 8'h46; 5:return 8'h42; 6:return 8'h42; default:return 0; endcase
//             "O": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "P": case(row) 0:return 8'h7C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7C; 4:return 8'h40; 5:return 8'h40; 6:return 8'h40; default:return 0; endcase
//             "R": case(row) 0:return 8'h7C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7C; 4:return 8'h50; 5:return 8'h48; 6:return 8'h44; default:return 0; endcase
//             "S": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h40; 3:return 8'h3C; 4:return 8'h02; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "T": case(row) 0:return 8'h7E; 1:return 8'h18; 2:return 8'h18; 3:return 8'h18; 4:return 8'h18; 5:return 8'h18; 6:return 8'h18; default:return 0; endcase
//             "U": case(row) 0:return 8'h42; 1:return 8'h42; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
//             "V": case(row) 0:return 8'h42; 1:return 8'h42; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h24; 6:return 8'h18; default:return 0; endcase
//             "W": case(row) 0:return 8'h81; 1:return 8'h81; 2:return 8'h81; 3:return 8'h99; 4:return 8'h99; 5:return 8'hA5; 6:return 8'hC3; default:return 0; endcase
//             "Y": case(row) 0:return 8'h42; 1:return 8'h42; 2:return 8'h42; 3:return 8'h3C; 4:return 8'h18; 5:return 8'h18; 6:return 8'h18; default:return 0; endcase
            
//             // --- Symbols ---
//             "?": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h02; 3:return 8'h1C; 4:return 8'h10; 5:return 8'h00; 6:return 8'h10; default:return 0; endcase
//             ":": case(row) 0:return 0;    1:return 8'h18; 2:return 8'h18; 3:return 0;    4:return 8'h18; 5:return 8'h18; 6:return 0;    default:return 0; endcase
//             "/": case(row) 0:return 8'h02; 1:return 8'h04; 2:return 8'h08; 3:return 8'h10; 4:return 8'h20; 5:return 8'h40; 6:return 8'h80; default:return 0; endcase
//             "!": case(row) 0:return 8'h18; 1:return 8'h18; 2:return 8'h18; 3:return 8'h18; 4:return 8'h00; 5:return 8'h00; 6:return 8'h18; default:return 0; endcase
//             "'": case(row) 0:return 8'h18; 1:return 8'h18; 2:return 8'h10; 3:return 0;    4:return 0;    5:return 0;    6:return 0;    default:return 0; endcase

//             default: font_row = 8'h00;
//         endcase
//     endfunction

//     //==========================================================
//     // 🛠️ Graphic Helper Functions
//     //==========================================================
//     function automatic logic in_rect(input [9:0] l, r, t, b);
//         in_rect = (x >= l && x < r && y >= t && y < b);
//     endfunction

//     function automatic logic on_border_thick(input [9:0] l, r, t, b, input [3:0] thickness);
//         logic outer, inner;
//         outer = (x >= l && x < r && y >= t && y < b);
//         inner = (x >= l+thickness && x < r-thickness && y >= t+thickness && y < b-thickness);
//         on_border_thick = outer && !inner;
//     endfunction

//     function automatic logic draw_char(input [7:0] ascii, input [9:0] px, input [9:0] py);
//         logic [7:0] row_bits;
//         if (x >= px && x < px + 8 && y >= py && y < py + 8) begin
//             row_bits  = font_row(ascii, y - py);
//             draw_char = row_bits[7-(x-px)];
//         end else begin
//             draw_char = 1'b0;
//         end
//     endfunction

//     //==========================================================
//     // 📝 String Helper Functions
//     //==========================================================
    
//     // "LET'S PLAY GAME" (Moved to Y=20 for Top HUD)
//     function automatic logic draw_str_LETS_PLAY_HUD();
//         logic h; h=0;
//         // Center X ~ 260, Y fixed at 20 (inside 50px top bar)
//         h |= draw_char("L", 260, 20); h |= draw_char("E", 268, 20); h |= draw_char("T", 276, 20); 
//         h |= draw_char("'", 284, 20); h |= draw_char("S", 292, 20);
        
//         /* Space */
        
//         h |= draw_char("P", 308, 20); h |= draw_char("L", 316, 20); h |= draw_char("A", 324, 20); h |= draw_char("Y", 332, 20);
        
//         /* Space */
        
//         h |= draw_char("G", 348, 20); h |= draw_char("A", 356, 20); h |= draw_char("M", 364, 20); h |= draw_char("E", 372, 20);
//         return h;
//     endfunction

//     // "GET READY!" (Center Screen)
//     function automatic logic draw_str_GET_READY();
//         logic h; h=0;
//         h |= draw_char("G", 280, 236); h |= draw_char("E", 288, 236); h |= draw_char("T", 296, 236);
//         h |= draw_char("R", 312, 236); h |= draw_char("E", 320, 236); h |= draw_char("A", 328, 236);
//         h |= draw_char("D", 336, 236); h |= draw_char("Y", 344, 236); h |= draw_char("!", 352, 236);
//         return h;
//     endfunction

//     // "ROUND: X / 5" (Top Left in HUD)
//     function automatic logic draw_hud_round(input [2:0] rnd);
//         logic h; h=0;
//         h |= draw_char("R", 20, 16); h |= draw_char("O", 28, 16); h |= draw_char("U", 36, 16);
//         h |= draw_char("N", 44, 16); h |= draw_char("D", 52, 16); h |= draw_char(":", 60, 16);
//         case(rnd)
//             0: h |= draw_char("1", 76, 16); 1: h |= draw_char("2", 76, 16); 2: h |= draw_char("3", 76, 16);
//             3: h |= draw_char("4", 76, 16); 4: h |= draw_char("5", 76, 16); default: h |= draw_char("?", 76, 16);
//         endcase
//         h |= draw_char("/", 92, 16); h |= draw_char("5", 108, 16);
//         return h;
//     endfunction

//     // "TOTAL SCORE: XXX" (Top Right in HUD)
//     function automatic logic draw_hud_score(input [2:0] sc);
//         logic h; h=0;
//         h |= draw_char("T", 450, 16); h |= draw_char("O", 458, 16); h |= draw_char("T", 466, 16);
//         h |= draw_char("A", 474, 16); h |= draw_char("L", 482, 16); 
//         h |= draw_char("S", 498, 16); h |= draw_char("C", 506, 16); h |= draw_char("O", 514, 16);
//         h |= draw_char("R", 522, 16); h |= draw_char("E", 530, 16); h |= draw_char(":", 538, 16);
        
//         unique case(sc)
//             3'd0: begin h |= draw_char("0", 562, 16); h |= draw_char("0", 570, 16); end
//             3'd1: begin h |= draw_char("2", 562, 16); h |= draw_char("0", 570, 16); end
//             3'd2: begin h |= draw_char("4", 562, 16); h |= draw_char("0", 570, 16); end
//             3'd3: begin h |= draw_char("6", 562, 16); h |= draw_char("0", 570, 16); end
//             3'd4: begin h |= draw_char("8", 562, 16); h |= draw_char("0", 570, 16); end
//             3'd5: begin h |= draw_char("1", 554, 16); h |= draw_char("0", 562, 16); h |= draw_char("0", 570, 16); end
//             default: begin h |= draw_char("0", 562, 16); h |= draw_char("0", 570, 16); end
//         endcase
//         return h;
//     endfunction

//     // Instructions
//     function automatic logic draw_instruction_full(input [1:0] region_idx);
//         logic h; h=0;
//         unique case (region_idx)
//             2'd0: begin h |= draw_char("L", 288, 236); h |= draw_char("E", 296, 236); h |= draw_char("F", 304, 236); h |= draw_char("T", 312, 236); /*Space*/ h |= draw_char("T", 328, 236); h |= draw_char("O", 336, 236); h |= draw_char("P", 344, 236); end
//             2'd1: begin h |= draw_char("R", 284, 236); h |= draw_char("I", 292, 236); h |= draw_char("G", 300, 236); h |= draw_char("H", 308, 236); h |= draw_char("T", 316, 236); /*Space*/ h |= draw_char("T", 332, 236); h |= draw_char("O", 340, 236); h |= draw_char("P", 348, 236); end
//             2'd2: begin h |= draw_char("L", 276, 236); h |= draw_char("E", 284, 236); h |= draw_char("F", 292, 236); h |= draw_char("T", 300, 236); /*Space*/ h |= draw_char("B", 316, 236); h |= draw_char("O", 324, 236); h |= draw_char("T", 332, 236); h |= draw_char("T", 340, 236); h |= draw_char("O", 348, 236); h |= draw_char("M", 356, 236); end
//             2'd3: begin h |= draw_char("R", 272, 236); h |= draw_char("I", 280, 236); h |= draw_char("G", 288, 236); h |= draw_char("H", 296, 236); h |= draw_char("T", 304, 236); /*Space*/ h |= draw_char("B", 320, 236); h |= draw_char("O", 328, 236); h |= draw_char("T", 336, 236); h |= draw_char("T", 344, 236); h |= draw_char("O", 352, 236); h |= draw_char("M", 360, 236); end
//         endcase
//         return h;
//     endfunction

//     // "PASS" / "FAIL"
//     function automatic logic draw_str_RESULT_FULL(input [1:0] res_type);
//         logic h; h=0;
//         if (res_type == 2'b01) begin 
//              h |= draw_char("P", 304, 236); h |= draw_char("A", 312, 236); 
//              h |= draw_char("S", 320, 236); h |= draw_char("S", 328, 236);
//         end else begin 
//              h |= draw_char("F", 304, 236); h |= draw_char("A", 312, 236); 
//              h |= draw_char("I", 320, 236); h |= draw_char("L", 328, 236);
//         end
//         return h;
//     endfunction

//     // "FINAL RESULTS"
//     function automatic logic draw_str_FINAL_RESULTS();
//         logic h; h=0;
//         h |= draw_char("F", 268, 140); h |= draw_char("I", 276, 140); h |= draw_char("N", 284, 140); h |= draw_char("A", 292, 140); h |= draw_char("L", 300, 140);
//         h |= draw_char("R", 324, 140); h |= draw_char("E", 332, 140); h |= draw_char("S", 340, 140); h |= draw_char("U", 348, 140); h |= draw_char("L", 356, 140); h |= draw_char("T", 364, 140); h |= draw_char("S", 372, 140);
//         return h;
//     endfunction

//     // "ROUND X : PASS"
//     function automatic logic draw_row_result_full(input [2:0] rnd_idx, input pass, input [9:0] py);
//         logic h; h=0;
//         h |= draw_char("R", 264, py); h |= draw_char("O", 272, py); h |= draw_char("U", 280, py); h |= draw_char("N", 288, py); h |= draw_char("D", 296, py);
//         case(rnd_idx)
//             0: h |= draw_char("1", 312, py); 1: h |= draw_char("2", 312, py); 2: h |= draw_char("3", 312, py);
//             3: h |= draw_char("4", 312, py); 4: h |= draw_char("5", 312, py);
//         endcase
//         h |= draw_char(":", 328, py);
        
//         if(pass) begin
//             h |= draw_char("P", 352, py); h |= draw_char("A", 360, py); h |= draw_char("S", 368, py); h |= draw_char("S", 376, py);
//         end else begin
//             h |= draw_char("F", 352, py); h |= draw_char("A", 360, py); h |= draw_char("I", 368, py); h |= draw_char("L", 376, py);
//         end
//         return h;
//     endfunction

//     // "TOTAL SCORE : XXX"
//     function automatic logic draw_str_FINAL_SCORE_SUM(input [2:0] sc, input [9:0] py);
//         logic h; h=0;
//         h |= draw_char("T", 240, py); h |= draw_char("O", 248, py); h |= draw_char("T", 256, py); h |= draw_char("A", 264, py); h |= draw_char("L", 272, py); 
//         h |= draw_char("S", 288, py); h |= draw_char("C", 296, py); h |= draw_char("O", 304, py); h |= draw_char("R", 312, py); h |= draw_char("E", 320, py); 
//         h |= draw_char(":", 336, py);

//         unique case (sc)
//             3'd0: begin h |= draw_char("0", 360, py); h |= draw_char("0", 368, py); end
//             3'd1: begin h |= draw_char("2", 360, py); h |= draw_char("0", 368, py); end
//             3'd2: begin h |= draw_char("4", 360, py); h |= draw_char("0", 368, py); end
//             3'd3: begin h |= draw_char("6", 360, py); h |= draw_char("0", 368, py); end
//             3'd4: begin h |= draw_char("8", 360, py); h |= draw_char("0", 368, py); end
//             3'd5: begin h |= draw_char("1", 352, py); h |= draw_char("0", 360, py); h |= draw_char("0", 368, py); end
//         endcase
//         return h;
//     endfunction

//     //==========================================================
//     // 🕹️ Main Design Logic
//     //==========================================================
//     logic box_main_center, box_top_hud, box_instruction;
//     logic box_scoreboard; 
//     logic box_border_wrap; 
    
//     logic border_main_outer, border_main_inner;
//     logic border_inst_outer, border_inst_inner;
//     logic border_score_outer, border_score_inner; 
//     logic scanline_effect;
    
//     // Border thickness constants
//     localparam TOP_HUD_HEIGHT = 50;
//     localparam WRAP_THICKNESS = 8; 

//     assign box_main_center  = in_rect(160, 480, 180, 300); 
//     assign border_main_outer = on_border_thick(160, 480, 180, 300, 4'd3);
//     assign border_main_inner = on_border_thick(163, 477, 183, 297, 4'd3);

//     assign box_scoreboard   = in_rect(120, 520, 100, 420);
//     assign border_score_outer = on_border_thick(120, 520, 100, 420, 4'd3);
//     assign border_score_inner = on_border_thick(123, 517, 103, 417, 4'd3);

//     assign box_top_hud      = in_rect(0, 640, 0, TOP_HUD_HEIGHT);

//     // Wrapper Border (Left, Right, Bottom)
//     assign box_border_wrap  = (x < WRAP_THICKNESS) || (x >= 640 - WRAP_THICKNESS) || (y >= 480 - WRAP_THICKNESS);

//     assign box_instruction  = in_rect(180, 460, 210, 270);
//     assign border_inst_outer = on_border_thick(180, 460, 210, 270, 4'd3);
//     assign border_inst_inner = on_border_thick(183, 457, 213, 267, 4'd3);

//     assign scanline_effect = y[1];

//     always_comb begin
//         overlay_en = 0;
//         r = 0; g = 0; b = 0;

//         if (DE) begin
            
//             // --- 1. Global Border & HUD Background ---
//             if (box_top_hud || box_border_wrap) begin
//                 overlay_en = 1;
//                 // Neon line at the bottom of the top HUD
//                 if (box_top_hud && y >= (TOP_HUD_HEIGHT - 3)) begin 
//                     r=0; g=C_NEON_CYAN; b=C_NEON_CYAN; 
//                 end else begin 
//                     r=C_HUD_BG; g=C_HUD_BG; b=C_HUD_BG; // Pure Black
//                 end
//             end

//             // --- 2. Top Bar Text Logic (Separated for persistence) ---
//             if (box_top_hud) begin
//                 if (fsm_state == 3'b000) begin
//                     // State: IDLE -> Show "LET'S PLAY GAME" in Top Bar
//                     if (draw_str_LETS_PLAY_HUD()) begin
//                         overlay_en = 1; 
//                         if (y[3]) begin r=C_NEON_MAGENTA; g=C_WHITE; b=C_NEON_MAGENTA; end
//                         else      begin r=C_WHITE; g=C_NEON_CYAN; b=C_NEON_CYAN; end
//                     end
//                 end else begin
//                     // State: READY, PLAY, RESULT, SCOREBOARD -> Show Score/Round continuously
//                     if (draw_hud_round(round_cnt)) begin
//                         overlay_en=1; r=C_NEON_CYAN; g=C_NEON_CYAN; b=C_WHITE;
//                     end
//                     if (draw_hud_score(score)) begin
//                         overlay_en=1; r=C_NEON_YELLOW; g=C_NEON_YELLOW; b=C_WHITE;
//                     end
//                 end
//             end

//             // --- 3. Main Game State Graphics ---
//             unique case (fsm_state)
//                 // IDLE (000) - Just background (Text handled above)
//                 3'b000: begin
//                     // "LET'S PLAY GAME" is now handled in the HUD block above
//                 end

//                 // READY (001) - Center Box "GET READY"
//                 3'b001: begin
//                     if (box_main_center) begin
//                         overlay_en = 1;
//                         if (border_main_outer)      begin r=0; g=C_NEON_CYAN; b=C_NEON_CYAN; end
//                         else if (border_main_inner) begin r=C_NEON_MAGENTA; g=0; b=C_NEON_MAGENTA; end
//                         else begin r=C_DARK_BG; g=C_DARK_BG; b=(scanline_effect ? 4'h3 : 4'h5); end
//                     end
//                     if (draw_str_GET_READY()) begin
//                         overlay_en = 1; r=C_NEON_YELLOW; g=C_NEON_YELLOW; b=0;
//                     end
//                 end

//                 // PLAY (010)
//                 3'b010: begin
//                     if (on_border_thick(170, 190, 125, 145, 4'd4) || 
//                         on_border_thick(450, 470, 125, 145, 4'd4) || 
//                         on_border_thick(170, 190, 335, 355, 4'd4) || 
//                         on_border_thick(450, 470, 335, 355, 4'd4))  
//                     begin
//                         overlay_en = 1; r = C_WHITE; g = C_WHITE; b = C_WHITE;
//                     end
//                     else if (box_instruction) begin
//                         overlay_en = 1;
//                         if (border_inst_outer || border_inst_inner) begin
//                             if (region[0] == 0) begin r=0; g=C_NEON_CYAN; b=C_NEON_CYAN; end
//                             else begin r=C_NEON_MAGENTA; g=0; b=C_NEON_MAGENTA; end
//                         end else begin
//                             r=C_DARK_BG; g=C_DARK_BG; b=(scanline_effect ? 4'h2 : 4'h4);
//                         end
//                     end
                    
//                     if (draw_instruction_full(region)) begin
//                         overlay_en=1;
//                         if (region[0] == 0) begin r=C_WHITE; g=C_NEON_CYAN; b=C_NEON_CYAN; end
//                         else begin r=C_NEON_MAGENTA; g=C_WHITE; b=C_NEON_MAGENTA; end
//                     end
//                 end

//                 // ROUND END (011) - PASS/FAIL Box
//                 3'b011: begin
//                     if (box_main_center) begin
//                         overlay_en = 1;
//                         if (result_type == 2'b01) begin 
//                             if (border_main_outer)      begin r=0; g=C_NEON_GREEN; b=0; end
//                             else if (border_main_inner) begin r=C_WHITE; g=C_WHITE; b=C_WHITE; end
//                             else begin r=0; g=(scanline_effect ? 4'h4 : 4'h6); b=0; end
//                         end else begin 
//                             if (border_main_outer)      begin r=C_NEON_RED; g=0; b=0; end
//                             else if (border_main_inner) begin r=C_NEON_YELLOW; g=C_NEON_YELLOW; b=0; end
//                             else begin r=(scanline_effect ? 4'h4 : 4'h6); g=0; b=0; end
//                         end
//                     end
//                     if (draw_str_RESULT_FULL(result_type)) begin
//                         overlay_en = 1;
//                         if (result_type == 2'b01) begin r=C_WHITE; g=C_NEON_GREEN; b=C_NEON_GREEN; end
//                         else begin r=C_NEON_RED; g=C_WHITE; b=C_NEON_MAGENTA; end
//                     end
//                 end

//                 // SCOREBOARD (100)
//                 3'b100: begin
//                     if (box_scoreboard) begin
//                         overlay_en = 1;
//                         if (border_score_outer || border_score_inner) begin
//                             r=C_WHITE; g=C_WHITE; b=C_WHITE;
//                         end else begin
//                             if ((y - 180) % 30 == 0) begin r=0; g=4'h4; b=4'h8; end 
//                             else begin r=0; g=0; b=(scanline_effect ? 4'h2 : 4'h4); end
//                         end
//                     end
                    
//                     if (draw_str_FINAL_RESULTS()) begin
//                         overlay_en=1; r=C_NEON_YELLOW; g=C_NEON_YELLOW; b=0;
//                     end
                    
//                     for (int i=0; i<5; i++) begin
//                         if (draw_row_result_full(i[2:0], round_result[i], 200 + i*30)) begin
//                             overlay_en=1;
//                             if(round_result[i]) begin r=0; g=C_NEON_GREEN; b=0; end
//                             else begin r=C_NEON_RED; g=0; b=0; end
//                         end
//                     end

//                     if (draw_str_FINAL_SCORE_SUM(score, 380)) begin
//                         overlay_en=1; r=C_NEON_CYAN; g=C_NEON_CYAN; b=C_WHITE; 
//                     end
//                 end

//                 default: begin end
//             endcase
//         end
//     end

// endmodule

`timescale 1ns / 1ps

module GameOverlay_4way (
    input logic       DE,    // Data Enable signal for VGA
    input logic [9:0] x,     // Current pixel X coordinate
    input logic [9:0] y,     // Current pixel Y coordinate

    // FSM State Input
    input logic [2:0] fsm_state,
    
    // Game Data Inputs
    input logic [1:0] region,       // 0:LT, 1:RT, 2:LB, 3:RB
    input logic [1:0] result_type,  // 0:None, 1:Success, 2:Fail
    input logic [2:0] round_cnt,    // Current round number
    input logic [4:0] round_result, // Bitmask results
    input logic [2:0] score,        // Total score count

    // Final VGA RGB Output
    output logic [3:0] r,
    output logic [3:0] g,
    output logic [3:0] b,
    output logic overlay_en // '1' if overlay is active
);

    //==========================================================
    // 🎨 Arcade Neon Color Palette
    //==========================================================
    localparam [3:0] C_BLACK        = 4'h0;
    localparam [3:0] C_WHITE        = 4'hF; 
    localparam [3:0] C_NEON_RED     = 4'hF; 
    localparam [3:0] C_NEON_GREEN   = 4'hE; 
    localparam [3:0] C_NEON_BLUE    = 4'hF; 
    localparam [3:0] C_NEON_YELLOW  = 4'hE; 
    localparam [3:0] C_NEON_CYAN    = 4'hD; 
    localparam [3:0] C_NEON_MAGENTA = 4'hD; 
    
    localparam [3:0] C_DARK_BG      = 4'h1; 
    localparam [3:0] C_HUD_BG       = 4'h0; 

    //==========================================================
    // 🔤 8x8 Bitmap Font Definition
    //==========================================================
    function automatic [7:0] font_row(input [7:0] ascii, input [2:0] row);
        unique case (ascii)
            // --- Numbers ---
            "0": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
            "1": case(row) 0:return 8'h10; 1:return 8'h30; 2:return 8'h10; 3:return 8'h10; 4:return 8'h10; 5:return 8'h10; 6:return 8'h38; default:return 0; endcase
            "2": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h02; 3:return 8'h0C; 4:return 8'h30; 5:return 8'h40; 6:return 8'h7E; default:return 0; endcase
            "3": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h02; 3:return 8'h1C; 4:return 8'h02; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
            "4": case(row) 0:return 8'h0C; 1:return 8'h14; 2:return 8'h24; 3:return 8'h44; 4:return 8'h7E; 5:return 8'h04; 6:return 8'h04; default:return 0; endcase
            "5": case(row) 0:return 8'h7E; 1:return 8'h40; 2:return 8'h7C; 3:return 8'h02; 4:return 8'h02; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
            "6": case(row) 0:return 8'h3C; 1:return 8'h40; 2:return 8'h7C; 3:return 8'h42; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
            "8": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h3C; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
            
            // --- Alphabets ---
            "A": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7E; 4:return 8'h42; 5:return 8'h42; 6:return 8'h42; default:return 0; endcase
            "B": case(row) 0:return 8'h7C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7C; 4:return 8'h42; 5:return 8'h42; 6:return 8'h7C; default:return 0; endcase
            "C": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h40; 3:return 8'h40; 4:return 8'h40; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
            "D": case(row) 0:return 8'h78; 1:return 8'h44; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h44; 6:return 8'h78; default:return 0; endcase
            "E": case(row) 0:return 8'h7E; 1:return 8'h40; 2:return 8'h40; 3:return 8'h7C; 4:return 8'h40; 5:return 8'h40; 6:return 8'h7E; default:return 0; endcase
            "F": case(row) 0:return 8'h7E; 1:return 8'h40; 2:return 8'h40; 3:return 8'h7C; 4:return 8'h40; 5:return 8'h40; 6:return 8'h40; default:return 0; endcase
            "G": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h40; 3:return 8'h4E; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
            "H": case(row) 0:return 8'h42; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7E; 4:return 8'h42; 5:return 8'h42; 6:return 8'h42; default:return 0; endcase
            "I": case(row) 0:return 8'h7E; 1:return 8'h18; 2:return 8'h18; 3:return 8'h18; 4:return 8'h18; 5:return 8'h18; 6:return 8'h7E; default:return 0; endcase
            "L": case(row) 0:return 8'h40; 1:return 8'h40; 2:return 8'h40; 3:return 8'h40; 4:return 8'h40; 5:return 8'h40; 6:return 8'h7E; default:return 0; endcase
            "M": case(row) 0:return 8'hC3; 1:return 8'hA5; 2:return 8'h99; 3:return 8'h99; 4:return 8'h81; 5:return 8'h81; 6:return 8'h81; default:return 0; endcase
            "N": case(row) 0:return 8'h42; 1:return 8'h62; 2:return 8'h52; 3:return 8'h4A; 4:return 8'h46; 5:return 8'h42; 6:return 8'h42; default:return 0; endcase
            "O": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
            "P": case(row) 0:return 8'h7C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7C; 4:return 8'h40; 5:return 8'h40; 6:return 8'h40; default:return 0; endcase
            "R": case(row) 0:return 8'h7C; 1:return 8'h42; 2:return 8'h42; 3:return 8'h7C; 4:return 8'h50; 5:return 8'h48; 6:return 8'h44; default:return 0; endcase
            "S": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h40; 3:return 8'h3C; 4:return 8'h02; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
            "T": case(row) 0:return 8'h7E; 1:return 8'h18; 2:return 8'h18; 3:return 8'h18; 4:return 8'h18; 5:return 8'h18; 6:return 8'h18; default:return 0; endcase
            "U": case(row) 0:return 8'h42; 1:return 8'h42; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h42; 6:return 8'h3C; default:return 0; endcase
            "V": case(row) 0:return 8'h42; 1:return 8'h42; 2:return 8'h42; 3:return 8'h42; 4:return 8'h42; 5:return 8'h24; 6:return 8'h18; default:return 0; endcase
            "W": case(row) 0:return 8'h81; 1:return 8'h81; 2:return 8'h81; 3:return 8'h99; 4:return 8'h99; 5:return 8'hA5; 6:return 8'hC3; default:return 0; endcase
            "Y": case(row) 0:return 8'h42; 1:return 8'h42; 2:return 8'h42; 3:return 8'h3C; 4:return 8'h18; 5:return 8'h18; 6:return 8'h18; default:return 0; endcase
            
            // --- Symbols ---
            "?": case(row) 0:return 8'h3C; 1:return 8'h42; 2:return 8'h02; 3:return 8'h1C; 4:return 8'h10; 5:return 8'h00; 6:return 8'h10; default:return 0; endcase
            ":": case(row) 0:return 0;    1:return 8'h18; 2:return 8'h18; 3:return 0;    4:return 8'h18; 5:return 8'h18; 6:return 0;    default:return 0; endcase
            "/": case(row) 0:return 8'h02; 1:return 8'h04; 2:return 8'h08; 3:return 8'h10; 4:return 8'h20; 5:return 8'h40; 6:return 8'h80; default:return 0; endcase
            "!": case(row) 0:return 8'h18; 1:return 8'h18; 2:return 8'h18; 3:return 8'h18; 4:return 8'h00; 5:return 8'h00; 6:return 8'h18; default:return 0; endcase
            "'": case(row) 0:return 8'h18; 1:return 8'h18; 2:return 8'h10; 3:return 0;    4:return 0;    5:return 0;    6:return 0;    default:return 0; endcase

            default: font_row = 8'h00;
        endcase
    endfunction

    //==========================================================
    // 🛠️ Graphic Helper Functions
    //==========================================================
    function automatic logic in_rect(input [9:0] l, r, t, b);
        in_rect = (x >= l && x < r && y >= t && y < b);
    endfunction

    function automatic logic on_border_thick(input [9:0] l, r, t, b, input [3:0] thickness);
        logic outer, inner;
        outer = (x >= l && x < r && y >= t && y < b);
        inner = (x >= l+thickness && x < r-thickness && y >= t+thickness && y < b-thickness);
        on_border_thick = outer && !inner;
    endfunction

    function automatic logic draw_char(input [7:0] ascii, input [9:0] px, input [9:0] py);
        logic [7:0] row_bits;
        if (x >= px && x < px + 8 && y >= py && y < py + 8) begin
            row_bits  = font_row(ascii, y - py);
            draw_char = row_bits[7-(x-px)];
        end else begin
            draw_char = 1'b0;
        end
    endfunction

    //==========================================================
    // 📝 String Helper Functions
    //==========================================================
    
    // "LET'S PLAY GAME" (Moved to Y=20 for Top HUD)
    function automatic logic draw_str_LETS_PLAY_HUD();
        logic h; h=0;
        // Center X ~ 260, Y fixed at 20 (inside 50px top bar)
        h |= draw_char("L", 260, 20); h |= draw_char("E", 268, 20); h |= draw_char("T", 276, 20); 
        h |= draw_char("'", 284, 20); h |= draw_char("S", 292, 20);
        
        /* Space */
        
        h |= draw_char("P", 308, 20); h |= draw_char("L", 316, 20); h |= draw_char("A", 324, 20); h |= draw_char("Y", 332, 20);
        
        /* Space */
        
        h |= draw_char("G", 348, 20); h |= draw_char("A", 356, 20); h |= draw_char("M", 364, 20); h |= draw_char("E", 372, 20);
        return h;
    endfunction

    // "GET READY!" (Center Screen)
    function automatic logic draw_str_GET_READY();
        logic h; h=0;
        h |= draw_char("G", 280, 236); h |= draw_char("E", 288, 236); h |= draw_char("T", 296, 236);
        h |= draw_char("R", 312, 236); h |= draw_char("E", 320, 236); h |= draw_char("A", 328, 236);
        h |= draw_char("D", 336, 236); h |= draw_char("Y", 344, 236); h |= draw_char("!", 352, 236);
        return h;
    endfunction

    // "ROUND: X / 5" (Top Left in HUD)
    function automatic logic draw_hud_round(input [2:0] rnd);
        logic h; h=0;
        h |= draw_char("R", 20, 16); h |= draw_char("O", 28, 16); h |= draw_char("U", 36, 16);
        h |= draw_char("N", 44, 16); h |= draw_char("D", 52, 16); h |= draw_char(":", 60, 16);
        case(rnd)
            0: h |= draw_char("1", 76, 16); 1: h |= draw_char("2", 76, 16); 2: h |= draw_char("3", 76, 16);
            3: h |= draw_char("4", 76, 16); 4: h |= draw_char("5", 76, 16); default: h |= draw_char("?", 76, 16);
        endcase
        h |= draw_char("/", 92, 16); h |= draw_char("5", 108, 16);
        return h;
    endfunction

    // "TOTAL SCORE: XXX" (Top Right in HUD)
    function automatic logic draw_hud_score(input [2:0] sc);
        logic h; h=0;
        h |= draw_char("T", 450, 16); h |= draw_char("O", 458, 16); h |= draw_char("T", 466, 16);
        h |= draw_char("A", 474, 16); h |= draw_char("L", 482, 16); 
        h |= draw_char("S", 498, 16); h |= draw_char("C", 506, 16); h |= draw_char("O", 514, 16);
        h |= draw_char("R", 522, 16); h |= draw_char("E", 530, 16); h |= draw_char(":", 538, 16);
        
        unique case(sc)
            3'd0: begin h |= draw_char("0", 562, 16); h |= draw_char("0", 570, 16); end
            3'd1: begin h |= draw_char("2", 562, 16); h |= draw_char("0", 570, 16); end
            3'd2: begin h |= draw_char("4", 562, 16); h |= draw_char("0", 570, 16); end
            3'd3: begin h |= draw_char("6", 562, 16); h |= draw_char("0", 570, 16); end
            3'd4: begin h |= draw_char("8", 562, 16); h |= draw_char("0", 570, 16); end
            3'd5: begin h |= draw_char("1", 554, 16); h |= draw_char("0", 562, 16); h |= draw_char("0", 570, 16); end
            default: begin h |= draw_char("0", 562, 16); h |= draw_char("0", 570, 16); end
        endcase
        return h;
    endfunction

    // Instructions
    function automatic logic draw_instruction_full(input [1:0] region_idx);
        logic h; h=0;
        unique case (region_idx)
            2'd0: begin h |= draw_char("L", 288, 236); h |= draw_char("E", 296, 236); h |= draw_char("F", 304, 236); h |= draw_char("T", 312, 236); /*Space*/ h |= draw_char("T", 328, 236); h |= draw_char("O", 336, 236); h |= draw_char("P", 344, 236); end
            2'd1: begin h |= draw_char("R", 284, 236); h |= draw_char("I", 292, 236); h |= draw_char("G", 300, 236); h |= draw_char("H", 308, 236); h |= draw_char("T", 316, 236); /*Space*/ h |= draw_char("T", 332, 236); h |= draw_char("O", 340, 236); h |= draw_char("P", 348, 236); end
            2'd2: begin h |= draw_char("L", 276, 236); h |= draw_char("E", 284, 236); h |= draw_char("F", 292, 236); h |= draw_char("T", 300, 236); /*Space*/ h |= draw_char("B", 316, 236); h |= draw_char("O", 324, 236); h |= draw_char("T", 332, 236); h |= draw_char("T", 340, 236); h |= draw_char("O", 348, 236); h |= draw_char("M", 356, 236); end
            2'd3: begin h |= draw_char("R", 272, 236); h |= draw_char("I", 280, 236); h |= draw_char("G", 288, 236); h |= draw_char("H", 296, 236); h |= draw_char("T", 304, 236); /*Space*/ h |= draw_char("B", 320, 236); h |= draw_char("O", 328, 236); h |= draw_char("T", 336, 236); h |= draw_char("T", 344, 236); h |= draw_char("O", 352, 236); h |= draw_char("M", 360, 236); end
        endcase
        return h;
    endfunction

    // "PASS" / "FAIL"
    function automatic logic draw_str_RESULT_FULL(input [1:0] res_type);
        logic h; h=0;
        if (res_type == 2'b01) begin 
             h |= draw_char("P", 304, 236); h |= draw_char("A", 312, 236); 
             h |= draw_char("S", 320, 236); h |= draw_char("S", 328, 236);
        end else begin 
             h |= draw_char("F", 304, 236); h |= draw_char("A", 312, 236); 
             h |= draw_char("I", 320, 236); h |= draw_char("L", 328, 236);
        end
        return h;
    endfunction

    // "FINAL RESULTS"
    function automatic logic draw_str_FINAL_RESULTS();
        logic h; h=0;
        h |= draw_char("F", 268, 140); h |= draw_char("I", 276, 140); h |= draw_char("N", 284, 140); h |= draw_char("A", 292, 140); h |= draw_char("L", 300, 140);
        h |= draw_char("R", 324, 140); h |= draw_char("E", 332, 140); h |= draw_char("S", 340, 140); h |= draw_char("U", 348, 140); h |= draw_char("L", 356, 140); h |= draw_char("T", 364, 140); h |= draw_char("S", 372, 140);
        return h;
    endfunction

    // "ROUND X : PASS"
    function automatic logic draw_row_result_full(input [2:0] rnd_idx, input pass, input [9:0] py);
        logic h; h=0;
        h |= draw_char("R", 264, py); h |= draw_char("O", 272, py); h |= draw_char("U", 280, py); h |= draw_char("N", 288, py); h |= draw_char("D", 296, py);
        case(rnd_idx)
            0: h |= draw_char("1", 312, py); 1: h |= draw_char("2", 312, py); 2: h |= draw_char("3", 312, py);
            3: h |= draw_char("4", 312, py); 4: h |= draw_char("5", 312, py);
        endcase
        h |= draw_char(":", 328, py);
        
        if(pass) begin
            h |= draw_char("P", 352, py); h |= draw_char("A", 360, py); h |= draw_char("S", 368, py); h |= draw_char("S", 376, py);
        end else begin
            h |= draw_char("F", 352, py); h |= draw_char("A", 360, py); h |= draw_char("I", 368, py); h |= draw_char("L", 376, py);
        end
        return h;
    endfunction

    // "TOTAL SCORE : XXX"
    function automatic logic draw_str_FINAL_SCORE_SUM(input [2:0] sc, input [9:0] py);
        logic h; h=0;
        h |= draw_char("T", 240, py); h |= draw_char("O", 248, py); h |= draw_char("T", 256, py); h |= draw_char("A", 264, py); h |= draw_char("L", 272, py); 
        h |= draw_char("S", 288, py); h |= draw_char("C", 296, py); h |= draw_char("O", 304, py); h |= draw_char("R", 312, py); h |= draw_char("E", 320, py); 
        h |= draw_char(":", 336, py);

        unique case (sc)
            3'd0: begin h |= draw_char("0", 360, py); h |= draw_char("0", 368, py); end
            3'd1: begin h |= draw_char("2", 360, py); h |= draw_char("0", 368, py); end
            3'd2: begin h |= draw_char("4", 360, py); h |= draw_char("0", 368, py); end
            3'd3: begin h |= draw_char("6", 360, py); h |= draw_char("0", 368, py); end
            3'd4: begin h |= draw_char("8", 360, py); h |= draw_char("0", 368, py); end
            3'd5: begin h |= draw_char("1", 352, py); h |= draw_char("0", 360, py); h |= draw_char("0", 368, py); end
        endcase
        return h;
    endfunction

    //==========================================================
    // 🕹️ Main Design Logic
    //==========================================================
    logic box_main_center, box_top_hud, box_instruction;
    logic box_scoreboard; 
    logic box_border_wrap; 
    
    logic border_main_outer, border_main_inner;
    logic border_inst_outer, border_inst_inner;
    logic border_score_outer, border_score_inner; 
    logic scanline_effect;
    
    // Border thickness constants
    localparam TOP_HUD_HEIGHT = 50;
    localparam WRAP_THICKNESS = 8; 

    assign box_main_center  = in_rect(160, 480, 180, 300); 
    assign border_main_outer = on_border_thick(160, 480, 180, 300, 4'd3);
    assign border_main_inner = on_border_thick(163, 477, 183, 297, 4'd3);

    assign box_scoreboard   = in_rect(120, 520, 100, 420);
    assign border_score_outer = on_border_thick(120, 520, 100, 420, 4'd3);
    assign border_score_inner = on_border_thick(123, 517, 103, 417, 4'd3);

    assign box_top_hud      = in_rect(0, 640, 0, TOP_HUD_HEIGHT);

    // Wrapper Border (Left, Right, Bottom)
    assign box_border_wrap  = (x < WRAP_THICKNESS) || (x >= 640 - WRAP_THICKNESS) || (y >= 480 - WRAP_THICKNESS);

    assign box_instruction  = in_rect(180, 460, 210, 270);
    assign border_inst_outer = on_border_thick(180, 460, 210, 270, 4'd3);
    assign border_inst_inner = on_border_thick(183, 457, 213, 267, 4'd3);

    assign scanline_effect = y[1];

    always_comb begin
        overlay_en = 0;
        r = 0; g = 0; b = 0;

        if (DE) begin
            
            // --- 1. Global Border & HUD Background ---
            if (box_top_hud || box_border_wrap) begin
                overlay_en = 1;
                // Neon line at the bottom of the top HUD
                if (box_top_hud && y >= (TOP_HUD_HEIGHT - 3)) begin 
                    r=0; g=C_NEON_CYAN; b=C_NEON_CYAN; 
                end else begin 
                    r=C_HUD_BG; g=C_HUD_BG; b=C_HUD_BG; // Pure Black
                end
            end

            // --- 2. Top Bar Text Logic (Separated for persistence) ---
            if (box_top_hud) begin
                if (fsm_state == 3'b000) begin
                    // State: IDLE -> Show "LET'S PLAY GAME" in Top Bar
                    if (draw_str_LETS_PLAY_HUD()) begin
                        overlay_en = 1; 
                        if (y[3]) begin r=C_NEON_MAGENTA; g=C_WHITE; b=C_NEON_MAGENTA; end
                        else      begin r=C_WHITE; g=C_NEON_CYAN; b=C_NEON_CYAN; end
                    end
                end else begin
                    // State: READY, PLAY, RESULT, SCOREBOARD -> Show Score/Round continuously
                    if (draw_hud_round(round_cnt)) begin
                        overlay_en=1; r=C_NEON_CYAN; g=C_NEON_CYAN; b=C_WHITE;
                    end
                    if (draw_hud_score(score)) begin
                        overlay_en=1; r=C_NEON_YELLOW; g=C_NEON_YELLOW; b=C_WHITE;
                    end
                end
            end

            // --- 3. Main Game State Graphics ---
            unique case (fsm_state)
                // IDLE (000) - Just background (Text handled above)
                3'b000: begin
                    // "LET'S PLAY GAME" is now handled in the HUD block above
                end

                // READY (001) - Center Box "GET READY"
                3'b001: begin
                    if (box_main_center) begin
                        overlay_en = 1;
                        if (border_main_outer)      begin r=0; g=C_NEON_CYAN; b=C_NEON_CYAN; end
                        else if (border_main_inner) begin r=C_NEON_MAGENTA; g=0; b=C_NEON_MAGENTA; end
                        else begin r=C_DARK_BG; g=C_DARK_BG; b=(scanline_effect ? 4'h3 : 4'h5); end
                    end
                    if (draw_str_GET_READY()) begin
                        overlay_en = 1; r=C_NEON_YELLOW; g=C_NEON_YELLOW; b=0;
                    end
                end

                // PLAY (010) - Custom 4-Way Colors
                3'b010: begin
                    if (on_border_thick(170, 190, 125, 145, 4'd4) || 
                        on_border_thick(450, 470, 125, 145, 4'd4) || 
                        on_border_thick(170, 190, 335, 355, 4'd4) || 
                        on_border_thick(450, 470, 335, 355, 4'd4))  
                    begin
                        overlay_en = 1; r = C_WHITE; g = C_WHITE; b = C_WHITE;
                    end
                    else if (box_instruction) begin
                        overlay_en = 1;
                        if (border_inst_outer || border_inst_inner) begin
                            // Region based neon colors (LT, RT, LB, RB)
                            unique case (region)
                                2'd0: begin r=0; g=0; b=C_NEON_BLUE; end         // LT: Blue
                                2'd1: begin r=C_NEON_RED; g=0; b=0; end          // RT: Red
                                2'd2: begin r=C_WHITE; g=C_WHITE; b=C_WHITE; end // LB: White (for Black/Monochrome Neon look)
                                2'd3: begin r=0; g=C_NEON_GREEN; b=0; end        // RB: Green
                            endcase
                        end else begin
                            r=C_DARK_BG; g=C_DARK_BG; b=(scanline_effect ? 4'h2 : 4'h4);
                        end
                    end
                    
                    if (draw_instruction_full(region)) begin
                        overlay_en=1;
                        unique case (region)
                            2'd0: begin r=C_WHITE; g=C_WHITE; b=C_NEON_BLUE; end // Text with Blue tint
                            2'd1: begin r=C_NEON_RED; g=C_WHITE; b=C_WHITE; end  // Text with Red tint
                            2'd2: begin r=C_WHITE; g=C_WHITE; b=C_WHITE; end     // White Text
                            2'd3: begin r=C_WHITE; g=C_NEON_GREEN; b=C_WHITE; end // Text with Green tint
                        endcase
                    end
                end

                // ROUND END (011) - PASS/FAIL Box
                3'b011: begin
                    if (box_main_center) begin
                        overlay_en = 1;
                        if (result_type == 2'b01) begin 
                            if (border_main_outer)      begin r=0; g=C_NEON_GREEN; b=0; end
                            else if (border_main_inner) begin r=C_WHITE; g=C_WHITE; b=C_WHITE; end
                            else begin r=0; g=(scanline_effect ? 4'h4 : 4'h6); b=0; end
                        end else begin 
                            if (border_main_outer)      begin r=C_NEON_RED; g=0; b=0; end
                            else if (border_main_inner) begin r=C_NEON_YELLOW; g=C_NEON_YELLOW; b=0; end
                            else begin r=(scanline_effect ? 4'h4 : 4'h6); g=0; b=0; end
                        end
                    end
                    if (draw_str_RESULT_FULL(result_type)) begin
                        overlay_en = 1;
                        if (result_type == 2'b01) begin r=C_WHITE; g=C_NEON_GREEN; b=C_NEON_GREEN; end
                        else begin r=C_NEON_RED; g=C_WHITE; b=C_NEON_MAGENTA; end
                    end
                end

                // SCOREBOARD (100)
                3'b100: begin
                    if (box_scoreboard) begin
                        overlay_en = 1;
                        if (border_score_outer || border_score_inner) begin
                            r=C_WHITE; g=C_WHITE; b=C_WHITE;
                        end else begin
                            if ((y - 180) % 30 == 0) begin r=0; g=4'h4; b=4'h8; end 
                            else begin r=0; g=0; b=(scanline_effect ? 4'h2 : 4'h4); end
                        end
                    end
                    
                    if (draw_str_FINAL_RESULTS()) begin
                        overlay_en=1; r=C_NEON_YELLOW; g=C_NEON_YELLOW; b=0;
                    end
                    
                    for (int i=0; i<5; i++) begin
                        if (draw_row_result_full(i[2:0], round_result[i], 200 + i*30)) begin
                            overlay_en=1;
                            if(round_result[i]) begin r=0; g=C_NEON_GREEN; b=0; end
                            else begin r=C_NEON_RED; g=0; b=0; end
                        end
                    end

                    if (draw_str_FINAL_SCORE_SUM(score, 380)) begin
                        overlay_en=1; r=C_NEON_CYAN; g=C_NEON_CYAN; b=C_WHITE; 
                    end
                end

                default: begin end
            endcase
        end
    end

endmodule