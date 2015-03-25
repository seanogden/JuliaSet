library verilog;
use verilog.vl_types.all;
entity signed_mult is
    port(
        \out\           : out    vl_logic_vector(39 downto 0);
        a               : in     vl_logic_vector(36 downto 0);
        b               : in     vl_logic_vector(36 downto 0)
    );
end signed_mult;
