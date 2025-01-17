library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_mux4to1 is
end tb_mux4to1;


architecture Behavioral of tb_mux4to1 is
    component mux4to1
        Port (
            a   : in  STD_LOGIC;
            b   : in  STD_LOGIC;
            c   : in  STD_LOGIC;
            d   : in  STD_LOGIC;
            sel : in  STD_LOGIC_VECTOR(1 downto 0);
            y   : out STD_LOGIC
        );
    end component;
    signal a, b, c, d : STD_LOGIC := '0';
    signal sel        : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal y          : STD_LOGIC;

begin
    uut: mux4to1
        Port map (
            a   => a,
            b   => b,
            c   => c,
            d   => d,
            sel => sel,
            y   => y
        );
    stim_proc: process
    begin
       
        a <= '1'; b <= '0'; c <= '0'; d <= '0'; sel <= "00";
        wait for 10 ns;
        a <= '0'; b <= '1'; c <= '0'; d <= '0'; sel <= "01";
        wait for 10 ns;
        a <= '0'; b <= '0'; c <= '1'; d <= '0'; sel <= "10";
        wait for 10 ns;
        a <= '0'; b <= '0'; c <= '0'; d <= '1'; sel <= "11";
        wait for 10 ns;       
        a <= '1'; b <= '1'; c <= '1'; d <= '1'; sel <= "00";
        wait for 10 ns;
        wait;
    end process;
end Behavioral;
