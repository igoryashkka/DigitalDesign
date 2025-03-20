library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity spi_slave is
    generic (N : integer := 8);
    port (
        clk_c       : in  std_logic;  -- System clock
        reset_r     : in  std_logic;  -- Reset
        sck         : in  std_logic;  -- SPI clock from master
        cs          : in  std_logic;  -- Chip select (active low)
        mosi_i      : in  std_logic;  -- Master out, slave in
        miso_o      : out std_logic;  -- Master in, slave out
        outputData_o: out std_logic_vector(N-1 downto 0);
        received_o  : out std_logic  -- Indicates data reception
    );
end spi_slave;

architecture Behavioral of spi_slave is
    signal shift_reg : std_logic_vector(N-1 downto 0) := (others => '0');
    signal bit_count : integer range 0 to N := 0;
    signal received  : std_logic := '0';
    
begin
    process(sck, reset_r, cs)
    begin
        if reset_r = '1' or cs = '1' then
            shift_reg <= (others => '0');
            bit_count <= 0;
            received  <= '0';
        elsif falling_edge(sck) then
            shift_reg <= shift_reg(N-2 downto 0) & mosi_i;
            if bit_count = N-1 then
                bit_count <= 0;
                received  <= '1';
            else
                bit_count <= bit_count + 1;
                received  <= '0';
            end if;
        end if;
    end process;
    
    miso_o        <= shift_reg(N-1); -- MSB first
    outputData_o  <= shift_reg when received = '1' else (others => '0');
    received_o    <= received;
end Behavioral;
