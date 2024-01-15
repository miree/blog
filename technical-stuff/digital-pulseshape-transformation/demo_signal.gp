set term pngcairo  size 640,300
set output "demo_signal.png"

plot "demo_signal.dat" using 0:1 w l lw 3 title "possible detector signal"