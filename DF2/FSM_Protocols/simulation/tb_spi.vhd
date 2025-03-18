library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tb_spi is
end tb_spi;

architecture Behavioral of tb_spi is

    signal clk, reset, start, cs : std_logic := '0';
    signal inputData             : std_logic_vector(7 downto 0) := (others => '0');
    signal completeTransmit, completeReceive, sck, mosi, miso : std_logic;
    signal dataFromSlave, dataFromMaster : std_logic_vector(7 downto 0);
    
    component spi_master
        generic (N : integer := 8);
        port (
            clk_c                : in  std_logic;
            reset_r              : in  std_logic;
            start_i              : in  std_logic;
            miso_i               : in  std_logic;
            inputData_i          : in  std_logic_vector(N-1 downto 0);
            mosi_o               : out std_logic;
            done_o               : out std_logic;
            outData_o            : out std_logic_vector(N-1 downto 0);
            sck                  : out std_logic
        );
    end component;
    
    component spi_slave
        generic (N : integer := 8);
        port (
            slk_c               : in  std_logic;
            reset_r             : in  std_logic;
            mosi_i              : in  std_logic;
            cs                  : in  std_logic;
            miso_o              : out std_logic;
            done_o  : out std_logic;
            outData_o : out std_logic_vector(N-1 downto 0)
        );
    end component;
    
begin
    
   
    process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;
    
   
    MASTER_INST: spi_master
        generic map (N => 8)
        port map (
            clk_c => clk,
            reset_r => reset,
            start_i => start,
            miso_i => miso,
            inputData_i => inputData,
            mosi_o => mosi,
            done_o => completeTransmit,
            outData_o => dataFromSlave,
            sck => sck
        );
    
    SLAVE_INST: spi_slave
        generic map (N => 8)
        port map (
            slk_c => sck,
            reset_r => reset,
            mosi_i => mosi,
            cs => cs,
            miso_o => miso,
            done_o => completeReceive,
            outData_o => dataFromMaster
        );
    
    
    process
    begin
        
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        cs <= '0';
        wait for 10 ns;
        
        
        start <= '1';
        inputData <= X"EF";
        wait for 10 ns;
        start <= '0';
        
        
        for i in 0 to 7 loop
            wait until rising_edge(clk);
        end loop;
        
        wait;
    end process;
    
end Behavioral;