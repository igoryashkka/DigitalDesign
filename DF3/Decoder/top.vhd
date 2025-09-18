library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


use work.alu_pkg.all; 

entity top_alu is
  generic(
    CLK_FREQ_HZ : integer := 50_000_000;
    BAUD        : integer := 115200
  );
  port(
    clk            : in  std_logic;
    rst_n          : in  std_logic;

    ctrl_mode      : in  std_logic;               -- '0' = buttons, '1' = uart

   
    btn_a_up       : in  std_logic;
    btn_a_down     : in  std_logic;
    btn_b_up       : in  std_logic;
    btn_b_down     : in  std_logic;

    -- UART
   -- uart_rx_i      : in  std_logic;
   -- uart_tx_o      : out std_logic;

    -- sts
    led_zero_o     : out std_logic;
    led_carry_o    : out std_logic;
    led_over_o     : out std_logic;
    led_neg_o      : out std_logic;

    -- PWM RGB
    pwm_r_o        : out std_logic;
    pwm_g_o        : out std_logic;
    pwm_b_o        : out std_logic
  );
end entity;

architecture rtl of top_alu is
  -- Debounced pulses
  signal a_up_p, a_dn_p, b_up_p, b_dn_p : std_logic;

  -- A/B regs 
  signal reg_a, reg_b : unsigned(7 downto 0) := (others=>'0');

  --  A/B btns
  signal btn_a_q, btn_b_q : std_logic_vector(7 downto 0);

  --
  signal op_sel   : op_t := OP_ADD;

--   --  ALU
  signal y_add,y_sub,y_mul,y_shl,y_shr,y_sar : std_logic_vector(15 downto 0);
  signal c_add,v_add,n_add,z_add : std_logic;
  signal c_sub,v_sub,n_sub,z_sub : std_logic;
  signal c_mul,v_mul,n_mul,z_mul : std_logic;
  signal c_shl,v_shl,n_shl,z_shl : std_logic;
  signal c_shr,v_shr,n_shr,z_shr : std_logic;
  signal c_sar,v_sar,n_sar,z_sar : std_logic;

  signal Y          : std_logic_vector(15 downto 0);
  signal C,V,N,Z    : std_logic;

    signal duty_r, duty_g, duty_b : std_logic_vector(7 downto 0);
    
--   -- UART wires
  signal rx_byte    : std_logic_vector(7 downto 0);
  signal rx_valid   : std_logic;
  signal rx_ready   : std_logic := '1';

  signal tx_ready   : std_logic;
  signal tx_start   : std_logic := '0';
  signal tx_byte    : std_logic_vector(7 downto 0) := (others=>'0');

--   -- Parser outputs
   signal p_op       : unsigned(2 downto 0); -- save for compilation
   signal p_a        : unsigned(7 downto 0);
   signal p_b        : unsigned(7 downto 0);
   signal p_stb      : std_logic; -- save for compilation

 begin

--   -- UART
  u_rx: entity work.uart_rx
   generic map(CLK_FREQ_HZ=>CLK_FREQ_HZ, BAUD=>BAUD)
    port map(
     clk=>clk, rst_n=>rst_n, rx_pin=>uart_rx_i,
     rx_data=>rx_byte, rx_data_valid=>rx_valid, rx_data_ready=>rx_ready
    );

  u_tx: entity work.uart_tx
   generic map(CLK_FREQ_HZ=>CLK_FREQ_HZ, BAUD=>BAUD)
    port map(
     clk=>clk, rst_n=>rst_n,
      tx_data=>tx_byte, tx_data_valid=>tx_start, tx_data_ready=>tx_ready,
      tx_pin=>uart_tx_o
    );
  
  process(clk, rst_n) begin
    if rst_n='0' then
      tx_start <= '0';
    elsif rising_edge(clk) then
      tx_start <= '0';
      if rx_valid='1' and tx_ready='1' then
        tx_byte  <= rx_byte;
        tx_start <= '1';
      end if;
    end if;
  end process;

--  alu:<op>:<A>;<B>\n
 u_parser: entity work.uart_alu_parser
   port map(
     clk=>clk, rst_n=>rst_n,
     rx_data=>rx_byte, rx_valid=>rx_valid, rx_ready=>open,
     op_out=>p_op, a_out=>p_a, b_out=>p_b, cmd_stb=>p_stb
    );

--   ----------------------------------------------------------------------------
--   -- Buttons → pulses
  db_aup : entity work.debounce_onepulse generic map(N_SAMPLES=>20000) port map(clk,rst_n,btn_a_up ,a_up_p);
  db_adn : entity work.debounce_onepulse generic map(N_SAMPLES=>20000) port map(clk,rst_n,btn_a_down,a_dn_p);
  db_bup : entity work.debounce_onepulse generic map(N_SAMPLES=>20000) port map(clk,rst_n,btn_b_up ,b_up_p);
  db_bdn : entity work.debounce_onepulse generic map(N_SAMPLES=>20000) port map(clk,rst_n,btn_b_down,b_dn_p);

 
  regA_btn: entity work.updown_byte port map(clk,rst_n,a_up_p,a_dn_p,btn_a_q);
  regB_btn: entity work.updown_byte port map(clk,rst_n,b_up_p,b_dn_p,btn_b_q);


  process(clk, rst_n) begin
    if rst_n='0' then
      reg_a <= (others=>'0');
      reg_b <= (others=>'0');
      op_sel <= OP_ADD;
    elsif rising_edge(clk) then
      if ctrl_mode='0' then

        reg_a <= unsigned(btn_a_q);
        reg_b <= unsigned(btn_b_q);
    
      else
       
        if p_stb='1' then
          case to_integer(p_op) is
            when 0 => op_sel <= OP_ADD;
            when 1 => op_sel <= OP_SUB;
            when 2 => op_sel <= OP_MUL;
            when 3 => op_sel <= OP_SHL;
            when 4 => op_sel <= OP_SHR;
            when 5 => op_sel <= OP_SAR;
            when others => op_sel <= OP_ADD;
          end case;
          reg_a <= p_a;
          reg_b <= p_b; init via uart 
        end if;
      end if;
    end if;
  end process;

--   ----------------------------------------------------------------------------
--   -- ALU operators 
 u_add: entity work.op_add port map(std_logic_vector(reg_a), std_logic_vector(reg_b), y_add,c_add,v_add,n_add,z_add);
 u_sub: entity work.op_sub port map(std_logic_vector(reg_a), std_logic_vector(reg_b), y_sub,c_sub,v_sub,n_sub,z_sub);
 u_mul: entity work.op_mul port map(std_logic_vector(reg_a), std_logic_vector(reg_b), y_mul,c_mul,v_mul,n_mul,z_mul);
-- u_shl: entity work.op_shl port map(std_logic_vector(reg_a), std_logic_vector(reg_b(2 downto 0)), y_shl,c_shl,v_shl,n_shl,z_shl);
-- u_shr: entity work.op_shr port map(std_logic_vector(reg_a), std_logic_vector(reg_b(2 downto 0)), y_shr,c_shr,v_shr,n_shr,z_shr);
-- u_sar: entity work.op_sar port map(std_logic_vector(reg_a), std_logic_vector(reg_b(2 downto 0)), y_sar,c_sar,v_sar,n_sar,z_sar);

  -- ALU MUX 
 u_mux: entity work.alu_mux
   port map(
     sel=>op_sel,
     y_add=>y_add, c_add=>c_add, v_add=>v_add, n_add=>n_add, z_add=>z_add,
     y_sub=>y_sub, c_sub=>c_sub, v_sub=>v_sub, n_sub=>n_sub, z_sub=>z_sub,
     y_mul=>y_mul, c_mul=>c_mul, v_mul=>v_mul, n_mul=>n_mul, z_mul=>z_mul,
     -- ------------------------------------------------------------------ 
     y_shl=>y_shl, c_shl=>c_shl, v_shl=>v_shl, n_shl=>n_shl, z_shl=>z_shl,
     y_shr=>y_shr, c_shr=>c_shr, v_shr=>v_shr, n_shr=>n_shr, z_shr=>z_shr,
     y_sar=>y_sar, c_sar=>c_sar, v_sar=>v_sar, n_sar=>n_sar, z_sar=>z_sar,
     -- ------------------------------------------------------------------
     y=>Y, carry=>C, overflow=>V, negative=>N, zero=>Z
   );

   -- ALU Status
  led_zero_o <= Z; led_carry_o<=C; led_over_o<=V; led_neg_o<=N;

 
  
  duty_r <= std_logic_vector(unsigned(Y(15 downto 8)));  
  duty_g <= std_logic_vector(unsigned(Y(7 downto 0)));   
  duty_b <= std_logic_vector(unsigned(Y(7 downto 0)));        

  -- PWM  --  std_logic_vector(unsigned(Y) / 256); 
 u_pwm_r: entity work.pwm8 port map(clk=>clk, rst_n=>rst_n, duty => duty_r , pwm => pwm_r_o);
 u_pwm_g: entity work.pwm8 port map(clk=>clk, rst_n=>rst_n, duty => duty_g , pwm => pwm_g_o);
 u_pwm_b: entity work.pwm8 port map(clk=>clk, rst_n=>rst_n, duty => duty_b , pwm => pwm_b_o);
end architecture;
