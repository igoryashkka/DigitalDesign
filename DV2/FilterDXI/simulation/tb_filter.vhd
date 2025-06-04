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
    SIGNAL config_select : std_logic_vector(1 DOWNTO 0) := "01"; 

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
        VARIABLE pixels : std_logic_vector(7 DOWNTO 0);
        VARIABLE vector72 : std_logic_vector(71 DOWNTO 0);
    BEGIN
       

        rstn <= '1';
        WAIT FOR clk_period;

       
       vector72 := x"0A0A0A0A1A0A0A0B0B";
       

       
        dxi_valid <= '1';
        dxi_data <= vector72;
        WAIT FOR clk_period;
        WAIT UNTIL dxi_ready = '1' AND rising_edge(clk);
        WAIT FOR clk_period;

    

       
        WAIT UNTIL dxi_out_valid = '1' AND rising_edge(clk);
        WAIT FOR 10 * clk_period;

        WAIT;
    END PROCESS;

END ARCHITECTURE;
