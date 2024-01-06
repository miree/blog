set term pngcairo size 640,3000
set output "likelihood_and_posterior.png"


T0 =0   ; Y0 = 0.3
T1 =1   ; Y1 =-0.2
T2 =2   ; Y2 = 0.4
T3 =3   ; Y3 = 1.8
T4 =4   ; Y4 = 2.3
T5 =5   ; Y5 = 3.4
T6 =6   ; Y6 = 3.8 
T7 =7   ; Y7 = 2.3
T8 =8   ; Y8 = 1.4
T9 =9   ; Y9 = 0.8
T10=10  ; Y10= 0.3
T11=11  ; Y11=-0.2

# known signal parameters
dy = 0.3
w  = 4

set isosamples 1000
set xlabel "t0"
set ylabel "A"

p_leading (A,t0,yi,ti,dy,w) = exp(-0.5*((yi-A*(1+(ti-t0)/w))/dy)**2)
p_trailing(A,t0,yi,ti,dy,w) = exp(-0.5*((yi-A*(1+(t0-ti)/w))/dy)**2)

p_l(A,t0,yi,ti,dy,w) = p_leading(A,t0,yi,ti,dy,w)+p_trailing(A,t0,yi,ti,dy,w)
set palette defined (0 "white", 0.25 "blue" , 0.5 "green", 0.75 "yellow", 1 "red")

set pm3d map
set isosamples 50
unset colorbox

set multiplot layout 8,2

#	pl0(x,y) = p_l(x,y,Y0,T0,dy,w)
#	pp0(x,y) = pl0(x,y)
#	splot[0:11][0:8] pl0(y,x)
#	splot[0:11][0:8] pp0(y,x)
#
#	pl1(x,y) = p_l(x,y,Y1,T1,dy,w)
#	pp1(x,y) = pp0(x,y)*pl1(x,y)
#	splot[0:11][0:8] pl1(y,x) w pm3d
#	splot[0:11][0:8] pp1(y,x) w pm3d

	pl2(x,y) = p_leading(x,y,Y2,T2,dy,w)
	pp2(x,y) = pl2(x,y) #pp1(x,y)*pl2(x,y)
	set arrow from T2,0 to T2,8 front nohead lw 1
	set arrow from 0,Y2 to 11,Y2  front nohead lw 1
	set title "likelihood 2"
	splot[0:11][0:8] pl2(y,x) w pm3d, "example_signal.dat" using 1:3:(0) w p pt 7 ps 1 lc black notitle
	unset arrow
	set title "posterior 2"
	splot[0:11][0:8] pp2(y,x) w pm3d

	pl3(x,y) = p_leading(x,y,Y3,T3,dy,w)
	pp3(x,y) = pp2(x,y)*pl3(x,y)
	set arrow from T3,0 to T3,8 front nohead lw 1
	set arrow from 0,Y3 to 11,Y3  front nohead lw 1
	set title "likelihood 3"
	splot[0:11][0:8] pl3(y,x) w pm3d, "example_signal.dat" using 1:3:(0) w p pt 7 ps 1 lc black notitle
	unset arrow
	set title "posterior 3"
	splot[0:11][0:8] pp3(y,x) w pm3d

	pl4(x,y) = p_leading(x,y,Y4,T4,dy,w)
	pp4(x,y) = pp3(x,y)*pl4(x,y)
	set arrow from T4,0 to T4,8 front nohead lw 1
	set arrow from 0,Y4 to 11,Y4  front nohead lw 1
	set title "likelihood 4"
	splot[0:11][0:8] pl4(y,x) w pm3d, "example_signal.dat" using 1:3:(0) w p pt 7 ps 1 lc black notitle
	unset arrow
	set title "posterior 4"
	splot[0:11][0:8] pp4(y,x) w pm3d

	pl5(x,y) = p_leading(x,y,Y5,T5,dy,w)
	pp5(x,y) = pp4(x,y)*pl5(x,y)
	set arrow from T5,0 to T5,8 front nohead lw 1
	set arrow from 0,Y5 to 11,Y5  front nohead lw 1
	set title "likelihood 5"
	splot[0:11][0:8] pl5(y,x) w pm3d, "example_signal.dat" using 1:3:(0) w p pt 7 ps 1 lc black notitle
	unset arrow
	set title "posterior 5"
	splot[0:11][0:8] pp5(y,x) w pm3d

	pl6(x,y) = p_trailing(x,y,Y6,T6,dy,w)
	pp6(x,y) = pp5(x,y)*pl6(x,y)
	set arrow from T6,0 to T6,8 front nohead lw 1
	set arrow from 0,Y6 to 11,Y6  front nohead lw 1
	set title "likelihood 6"
	splot[0:11][0:8] pl6(y,x) w pm3d, "example_signal.dat" using 1:3:(0) w p pt 7 ps 1 lc black notitle
	unset arrow
	set title "posterior 6"
	splot[0:11][0:8] pp6(y,x) w pm3d

	pl7(x,y) = p_trailing(x,y,Y7,T7,dy,w)
	pp7(x,y) = pp6(x,y)*pl7(x,y)
	set arrow from T7,0 to T7,8 front nohead lw 1
	set arrow from 0,Y7 to 11,Y7  front nohead lw 1
	set title "likelihood 7"
	splot[0:11][0:8] pl7(y,x) w pm3d, "example_signal.dat" using 1:3:(0) w p pt 7 ps 1 lc black notitle
	unset arrow
	set title "posterior 7"
	splot[0:11][0:8] pp7(y,x) w pm3d

	pl8(x,y) = p_trailing(x,y,Y8,T8,dy,w)
	pp8(x,y) = pp7(x,y)*pl8(x,y)
	set arrow from T8,0 to T8,8 front nohead lw 1
	set arrow from 0,Y8 to 11,Y8  front nohead lw 1
	set title "likelihood 8"
	splot[0:11][0:8] pl8(y,x) w pm3d, "example_signal.dat" using 1:3:(0) w p pt 7 ps 1 lc black notitle
	unset arrow
	set title "posterior 8"
	splot[0:11][0:8] pp8(y,x) w pm3d

	pl9(x,y) = p_trailing(x,y,Y9,T9,dy,w)
	pp9(x,y) = pp8(x,y)*pl9(x,y)
	set arrow from T9,0 to T9,8 front nohead lw 1
	set arrow from 0,Y9 to 11,Y9  front nohead lw 1
	set title "likelihood 9"
	splot[0:11][0:8] pl9(y,x) w pm3d, "example_signal.dat" using 1:3:(0) w p pt 7 ps 1 lc black notitle
	unset arrow
	set title "posterior 9"
	splot[0:11][0:8] pp9(y,x) w pm3d

#	pl10(x,y) = p_l(x,y,Y10,T10,dy,w)
#	pp10(x,y) = pp9(x,y)*pl10(x,y)
#	splot[0:11][0:8] pl10yxxy) w pm3d
#	splot[0:11][0:8] pp10yxxy) w pm3d
#
#	pl11(x,y) = p_l(x,y,Y11,T11,dy,w)
#	pp11(x,y) = pp10(x,y)*pl11(x,y)
#	splot[0:11][0:8] pl11yxxy) w pm3d
#	splot[0:11][0:8] pp11yxxy) w pm3d



unset multiplot

