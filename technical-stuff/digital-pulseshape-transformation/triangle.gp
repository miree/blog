set term pngcairo size 640,300
set output "triangle.png"

set grid

plot[40:100][-0.2:1.2] \
	"demo_signal.dat" using 0:1 w l lw 3 title "detector signal", \
    "triangle.dat"    using 0:1 w l lw 3 title "transformed detector signal", \
	(x-50.3)/10   lc black dt '-' notitle, \
	-(x-70.3)/10  lc black dt '-' notitle, \
	0             lc black dt '-' notitle