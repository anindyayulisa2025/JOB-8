library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_master is
    Generic (
        CLK_FREQ_HZ : integer := 100_000_000; -- Clock input 100 MHz
        I2C_BUS_FREQ: integer := 100_000      -- Standard mode I2C 100 kHz
    );
    Port (
        clk       : in    STD_LOGIC;
        reset     : in    STD_LOGIC;
        start     : in    STD_LOGIC;
        read_req  : in    STD_LOGIC;                   -- '0' = Write, '1' = Read
        slave_addr: in    STD_LOGIC_VECTOR(6 downto 0);
        reg_addr  : in    STD_LOGIC_VECTOR(7 downto 0);
        tx_data   : in    STD_LOGIC_VECTOR(7 downto 0);
        rx_data   : out   STD_LOGIC_VECTOR(7 downto 0);
        busy      : out   STD_LOGIC;
        ack_error : out   STD_LOGIC;
        scl       : out   STD_LOGIC;
        sda       : inout STD_LOGIC
    );
end i2c_master;

architecture Behavioral of i2c_master is
    type state_type is (
        S_IDLE, S_START, S_ADDR, S_ADDR_ACK, 
        S_REG_ADDR, S_REG_ACK, S_RESTART, S_READ_ADDR, S_READ_ACK,
        S_DATA, S_DATA_ACK, S_STOP
    );
    signal state, next_state : state_type := S_IDLE;

    -- Divider SCL (100 MHz -> 4x I2C Rate = 400 kHz)
    constant CLK_DIV : integer := CLK_FREQ_HZ / (I2C_BUS_FREQ * 4);
    signal clk_cnt   : integer range 0 to CLK_DIV := 0;
    signal i2c_clk_en: std_logic := '0';

    signal scl_clk   : std_logic := '1';
    signal sda_out   : std_logic := '1';
    signal sda_ena   : std_logic := '1';

    signal bit_cnt   : integer range 0 to 7 := 7;
    signal data_tx   : std_logic_vector(7 downto 0) := (others => '0');
    signal data_rx   : std_logic_vector(7 downto 0) := (others => '0');
    signal ack_err   : std_logic := '0';

begin

    -- Pembangkit clock enable untuk kecepatan I2C
    process(clk, reset)
    begin
        if reset = '1' then
            clk_cnt <= 0;
            i2c_clk_en <= '0';
        elsif rising_edge(clk) then
            if clk_cnt = CLK_DIV - 1 then
                clk_cnt <= 0;
                i2c_clk_en <= '1';
            else
                clk_cnt <= clk_cnt + 1;
                i2c_clk_en <= '0';
            end if;
        end if;
    end process;

    -- FSM Utama
    process(clk, reset)
    begin
        if reset = '1' then
            state <= S_IDLE;
            scl_clk <= '1';
            sda_out <= '1';
            sda_ena <= '0';
            busy <= '0';
            bit_cnt <= 7;
            ack_err <= '0';
            rx_data <= (others => '0');
        elsif rising_edge(clk) then
            if i2c_clk_en = '1' then
                case state is
                    when S_IDLE =>
                        busy <= '0';
                        scl_clk <= '1';
                        sda_out <= '1';
                        sda_ena <= '1';
                        if start = '1' then
                            state <= S_START;
                            busy <= '1';
                            ack_err <= '0';
                            data_tx <= slave_addr & '0'; -- Alamat Slave + Write ('0')
                        end if;

                    when S_START =>
                        sda_out <= '0'; -- Kondisi START: SDA turun saat SCL tinggi
                        state <= S_ADDR;
                        bit_cnt <= 7;

                    when S_ADDR =>
                        scl_clk <= '0';
                        sda_out <= data_tx(bit_cnt);
                        sda_ena <= '1';
                        state <= S_ADDR_ACK;

                    when S_ADDR_ACK =>
                        scl_clk <= '1';
                        if bit_cnt > 0 then
                            bit_cnt <= bit_cnt - 1;
                            state <= S_ADDR;
                        else
                            sda_ena <= '0'; -- Lepas SDA untuk membaca ACK dari slave
                            if sda = '1' then ack_err <= '1'; end if;
                            state <= S_REG_ADDR;
                            data_tx <= reg_addr;
                            bit_cnt <= 7;
                        end if;

                    when S_REG_ADDR =>
                        scl_clk <= '0';
                        sda_out <= data_tx(bit_cnt);
                        sda_ena <= '1';
                        state <= S_REG_ACK;

                    when S_REG_ACK =>
                        scl_clk <= '1';
                        if bit_cnt > 0 then
                            bit_cnt <= bit_cnt - 1;
                            state <= S_REG_ADDR;
                        else
                            sda_ena <= '0';
                            if read_req = '1' then
                                state <= S_RESTART;
                            else
                                state <= S_DATA;
                                data_tx <= tx_data;
                                bit_cnt <= 7;
                            end if;
                        end if;

                    when S_RESTART =>
                        scl_clk <= '1';
                        sda_out <= '1';
                        sda_ena <= '1';
                        data_tx <= slave_addr & '1'; -- Alamat Slave + Read ('1')
                        bit_cnt <= 7;
                        state <= S_READ_ADDR;

                    when S_READ_ADDR =>
                        scl_clk <= '0';
                        sda_out <= data_tx(bit_cnt);
                        state <= S_READ_ACK;

                    when S_READ_ACK =>
                        scl_clk <= '1';
                        if bit_cnt > 0 then
                            bit_cnt <= bit_cnt - 1;
                            state <= S_READ_ADDR;
                        else
                            sda_ena <= '0'; -- Lepas SDA untuk menerima data
                            bit_cnt <= 7;
                            state <= S_DATA;
                        end if;

                    when S_DATA =>
                        scl_clk <= '0';
                        if read_req = '1' then
                            data_rx(bit_cnt) <= sda;
                        else
                            sda_out <= data_tx(bit_cnt);
                            sda_ena <= '1';
                        end if;
                        state <= S_DATA_ACK;

                    when S_DATA_ACK =>
                        scl_clk <= '1';
                        if bit_cnt > 0 then
                            bit_cnt <= bit_cnt - 1;
                            state <= S_DATA;
                        else
                            if read_req = '1' then
                                rx_data <= data_rx;
                                sda_out <= '1'; -- NACK untuk akhir pembacaan
                                sda_ena <= '1';
                            end if;
                            state <= S_STOP;
                        end if;

                    when S_STOP =>
                        scl_clk <= '1';
                        sda_out <= '0';
                        sda_ena <= '1';
                        state <= S_IDLE;

                    when others =>
                        state <= S_IDLE;
                end case;
            end if;
        end if;
    end process;

    scl <= scl_clk;
    sda <= sda_out when sda_ena = '1' else 'Z'; -- Tri-state Driver SDA
    ack_error <= ack_err;

end Behavioral;