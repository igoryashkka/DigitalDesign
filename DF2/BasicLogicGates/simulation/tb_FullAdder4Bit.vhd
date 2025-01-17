library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_FullAdder4Bit is
end tb_FullAdder4Bit;

architecture Behavioral of tb_FullAdder4Bit is
    component FullAdder4Bit
        Port (
            A      : in  STD_LOGIC_VECTOR(3 downto 0);
            B      : in  STD_LOGIC_VECTOR(3 downto 0);
            Cin    : in  STD_LOGIC;
            Sum    : out STD_LOGIC_VECTOR(3 downto 0);
            Cout   : out STD_LOGIC
        );
    end component;

    signal A, B    : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal Cin     : STD_LOGIC := '0';
    signal Sum     : STD_LOGIC_VECTOR(3 downto 0);
    signal Cout    : STD_LOGIC;

begin
    uut: FullAdder4Bit
        Port map (
            A => A,
            B => B,
            Cin => Cin,
            Sum => Sum,
            Cout => Cout
        );


    process
    begin
        A <= "0001"; B <= "0010"; Cin <= '0'; wait for 10 ns;  -- 1 + 2 = 3
        A <= "1110"; B <= "0001"; Cin <= '0'; wait for 10 ns;  -- E + 1 = F
        A <= "0110"; B <= "0111"; Cin <= '1'; wait for 10 ns;  -- 6 + 7 = D + carry
        A <= "1001"; B <= "0010"; Cin <= '1'; wait for 10 ns;  -- 9 + 2 = B + carry
        wait; 
    end process;
end Behavioral;
