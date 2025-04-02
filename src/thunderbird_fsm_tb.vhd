--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
        port(
            i_left    :   in std_logic;
            i_right   :   in std_logic;
            i_reset   :   in std_logic;
            i_clk     :   in std_logic;
            o_lights_L:   out std_logic_vector(2 downto 0);
            o_lights_R:   out std_logic_vector(2 downto 0)
            );
	end component thunderbird_fsm;

	-- test I/O signals
	   signal w_left   : std_logic := '0';
	   signal w_right  : std_logic := '0';
	   signal w_clk    : std_logic := '0';
	   signal w_reset  : std_logic := '0';
	   
	   signal w_lights_L : std_logic_vector(2 downto 0) := "000"; -- LC LB LA One hot
	   signal w_lights_R : std_logic_vector(2 downto 0) := "000"; -- RA RB RC One Hot

	-- constants
	   constant k_clk_period : time := 10 ns;
	
	
begin
	-- PORT MAPS ----------------------------------------
	uut: thunderbird_fsm port map (
	   i_left => w_left,
	   i_right => w_right,
	   i_clk => w_clk,
	   i_reset => w_reset,
	   o_lights_L(2) => w_lights_L(2), --LC
	   o_lights_L(1) => w_lights_L(1), --LB
	   o_lights_L(0) => w_lights_L(0), --LA
	   o_lights_R(2) => w_lights_R(2), --RA
	   o_lights_R(1) => w_lights_R(1), --RB
	   o_lights_R(0) => w_lights_R(0)  --RC
	   );
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    clk_proc : process
    begin
        w_clk <= '0';
        wait for k_clk_period/2;
        w_clk <= '1';
        wait for k_clk_period/2;
    end process;
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	sim_proc : process
	begin
	   w_reset <= '1';
	   wait until falling_edge(w_clk);
	   wait for k_clk_period;
	       assert w_lights_L = "000" report "bad reset" severity error;
	       assert w_lights_R = "000" report "bad reset" severity error;
	   w_reset <= '0';
	   wait for k_clk_period;
	   
-- Right 
        w_right <= '0';
        wait for k_clk_period;
        assert w_lights_R = "000" report "no right blinkers on" severity error;
        
-- right blinker button input pressed
        w_right <= '1';
        wait for k_clk_period;
                
        assert w_lights_R = "001" report "RA should be lit" severity error;
        wait for k_clk_period; -- RA stays on
        
        assert w_lights_R = "011" report "RA RB should be lit" severity error;
        wait for k_clk_period; -- RA RB stays on
        
        assert w_lights_R = "111" report "RA RB RC should be lit" severity error;
        wait for k_clk_period;
        
        assert w_lights_R = "000" report "RA RB RC should be off" severity error;
        wait for k_clk_period;
        
        w_right <= '0';
        wait for k_clk_period;
        
-- Left
        w_left <= '0';
        wait for k_clk_period;
        assert w_lights_L = "000" report "no left blinkers on" severity error;

-- left blinker button input pressed
        w_left <= '1';
        wait for k_clk_period;
        assert w_lights_L = "001" report "LA should be lit" severity error;
--         LA stays on
        
        assert w_lights_L = "011" report "LA LB should be lit" severity error;
        wait for k_clk_period; -- LA LB stays on
        
        assert w_lights_L = "111" report "LA LB should be lit" severity error;
        wait until rising_edge(w_clk);
        wait for k_clk_period*2;
        
        assert w_lights_L = "000" report "LA LB LC should be off" severity error;
        wait for k_clk_period;
        
        w_left <= '0';
        wait for k_clk_period;
        
-- Hazard Lights
        
        w_left <= '1'; w_right <= '1';
        wait until rising_edge(w_clk);
        assert w_lights_L = "111" report "both sides on" severity error;
        assert w_lights_R = "111" report "both sides on1" severity error;
        wait until rising_edge(w_clk);
        
        w_left <= '0'; w_right <= '0';
        wait until rising_edge(w_clk);
        assert w_lights_L = "000" report "both sides off" severity error;
        assert w_lights_R = "000" report "both sides off1" severity error;
        wait until rising_edge(w_clk);

        w_left <= '1'; w_right <= '1';
        wait until rising_edge(w_clk);
        assert w_lights_L = "111" report "both sides on" severity error;
        assert w_lights_R = "111" report "both sides on1" severity error;

        w_left <= '0'; w_right <= '0';
        wait until rising_edge(w_clk);
        assert w_lights_L = "000" report "both sides off" severity error;
        assert w_lights_R = "000" report "both sides off1" severity error;
        wait until rising_edge(w_clk);
        
        wait;        
	end process;
	-----------------------------------------------------	
	
end test_bench;
