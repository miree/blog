set term pngcairo 
set output "leading_half.png"

w=4.
A=5.
t0=5.

set samples 1000
set xlabel "t"
set ylabel "y"
set xtics 1
set ytics 1

sig(x,w) = (abs(x)<=w)?(1-abs(x)/w):0/0


set label "(ti=2,yi=1)" at 2,1.5 right

set grid
set key top left
plot[-1:6][-1:9] \
	8*sig(x-5.5,4) lw 4 title "A=8, t0=5.5 (w=4)"   , \
	4*sig(x-5,4) lw 4   title "A=4, t0=5.0 (w=4)"   , \
	2*sig(x-4,4) lw 4   title "A=2, t0=4.0 (w=4)"   , \
	0 lw 1 dt '-' lc black notitle,  \
	4*1/(4+2-x) w l lw 3 lc black dt '-' title "A=w*yi/(w+ti-t0)", \
	"single_sample.dat" using 1:2 w p pt 7 ps 2 lt 7 title "single sampled point"