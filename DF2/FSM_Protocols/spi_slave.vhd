library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity spi_slave is
    generic (N : integer := 8);
    port (
        slk_c               : in  std_logic;
        reset_r             : in  std_logic;
        mosi_i              : in  std_logic;
        cs                  : in  std_logic;
        miso_o              : out std_logic;
        done_o              : out std_logic;
        outData_o           : out std_logic_vector(N-1 downto 0)
    );
end spi_slave;

architecture Behavioral of spi_slave is

    signal lastNumber_o : std_logic;
    signal transientMasterData : std_logic_vector(N-1 downto 0);
    signal bit_count : integer range 0 to N-1 := 0;
begin    
    -- Shift Register 
    process(slk_c, reset_r)
    begin
        if reset_r = '1' then
            transientMasterData <= (others => '0');
        elsif rising_edge(slk_c) then
            if cs = '0' then  
                transientMasterData <= transientMasterData(N-2 downto 0) & mosi_i;
            end if;
        end if;
    end process;
    
    -- Outputs
    miso_o <= transientMasterData(N-1);
    done_o <= lastNumber_o;
    outData_o <= transientMasterData when lastNumber_o = '1' else (others => '0');
    
    -- Bit Counter 
    process(slk_c, reset_r)
    begin
        if reset_r = '1' then
            bit_count <= 0;
        elsif rising_edge(slk_c) then
            if cs = '0' then
                if bit_count = N-1 then
                    bit_count <= 0;
                else
                    bit_count <= bit_count + 1;
                end if;
            else
                bit_count <= 0;
            end if;
        end if;
    end process;
    
    lastNumber_o <= '1' when bit_count = N-1 else '0';
    
end Behavioral;