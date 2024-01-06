set term pngcairo 
set output "example_signal.png"

w=4.
A=4.
t0=5.5

set samples 1000
set xlabel "t"
set ylabel "y"
set xtics 1
set ytics 1

sig(x,w) = (abs(x)<=w)?(1-abs(x)/w):0

set multiplot layout 2,1

plot[:][-0.5:A+1] \
	sig(x-t0,w)*A        lw 3                    title "ideal signal",  \
	"example_signal.dat" using 1:2 w p lt 7 pt 7 ps 1 title "sampled signal" \

plot[:][-0.5:A+1]  \
	sig(x-t0,w)*A        lw 3                    notitle,  \
	"example_signal.dat" using 1:3 w p lt 7 pt 7 ps 1 title "samples with noise" \

unset multiplot

#plot[t0-2*w:t0+2*w][-0.5:A+2] A*sig(x-t0,w) lw 4 notitle "signal shape"