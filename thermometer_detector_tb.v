`timescale 1ns / 1ps
module thermometer_detector_tb;
    reg [7:0] sw;
    wire [0:0] led;

    integer i;
    reg expected_led;

    top cut (.sw(A),.led(led));

    initial begin

        for (i = 0; i < 256; i = i + 1) begin

            sw = i[7:0];

            expected_led = (i >= 160) && (i <= 184);

            #10;

        end

        $finish;

    end

endmodule