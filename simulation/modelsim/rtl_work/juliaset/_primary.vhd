library verilog;
use verilog.vl_types.all;
entity juliaset is
    generic(
        compute_pixel_init: integer := 1;
        compute_pixel_loop: integer := 2;
        draw_pixel      : integer := 7;
        draw_pixel1     : integer := 12;
        draw_pixel2     : integer := 13;
        done            : integer := 14
    );
    port(
        CLOCK_50        : in     vl_logic;
        CLOCK2_50       : in     vl_logic;
        CLOCK3_50       : in     vl_logic;
        KEY             : in     vl_logic_vector(3 downto 0);
        SW              : in     vl_logic_vector(17 downto 0);
        LCD_BLON        : out    vl_logic;
        LCD_DATA        : inout  vl_logic_vector(7 downto 0);
        LCD_EN          : out    vl_logic;
        LCD_ON          : out    vl_logic;
        LCD_RS          : out    vl_logic;
        LCD_RW          : out    vl_logic;
        UART_CTS        : in     vl_logic;
        UART_RTS        : out    vl_logic;
        UART_RXD        : in     vl_logic;
        UART_TXD        : out    vl_logic;
        VGA_B           : out    vl_logic_vector(7 downto 0);
        VGA_BLANK_N     : out    vl_logic;
        VGA_CLK         : out    vl_logic;
        VGA_G           : out    vl_logic_vector(7 downto 0);
        VGA_HS          : out    vl_logic;
        VGA_R           : out    vl_logic_vector(7 downto 0);
        VGA_SYNC_N      : out    vl_logic;
        VGA_VS          : out    vl_logic
    );
end juliaset;
