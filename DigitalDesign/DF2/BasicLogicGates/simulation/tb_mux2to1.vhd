library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_mux2to1 is
end tb_mux2to1;

architecture Behavioral of tb_mux2to1 is
    component mux2to1 is
        Port (
            a,b,sel    : in  std_logic;
            y : out std_logic
        );
    end component;

    signal a,b,sel,y    : std_logic := '0';
begin
    uut: mux2to1 Port Map (
        a   => a,
        b   => b,
        sel => sel,
        y => y
    );

    process
    begin
        a <= '0'; b <= '0'; sel <= '0';
        wait for 10 ns;
        a <= '0'; b <= '0'; sel <= '1';
        wait for 10 ns;
        a <= '0'; b <= '1'; sel <= '0';
        wait for 10 ns;
        a <= '0'; b <= '1'; sel <= '1';
        wait for 10 ns;
        a <= '1'; b <= '0'; sel <= '1';
        wait for 10 ns;
        a <= '1'; b <= '0'; sel <= '0';
        wait for 10 ns;
        wait;
    end process;
end Behavioral;
