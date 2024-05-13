module VGA_Controller_FPGA (
  CLK,             // System Clock Input (FPGA)
  RSTN,            // System Reset Signal (FPGA active low)
  VGA_CLK,         // VGA Pixel Clock
  VGA_VS,          // VGA Vertical Sync (vsync) Signal
  VGA_HS,          // VGA Horizontal Sync (hsync) Signal
  VGA_BLANK_N,     // VGA Blank Input
  VGA_SYNC_N,      // VGA Sync Signal
  VGA_R,           // VGA 8-bit Red Input
  VGA_G,           // VGA 8-bit Green Input
  VGA_B            // VGA 8-bit Blue Input
);

input CLK, RSTN;
output VGA_CLK, VGA_SYNC_N;
output reg VGA_VS, VGA_HS, VGA_BLANK_N;
output [7:0] VGA_R, VGA_G, VGA_B;

// If you wanna use 1280 x 1024 resolution you can use such parameter for horizontal (16'd1280, 16'd48, 16'd112, 16'd248)
parameter HD = 16'd600; // Horizontal Resolution (600) 
parameter HFP = 16'd16; // Right border (front porch)
parameter HSP = 16'd96; // Sync Pulse (Re-trace)
parameter HBP = 16'd48; // Left border (back porch)
parameter HPOS_MAX = HD + HFP + HSP + HBP - 1;

// If you wanna use 1280 x 1024 resolution you can use such parameter for vertical (16'd1080, 16'd1, 16'd3, 16'd38)
parameter VD = 16'd480; // Vertical Display (480)
parameter VFP = 16'd10; // Right border (front porch)
parameter VSP = 16'd2;  // Sync pulse (Retrace)
parameter VBP = 16'd33; // Left border (back porch)
parameter VPOS_MAX = VD + VFP + VSP + VBP - 1;

reg clk_div2 = 0; // Internal Register for Divide-by-2 Clock
reg [15:0] hPos = 0; // Register for current Horizontal Position Storage
reg [15:0] vPos = 0; // Register for current Vertical Position Storage
reg hs = 0, vs = 0, de = 0;

// outputs
assign VGA_SYNC_N = 0;
assign VGA_CLK = clk_div2;

// Clock Divided by 2
always @(posedge CLK)
    clk_div2 = ~clk_div2;

// Horizontal and vertical position counters * Changed by GPT
always @(posedge clk_div2) begin
  if (RSTN) begin
    hPos <= 0;
    vPos <= 0;
  end else if (clk_div2 == 1) begin
    if (hPos == HPOS_MAX) begin
      hPos <= 0;
      if (vPos == VPOS_MAX)
        vPos <= 0;
      else
        vPos <= vPos + 1;
      end else
      hPos <= hPos + 1;
  end
end

// Horizontal and vertical sync generation * Changed by GPT
always @(posedge clk_div2, negedge RSTN) begin
  if (!RSTN) begin
    hs <= 1;
    VGA_HS <= 1;
    vs <= 1;
    VGA_VS <= 1;
  end else if (clk_div2 == 1) begin
    hs <= (hPos >= (HD + HFP) && hPos < (HD + HFP + HSP)) ? 0 : 1;
    vs <= (vPos >= (VD + VFP) && vPos < (VD + VFP + VSP)) ? 0 : 1;
    VGA_HS <= hs;
    VGA_VS <= vs;
  end
end

// Display enable and blanking
always @(posedge clk_div2, negedge RSTN) begin
  if (!RSTN) begin
    de <= 0;
    VGA_BLANK_N <= 0;
  end else if (clk_div2 == 1) begin
    de <= (hPos < HD) && (vPos < VD);
    VGA_BLANK_N <= de;
  end
end

// Image ROM
wire [7:0] image_data;
reg [15:0] rom_address;
rom_1_port rom_name (
  .address(rom_address),
  .clock(clk_div2),
  .q(image_data)
);

// Calculate ROM Address for image display
wire display_area;
assign display_area = (hPos >= 192 && hPos < 448 && vPos >= 112 && vPos < 368); // (1280x1024) assign display_area = (hPos >= 512 && hPos < 768 && vPos >= 384 && vPos < 640);
always @(posedge clk_div2) begin
  if (display_area)
    rom_address <= ((vPos - 112) * 256) + (hPos - 192); // (1280x1024) rom_address <= ((vPos - 384) * 256) + (hPos - 512);
  else
    rom_address <= 0;
end

// Assign colors from ROM (RGB332) or default background white
assign VGA_R = display_area ? {image_data[7:5], 5'b00000} : 8'hFF;  // Expand red component to 8 bits
assign VGA_G = display_area ? {image_data[4:2], 5'b00000} : 8'hFF;  // Expand green component to 8 bits
assign VGA_B = display_area ? {image_data[1:0], 6'b000000} : 8'hFF; // Expand blue component to 8 bits

endmodule
