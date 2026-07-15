LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY tb_counter IS
END tb_counter;

ARCHITECTURE behavior OF tb_counter IS
    COMPONENT counter
        PORT (
            clk_i   : IN  STD_LOGIC;        
            reset_i : IN  STD_LOGIC;        
            enable_i: IN  STD_LOGIC;        
            count_o : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)  
        );
    END COMPONENT;

    SIGNAL clk   : STD_LOGIC := '0';
    SIGNAL reset : STD_LOGIC := '0';
    SIGNAL enable: STD_LOGIC := '0';
    SIGNAL count : STD_LOGIC_VECTOR(2 DOWNTO 0);

    CONSTANT clk_period : TIME := 10 ns;

BEGIN
    uut: counter PORT MAP (
        clk_i   => clk,
        reset_i => reset,
        enable_i=> enable,
        count_o => count
    );

    clk_process: PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR clk_period / 2;
        clk <= '1';
        WAIT FOR clk_period / 2;
    END PROCESS;

    stimulus_process: PROCESS
    BEGIN
        reset <= '1';
        enable <= '0';
        WAIT FOR 20 ns;
        reset <= '0';
        
        enable <= '1';
        WAIT FOR clk_period * 10;

        enable <= '0';
        WAIT FOR clk_period * 5;

        reset <= '1';
        WAIT FOR 20 ns;
        reset <= '0';

        WAIT;
    END PROCESS;
END behavior;
