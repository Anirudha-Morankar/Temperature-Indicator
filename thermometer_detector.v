module thermometer_detector(
    input [7:0] A,
    output [0:0] led
);

    assign led[0] = A[7] & ~A[6] & A[5] &(~A[4] |~A[3] |(~A[2] & ~A[1] & ~A[0]));

endmodule