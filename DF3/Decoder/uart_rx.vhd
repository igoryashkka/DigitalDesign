-- uart_rx.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
  generic(
    CLK_FREQ_HZ : integer := 50_000_000;
    BAUD        : integer := 115200
  );
  port(
    clk           : in  std_logic;
    rst_n         : in  std_logic;
    rx_pin        : in  std_logic;               -- serial RX
    rx_data       : out std_logic_vector(7 downto 0);
    rx_data_valid : out std_logic;               -- 1 clk pulse when a byte is ready
    rx_data_ready : in  std_logic                -- handshake: drop valid when '1'
  );
end entity;

architecture rtl of uart_rx is
  constant CYCLE : integer := integer(CLK_FREQ_HZ / BAUD);

  type rx_state_t is (RX_IDLE, RX_START, RX_DATA_STATE, RX_STOP, RX_HOLD);
  signal state, nxt : rx_state_t := RX_IDLE;

  -- sync / edge detect
  signal rx_d0, rx_d1 : std_logic := '1';
  signal start_edge   : std_logic;

  signal baud_cnt     : unsigned(15 downto 0) := (others=>'0');
  signal bit_idx      : unsigned(2 downto 0)  := (others=>'0');
  signal sample_mid   : std_logic;
  signal bits         : std_logic_vector(7 downto 0) := (others=>'0');

  signal valid_q      : std_logic := '0';
  signal data_q       : std_logic_vector(7 downto 0) := (others=>'0');
begin
  -- outputs
  rx_data       <= data_q;
  rx_data_valid <= valid_q;

  -- 2FF synchronizer
  process(clk, rst_n) begin
    if rst_n='0' then
      rx_d0 <= '1';
      rx_d1 <= '1';
    elsif rising_edge(clk) then
      rx_d0 <= rx_pin;
      rx_d1 <= rx_d0;
    end if;
  end process;

  -- detect start (falling edge)
  start_edge <= rx_d1 and not rx_d0;

  -- state register
  process(clk, rst_n) begin
    if rst_n='0' then
      state <= RX_IDLE;
    elsif rising_edge(clk) then
      state <= nxt;
    end if;
  end process;

  process(state, start_edge, baud_cnt, bit_idx, rx_data_ready) begin
    nxt <= state;
    case state is
      when RX_IDLE =>
        if start_edge = '1' then
          nxt <= RX_START;
        end if;

      when RX_START =>
        if to_integer(baud_cnt) = CYCLE - 1 then
          nxt <= RX_DATA_STATE;
        end if;

      when RX_DATA_STATE =>
        if (to_integer(baud_cnt) = CYCLE - 1) and
           (bit_idx = to_unsigned(7, bit_idx'length)) then
          nxt <= RX_STOP;
        end if;

      when RX_STOP =>
        if to_integer(baud_cnt) = (CYCLE/2 - 1) then
          nxt <= RX_HOLD;
        end if;

      when RX_HOLD =>
        if rx_data_ready = '1' then
          nxt <= RX_IDLE;
        end if;
    end case;
  end process;

  -- half-bit sample point
  sample_mid <= '1' when to_integer(baud_cnt) = (CYCLE/2 - 1) else '0';

  -- baud counter
  process(clk, rst_n) begin
    if rst_n='0' then
      baud_cnt <= (others=>'0');
    elsif rising_edge(clk) then
      if (state = RX_DATA_STATE and to_integer(baud_cnt) = CYCLE - 1) or (state /= nxt) then
        baud_cnt <= (others=>'0');
      else
        baud_cnt <= baud_cnt + 1;
      end if;
    end if;
  end process;

  -- bit index
  process(clk, rst_n) begin
    if rst_n='0' then
      bit_idx <= (others=>'0');
    elsif rising_edge(clk) then
      if state = RX_DATA_STATE then
        if to_integer(baud_cnt) = CYCLE - 1 then
          bit_idx <= bit_idx + 1;
        end if;
      else
        bit_idx <= (others=>'0');
      end if;
    end if;
  end process;

  
  process(clk, rst_n) begin
    if rst_n='0' then
      bits <= (others=>'0');
    elsif rising_edge(clk) then
      if state = RX_DATA_STATE and sample_mid = '1' then
        bits(to_integer(bit_idx)) <= rx_d1;
      end if;
    end if;
  end process;

  
  process(clk, rst_n) begin
    if rst_n='0' then
      data_q  <= (others=>'0');
      valid_q <= '0';
    elsif rising_edge(clk) then
      if state = RX_STOP and state /= nxt then
        data_q  <= bits;
        valid_q <= '1';
      elsif state = RX_HOLD and rx_data_ready = '1' then
        valid_q <= '0';
      end if;
    end if;
  end process;
end architecture;
