library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_i2c_master is
end tb_i2c_master;

architecture Behavioral of tb_i2c_master is
    component i2c_master
        Generic ( CLK_FREQ_HZ : integer; I2C_BUS_FREQ: integer );
        Port (
            clk : in STD_LOGIC; reset : in STD_LOGIC; start : in STD_LOGIC;
            read_req : in STD_LOGIC; slave_addr : in STD_LOGIC_VECTOR(6 downto 0);
            reg_addr : in STD_LOGIC_VECTOR(7 downto 0); tx_data : in STD_LOGIC_VECTOR(7 downto 0);
            rx_data : out STD_LOGIC_VECTOR(7 downto 0); busy : out STD_LOGIC;
            ack_error : out STD_LOGIC; scl : out STD_LOGIC; sda : inout STD_LOGIC
        );
    end component;

    signal clk : STD_LOGIC := '0';
    signal reset : STD_LOGIC := '1';
    signal start : STD_LOGIC := '0';
    signal read_req : STD_LOGIC := '1';
    signal slave_addr : STD_LOGIC_VECTOR(6 downto 0) := "1001011"; -- ADT7420 (0x4B)
    signal reg_addr : STD_LOGIC_VECTOR(7 downto 0) := x"00";       -- Register Temp MSB
    signal tx_data : STD_LOGIC_VECTOR(7 downto 0) := x"00";
    signal rx_data : STD_LOGIC_VECTOR(7 downto 0);
    signal busy, ack_error, scl : STD_LOGIC;
    signal sda : STD_LOGIC := 'H'; -- Open-drain pull-up simulation

    constant CLK_PERIOD : time := 10 ns;
begin
    -- Instansiasi dengan clock dipercepat agar durasi simulasi singkat
    uut: i2c_master 
        generic map ( CLK_FREQ_HZ => 10_000_000, I2C_BUS_FREQ => 1_000_000 )
        port map (
            clk => clk, reset => reset, start => start, read_req => read_req,
            slave_addr => slave_addr, reg_addr => reg_addr, tx_data => tx_data,
            rx_data => rx_data, busy => busy, ack_error => ack_error, scl => scl, sda => sda
        );

    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    stim_proc: process
    begin
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- Pemicu transaksi I2C Read
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        wait until busy = '0';
        wait for 1 us;
        wait;
    end process;
end Behavioral;