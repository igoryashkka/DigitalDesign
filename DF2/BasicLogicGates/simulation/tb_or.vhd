library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_orGate is
-- No ports in the test bench
end tb_orGate;

architecture Behavioral of tb_orGate is
    -- Component declaration
    component orGate is
        Port (
            in1    : in  std_logic;
            in2    : in  std_logic;
            result : out std_logic
        );
    end component;

    -- Signals for testing
    signal in1    : std_logic := '0';
    signal in2    : std_logic := '0';
    signal result : std_logic;

begin
    -- Instantiate the OR Gate
    uut: orGate Port Map (
        in1    => in1,
        in2    => in2,
        result => result
    );

    -- Test process
    process
    begin
        in1 <= '0'; in2 <= '0';
        wait for 10 ns;
        in1 <= '0'; in2 <= '1';
        wait for 10 ns;
        in1 <= '1'; in2 <= '0';
        wait for 10 ns;
        in1 <= '1'; in2 <= '1';
        wait for 10 ns;
        wait;
    end process;
end Behavioral;
