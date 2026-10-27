library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity js08_top is
    Port (
        clk  : in    STD_LOGIC;                   -- 100 MHz Basys 3
        btnC : in    STD_LOGIC;                   -- Reset
        scl  : out   STD_LOGIC;                   -- Pmod JA Pin 1 (SCL)
        sda  : inout STD_LOGIC;                   -- Pmod JA Pin 2 (SDA)
        seg  : out   STD_LOGIC_VECTOR (6 downto 0);
        dp   : out   STD_LOGIC;
        an   : out   STD_LOGIC_VECTOR (3 downto 0)
    );
end js08_top;

architecture Behavioral of js08_top is
    signal rx_temp : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal display_data : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal start_trig : STD_LOGIC := '0';
    signal busy_sig : STD_LOGIC;
    signal timer_cnt : integer range 0 to 100_000_000 := 0;

begin

    -- Instance Master I2C
    u_i2c : entity work.i2c_master
        generic map ( CLK_FREQ_HZ => 100_000_000, I2C_BUS_FREQ => 100_000 )
        port map (
            clk => clk, reset => btnC, start => start_trig, read_req => '1',
            slave_addr => "1001011", reg_addr => x"00", tx_data => x"00",
            rx_data => rx_temp, busy => busy_sig, ack_error => open,
            scl => scl, sda => sda
        );

    -- Instance 7-Segment Driver
    u_display : entity work.seven_seg_driver
        port map ( clk => clk, data_in => display_data, seg => seg, dp => dp, an => an );

    -- Timer untuk pembacaan berkala (Setiap 1 Detik)
    process(clk, btnC)
    begin
        if btnC = '1' then
            timer_cnt <= 0;
            start_trig <= '0';
            display_data <= x"0000";
        elsif rising_edge(clk) then
            if timer_cnt = 100_000_000 - 1 then
                timer_cnt <= 0;
                start_trig <= '1';
            else
                timer_cnt <= timer_cnt + 1;
                start_trig <= '0';
            end if;

            display_data <= x"00" & rx_temp; -- Menampilkan pembacaan data suhu
        end if;
    end process;

end Behavioral;