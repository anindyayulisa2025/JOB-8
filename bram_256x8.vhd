library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bram_1024x8 is
    Port ( 
        clk  : in  STD_LOGIC;
        we   : in  STD_LOGIC;                       -- Write Enable
        addr : in  STD_LOGIC_VECTOR (9 downto 0);  -- 10-bit alamat (1024 lokasi)
        din  : in  STD_LOGIC_VECTOR (7 downto 0);  -- Data input 8-bit
        dout : out STD_LOGIC_VECTOR (7 downto 0)   -- Data output 8-bit
    );
end bram_1024x8;

architecture Behavioral of bram_1024x8 is
    -- Definisi array memori 1024 x 8 bit
    type ram_type is array (0 to 1023) of STD_LOGIC_VECTOR(7 downto 0);
    signal ram : ram_type := (others => (others => '0'));
    signal dout_reg : STD_LOGIC_VECTOR(7 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(to_integer(unsigned(addr))) <= din;
            end if;
            -- Registered Output: Kunci utama Vivado memetakan rancangan ke Block RAM fisik (BRAM)
            dout_reg <= ram(to_integer(unsigned(addr))); 
        end if;
    end process;

    dout <= dout_reg;
end Behavioral;