library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_seg_driver is
    Port (
        clk     : in  STD_LOGIC;
        data_in : in  STD_LOGIC_VECTOR (15 downto 0); -- 4-digit Hex
        seg     : out STD_LOGIC_VECTOR (6 downto 0);
        dp      : out STD_LOGIC;
        an      : out STD_LOGIC_VECTOR (3 downto 0)
    );
end seven_seg_driver;

architecture Behavioral of seven_seg_driver is
    signal refresh_counter : unsigned(19 downto 0) := (others => '0');
    signal active_digit    : unsigned(1 downto 0) := "00";
    signal current_nibble  : std_logic_vector(3 downto 0);

    -- Fungsi konversi Hex ke Segment
    function hex_to_seg(digit : std_logic_vector(3 downto 0)) return STD_LOGIC_VECTOR is
    begin
        case digit is
            when "0000" => return "1000000"; -- 0
            when "0001" => return "1111001"; -- 1
            when "0010" => return "0100100"; -- 2
            when "0011" => return "0110000"; -- 3
            when "0100" => return "0011001"; -- 4
            when "0101" => return "0010010"; -- 5
            when "0110" => return "0000010"; -- 6
            when "0111" => return "1111000"; -- 7
            when "1000" => return "0000000"; -- 8
            when "1001" => return "0010000"; -- 9
            when "1010" => return "0001000"; -- A
            when "1011" => return "0000011"; -- b
            when "1100" => return "1000110"; -- C
            when "1101" => return "0100001"; -- d
            when "1110" => return "0000110"; -- E
            when "1111" => return "0001110"; -- F
            when others => return "1111111";
        end case;
    end function;
begin
    -- Pembagi Clock Multiplexing
    process(clk)
    begin
        if rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;

    active_digit <= refresh_counter(19 downto 18);

    -- Pengatur Anoda dan Pemilihan Nibble Data
    process(active_digit, data_in)
    begin
        case active_digit is
            when "00" =>
                an <= "1110";
                current_nibble <= data_in(3 downto 0);
            when "01" =>
                an <= "1101";
                current_nibble <= data_in(7 downto 4); -- Pastikan sintaks '7 downto 4'
            when "10" =>
                an <= "1011";
                current_nibble <= data_in(11 downto 8);
            when "11" =>
                an <= "0111";
                current_nibble <= data_in(15 downto 12);
            when others =>
                an <= "1111";
                current_nibble <= "0000";
        end case;
    end process;

    seg <= hex_to_seg(current_nibble);
    dp <= '1';
end Behavioral;