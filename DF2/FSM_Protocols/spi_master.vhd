library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity spi_master is
    Port ( clk      : in  STD_LOGIC;
           reset    : in  STD_LOGIC;
           data_in  : in  STD_LOGIC_VECTOR(7 downto 0);
           start    : in  STD_LOGIC;
           MOSI     : out STD_LOGIC;
           SCK      : out STD_LOGIC;
           done     : out STD_LOGIC);
end spi_master;

architecture Behavioral of spi_master is
    signal bit_count : integer range 0 to 7 := 0;   
    signal shift_reg : STD_LOGIC_VECTOR(7 downto 0); 
    signal SCK_reg   : STD_LOGIC := '0';            
    signal done_reg  : STD_LOGIC := '0';            
begin

    
    process(clk, reset)
    begin
        if reset = '1' then
            bit_count <= 0;
            shift_reg <= (others => '0');
            MOSI <= '0';
            SCK_reg <= '0';
            done_reg <= '0';
        elsif rising_edge(clk) then
            if start = '1' and bit_count = 0 then              
                shift_reg <= data_in;
                done_reg <= '0'; 
            end if;

            if bit_count < 7 then
               
                MOSI <= shift_reg(7);  
                shift_reg <= shift_reg(6 downto 0) & '0'; 
             
                SCK_reg <= not SCK_reg;  

                if SCK_reg = '1' then
                    
                    bit_count <= bit_count + 1;
                end if;
            else
                done_reg <= '1';  
            end if;
        end if;
    end process;

    
    SCK <= SCK_reg;
    done <= done_reg;

end Behavioral;
