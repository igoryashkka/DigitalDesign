library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tb_spi is
end tb_spi;

architecture testbench of tb_spi is
    signal clk      : STD_LOGIC := '0';
    signal reset    : STD_LOGIC := '0';
    signal data_in  : STD_LOGIC_VECTOR(7 downto 0);
    signal start    : STD_LOGIC := '0';
    signal MOSI     : STD_LOGIC;
    signal SCK      : STD_LOGIC;
    signal done     : STD_LOGIC;
    signal data_out : STD_LOGIC_VECTOR(7 downto 0);
    signal done_slave : STD_LOGIC;

    constant clk_period : time := 10 ns;

    component spi_master
        Port ( clk      : in  STD_LOGIC;
               reset    : in  STD_LOGIC;
               data_in  : in  STD_LOGIC_VECTOR(7 downto 0);
               start    : in  STD_LOGIC;
               MOSI     : out STD_LOGIC;
               SCK      : out STD_LOGIC;
               done     : out STD_LOGIC);
    end component;

    component spi_slave
        Port ( clk      : in  STD_LOGIC;
               reset    : in  STD_LOGIC;
               MOSI     : in  STD_LOGIC;
               SCK      : in  STD_LOGIC;
               start    : in  STD_LOGIC;
               data_out : out STD_LOGIC_VECTOR(7 downto 0);
               done     : out STD_LOGIC);
    end component;

begin

    UUT_Master: spi_master
        port map (
            clk      => clk,
            reset    => reset,
            data_in  => data_in,
            start    => start,
            MOSI     => MOSI,
            SCK      => SCK,
            done     => done
        );
    
  
    UUT_Slave: spi_slave
        port map (
            clk      => clk,
            reset    => reset,
            MOSI     => MOSI,
            SCK      => SCK,
            start    => start,
            data_out => data_out,
            done     => done_slave
        );

    
    process
    begin
        while true loop
            clk <= not clk;
            wait for clk_period / 2;
        end loop;
    end process;

    
    process
    begin
        
        reset <= '1';
        wait for clk_period;
        reset <= '0';
        wait for clk_period;
        

        data_in <= "10101010";
        start   <= '1';
        wait for clk_period;
       
        wait until done = '1';
        

        --report "Received data in slave: " & integer'image(to_integer(unsigned(data_out)));
        
        wait for clk_period * 5;
    
        data_in <= "11001100";
        start   <= '1';
        wait for clk_period;
        --start   <= '0';
        wait until done = '1';
    
        --report "Received data in slave: " & integer'image(to_integer(unsigned(data_out)));
        
        wait;
    end process;

end testbench;
