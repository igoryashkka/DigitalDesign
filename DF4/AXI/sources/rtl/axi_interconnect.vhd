library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_lite_interconnect is
  generic (
    S_COUNT    : positive := 2;   
    M_COUNT    : positive := 2;  
    ADDR_WIDTH : positive := 32;
    DATA_WIDTH : positive := 32;


    M_BASE_ADDR : std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0) :=
      x"40001000" & x"40000000";

    M_ADDR_MASK : std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0) :=
      x"FFFFF000" & x"FFFFF000"
  );
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;

    ----------------------------------------------------------------------------

    s_axi_awaddr  : in  std_logic_vector(S_COUNT*ADDR_WIDTH-1 downto 0);
    s_axi_awvalid : in  std_logic_vector(S_COUNT-1 downto 0);
    s_axi_awready : out std_logic_vector(S_COUNT-1 downto 0);

    s_axi_wdata   : in  std_logic_vector(S_COUNT*DATA_WIDTH-1 downto 0);
    s_axi_wstrb   : in  std_logic_vector(S_COUNT*(DATA_WIDTH/8)-1 downto 0);
    s_axi_wvalid  : in  std_logic_vector(S_COUNT-1 downto 0);
    s_axi_wready  : out std_logic_vector(S_COUNT-1 downto 0);

    s_axi_bresp   : out std_logic_vector(S_COUNT*2-1 downto 0);
    s_axi_bvalid  : out std_logic_vector(S_COUNT-1 downto 0);
    s_axi_bready  : in  std_logic_vector(S_COUNT-1 downto 0);

    s_axi_araddr  : in  std_logic_vector(S_COUNT*ADDR_WIDTH-1 downto 0);
    s_axi_arvalid : in  std_logic_vector(S_COUNT-1 downto 0);
    s_axi_arready : out std_logic_vector(S_COUNT-1 downto 0);

    s_axi_rdata   : out std_logic_vector(S_COUNT*DATA_WIDTH-1 downto 0);
    s_axi_rresp   : out std_logic_vector(S_COUNT*2-1 downto 0);
    s_axi_rvalid  : out std_logic_vector(S_COUNT-1 downto 0);
    s_axi_rready  : in  std_logic_vector(S_COUNT-1 downto 0);

    ----------------------------------------------------------------------------
    m_axi_awaddr  : out std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0);
    m_axi_awvalid : out std_logic_vector(M_COUNT-1 downto 0);
    m_axi_awready : in  std_logic_vector(M_COUNT-1 downto 0);

    m_axi_wdata   : out std_logic_vector(M_COUNT*DATA_WIDTH-1 downto 0);
    m_axi_wstrb   : out std_logic_vector(M_COUNT*(DATA_WIDTH/8)-1 downto 0);
    m_axi_wvalid  : out std_logic_vector(M_COUNT-1 downto 0);
    m_axi_wready  : in  std_logic_vector(M_COUNT-1 downto 0);

    m_axi_bresp   : in  std_logic_vector(M_COUNT*2-1 downto 0);
    m_axi_bvalid  : in  std_logic_vector(M_COUNT-1 downto 0);
    m_axi_bready  : out std_logic_vector(M_COUNT-1 downto 0);

    m_axi_araddr  : out std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0);
    m_axi_arvalid : out std_logic_vector(M_COUNT-1 downto 0);
    m_axi_arready : in  std_logic_vector(M_COUNT-1 downto 0);

    m_axi_rdata   : in  std_logic_vector(M_COUNT*DATA_WIDTH-1 downto 0);
    m_axi_rresp   : in  std_logic_vector(M_COUNT*2-1 downto 0);
    m_axi_rvalid  : in  std_logic_vector(M_COUNT-1 downto 0);
    m_axi_rready  : out std_logic_vector(M_COUNT-1 downto 0)
  );
end entity;

architecture rtl of axi_interconnect is

-- For FSMs signals and types

type t_write_state is (WR_IDLE, WR_ARB, WR_CAPTURE, WR_DECODE, WR_ISSUE, WR_WAIT_B, WR_RESP);
type t_read_state is (RD_IDLE, RD_ARB, RD_CAPTURE, RD_DECODE, RD_ISSUE, RD_WAIT_R, RD_RESP);

signal write_state : t_write_state := WR_IDLE;
signal read_state : t_rd_state := RD_IDLE;


signal wr_granted_idx  : integer range -1 to S_COUNT-1 := -1;
signal rd_granted_idx  : integer range -1 to S_COUNT-1 := -1;




signal wr_target_idx : integer range -1 to M_COUNT-1 := -1;
signal rd_target_idx : integer range -1 to M_COUNT-1 := -1;


signal wr_round_robin_start_ptr : integer range 0 to S_COUNT-1 := 0;
signal rr_rd_ptr : integer range 0 to S_COUNT-1 := 0;

signal wr_awaddr_reg : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
signal wr_wdata_reg  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal wr_wstrb_reg  : std_logic_vector((DATA_WIDTH/8)-1 downto 0) := (others => '0');
signal wr_aw_seen    : std_logic := '0';
signal wr_w_seen     : std_logic := '0';

signal rd_araddr_reg : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');


signal wr_bresp_reg  : std_logic_vector(1 downto 0) := AXI_RESP_OKAY;
signal rd_rdata_reg  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal rd_rresp_reg  : std_logic_vector(1 downto 0) := AXI_RESP_OKAY;


begin


process(clk)
  variable write_request_found : boolean;
  variable current_idx_interface   : integer;
begin
  if rising_edge(clk) then
    if rst_n = '0' then
      write_state      <= WR_IDLE;
      wr_granted_idx  <= -1;

      wr_target_idx <= -1;

      wr_round_robin_start_ptr     <= 0;
      wr_aw_seen    <= '0';
      wr_w_seen     <= '0';
      wr_bresp_reg  <= AXI_RESP_OKAY;

    else
      case write_state is

        when WR_IDLE =>
          wr_aw_seen    <= '0';
          wr_w_seen     <= '0';
          wr_granted_idx  <= -1;
          wr_target_idx <= -1;

          write_state      <= WR_ARB;

        when WR_ARB =>
          write_request_found := false;

          for k in 0 to S_COUNT-1 loop

            current_idx_interface := (wr_round_robin_start_ptr + k) mod S_COUNT;

            if get_bit(s_axi_awvalid, current_idx_interface) = '1' or get_bit(s_axi_wvalid, current_idx_interface) = '1' then
              wr_granted_idx <= current_idx_interface;
              wr_round_robin_start_ptr <= (current_idx_interface + 1) mod S_COUNT;
              write_request_found := true;
              exit;
            end if;

          end loop;

          if write_request_found then
            write_state <= WR_CAPTURE;
          end if;

        when WR_CAPTURE =>
          if wr_granted_idx /= -1 then
            if get_bit(s_axi_awvalid, wr_granted_idx) = '1' and wr_aw_seen = '0' then
              wr_awaddr_reg <= get_addr(s_axi_awaddr, wr_granted_idx, ADDR_WIDTH);
              wr_aw_seen    <= '1';
            end if;

            if get_bit(s_axi_wvalid, wr_granted_idx) = '1' and wr_w_seen = '0' then
              wr_wdata_reg <= get_data(s_axi_wdata, wr_granted_idx, DATA_WIDTH);
              wr_wstrb_reg <= get_strb(s_axi_wstrb, wr_granted_idx, DATA_WIDTH/8);
              wr_w_seen    <= '1';
            end if;

            if wr_aw_seen = '1' and wr_w_seen = '1' then
              write_state <= WR_DECODE;
            end if;
          else
            write_state <= WR_IDLE;
          end if;

        when WR_DECODE =>
          wr_target_idx <= decode_slave_idx(
            wr_awaddr_reg,
            M_BASE_ADDR,
            M_ADDR_MASK,
            M_COUNT,
            ADDR_WIDTH
          );

          if decode_slave_idx(wr_awaddr_reg, M_BASE_ADDR, M_ADDR_MASK, M_COUNT, ADDR_WIDTH) = -1 then
            wr_bresp_reg <= AXI_RESP_DECERR;
            write_state     <= WR_RESP;
          else
            write_state <= WR_ISSUE;
          end if;

        when WR_ISSUE =>

        when WR_RESP =>
          if wr_granted_idx /= -1 then
            if get_bit(s_axi_bready, wr_granted_idx) = '1' then
              write_state <= WR_IDLE;
            end if;
          else
            write_state <= WR_IDLE;
          end if;

      end case;
    end if;
  end if;
end process;



 
  function decode_slave_idx(
    addr      : std_logic_vector;
    base_addr : std_logic_vector;
    addr_mask : std_logic_vector;
    m_count   : integer;
    addr_width: integer
  ) return integer is
    variable idx : integer := -1;
    variable found : boolean := false;
    variable addr_u      : std_logic_vector(addr_width-1 downto 0);
    variable base_u      : std_logic_vector(addr_width-1 downto 0);
    variable mask_u      : std_logic_vector(addr_width-1 downto 0);
  begin
    addr_u := addr(addr_width-1 downto 0);
    for i in 0 to m_count-1 loop
      base_u := base_addr((i+1)*addr_width-1 downto i*addr_width);
      mask_u := addr_mask((i+1)*addr_width-1 downto i*addr_width);
      if (addr_u and mask_u) = (base_u and mask_u) then
        idx := i;
        found := true;
        exit;
      end if;
    end loop;
    return idx;
    
  end function;

end architecture;