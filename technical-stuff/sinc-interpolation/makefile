pictures: sinc_envelope.png sinc_first_derivatives.png


sinc_approx: *.d *.c
	dmd -i -I. sinc_approx.d 

compare.dat: sinc_approx
	./sinc_approx 10 100

sinc_envelope.png: sinc_envelope.gp compare.dat sinc_approx
	gnuplot sinc_envelope.gp

sinc_first_derivatives.png: sinc_first_derivatives.gp
	gnuplot sinc_first_derivatives.gp

clean:
	rm *.png *.dat sinc_approx *.o