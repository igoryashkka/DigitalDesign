library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tb_SequenceDetector is
end tb_SequenceDetector;

architecture testbench of tb_SequenceDetector is
    signal clk      : STD_LOGIC := '0';
    signal reset    : STD_LOGIC := '0';
    signal in_bit   : STD_LOGIC := '0';
    signal detected : STD_LOGIC;
    
    constant clk_period : time := 10 ns;
    
    component SequenceDetector
        Port (
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            in_bit   : in  STD_LOGIC;
            detected : out STD_LOGIC
        );
    end component;
    
begin
    
    uut: SequenceDetector
        port map (
            clk      => clk,
            reset    => reset,
            in_bit   => in_bit,
            detected => detected
        );
    
    process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;
    
    process
    begin
        reset <= '1';
        wait for clk_period;
        reset <= '0';
        wait for clk_period;
        
        in_bit <= '1'; wait for clk_period;
        in_bit <= '0'; wait for clk_period;
        in_bit <= '1'; wait for clk_period;
        in_bit <= '1'; wait for clk_period;
        
        in_bit <= '0'; wait for clk_period;
        in_bit <= '1'; wait for clk_period;
        in_bit <= '0'; wait for clk_period;
        in_bit <= '0'; wait for clk_period;
        in_bit <= '1'; wait for clk_period;
        
        wait;
    end process;
    
end testbench;
