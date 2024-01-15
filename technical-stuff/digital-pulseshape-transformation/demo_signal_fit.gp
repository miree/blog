set term pngcairo  size 640,300
set output "demo_signal_fit.png"

plot \
	"demo_signal.dat"           using 0:1 w l lw 5 title "possible detector signal", \
	"demo_signal_fitresult.dat" using 1:2 w l lw 2 lc black title "fitresult" 