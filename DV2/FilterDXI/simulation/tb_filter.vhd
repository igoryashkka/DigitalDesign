LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_filter IS
END ENTITY;

ARCHITECTURE sim OF tb_filter IS

    COMPONENT dxi_top
        PORT (
            i_clk           : IN  std_logic;
            i_rstn          : IN  std_logic;
            i_dxi_valid     : IN  std_logic;
            i_dxi_data      : IN  std_logic_vector(71 DOWNTO 0);
            o_dxi_ready     : OUT std_logic;
            i_dxi_out_ready : IN  std_logic;
            o_dxi_out_valid : OUT std_logic;
            o_master_data   : OUT std_logic_vector(7 DOWNTO 0);
            config_select   : IN  std_logic_vector(1 DOWNTO 0)
        );
    END COMPONENT;

    CONSTANT clk_period : TIME := 10 ns;

    SIGNAL clk           : std_logic := '0';
    SIGNAL rstn          : std_logic := '0';
    SIGNAL dxi_valid     : std_logic := '0';
    SIGNAL dxi_data      : std_logic_vector(71 DOWNTO 0) := (OTHERS => '0');
    SIGNAL dxi_ready     : std_logic;
    SIGNAL dxi_out_ready : std_logic := '1';
    SIGNAL dxi_out_valid : std_logic;
    SIGNAL master_data   : std_logic_vector(7 DOWNTO 0);
    SIGNAL config_select : std_logic_vector(1 DOWNTO 0) := "00";


    TYPE result_array IS ARRAY(natural range <>) OF std_logic_vector(7 DOWNTO 0);

    CONSTANT expected_outputs : result_array := (
        x"00",
        x"00",
        x"FF",
        x"A5"
    );

    TYPE input_array  IS ARRAY(natural range <>) OF std_logic_vector(71 DOWNTO 0);
    TYPE config_array IS ARRAY(natural range <>) OF std_logic_vector(1 DOWNTO 0);

    CONSTANT test_inputs : input_array := (
        x"000102030405060708",
        x"080706050403020100",
        x"FFFFFFFFFFFFFFFFFF",
        x"A5A5A5A5A5A5A5A5A5"
    );

    CONSTANT test_cfgs : config_array := (
        "00", "01", "10", "11"
    );

BEGIN

    uut: dxi_top
        PORT MAP (
            i_clk           => clk,
            i_rstn          => rstn,
            i_dxi_valid     => dxi_valid,
            i_dxi_data      => dxi_data,
            o_dxi_ready     => dxi_ready,
            i_dxi_out_ready => dxi_out_ready,
            o_dxi_out_valid => dxi_out_valid,
            o_master_data   => master_data,
            config_select   => config_select
        );

    clk_process : PROCESS
    BEGIN
        WHILE TRUE LOOP
            clk <= '0';
            WAIT FOR clk_period / 2;
            clk <= '1';
            WAIT FOR clk_period / 2;
        END LOOP;
    END PROCESS;

    stim_proc : PROCESS
        VARIABLE expected : std_logic_vector(7 DOWNTO 0);
    BEGIN
        rstn <= '0';
        dxi_valid <= '0';
        WAIT FOR 3 * clk_period;
        rstn <= '1';
        WAIT FOR clk_period;

        FOR i IN test_inputs'RANGE LOOP
            WAIT UNTIL dxi_ready = '1' AND rising_edge(clk);
            dxi_data   <= test_inputs(i);
            config_select <= test_cfgs(i);
            dxi_valid  <= '1';
            WAIT FOR clk_period;
            dxi_valid  <= '0';

            expected := expected_outputs(i);

            WAIT UNTIL dxi_out_valid = '1' AND rising_edge(clk);
            ASSERT master_data = expected
                REPORT "Mismatch on transaction " & integer'image(i)
                SEVERITY ERROR;

            WAIT FOR (i + 1) * clk_period;
        END LOOP;

        WAIT FOR 10 * clk_period;
        ASSERT FALSE REPORT "Simulation finished" SEVERITY NOTE;
        WAIT;
    END PROCESS;

END ARCHITECTURE;
