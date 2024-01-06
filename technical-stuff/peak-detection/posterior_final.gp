set term pngcairo 
set output "posterior_final.png"


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

set grid front


	pl2(x,y) = p_leading(x,y,Y2,T2,dy,w)
	pp2(x,y) = pl2(x,y) #pp1(x,y)*pl2(x,y)

	pl3(x,y) = p_leading(x,y,Y3,T3,dy,w)
	pp3(x,y) = pp2(x,y)*pl3(x,y)

	pl4(x,y) = p_leading(x,y,Y4,T4,dy,w)
	pp4(x,y) = pp3(x,y)*pl4(x,y)

	pl5(x,y) = p_leading(x,y,Y5,T5,dy,w)
	pp5(x,y) = pp4(x,y)*pl5(x,y)

	pl6(x,y) = p_trailing(x,y,Y6,T6,dy,w)
	pp6(x,y) = pp5(x,y)*pl6(x,y)

	pl7(x,y) = p_trailing(x,y,Y7,T7,dy,w)
	pp7(x,y) = pp6(x,y)*pl7(x,y)

	pl8(x,y) = p_trailing(x,y,Y8,T8,dy,w)
	pp8(x,y) = pp7(x,y)*pl8(x,y)

	pl9(x,y) = p_trailing(x,y,Y9,T9,dy,w)
	pp9(x,y) = pp8(x,y)*pl9(x,y)

	splot[5:6][3:5] pp9(y,x) w pm3d


