library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity leds is
    Port (
        sys_clk_p : in std_logic;
        sys_clk_n : in std_logic;
        sys_rstn  : in std_logic;
        led       : out std_logic_vector(1 downto 0)
    );
end entity;

architecture rtl of leds is
    signal clk     : std_logic;
    signal cnt     : unsigned(31 downto 0) := (others => '0');
    signal led_r   : std_logic_vector(1 downto 0) := "00";
    signal i       : unsigned(5 downto 0) := (others => '0');
begin

    clk_buffer : IBUFDS
        generic map (
            DIFF_TERM    => false,
            IBUF_LOW_PWR => true ,
            IOSTANDARD   => "DEFAULT"
        )
        port map (
            O  => clk,
            I  => sys_clk_p,
            IB => sys_clk_n
        );

 
    
      process(clk)
    begin
        if rising_edge(clk) then
        if sys_rstn = '0' then
           led_r <= "00";
                cnt <= (others => '0');
            elsif cnt < 199_999_999 then  
                 cnt <= cnt + 1;
              
               
            else
                 cnt <= (others => '0');
                  led_r <= not led_r;
            end if;
        end if;
    end process;

    led <= led_r;

end architecture;
