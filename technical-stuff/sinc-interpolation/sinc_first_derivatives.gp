set term pngcairo
set output "sinc_first_derivatives.png"

set grid
set samples 1000
set xtics 1
sinc(x) = (x!=0)?(sin(pi*x)/(pi*x)):1
dsinc(x) = (x!=0)?(cos(pi*x)/x - sin(pi*x)/pi/x**2):0


deriv(x,n,w) = (x<n-w)?(0/0):(x>n+w)?(0/0):(dsinc(n)*(x-n)+sinc(n))

round(x) = int(x+1000.5)-1000

f(x) = deriv(x,round(x),0.4)
points(x) = deriv(x,round(x),0.03)

poly1(x) = (x<0)?(0/0):((x>1)?(0/0):(1.0-2.0*x**2+1.0*x**3))

poly2(x) = (x<0)?(0/0):((x>1)?(0/0):(-1.0*x+3.0/2.0*x**2-1.0/2.0*x**3))
poly3(x) = (x<0)?(0/0):((x>1)?(0/0):( 1.0/2.0*x-2.0/3.0*x**2+1.0/6.0*x**3))


set xlabel "t"
set ytics 0.5
set multiplot layout 2,1
plot[-4:4][-0.5:1.2] \
	sinc(x) lw 4 lt 6                    title "sinc(t)",              \
	"points.dat" using 1:2 w p lt 7 pt 7 ps 2 title "sampling points", \
	f(x) lw 3 lt 7                       title "derivatives",          \
	poly1(x-0) lt 8 lw 4 dt "-"          title "polynoms",             \
	poly2(x-1) lt 8 lw 4 dt "-"          notitle,                      \
	poly3(x-2) lt 8 lw 4 dt "-"          notitle                       

unset key
set ytics 0.2
plot[0.5:3.5][-0.25:0.25] \
	sinc(x) lw 4 lt 6                    title "sinc(t)",              \
	"points.dat" using 1:2 w p lt 7 pt 7 ps 2 title "sampling points", \
	f(x) lw 3 lt 7                       title "derivatives",          \
	poly1(x-0) lt 8 lw 4 dt "-"          title "polynoms",             \
	poly2(x-1) lt 8 lw 4 dt "-"          notitle,                      \
	poly3(x-2) lt 8 lw 4 dt "-"          notitle                       	
unset multiplot
