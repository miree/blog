//@safe:

import multifit_nlin;
import std.stdio;

void main(string[] args)
{
	if (args.length == 1) {
		writeln("usage: ", args[0], " {<filter> } <command>");
		writeln(" <filter> is <type>,<parameters> where");
		writeln("   <type> is one of l (lowpass) or h (highpass)");
		writeln("   <parameters> is a comma separated list of numbers");
		writeln("     for lowpass and highpass there is only one paramer");
		writeln("   for lowpass and highpass the parameters are time constants");
		writeln(" if <command> is gen,<t0>,<dt>,<t1>,<noise> the step response");
		writeln("   of all specified filters is generated between t0 and t1");
		writeln("   with timesteps of dt and written to stdout");
		writeln(" if <command> is apply the filters are applied to the signal");
		writeln("   on stdin, the result is written to stdout");
		writeln(" if <command> is fit:<x0>,<A> the filter paramters are fitted to the signal");
		writeln("   on stdin, the result is written to stdout as (t y) pairs");
		writeln(" available filters:");
		writeln("  h<tau>   high pass with time constant tau");
		writeln("  l<tau>   low pass with time constant tau");
		writeln("  H<tau>   inverse high pass with time constant tau");
		writeln("  L<tau>   inverse low pass with time constant tau");
		writeln("  i<w>     moving window average with withd w");
		writeln("  d<d>     delayed difference with delay d");
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
		if (arg.startsWith("i")) {
			filters ~= new WindowIntegral(arg[1..$].to!int);
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
		if (arg.startsWith("H")) {
			filters ~= new InverseHighPass(arg[1..$].to!double);
			params  ~= arg[1..$].to!double;
		}
		if (arg.startsWith("r")) {
			filters ~= new LinearRegression(arg[1..$].to!double);
			params  ~= arg[1..$].to!double;
		}
		if (arg.startsWith("gen:")) {
			auto ff = FitFunc(filters);
			auto gen_params = arg[4..$].split(',').map!(to!double).array;
			double t0 = gen_params[0];
			double dt = gen_params[1];
			double t1 = gen_params[2];
			double ns = gen_params[3];
			import std.random;
			params ~= 0.0; // append t0 (pulse start time)
			params ~= 1.0; // append A (amplitude)
			for(double t = t0; t < t1+dt/2; t+=dt) writeln(ff(t, params)+uniform(-ns,ns));
		}
		if (arg.startsWith("apply")) {
			foreach(l;stdin.byLine) {
				writeln(filters.apply(l.to!double));
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
	double[double] cache;
	double opCall(double t, double[] params) {
		assert(params.length == filters.length+2); // 2 additional parameters: t0 and A
		double t0 = params[$-2];
		double A  = params[$-1];
		t+=17;
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
	double[] buffer;
	int idx = 0;
	double integral;
	this (int width) {
		buffer = new double[width];
		integral = 0;
	}
	override void reset(double width) {
		buffer.length = cast(int)width;
		buffer[] = double.init;
		integral = 0;
		idx = 0;
	}
	override double apply(double x) {
		integral += x;
		double result = integral/buffer.length;
		buffer[idx] = x;
		if (++idx == buffer.length) idx = 0;
		if (buffer[idx] !is double.init) integral -= buffer[idx];
		return result;
	}
}

class DelayedDifference : Filter {
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
		if (buffer[idx] !is double.init) result -= buffer[idx];
		buffer[idx] = x;
		if (++idx == buffer.length) idx = 0;
		return result;
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
	this (double w) {
		N = cast(int)w;
		buffer = new double[N];
		buffer[] = 0.0;
		buffer2 = new double[N];
		buffer2[] = 0.0;
		x_sum = 0.0;
		xx_sum = 0.0;
		foreach(i;0..N) {
			x_sum  += i;
			xx_sum += i*i;
		}
		y_sum  = 0.0;
		y2_sum  = 0.0;
		xy_sum = 0.0;
		xy2_sum = 0.0;
	}
	override void reset(double w) {
		N = cast(int)w;
		buffer.length = N;
		buffer[] = 0.0;
		buffer2.length = N;
		buffer2[] = 0.0;
		idx = 0;
		x_sum = 0.0;
		xx_sum = 0.0;
		foreach(i;0..N) {
			x_sum  += i;
			xx_sum += i*i;
		}
		y_sum  = 0.0;
		y2_sum  = 0.0;
		xy_sum = 0.0;
		xy2_sum = 0.0;
	}
	double slope(double[] ys, int idx) {
		double x_sum  = 0;
		double y_sum  = 0;
		double xx_sum = 0;
		double xy_sum = 0;
		int N = 0;
		for(int x = 0; x < ys.length; ++x) {
			int i = idx+x;
			if (i>=ys.length) i-=ys.length;
			double y = ys[i];
			x_sum += x;
			y_sum += y;
			xx_sum += x*x;
			xy_sum += x*y;
			++N;
		}
		double D = xx_sum*N - x_sum*x_sum;
		return  (xy_sum*N - x_sum*y_sum) / D;
		//return xy_sum;
	}
//                              y_sum -vvvvvvvvvvvvvvvvv
// 0*y0 + 1*y1 + 2*y2 + 3*y3[+ 4*y4 - (y0 + y1 + y2 + y3 + y4 - y0) ]
//        0*y1 + 1*y2 + 2*y3 + 3*y4[+ 4*y5 - (y2 + y3 + y4 + y5) ]
//               0*y2 + 1*y3 + 2*y4 + 3*y5 
// => xy_sum += (N-1)*y - y_sum;
// => y_sum += y-buffer[idx];
// => buffer[idx] = y; 


// [0,0,0,0] y_sum = 0; xy_sum = 0
// [1,0,0,0] y_sum = 1; xy_sum = 4	
// [1,2,0,0] y_sum = 3; xy_sum = 4+8	
// [1,2,3,0] y_sum = 6; xy_sum = 0	
// [1,2,3,4] y_sum =10; xy_sum = 0	
// [5,2,3,4] y_sum =14; xy_sum = 0	
	override double apply(double y) {

		y2_sum  += buffer[idx]-buffer2[idx];
		xy2_sum += N*buffer[idx] - y2_sum;
		buffer2[idx] = buffer[idx];

		y_sum  += y-buffer[idx];
		xy_sum += N*y - y_sum;
		buffer[idx] = y;

		if (++idx >= N) idx = 0;

		//double slope1 = slope(buffer, idx);
		//double slope2 = slope(buffer2);




		double D = (xx_sum*N - x_sum*x_sum);
		double b1 = (xy_sum*N - x_sum*y_sum)/D;
		double a1 = y_sum/N - b1 * x_sum/N;
		double b2 = (xy2_sum*N - x_sum*y2_sum)/D;
		double a2 = y2_sum/N - b2 * x_sum/N;

		double dx1 = -(0*N+(b1*N+a1)/b1);
		double dx2 = -(0*N+a2/b2);
		double dx = 0.5*(dx1+dx2);
		stderr.writeln(-b1*N, " ", b2*N, " ", (y_sum+y2_sum)/N, " ", dx);

		return xy_sum;
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
