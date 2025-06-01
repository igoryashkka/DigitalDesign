LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY dxi_top IS
    PORT (
        i_clk          : IN  std_logic;
        i_rstn         : IN  std_logic;
        i_dxi_valid    : IN  std_logic; -- Master gives us to indicate that data is valid
        i_dxi_data     : IN  std_logic_vector(31 DOWNTO 0);
        o_dxi_ready    : OUT std_logic;

        i_master_ready : IN  std_logic;
        o_master_valid : OUT std_logic;
        o_master_data  : OUT std_logic_vector(39 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF dxi_top IS

    SIGNAL ready_reg     : std_logic := '0';
    SIGNAL valid_reg     : std_logic := '0';
    SIGNAL data_reg      : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL comb_out      : std_logic_vector(39 DOWNTO 0) := (OTHERS => '0');

BEGIN

    slave_process : PROCESS(i_clk)
    BEGIN
        IF RISING_EDGE(i_clk) THEN
            IF i_rstn = '0' THEN
                ready_reg <= '0';
                valid_reg <= '0';
                data_reg  <= (OTHERS => '0');
            ELSIF i_dxi_valid = '1' THEN
                ready_reg <= '1';
                valid_reg <= '1';
                data_reg  <= i_dxi_data;
            ELSE
                ready_reg <= '0';
                valid_reg <= '0';
            END IF;
        END IF;
    END PROCESS;

    o_dxi_ready <= ready_reg;

    comb_block : PROCESS(data_reg)
        VARIABLE v_temp : unsigned(39 DOWNTO 0);
    BEGIN
        v_temp := (OTHERS => '0');
        v_temp := v_temp +
                  (TO_UNSIGNED(3, 8) * unsigned(data_reg(7 DOWNTO 0))) +
                  (TO_UNSIGNED(5, 8) * unsigned(data_reg(15 DOWNTO 8))) +
                  (TO_UNSIGNED(7, 8) * unsigned(data_reg(23 DOWNTO 16))) +
                  (TO_UNSIGNED(11, 8) * unsigned(data_reg(31 DOWNTO 24)));
        comb_out <= std_logic_vector(v_temp);
    END PROCESS;

    master_process : PROCESS(i_clk)
    BEGIN
        IF RISING_EDGE(i_clk) THEN
            IF i_rstn = '0' THEN
                o_master_valid <= '0';
                o_master_data  <= (OTHERS => '0');
            ELSIF valid_reg = '1' AND i_master_ready = '1' THEN
                o_master_valid <= '1';
                o_master_data  <= comb_out;
            ELSE
                o_master_valid <= '0';
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE;
