library ieee;
use ieee.std_logic_1164.all;

entity thermometer_detector is
    port (
        A   : in  std_logic_vector(7 downto 0);
        led : out std_logic
    );
end entity thermometer_detector;

architecture rtl of thermometer_detector is
begin

    led <= A(7) and (not A(6)) and A(5) and ( (not A(4)) or (not A(3)) or
             ((not A(2)) and (not A(1)) and (not A(0))) );

end architecture rtl;