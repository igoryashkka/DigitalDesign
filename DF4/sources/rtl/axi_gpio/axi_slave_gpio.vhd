library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_lite_regs_if is
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

    rd_en         : out std_logic;
    rd_addr       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    rd_data       : in  std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of axi_lite_regs_if is
  constant BYTE_LANES : integer := DATA_WIDTH/8;

  signal address_reg : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal wdata_reg  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal wstrb_reg  : std_logic_vector(BYTE_LANES-1 downto 0);

    
  signal aw_stored  : std_logic := '0';
  signal w_stored   : std_logic := '0';


  signal bresp_reg      : std_logic_vector(1 downto 0) := "00"; -- OKAY = "00"
  


  signal araddr_reg : std_logic_vector(ADDR_WIDTH-1 downto 0);


  signal rdata_reg  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'0');
begin


  -------------------------------------------
  -- Write opeartions
  s_axi_bresp <= bresp_reg;

  s_axi_awready <= '1' when (s_axi_bvalid='0' and aw_stored='0') else '0';
  s_axi_wready  <= '1' when (s_axi_bvalid='0' and w_stored='0')  else '0';

  wr_addr <= address_reg;
  wr_data <= wdata_reg;
  wr_strb <= wstrb_reg;

  process (s_axi_aclk)
    -- Write variables channel
    variable aw_hand_shake : boolean;
    variable w_hand_shake  : boolean;
  

    variable ar_hand_shake : boolean;
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn='0' then
        address_reg   <= (others=>'0');
        wdata_reg    <= (others=>'0');
        wstrb_reg    <= (others=>'0');
        araddr_reg   <= (others=>'0');

        aw_stored    <= '0';
        w_stored     <= '0';

        s_axi_bvalid <= '0';
        s_axi_rvalid <= '0';
        rdata_reg    <= (others=>'0');

        axi_write_fire        <= '0';
        rd_en        <= '0';
      else



        ----------------------------------------------------------
        -- Write Address Channel logic 
        ----------------------------------------------------------
        axi_write_fire <= '0';
        aw_hand_shake := (s_axi_awvalid='1' and s_axi_awready='1'); -- for address hs 
        w_hand_shake  := (s_axi_wvalid='1'  and s_axi_wready='1');  -- for data hs

        -- Capture AW
        if aw_hand_shake then
          address_reg <= s_axi_awaddr; -- addrr
          aw_stored  <= '1';
        end if;

        -- Capture W
        if w_hand_shake then
          wdata_reg <= s_axi_wdata;  -- data
          wstrb_reg <= s_axi_wstrb;
          w_stored  <= '1';
        end if;
        ----------------------------------------------------------
        -- Perform write when both captured and no outstanding B
        if (aw_stored='1' and w_stored='1' and s_axi_bvalid='0') then   --  and s_axi_bvalid='0' idk if needed to check bvalid here
          axi_write_fire <= '1';     
          s_axi_bvalid   <= '1';     
          bresp_reg      <= "00";    
          aw_stored      <= '0';
          w_stored       <= '0';
        end if;
        ----------------------------------------------------------
        if (s_axi_bvalid='1' and s_axi_bready='1') then
          s_axi_bvalid    <= '0';
        end if;
       ----------------------------------------------------------

                
        







        
        ar_hand_shake := (s_axi_arvalid='1' and s_axi_arready='1');


       

        -- Read address handshake
        if ar_hand_shake then
          araddr_reg <= s_axi_araddr;
          rd_en      <= '1';       -- 1-cycle pulse
          -- latch rd_data into RDATA on next clock or same clock?
          -- We assume reg-block rd_data is combinational from rd_addr,
          -- but to be safe we sample it in the next lines (same cycle after rd_en pulse)
          rdata_reg  <= rd_data;
          s_axi_rvalid <= '1';
        end if;

        -- Complete read response
        if (s_axi_rvalid='1' and s_axi_rready='1') then
          s_axi_rvalid <= '0';
        end if;

        -- If reg-block read data changes after ar_hand_shake (combinational), you might prefer:
        -- if s_axi_rvalid='1' then rdata_reg <= rd_data; end if;
        -- But for stable register maps, sampling once is typical.
      end if;
    end if;
  end process;
end architecture;
