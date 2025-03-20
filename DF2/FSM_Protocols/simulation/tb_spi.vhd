library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_spi is
end tb_spi;

architecture Behavioral of tb_spi is

    constant N : integer := 8;

    component spi_master
        generic (N : integer := 8);
        port (
            clk_c       : in  std_logic;
            reset_r     : in  std_logic;
            start_i     : in  std_logic;
            miso_i      : in  std_logic;
            inputData_i : in  std_logic_vector(N-1 downto 0);
            mosi_o      : out std_logic;
            done_o      : out std_logic;
            sck         : out std_logic;
            cs          : out std_logic
        );
    end component;

    component spi_slave
        generic (N : integer := 8);
        port (
            reset_r      : in  std_logic;
            sck          : in  std_logic;
            cs           : in  std_logic;
            mosi_i       : in  std_logic;
            miso_o       : out std_logic;
            outputData_o : out std_logic_vector(N-1 downto 0);
            received_o   : out std_logic
        );
    end component;

    signal clk_c        : std_logic := '0';
    signal reset_r      : std_logic := '0';
    signal start_i      : std_logic := '0';
    signal miso_i       : std_logic := '0'; -- initialized
    signal inputData_i  : std_logic_vector(N-1 downto 0) := "10101010";
    signal mosi_o       : std_logic;
    signal done_o       : std_logic;
    signal sck          : std_logic;
    signal cs           : std_logic;

    signal outputData_o : std_logic_vector(N-1 downto 0) := (others => '0'); -- initialized
    signal received_o   : std_logic := '0'; -- initialized

    constant clk_period : time := 10 ns;

begin

    UUT_Master: spi_master
        generic map(N => N)
        port map(
            clk_c       => clk_c,
            reset_r     => reset_r,
            start_i     => start_i,
            miso_i      => miso_i,
            inputData_i => inputData_i,
            mosi_o      => mosi_o,
            done_o      => done_o,
            sck         => sck,
            cs          => cs
        );

    UUT_Slave: spi_slave
        generic map(N => N)
        port map(
            reset_r      => reset_r,
            sck          => sck,
            cs           => cs,
            mosi_i       => mosi_o,
            miso_o       => miso_i,
            outputData_o => outputData_o,
            received_o   => received_o
        );

    clk_process: process
    begin
        clk_c <= '0';
        wait for clk_period / 2;
        clk_c <= '1';
        wait for clk_period / 2;
    end process;

    stim_proc: process
    begin
        reset_r <= '1';
        wait for 20 ns;
        reset_r <= '0';
        wait for 20 ns;

        start_i <= '1';
        wait for clk_period;
        start_i <= '0';

        wait until done_o = '1';

        wait for 50 ns;
        assert outputData_o = inputData_i report "SPI data mismatch!" severity error;

        wait;
    end process;

end Behavioral;
