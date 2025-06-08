

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_andGate is

end tb_andGate;

architecture Behavioral of tb_andGate is
    -- Component declaration
    component andGate is
        Port (
            in1 : in  std_logic;
            in2 : in  std_logic;
            result : out std_logic
        );
    end component;

    -- Signals for testing
    signal in1 : std_logic := '0';
    signal in2 : std_logic := '0';
    signal result    : std_logic;

begin
    -- Instantiate the AND Gate
    uut: andGate Port Map (
        in1 => in1,
        in2 => in2,
        result => result
    );

    -- Test process
    process
    begin
        in1 <= '0'; in2 <= '0';
        wait for 10 ns;
        assert result = '0' report "0 AND 0 should be 0" severity error;

        in1 <= '0'; in2 <= '1';
        wait for 10 ns;
        assert result = '0' report "0 AND 1 should be 0" severity error;

        in1 <= '1'; in2 <= '0';
        wait for 10 ns;
        assert result = '0' report "1 AND 0 should be 0" severity error;

        in1 <= '1'; in2 <= '1';
        wait for 10 ns;
        assert result = '1' report "1 AND 1 should be 1" severity error;

        assert false report "Testbench completed successfully" severity note;
        wait;
    end process;
end Behavioral;
