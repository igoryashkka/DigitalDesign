-- uart_tx.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
  generic(
    CLK_FREQ_HZ : integer := 50_000_000;
    BAUD        : integer := 115200
  );
  port(
    clk           : in  std_logic;
    rst_n         : in  std_logic;
    tx_data       : in  std_logic_vector(7 downto 0);
    tx_data_valid : in  std_logic;              
    tx_data_ready : out std_logic;            
    tx_pin        : out std_logic               
  );
end entity;

architecture rtl of uart_tx is
  constant CYCLE : integer := integer(CLK_FREQ_HZ / BAUD);

  type tx_state_t is (TX_IDLE, TX_START, TX_DATA, TX_STOP);
  signal state, nxt : tx_state_t := TX_IDLE;

  signal bit_idx    : unsigned(2 downto 0) := (others=>'0');
  signal baud_cnt   : unsigned(15 downto 0) := (others=>'0');
  signal shifter    : std_logic_vector(7 downto 0) := (others=>'0');
  signal tx_q       : std_logic := '1';
begin
  tx_pin <= tx_q;

  -- state reg
  process(clk, rst_n) begin
    if rst_n='0' then
      state    <= TX_IDLE;
    elsif rising_edge(clk) then
      state    <= nxt;
    end if;
  end process;

  -- next-state
  process(state, tx_data_valid, baud_cnt, bit_idx) begin
    nxt := state;
    case state is
      when TX_IDLE  =>
        if tx_data_valid='1' then nxt := TX_START; end if;
      when TX_START =>
        if to_integer(baud_cnt)=CYCLE-1 then nxt := TX_DATA; end if;
      when TX_DATA  =>
        if to_integer(baud_cnt)=CYCLE-1 and bit_idx=7 then
          nxt := TX_STOP;
        end if;
      when TX_STOP  =>
        if to_integer(baud_cnt)=CYCLE-1 then nxt := TX_IDLE; end if;
    end case;
  end process;

  -- ready
  tx_data_ready <= '1' when state=TX_IDLE else
                   '1' when (state=TX_STOP and to_integer(baud_cnt)=CYCLE-1) else
                   '0';

  -- data latch
  process(clk, rst_n) begin
    if rst_n='0' then
      shifter <= (others=>'0');
    elsif rising_edge(clk) then
      if state=TX_IDLE and tx_data_valid='1' then
        shifter <= tx_data;
      end if;
    end if;
  end process;

  -- bit index
  process(clk, rst_n) begin
    if rst_n='0' then
      bit_idx <= (others=>'0');
    elsif rising_edge(clk) then
      if state=TX_DATA then
        if to_integer(baud_cnt)=CYCLE-1 then
          bit_idx <= bit_idx + 1;
        end if;
      else
        bit_idx <= (others=>'0');
      end if;
    end if;
  end process;

  -- baud counter
  process(clk, rst_n) begin
    if rst_n='0' then
      baud_cnt <= (others=>'0');
    elsif rising_edge(clk) then
      if (state=TX_DATA and to_integer(baud_cnt)=CYCLE-1) or (state/=nxt) then
        baud_cnt <= (others=>'0');
      else
        baud_cnt <= baud_cnt + 1;
      end if;
    end if;
  end process;

  -- tx line
  process(clk, rst_n) begin
    if rst_n='0' then
      tx_q <= '1';
    elsif rising_edge(clk) then
      case state is
        when TX_IDLE | TX_STOP => tx_q <= '1';
        when TX_START          => tx_q <= '0';
        when TX_DATA           => tx_q <= shifter(to_integer(bit_idx));
      end case;
    end if;
  end process;
end architecture;
