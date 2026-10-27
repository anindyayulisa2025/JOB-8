library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_bram_1024x8 is
-- Testbench tidak memiliki port eksternal
end tb_bram_1024x8;

architecture Behavioral of tb_bram_1024x8 is
    component bram_1024x8
        Port (
            clk  : in  STD_LOGIC;
            we   : in  STD_LOGIC;
            addr : in  STD_LOGIC_VECTOR (9 downto 0);
            din  : in  STD_LOGIC_VECTOR (7 downto 0);
            dout : out STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;

    signal clk  : STD_LOGIC := '0';
    signal we   : STD_LOGIC := '0';
    signal addr : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
    signal din  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal dout : STD_LOGIC_VECTOR(7 downto 0);

    constant CLK_PERIOD : time := 10 ns; -- Clock 100 MHz
begin
    uut: bram_1024x8 port map (
        clk  => clk,
        we   => we,
        addr => addr,
        din  => din,
        dout => dout
    );

    -- Pembangkit Clock
    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Proses Stimulus Pengujian
    stim_proc: process
    begin
        wait for CLK_PERIOD*2;

        -- Operasi Penulisan ke Alamat Awal, Tengah, dan Ujung (Max 1023 / 0x3FF)
        we <= '1';
        addr <= "00" & x"0A"; din <= x"AB"; wait for CLK_PERIOD; -- Alamat 10 (0x00A)
        addr <= "01" & x"FF"; din <= x"CD"; wait for CLK_PERIOD; -- Alamat 511 (0x1FF)
        addr <= "11" & x"FF"; din <= x"EF"; wait for CLK_PERIOD; -- Alamat 1023 (0x3FF)

        -- Nonaktifkan Write Enable
        we <= '0';
        addr <= (others => '0'); wait for CLK_PERIOD;

        -- Pembacaan dan Verifikasi Data
        addr <= "00" & x"0A"; wait for CLK_PERIOD * 2;
        assert (dout = x"AB") report "GAGAL: Alamat 0x00A tidak sesuai!" severity error;

        addr <= "01" & x"FF"; wait for CLK_PERIOD * 2;
        assert (dout = x"CD") report "GAGAL: Alamat 0x1FF tidak sesuai!" severity error;

        addr <= "11" & x"FF"; wait for CLK_PERIOD * 2;
        assert (dout = x"EF") report "GAGAL: Alamat 0x3FF tidak sesuai!" severity error;

        report "SUKSES: Seluruh verifikasi pembacaan memori BRAM 1024x8 berhasil!";
        wait;
    end process;
end Behavioral;