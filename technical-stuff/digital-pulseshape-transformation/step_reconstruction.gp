set term pngcairo  size 640,300
set output "step_reconstruction.png"

set key bottom right
set grid 
plot \
	"step_reconstruction.dat"     using 0:1 w l lw 2 title "reconstructed step function"

