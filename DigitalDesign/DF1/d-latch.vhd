library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- RS Latch 
entity rs_latch is
port (
    r, s  : in STD_LOGIC;  
    q, qn : out STD_LOGIC  
);
end rs_latch;

architecture synth_rs_latch of rs_latch is
    signal q_internal, qn_internal : STD_LOGIC;
begin
    q_internal <= r nor qn_internal;
    qn_internal <= s nor q_internal;
    
    q <= q_internal;
    qn <= qn_internal;
end synth_rs_latch;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- D Latch 
entity d_latch is

port (
    clk, d : in STD_LOGIC;  
    q, qn : out STD_LOGIC  
);
end d_latch;

architecture synth_d_latch of d_latch is
    signal r, s : STD_LOGIC;
    signal q_internal, qn_internal : STD_LOGIC;
begin
    r <= clk and (not d); 
    s <= clk and d;      

    
    u_rs_latch: entity work.rs_latch
    port map (
        r => r,
        s => s,
        q => q_internal,
        qn => qn_internal
    );

    q <= q_internal;
    qn <= qn_internal;
end synth_d_latch;




-- Top Module 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity top_module is
port (
    clk, d : in STD_LOGIC;  
    r, s   : in STD_LOGIC;  
    q_rs, qn_rs : out STD_LOGIC; 
    q_d, qn_d   : out STD_LOGIC  
);
end top_module;

architecture synth_top_module of top_module is
    signal q_rs_internal, qn_rs_internal : STD_LOGIC;
    signal q_d_internal, qn_d_internal : STD_LOGIC;
begin
    u_rs_latch: entity work.rs_latch
    port map (
        r  => r,
        s  => s,
        q  => q_rs_internal,
        qn => qn_rs_internal
    );

    q_rs <= q_rs_internal;
    qn_rs <= qn_rs_internal;

    u_d_latch: entity work.d_latch
    port map (
        clk => clk,
        d   => d,
        q   => q_d_internal,
        qn  => qn_d_internal
    );

    q_d <= q_d_internal;
    qn_d <= qn_d_internal;
end synth_top_module;
