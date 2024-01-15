set term pngcairo  size 640,900
set output "mawd.png"



set multiplot layout 4,1
set key top left

plot[80:200][-0.2:1.4] "mawd1.dat" using 0:1 w l lw 3 title "detector pulse shape" ,   1 lt 1 lc black dt '-' notitle
plot[80:200][-0.2:1.4] "mawd2.dat" using 0:1 w l lw 3 title "inverse high pass" ,      1 lt 1 lc black dt '-' notitle
plot[80:200][-0.2:1.4] "mawd3.dat" using 0:1 w l lw 3 title "delayed difference" ,     1 lt 1 lc black dt '-' notitle
plot[80:200][-0.2:1.4] "mawd4.dat" using 0:1 w l lw 3 title "window integral" ,        1 lt 1 lc black dt '-' notitle

unset multiplot	