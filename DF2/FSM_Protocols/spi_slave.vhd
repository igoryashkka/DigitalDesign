library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity spi_slave is
    Port ( clk      : in  STD_LOGIC;
           reset    : in  STD_LOGIC;
           MOSI     : in  STD_LOGIC;
           SCK      : in  STD_LOGIC;
           start    : in  STD_LOGIC;
           data_out : out STD_LOGIC_VECTOR(7 downto 0);
           done     : out STD_LOGIC);
end spi_slave;

architecture Behavioral of spi_slave is
    signal bit_count : integer range 0 to 7 := 0;
    signal shift_reg : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal done_reg  : STD_LOGIC := '0';
begin

    process(clk, reset)
    begin
        if reset = '1' then
            bit_count <= 0;
            shift_reg <= (others => '0');
            done_reg  <= '0';
        elsif rising_edge(clk) then
            if start = '1' then
                done_reg <= '0';
                bit_count <= 0;
            end if;

            if rising_edge(SCK) then
                if bit_count < 7 then
                    shift_reg <= shift_reg(6 downto 0) & MOSI;
                    bit_count <= bit_count + 1;
                end if;
                
                if bit_count = 7 then
                    done_reg <= '1';
                end if;
            end if;
        end if;
    end process;
    
    data_out <= shift_reg;
    done <= done_reg;

end Behavioral;
