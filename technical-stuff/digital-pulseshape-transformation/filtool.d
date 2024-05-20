//@safe:

import multifit_nlin;
import std.stdio;

void main(string[] args)
{
	if (args.length == 1) {
		writeln("usage: ", args[0], " {<filter> } <command>");
		writeln(" <filter> is <type><parameters> where");
		writeln("   <type> is one of l (lowpass) or h (highpass)");
		writeln("   <parameters> is a comma separated list of numbers");
		writeln("     for lowpass and highpass there is only one paramer");
		writeln("   for lowpass and highpass the parameters are time constants");
		writeln(" if <command> is gen:<t0>,<dt>,<t1>,<noise> the step response");
		writeln("   of all specified filters is generated between t0 and t1");
		writeln("   with timesteps of dt and additional noise written to stdout");
		writeln(" if <command> is gen2:<t0>,<t1> the step response");
		writeln("   of all specified filters is generated between t0 and t1");
		writeln("   written to stdout. Format is four polynomial coefficients");
		writeln("   per line: a0 a1 a2 a3");
		writeln("   In this case polynomial approximation to sinc is used for interpolation");
		writeln(" if <command> is gen3:<t0>,<t1> the step response");
		writeln("   of all specified filters is generated between t0 and t1");
		writeln("   written to stdout. Format is five polynomial coefficients");
		writeln("   per line: a0 a1 a2 a3 a4");
		writeln("   In this case the true sinc is used for interpolation");
		writeln(" if <command> is apply the filters are applied to the signal");
		writeln("   on stdin, the result is written to stdout");
		writeln(" if <command> is apply2 the filters are applied to the signal");
		writeln("   on stdin which is expected in the form of polynomial coefficients.");
		writeln("   The result is written to stdout");
		writeln(" if <command> is fit:<x0>,<A> the filter paramters are fitted to the signal");
		writeln("   on stdin, the result is written to stdout as (t y) pairs");
		writeln(" available filters:");
		writeln("  n<a>     add noise with amplitude a");
		writeln("  h<tau>   high pass with time constant tau");
		writeln("  l<tau>   low pass with time constant tau");
		writeln("  H<tau>   inverse high pass with time constant tau");
		writeln("  L<tau>   inverse low pass with time constant tau");
		writeln("  i<w>     moving window average with withd w");
		writeln("  I<w>     inverse moving window average with withd w");
		writeln("  d<d>     delayed difference with delay d");
		writeln("  D<d>     inverse delayed difference with delay d");
		writeln("  r<w>,<n> dual linear regression window width w");
		writeln("  o<f>,<d> oscillator with freq. f (1.0=sampling freq.) and damping d");
		writeln("  O<f>,<d> inverse oscillator with freq. f (1.0=sampling freq.) and damping d");
		writeln("  c<f>,<d> const. fract. discr. with fraction f and delay d");
		writeln(" example: ", args[0], " l9.1 l15.0 h3.0 h4.5 gen:-10,1.0,100,0.0001 > signal.dat");
		writeln(" example: ", args[0], " l10 l10 h10 h10 fit:10,1.0 < signal.dat > fitresult.dat");
		writeln(" example: ", args[0], " L9.1 L15.0 H3.0 H4.5 apply < signal.dat > reversed.dat");
		return;
	}

	import std.algorithm, std.array, std.conv;

	Filter[] filters;
	double[] params;
	foreach(arg; args) {
		if (arg.startsWith("d")) {
			filters ~= new DelayedDifference(arg[1..$].to!int);
			params  ~= arg[1..$].to!double;
		}
		if (arg.startsWith("D")) {
			filters ~= new InverseDelayedDifference(arg[1..$].to!int);
			params  ~= arg[1..$].to!double;
		}
		if (arg.startsWith("i")) {
			filters ~= new WindowIntegral(arg[1..$].to!int);
			params  ~= arg[1..$].to!double;
		}
		if (arg.startsWith("I")) {
			filters ~= new InverseWindowIntegral(arg[1..$].to!int);
			params  ~= arg[1..$].to!double;
		}
		if (arg.startsWith("l")) {
			filters ~= new LowPass(arg[1..$].to!double);
			params  ~= arg[1..$].to!double;
		}
		if (arg.startsWith("L")) {
			filters ~= new InverseLowPass(arg[1..$].to!double);
			params  ~= arg[1..$].to!double;
		}
		if (arg.startsWith("h")) {
			filters ~= new HighPass(arg[1..$].to!double);
			params  ~= arg[1..$].to!double;
		}
		if (arg.startsWith("n")) {
			filters ~= new AddNoise(arg[1..$].to!double);
			params  ~= arg[1..$].to!double;
		}
		if (arg.startsWith("H")) {
			filters ~= new InverseHighPass(arg[1..$].to!double);
			params  ~= arg[1..$].to!double;
		}
		if (arg.startsWith("r")) {
			long comma_pos = -1;
			foreach(i,ch;arg) if (ch==',') comma_pos = i;
			filters ~= new LinearRegression(arg[1..comma_pos].to!double,
				                            arg[comma_pos+1..$].to!double);
			params  ~= arg[1..comma_pos].to!double;
		}
		if (arg.startsWith("c")) {
			long comma_pos = -1;
			foreach(i,ch;arg) if (ch==',') comma_pos = i;
			filters ~= new ConstantFraction(cast(int)arg[1..comma_pos].to!double,
				                            arg[comma_pos+1..$].to!double);
			params  ~= arg[1..comma_pos].to!double;
		}
		if (arg.startsWith("o")) {
			long comma_pos = -1;
			foreach(i,ch;arg) if (ch==',') comma_pos = i;
			filters ~= new Oscillator(arg[1..comma_pos].to!double,
				                      arg[comma_pos+1..$].to!double);
			params  ~= arg[1..comma_pos].to!double;
		}
		if (arg.startsWith("O")) {
			long comma_pos = -1;
			foreach(i,ch;arg) if (ch==',') comma_pos = i;
			filters ~= new InverseOscillator(arg[1..comma_pos].to!double,
				                      arg[comma_pos+1..$].to!double);
			params  ~= arg[1..comma_pos].to!double;
		}
		if (arg.startsWith("gen:")) {
			auto ff = FitFunc(filters);
			auto gen_params = arg[4..$].split(',').map!(to!double).array;
			double t0 = gen_params[0];
			double dt = gen_params[1];
			double t1 = gen_params[2];
			import std.random;
			params ~= 0.0; // append t0 (pulse start time)
			params ~= 1.0; // append A (amplitude)
			if (gen_params.length == 4) {
				double ns = gen_params[3];
				for(double t = t0; t < t1+dt/2; t+=dt) writeln(ff(t, params)+uniform(-ns,ns));
			}
			else {
				for(double t = t0; t < t1+dt/2; t+=dt) writeln(ff(t, params));
			}        
		}
		if (arg.startsWith("gen2:")) {
			auto sinc = new SincInterpolation;
			auto sinc_out = new SincInterpolation;
			auto gen_params = arg[5..$].split(',').map!(to!double).array;
			double t0 = gen_params[0];
			int N = cast(int)gen_params[1];
			double t1 = t0+N;
			import std.math;
			double x = t0-floor(t0);
			stderr.writeln("x = ", x, " N = ", N);
			//import std.random;
			int t00 = cast(int)(t0)-40;
			if (t00 > -40) t00 = -40;
			writeln("# ", t0, " ", t1);
			for(double t = t00; N; t+=1.0) {
				if (t < -17-16) {
					sinc.put(filters.apply(0));
					stderr.writeln(t, " ", 0);
				} else {
					sinc.put(filters.apply(1));
					stderr.writeln(t, " ", 1);
				}
				sinc_out.put(sinc.eval(x));

				auto c = sinc_out.get();
				if (t>t0) {
					writeln(c[0], " ", c[1], " ", c[2], " ", c[3]);
					--N;
				}
			}
		}
		if (arg.startsWith("gen3:")) {
			import std.math;
			auto gen_params = arg[5..$].split(',').map!(to!double).array;
			double t0 = gen_params[0];
			int N = cast(int)gen_params[1];
			int T0 = cast(int)floor(t0);
			writeln("# ", t0, " ", t0+N);
			double[] trace;
			for(int i = 0; i < N+1; ++i) {
				if (T0+i < 0) {
					trace ~= filters.apply(0);
				} else {
					trace ~= filters.apply(1);
				}
			}
			double sinc_interpolate(double[] ys, double t) {
				//stderr.writeln("interpolate at ", t);
				double f_sinc(double x) {
					import std.math;
					if (x == 0) return 1;
					return sin(PI*x)/(PI*x);
				}
				double result = 0.0;
				int N = 500; // exta points (left and reight) beoynd the range of "ys" array
				int i0 = -N;
				int i1 = cast(int)ys.length+N;
				double y = ys[0];
				for(int i = i0; i < i1; ++i) {
					if (i>=0 && i< ys.length) y=ys[i];
					result += y*f_sinc(t-i);
				}
				return result;
			}
			for (int i = 0; i < N; ++i) {
				double t = t0+i;
				double y0 = sinc_interpolate(trace, t-T0+0.0/4.0);
				double y1 = sinc_interpolate(trace, t-T0+1.0/4.0);
				double y2 = sinc_interpolate(trace, t-T0+2.0/4.0);
				double y3 = sinc_interpolate(trace, t-T0+3.0/4.0);
				double y4 = sinc_interpolate(trace, t-T0+4.0/4.0);
				double a = y0;
				double b = (-(3*y4)+16*y3-36*y2+48*y1-25*y0)/3;
		        double c = -((-(22*y4)+112*y3-228*y2+208*y1-70*y0)/3);
		        double d = (-(48*y4)+224*y3-384*y2+288*y1-80*y0)/3;
		        double e = -((-(32*y4)+128*y3-192*y2+128*y1-32*y0)/3);
				writeln(a, " ", b, " ", c, " ", d, " ", e);
			}
		}

		if (arg.startsWith("apply2")) {
			auto sinc = new SincInterpolation;
			import std.range;
			stdin.byLine.take(1).each!writeln;
			int i = 0;
			double value;
			foreach(l;stdin.byLine) {
				value = l.split(' ').front.to!double;
				sinc.put(filters.apply(value));
				if (i++ >= 17) {
					auto c = sinc.get();
					writeln(c[0], " ", c[1], " ", c[2], " ", c[3]);
				}
			}
			foreach(j;0..17) {
					sinc.put(filters.apply(value));
					auto c = sinc.get();
					writeln(c[0], " ", c[1], " ", c[2], " ", c[3]);				
			}
			return;
		}
		if (arg.startsWith("apply")) {
			foreach(l;stdin.byLine) {
				if (l.startsWith('#')) continue;
				writeln(filters.apply(l.split(' ').front.to!double));
			}
		}
		if (arg.startsWith("fit")) {
			import multifit_nlin;
			auto fit_params = arg[4..$].split(',').map!(to!double).array;
			double t0 = fit_params[0];
			double A  = fit_params[1];
			Dp!double[] data;
			double t = 0.0;
			foreach(l; stdin.byLine) {
				data ~= Dp!double(t,l.to!double,0.01);
				t+=1.0;
			}
			params ~= t0;
			params ~= A;
			auto fitfun = FitFunc(filters);
			auto fitter = MultifitNlin!(double, typeof(fitfun))(fitfun,data,params,true);
			fitter.run; 

			foreach(n; 0..data.length*10) {
				double tt = 0.1*n;
				writeln(tt, " ", fitfun(tt,fitter.result_params));
			}

			auto covar = fitter.result_covar;
			foreach(i, cov_line; covar) {
				import std.math;
				import std.array: appender;
				import std.format: formattedWrite;
				auto writer = appender!string;
				foreach (j, cij; cov_line)
					writer.formattedWrite("%12s",cij/sqrt(covar[i][i])/sqrt(covar[j][j]));
				std.stdio.stderr.writeln(writer[]);
			}
		}
	}
}

struct FitFunc
{
	Filter[] filters;
	SincInterpolation sinc;
	this(Filter[] filter_list) {
		filters = filter_list;
		sinc = new SincInterpolation;
	}
	double opCall(double t, double[] params) {
		assert(params.length == filters.length+2); // 2 additional parameters: t0 and A
		double t0 = params[$-2];
		double A  = params[$-1];
		t+=17; // compensate for the sinc cutoff range
		t-=t0;

		if (t<=0) return 0.0;

		foreach(i, ref filter; filters) filter.reset(params[i]);
		sinc.reset;
		// generate a filtered step function and apply sinc interpolation to it
		sinc.put(filters.apply(0));
		int n;
		for(n=0; n+1<t; ++n) sinc.put(filters.apply(1));
		return A*sinc.eval(t-n);
	}
}


interface Filter {
	void reset(double param);
	double apply(double y);
}
double apply(Filter[] filter_chain, double y) {
	double result = y;
	foreach(filter; filter_chain) {
		result = filter.apply(result);
	}
	return result;
}

class WindowIntegral : Filter {
	double[] buffer1;
	double[] buffer2;
	double fraction;
	int idx1 = 0;
	int idx2 = 0;
	double integral1;
	double integral2;
	this (double width) {
		int l1 = cast(int)width;
		if (l1 < 1) l1 = 1;
		if (l1 > 10000) l1 = 10000;
		int l2 = l1+1;
		fraction = width-l1;
		buffer1 = new double[l1];
		buffer2 = new double[l2];
		integral1 = 0;
		integral2 = 0;
	}
	override void reset(double width) {
		int l1 = cast(int)width;
		if (l1 < 1) l1 = 1;
		if (l1 > 10000) l1 = 10000;
		int l2 = l1+1;
		fraction = width-l1;
		buffer1.length = l1;
		buffer2.length = l2;
		buffer1[] = double.init;
		buffer2[] = double.init;
		integral1 = 0;
		integral2 = 0;
		idx1 = 0;
		idx2 = 0;
	}
	override double apply(double x) {
		integral1 += x;
		double result1 = integral1/buffer1.length;
		buffer1[idx1] = x;
		if (++idx1 == buffer1.length) idx1 = 0;
		if (buffer1[idx1] !is double.init) integral1 -= buffer1[idx1];

		integral2 += x;
		double result2 = integral2/buffer2.length;
		buffer2[idx2] = x;
		if (++idx2 == buffer2.length) idx2 = 0;
		if (buffer2[idx2] !is double.init) integral2 -= buffer2[idx2];

		return result2*fraction + result1*(1-fraction);
	}
}

class InverseWindowIntegral : Filter {
	double[] buffer;
	int idx = 0;
	double integral;
	this (int width) {
		buffer = new double[width-1];
		integral = 0;
	}
	override void reset(double width) {
		buffer.length = cast(int)width-1;
		buffer[] = double.init;
		integral = 0;
		idx = 0;
	}
	override double apply(double x) {
		//integral += x;
		double result = x - integral;
		integral += result;
		if (buffer[idx] !is double.init) integral -= buffer[idx];
		buffer[idx] = result;
		if (++idx == buffer.length) idx = 0;
		return result*(buffer.length+1);
	}
}

class DelayedDifference : Filter {
	double[] buffer1;
	double[] buffer2;
	double fraction;
	int idx1 = 0;
	int idx2 = 0;
	this (double delay) {
		int l1 = cast(int)delay;
		if (l1 < 1) l1 = 1;
		if (l1 > 10000) l1 = 10000;
		int l2 = l1+1;
		fraction = delay-l1;
		buffer1 = new double[l1];
		buffer2 = new double[l2];
	}
	override void reset(double delay) {
		int l1 = cast(int)delay;
		if (l1 < 1) l1 = 1;
		if (l1 > 10000) l1 = 10000;
		int l2 = l1+1;
		fraction = delay-l1;
		buffer1.length = l1;//cast(int)delay;
		buffer2.length = l2;//cast(int)delay;
		buffer1[] = double.init;
		buffer2[] = double.init;
		idx1 = 0;
		idx2 = 0;
	}
	override double apply(double x) {
		double result1 = x;
		if (buffer1[idx1] !is double.init) result1 -= buffer1[idx1];
		buffer1[idx1] = x;
		if (++idx1 == buffer1.length) idx1 = 0;

		double result2 = x;
		if (buffer2[idx2] !is double.init) result2 -= buffer2[idx2];
		buffer2[idx2] = x;
		if (++idx2 == buffer2.length) idx2 = 0;

		return result2*fraction+result1*(1-fraction);
	}
}

class InverseDelayedDifference : Filter {
	double[] buffer;
	int idx = 0;
	this (int delay) {
		buffer = new double[delay];
	}
	override void reset(double delay) {
		buffer.length = cast(int)delay;
		buffer[] = double.init;
		idx = 0;
	}
	override double apply(double x) {
		double result = x;
		if (buffer[idx] !is double.init) result += buffer[idx];
		buffer[idx] = result;
		if (++idx == buffer.length) idx = 0;
		return result;
	}
}

class AddNoise : Filter {
	double amplitude;
	this (double a) {
		amplitude = a;
	}
	override void reset(double dummy) {
		stderr.writeln("AddNoise filter cannot be used with fit or gen");
		assert(false);
	}
	override double apply(double x) {
		import std.random;
		return x + uniform(-amplitude,amplitude);
	}
}
class HighPass : Filter {
	double tau;
	this (double TAU) {
		tau = TAU;
	}
	double integral = 0.0;
	override void reset(double TAU) {
		integral = 0.0;
		tau = TAU;
	}
	override double apply(double x) {
		double output = x-integral;
		integral += output/tau;
		return output;
	}
}
class InverseHighPass : Filter {
	double tau;
	this (double TAU) {
		tau = TAU;
	}
	double integral = 0.0;
	override void reset(double TAU) {
		integral = 0.0;
		tau = TAU;
	}
	override double apply(double x) {
		double output = x+integral;
		integral += x/tau;
		return output;
	}
}
class LowPass : Filter {
	double tau;
	this (double TAU) {
		tau = TAU;
	}
	double integral = 0.0;
	override void reset(double TAU) {
		integral = 0.0;
		tau = TAU;
	}
	override double apply(double x) {
		double dI = (x-integral)/tau;
		integral += dI;
		return integral;
	}
}
class InverseLowPass : Filter {
	double tau;
	this (double TAU) {
		tau = TAU;
	}
	double integral = 0.0;
	override void reset(double TAU) {
		integral = 0.0;
		tau = TAU;
	}
	override double apply(double i) {
		double dI = i - integral;
		double x = dI*tau + integral;
		integral += dI;
		return x;
	}
}
class Oscillator : Filter {
	double frequency;
	double damping;
	double dy0 = 0.0;
	double y0  = 0.0;
	this (double FREQ, double DAMP) {
		frequency = FREQ;
		damping = DAMP;
	}
	override void reset(double dummy) {
		stderr.writeln("Oscillator filter cannot be used with fit or gen");
		assert(false);
	}
	override double apply(double x) {
		double y1  = y0+dy0;
		double dy1 = dy0 + (x-y1)*frequency - dy0*damping;
		dy0 = dy1;
		y0  = y1;
		return y1;
	}
}
class InverseOscillator : Filter {
	double frequency;
	double damping;
	double y0;
	double y1;
	this (double FREQ, double DAMP) {
		frequency = FREQ;
		damping = DAMP;
	}
	override void reset(double dummy) {
		stderr.writeln("InverseOscillator filter cannot be used with fit or gen");
		assert(false);
	}
	override double apply(double y2) {
		if (y0 !is y0.init) {
			double dy1 = y2-y1;
			double dy0 = y1-y0;
			double x = (frequency*y1+dy1+(damping-1)*dy0)/frequency;
			y0 = y1;
			y1 = y2;
			return x;
		}
		y0 = y1;
		y1 = y2;
		return y2;
	}
}
class ConstantFraction : Filter {
	double[] buffer;
	int idx = 0;
	double fraction;
	double output;
	double input;
	File *file;
	double t;
	this(int w, double f) {
		t = 0;
		buffer = new double[w];
		buffer[] = 0.0;
		idx = 0;
		fraction = f;
		output = 0;
		file = new File("pulses.dat","w+");
	}
	override void reset(double dummy) {
		stderr.writeln("ConstantFraction filter cannot be used with fit or gen");
		assert(false);
	}
	override double apply(double y) {
		t+=1;
		double delayed = buffer[idx];
		buffer[idx] = y;
		if (++idx >= buffer.length) idx = 0;

		double new_output = -fraction*y+delayed;

		if (new_output >= 0 && output < 0) {
			double dx = new_output / (new_output - output);
			double amplitude = input*dx + y*(1-dx);
			file.writeln(t-2-dx, " ", 0);
			file.writeln(t-1-dx, " ", amplitude);
			file.writeln(t-0-dx, " ", 0);
		}

		output = new_output;
		input  = y;
		return new_output;
	}

}


// 1*y1 + 2*y2 + 3*y3 + 4*y4
// 1*y1 + 2*y2 + 3*y3 + 4*y4 + 5*y5 - (y1 + y2 + y3 + y4)
// 1*y2 + 2*y3 + 3*y4 + 4*y5 
class LinearRegression : Filter {
	double[] buffer;
	double[] buffer2;
	int idx = 0;
	double x_sum  = 0.0;
	double y_sum  = 0.0;
	double y2_sum  = 0.0;
	double xx_sum = 0.0;
	double xy_sum = 0.0;
	double xy2_sum = 0.0;
	int N = 0;
	double noise_level;

	double min_b1 = 0;
	int detect_countdown = 0;
	double A_detected = 0;
	double x_detected = 0;
	int N_detected = 0;
	double A_max = 0;
	double dx_Amax = 0;
	double A_rising = 0;

	double peak0 = 0;
	double peak1 = 0;
	double peak2 = 0;

	double peakt1 = 0;


	double t = 0;

	File* f;

	this (double w, double noise) {
		peak0 = 0;
		peak1 = 0;
		peak2 = 0;
		peakt1 = 0;
		f = new File("pulses.dat","w+");

		t = 0;
		
		N = cast(int)w;
		noise_level = noise;

		buffer = new double[N];
		buffer[] = 0.0;
		buffer2 = new double[N];
		buffer2[] = 0.0;
		x_sum = 0.0;
		xx_sum = 0.0;
		foreach(x;0..N) {
			x_sum  += x;
			xx_sum += x*x;
		}
		y_sum  = 0.0;
		y2_sum  = 0.0;
		xy_sum = 0.0;
		xy2_sum = 0.0;
	}
	override void reset(double dummy) {
		stderr.writeln("LinearRegression filter cannot be used with fit or gen");
		assert(false);
	}
	override double apply(double y) {
		t+=1.0;


		y2_sum  += buffer[idx]-buffer2[idx];
		xy2_sum += N*buffer[idx] - y2_sum;
		buffer2[idx] = buffer[idx];

		y_sum  += y-buffer[idx];
		xy_sum += N*y - y_sum;
		buffer[idx] = y;


		if (++idx >= N) idx = 0;

		double D = (xx_sum*N - x_sum*x_sum);
		double b1 = (xy_sum*N - x_sum*y_sum)/D; // slope
		double a1 = y_sum/N - b1 * x_sum/N;     // y-axis intersection

		double b2 = (xy2_sum*N - x_sum*y2_sum)/D; // slope
		double a2 = y2_sum/N - b2 * x_sum/N;      // y-axis intersection

		double dx1 = -(0*N+(b1*N+a1)/b1); // sub-sample x-position of falling side
		double dx2 = -(0*N+a2/b2);        // sub-sample x-position of rising edge
		double dx  = 0.5*(dx1+dx2);

		// different amplitude estimates
		double y1 = -b1*N;
		double y2 =  b2*N;
		double y3 = (y_sum+y2_sum)/N;

		// find local maximum
		peak2=peak1;
		peak1=peak0;
		//peak0=(y1+y2+y3)/3.0;
		peak0=(y1+y2)/2.0;
		if (peak0 < peak1 && peak1 >= peak2 && (N+(peakt1-t)>=-N && N+(peakt1-t)<=N) ) { // local maximum in input N samples ago
			//double tp = t-N+dx_Amax;
			f.writeln(peakt1-2," 0");
			f.writeln(peakt1-1," ", peak1, " ", N+(peakt1-t));
			f.writeln(peakt1-0," 0");
		}
		A_rising = 0;

		// remember previous peak time
		peakt1 = t+dx-N+1;


		//stderr.writeln(y1, " ", y2, " ", y3, " ", dx);

		//return (y1+y2+y3)/3.0;
		return (y1+y2)/2.0;
	}
}



//class SincResample : SincInterpolation , Filter {
//	double pos;
//	this(double resample_position) {
//		pos = resample_position;
//	}
//	override void reset(double) {
//		// nothing
//	}
//	override double apply(double x) {
//		put(x);
//		if (empty) return x;
//		return eval(pos);
//	}
//}


interface Interpolate {
	void put(double x);
	bool empty(); // returns true if there is a new value available on the output
	uint N(); // return the lenght of the array that will be returned by get();
	double[] get(); // only call if empty() is false
}


class SincInterpolation : Interpolate {
	// sample height and first derivative
	struct Sample {
		double y;
		double yd = 0.0;
	}
	double[4] coefficients;
	void calc_coefficients(in Sample s0, in Sample s1) {
		coefficients[0] = s0.y;
		coefficients[1] = s0.yd;
		coefficients[2] = -1*s1.yd + 3*s1.y - 2*s0.yd - 3*s0.y;
		coefficients[3] =    s1.yd - 2*s1.y + 1*s0.yd + 2*s0.y;
	}
	double eval(double x) {
		assert(x >= 0);
		assert(x <= 1);
		double a = coefficients[0];
		double b = coefficients[1];
		double c = coefficients[2];
		double d = coefficients[3];
		return a+(b+(c+d*x)*x)*x;
	}


	import std.math, std.range;
	// table of derivatives of sinc function
	// optimized in a way such that 3rd order polynomial interpolation reproduces the sinc function more precisely
	static immutable double[] dsinc_dx = [0.0, 
	                                     -1.07432, 
	                                      0.587811, 
	                                     -0.402117, 
	                                      0.303929, 
	                                     -0.244447, 
	                                      0.204067, 
	                                     -0.175336, 
	                                      0.153231, 
	                                     -0.130252, 
	                                      0.106675, 
	                                     -0.0831741, 
	                                      0.060211, 
	                                     -0.0384085, 
	                                      0.0180193, 
	                                     9.70157e-05];

	Sample[dsinc_dx.length] samples; // ringbuffer of samples
	ulong front_idx;                 // index into ringbuffer pointing to the front element of the range
	bool is_empty = true;
	Sample front_sample;
	Sample previous_sample;

	void reset() {
		front_idx = 0;
		is_empty = true;
		front_sample = Sample();
		previous_sample = Sample();
	}

	override void put(double y) {
		if (is_empty) {
			samples[] = Sample(y);
			front_sample = samples[front_idx];
			is_empty = false;
		} 
		previous_sample = front_sample;
		front_sample = samples[front_idx];
		samples[front_idx] = Sample(y);
		ulong end   = front_idx;
		ulong begin = end+1;
		if (begin >= samples.length) begin = 0;

		long xi = samples.length-1;
		for(ulong i = begin; i != end; i = (i+1)%samples.length) {
			samples[i].yd         -= dsinc_dx[xi] * samples[front_idx].y;
			samples[front_idx].yd += dsinc_dx[xi] * samples[i].y;
			--xi;
		}
		front_idx = begin;
		calc_coefficients(previous_sample, front_sample);
	}
	bool empty() { return is_empty; }
	uint N() {return 4;}
	double[] get() { return coefficients; }
}
