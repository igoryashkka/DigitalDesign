library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_gpio is
  generic (
    ADDR_WIDTH : positive := 6;
    DATA_WIDTH : positive := 32
  );
  port (
    -- AXI4-Lite
    s_axi_aclk    : in  std_logic;
    s_axi_aresetn : in  std_logic;
    -----------------------------------------------------------
    --- AXI4-Lite Write Address Channel
    -----------------------------------------------------------
    s_axi_awaddr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    s_axi_awvalid : in  std_logic;
    s_axi_awready : out std_logic;
    -----------------------------------------------------------
    --- AXI4-Lite Write Data Channel  
    -----------------------------------------------------------
    s_axi_wdata   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    s_axi_wstrb   : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    s_axi_wvalid  : in  std_logic;
    s_axi_wready  : out std_logic;
    -----------------------------------------------------------
    --- AXI4-Lite Write Response Channel
    -----------------------------------------------------------
    s_axi_bresp   : out std_logic_vector(1 downto 0);
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in  std_logic;
    -----------------------------------------------------------
    --- AXI4-Lite Read Address Channel
    -----------------------------------------------------------
    s_axi_araddr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    s_axi_arvalid : in  std_logic;
    s_axi_arready : out std_logic;
    -----------------------------------------------------------
    --- AXI4-Lite Read Data Channel       
    s_axi_rdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    s_axi_rresp   : out std_logic_vector(1 downto 0);
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in  std_logic;
    -----------------------------------------------------------
    -- Register-file side
    axi_write_fire : out std_logic;
    wr_addr        : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    wr_data        : out std_logic_vector(DATA_WIDTH-1 downto 0);
    wr_strb        : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);

    axi_read_fire  : out std_logic;
    rd_addr        : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    rd_data        : in  std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity;
architecture rtl of axi_gpio is
  constant BYTE_LANES : integer := DATA_WIDTH/8;

  signal address_reg : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others=>'0');
  signal wdata_reg   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'0');
  signal wstrb_reg   : std_logic_vector(BYTE_LANES-1 downto 0) := (others=>'0');

  signal aw_stored   : std_logic := '0';
  signal w_stored    : std_logic := '0';

  signal bresp_reg   : std_logic_vector(1 downto 0) := "00"; -- OKAY


  signal rd_addr_reg  : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others=>'0');
  signal rdata_reg    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'0');
  signal rresp_reg    : std_logic_vector(1 downto 0) := "00";
  signal read_pending : std_logic := '0';  

begin
  ---------------------------------------------------------------
  -- AXI4-Lite output assignments and combinational logic
  ---------------------------------------------------------------
  s_axi_bresp <= bresp_reg;

  s_axi_rdata <= rdata_reg;
  s_axi_rresp <= rresp_reg;

  rd_addr <= rd_addr_reg;

  s_axi_awready <= '1' when (s_axi_bvalid='0' and aw_stored='0') else '0';
  s_axi_wready  <= '1' when (s_axi_bvalid='0' and w_stored='0')  else '0';
  s_axi_arready <= '1' when (s_axi_rvalid='0' and read_pending='0') else '0';
  -----------------------------------------------------------------------               
  -- Register-file side wiring
  wr_addr <= address_reg;
  wr_data <= wdata_reg;
  wr_strb <= wstrb_reg;
  ----------------------------------------------------------------
  process (s_axi_aclk)
    variable aw_hand_shake : boolean;
    variable w_hand_shake  : boolean;
    variable ar_hand_shake : boolean;
    variable r_hand_shake  : boolean;
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn='0' then
        -- write reset
        address_reg    <= (others=>'0');
        wdata_reg      <= (others=>'0');
        wstrb_reg      <= (others=>'0');
        aw_stored      <= '0';
        w_stored       <= '0';
        s_axi_bvalid   <= '0';
        bresp_reg      <= "00";
        axi_write_fire <= '0';

        -- read reset
        rd_addr_reg    <= (others=>'0');
        rdata_reg      <= (others=>'0');
        rresp_reg      <= "00";
        s_axi_rvalid   <= '0';
        read_pending   <= '0';
        axi_read_fire  <= '0';

      else
       -------------------------------------------------------------
       -- Write transaction handling
       -------------------------------------------------------------
        axi_write_fire <= '0';
        -- Handshakes detection
        aw_hand_shake := (s_axi_awvalid='1' and s_axi_awready='1');
        w_hand_shake  := (s_axi_wvalid='1'  and s_axi_wready='1');

        -- Capture AW
        if aw_hand_shake then
          address_reg <= s_axi_awaddr;
          aw_stored   <= '1';
        end if;

        -- Capture W
        if w_hand_shake then
          wdata_reg <= s_axi_wdata;
          wstrb_reg <= s_axi_wstrb;
          w_stored  <= '1';
        end if;
      
        if (aw_stored='1' and w_stored='1' and s_axi_bvalid='0') then
          axi_write_fire <= '1';   -- flag to reg-file
          s_axi_bvalid   <= '1';   -- response pending
          bresp_reg      <= "00";  -- OKAY, 0x00 for OK
          aw_stored      <= '0';   -- clear flag aw
          w_stored       <= '0';   -- clear flag w
        end if;

        if (s_axi_bvalid='1' and s_axi_bready='1') then
          s_axi_bvalid <= '0';
        end if;
        -------------------------------------------------------------   
        -- Read  transaction handling
        -------------------------------------------------------------
        axi_read_fire <= '0';
          -- Handshakes detection
        ar_hand_shake := (s_axi_arvalid='1' and s_axi_arready='1');
        r_hand_shake  := (s_axi_rvalid='1'  and s_axi_rready='1');

        -- Capture AR
        if ar_hand_shake then
          rd_addr_reg  <= s_axi_araddr;
          axi_read_fire <= '1';
          read_pending <= '1';
        end if;

        if (read_pending='1' and s_axi_rvalid='0') then
          rdata_reg     <= rd_data; -- data from reg-file
          s_axi_rvalid  <= '1';     -- response pending
          rresp_reg     <= "00";    -- OKAY, 0x00 for OK
          read_pending  <= '0';     -- clear flag ar
        end if;

        if r_hand_shake then
          s_axi_rvalid <= '0';
        end if;
        
      end if;
    end if;
  end process;

end architecture;
