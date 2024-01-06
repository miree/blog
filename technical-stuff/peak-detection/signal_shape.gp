set term pngcairo size 640,240
set output "signal_shape.png"

w=4.
A=5.
t0=5.

set samples 1000
set xlabel "t"
set ylabel "y"
set xtics 1
set ytics 1

sig(x,w) = (abs(x)<=w)?(1-abs(x)/w):0

set arrow from t0,0 to t0,A heads filled lw 4 front
set label "A" at t0+0.5,A/2 

set arrow from t0-w,0 to t0,0   heads filled lw 4 front
set label "w=4" at t0-w/2,0.5

set label "t_0" at t0,A+1 center

plot[t0-2*w:t0+2*w][-0.5:A+2] A*sig(x-t0,w) lw 4 notitle "signal shape"