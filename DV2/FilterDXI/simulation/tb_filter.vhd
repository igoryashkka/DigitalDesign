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

    TYPE pixel_array  IS ARRAY(0 TO 8) OF std_logic_vector(7 DOWNTO 0);
    TYPE kernel_array IS ARRAY(0 TO 8) OF INTEGER;

    CONSTANT lap1  : kernel_array := (  0, -1,  0,
                                        -1,  4, -1,
                                         0, -1,  0);
    CONSTANT lap2  : kernel_array := ( -1, -1, -1,
                                       -1,  8, -1,
                                       -1, -1, -1);
    CONSTANT gauss : kernel_array := ( 1, 2, 1,
                                       2, 4, 2,
                                       1, 2, 1);
    CONSTANT avg   : kernel_array := ( 1, 1, 1,
                                       1, 1, 1,
                                       1, 1, 1);

    FUNCTION unpack_pixel_bus(data_flat : std_logic_vector(71 DOWNTO 0)) RETURN pixel_array IS
        VARIABLE pixels : pixel_array;
    BEGIN
        FOR i IN 0 TO 8 LOOP
            pixels(i) := data_flat((71 - i*8) DOWNTO (64 - i*8));
        END LOOP;
        RETURN pixels;
    END FUNCTION;

    FUNCTION apply_filter(
        pixels : pixel_array;
        sel    : std_logic_vector(1 DOWNTO 0)
    ) RETURN std_logic_vector IS
        VARIABLE acc    : INTEGER := 0;
        VARIABLE norm   : INTEGER := 1;
        VARIABLE kernel : kernel_array;
        VARIABLE result : INTEGER;
    BEGIN
        CASE sel IS
            WHEN "00" => kernel := lap1;  norm := 1;
            WHEN "01" => kernel := lap2;  norm := 1;
            WHEN "10" => kernel := gauss; norm := 16;
            WHEN OTHERS => kernel := avg;  norm := 9;
        END CASE;

        FOR i IN 0 TO 8 LOOP
            acc := acc + kernel(i) * to_integer(unsigned(pixels(i)));
        END LOOP;

        result := acc / norm;
        IF result < 0 THEN
            result := 0;
        ELSIF result > 255 THEN
            result := 255;
        END IF;

        RETURN std_logic_vector(to_unsigned(result, 8));
    END FUNCTION;

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

            expected := apply_filter(unpack_pixel_bus(test_inputs(i)), test_cfgs(i));

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
