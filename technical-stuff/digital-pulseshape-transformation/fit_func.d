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
		writeln(" if <command> is fit:<x0> the filter paramters are fitted to the signal");
		writeln("   on stdin, the result is written to stdout as (t y) pairs");
		writeln(" example: ", args[0], " l9.1 l15.0 h3.0 h4.5 gen:-10,1.0,100,0.0001 > signal.dat");
		writeln(" example: ", args[0], " l10 l10 h10 h10 fit:10 < signal.dat > fitresult.dat");
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
		if (arg.startsWith("gen:")) {
			auto ff = FitFunc(filters);
			auto gen_params = arg[4..$].split(',').map!(to!double).array;
			double t0 = gen_params[0];
			double dt = gen_params[1];
			double t1 = gen_params[2];
			double ns = gen_params[3];
			import std.random;
			params ~= 0.0; // append x0
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
			Dp!double[] data;
			double t = 0.0;
			foreach(l; stdin.byLine) {
				data ~= Dp!double(t,l.to!double,0.01);
				t+=1.0;
			}
			params ~= t0;
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
	double opCall(double x, double[] params) {
		assert(params.length == filters.length+1);
		x+=17;
		x-=params[$-1];

		if (x<=0) return 0.0;

		foreach(i, ref filter; filters) filter.reset(params[i]);
		sinc.reset;
		// generate a filtered step function and apply sinc interpolation to it
		sinc.put(filters.apply(0));
		int n;
		for(n=0; n+1<x; ++n) sinc.put(filters.apply(1));
		return sinc.eval(x-n);
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
		if (buffer[idx] is double.init) {
			integral += x;
			buffer[idx] = x;
			double result = integral / ++idx;
			if (idx == buffer.length) idx = 0;
			return result;
		}
		integral += buffer[idx];
		if (++idx == buffer.length) idx = 0;
		integral -= buffer[idx];
		buffer[idx] = x;
		return integral/buffer.length;
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
		if (buffer[idx] is double.init) {
			buffer[idx] = x;
			if (++idx == buffer.length) idx = 0;
			return 0;
		}
		double result = x-buffer[idx];
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


class SincResample : SincInterpolation , Filter {
	double pos;
	this(double resample_position) {
		pos = resample_position;
	}
	override void reset(double) {
		// nothing
	}
	override double apply(double x) {
		put(x);
		if (empty) return x;
		return eval(pos);
	}
}


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
