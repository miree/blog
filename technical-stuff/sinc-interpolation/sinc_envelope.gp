set term pngcairo
set output "sinc_envelope.png"

set grid
set samples 1000
set xtics 1
sinc(x) = (x!=0)?(sin(pi*x)/(pi*x)):1

envelope(x,max)=(x<max/2.0)?(1.0):(x>max)?0:(cos(pi*(x/max-0.5)))


set multiplot layout 2,1

set ytics 0.5
plot[-1:15][-0.3:1.1] \
	envelope(x,10) lw 3 lt 7 title "envelope" ,\
	sinc(x)                lw 4 lt 6 title "sinc(t)",\
	sinc(x)*envelope(x,10) lw 2 lt 3 lc black title "sinc*envelope"

set ytics 0.2
set key bottom right
plot[0.5:3.5][-0.25:0.25] \
	sinc(x)                     lw 4 lt 6            title "sinc(t)",              \
	"compare.dat" using 1:3 w l lw 3 lc black dt '-' title "optimized approximation"

unset multiplot