# Digital pulse shape transformation

Electrical signals from pulsed detectors (e.g. particle / gamma-ray detectors) can often be described as step function that went through a series of lowpass and highpass filters.

Consider the following signal

![demo_signal](demo_signal.png)

Observations:
  - It is not extremely pointed at the start, so went through a low pass filter.
  - It goes back to the baseline, so it must have gone through a high pass
  - It is bipolar, so it went through a higher order high pass

# Fitting the filter paramters

With the assumtion, that the signal is a step function that was filtered by a first order low pass and a second order high pass filter, the program `fit_func.d` can find the optimal filter paramters under this assuption:

```bash 
./filtool l5 h5 h5  fit:50,1.0 < demo_signal.dat > demo_signal_fitresult.dat 
           5           5           5          50           1  (  0)
     9.66418     6.79087     8.82544     49.7906    0.486854  (  1)     chi=91.8257
     17.2456     15.6316     19.4611     50.2305    0.947885  (  2)     chi=56.7521
     15.6405     13.4852     17.8218     49.6837    0.966766  (  3)     chi=38.6012
     12.2523     7.58405     17.6141     50.0655     1.18845  (  4)     chi=25.4992
     12.6414     8.15464     19.3168     50.3126     1.30002  (  5)     chi=16.2164
     13.4947     7.93287     17.9151     50.2967     1.40153  (  6)     chi=16.1377
      14.443     7.77994      17.033     50.3011     1.50399  (  7)     chi=16.1294
     15.0552     7.75177     16.4222     50.3016     1.56869  (  8)     chi=16.124
     15.1785     7.76171      16.296     50.3013     1.58139  (  9)     chi=16.123
     15.2586     7.75701     16.2189     50.3015      1.5899  ( 10)     chi=16.123
      15.251     7.75831     16.2252     50.3014     1.58905  ( 11)     chi=16.123
     15.2587     7.75717     16.2191     50.3015      1.5899  ( 12)     chi=16.123
     15.2618     7.75827      16.214     50.3014     1.59014  ( 13)     chi=16.123
     15.2615     7.75823      16.214     50.3014     1.59013  ( 14)     chi=16.123
     15.2615     7.75815     16.2142     50.3014     1.59013  ( 15)     chi=16.123


```

![demo_signal_fit](demo_signal_fit.png)

The fit result a good description of the signal. 
The best estimate for the low pass time constant is `10.0432`.
The best estimates for the high pass time constants are `20.3224` and `9.88288`.

Indeed the signal was generated from a step function tha was processed with a low pass filter with time constant `10` and two high pass filterse with time constants `10` and `20`.

# Filter inversion

Knowing the filter topology and filter paramters, it is possible to apply matching inverse filters to the signal to reproduce the step function.

![step_reconstruction](step_reconstruction.png)

The signal is noisier than the input signal because inverting a low pass filter amplifies noise just as the normal low pass filter reduced noise.
However, the reconstructed step function allows to reshape the pulse shape by applying differnt filters, such as moving average (aka box filter) or delayed differences.

![triangle](triangle.png)

It is possible to create a filter that transforms an arbitrary signals shape into triangular shape.
The only condition is that the original signal must be derived from a step function. 

