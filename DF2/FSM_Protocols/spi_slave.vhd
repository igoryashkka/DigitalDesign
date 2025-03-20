library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity spi_slave is
    generic (N : integer := 9);
    port (
        reset_r      : in  std_logic;
        sck          : in  std_logic;
        cs           : in  std_logic;
        mosi_i       : in  std_logic;
        miso_o       : out std_logic;
        outputData_o : out std_logic_vector(N-1 downto 0);
        received_o   : out std_logic
    );
end spi_slave;

architecture Behavioral of spi_slave is
    signal shift_reg  : std_logic_vector(N-1 downto 0);
    signal bit_count  : integer range 0 to N := 0;
    signal received_r : std_logic := '0';

begin

    process(sck, reset_r, cs)
    begin
        if reset_r = '1' then
            shift_reg   <= (others => '0');
            bit_count   <= 0;
            received_r  <= '0';
            outputData_o <= (others => '0'); 
        elsif cs = '1' then
            bit_count   <= 0;
            received_r  <= '0';
        elsif rising_edge(sck) and cs = '0' then
            shift_reg <= shift_reg(N-2 downto 0) & mosi_i;
            bit_count <= bit_count + 1;

            if bit_count = N-1 then
                outputData_o <= shift_reg(N-2 downto 0) & mosi_i;
                received_r   <= '1';
            else
                received_r <= '0';
            end if;
        end if;
    end process;

    miso_o     <= shift_reg(N-1); 
    received_o <= received_r;

end Behavioral;