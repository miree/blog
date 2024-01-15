pictures: demo_signal.png           \
          demo_signal_fit.png       \
          step_reconstruction.png   \
          triangle.png              \
          mawd.png                  \


filtool: *.d *.c
	dmd -i -I. filtool.d

demo_signal.dat: filtool
	./filtool l10 h10 h20 gen:-50.3,1.0,150.3,0.004 > demo_signal.dat

demo_signal_fitresult.dat: demo_signal.dat filtool
	./filtool l5 h5 h5  fit:50,1.0 < demo_signal.dat > demo_signal_fitresult.dat 

step_reconstruction.dat: demo_signal.dat filtool
	./filtool L10.0145 H10.0271 H19.8401 apply < demo_signal.dat > step_reconstruction.dat

triangle.dat: demo_signal.dat filtool
	./filtool L10.0145 H10.0271 H19.8401 i10 d10 apply < demo_signal.dat > triangle.dat

demo_signal.png: demo_signal.gp demo_signal.dat
	gnuplot demo_signal.gp

demo_signal_fit.png: demo_signal_fit.gp demo_signal.dat demo_signal_fitresult.dat
	gnuplot demo_signal_fit.gp

step_reconstruction.png: step_reconstruction.gp step_reconstruction.dat
	gnuplot step_reconstruction.gp

triangle.png: triangle.gp triangle.dat
	gnuplot triangle.gp

mawd.png: mawd.gp filtool
	./filtool i3 l2 h50 gen:-100,1,100,0.01 > mawd1.dat
	./filtool H50 apply < mawd1.dat > mawd2.dat
	./filtool d20 apply < mawd2.dat > mawd3.dat
	./filtool i10 apply < mawd3.dat > mawd4.dat
	gnuplot mawd.gp

sinc_first_derivatives.png: sinc_first_derivatives.gp points.dat
	gnuplot sinc_first_derivatives.gp

clean:
	rm *.png *.dat filtool *.o