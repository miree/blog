import multifit_nlin;

double sinc(double x) {
	import std.math;
	if (x==0) return 1;
	return sin(PI*x)/PI/x;
}
double sinc_yd(long xi) {
	if (xi == 0) return  0.0;
	if (xi%2)    return -1.0/xi;
	             return  1.0/xi;
}
double envelope(double x) {
	import std.math;
	if (x < 0.5) return 1.0;
	double c = cos(PI*(x-0.5));
	return c;
}

double sinc_approx(double x, double[] params) {
	assert (x >= 0.0);
	int i = cast(int)x;
	assert(i < params.length);
	x -= i;
	assert(x >= 0.0 && x <= 1.0);

	double y0 = (i==0)?1.0:0.0;
	double d0 = (i==0)?0.0:params[i-1];
	double y1 = 0.0;
	double d1 = params[i];

	double a = y0;
	double b = d0;
	double c = -1*d1 +3*y1 -2*d0 -3*y0;
	double d = +1*d1 -2*y1 +1*d0 +2*y0;

	return a + b*x + c*x*x + d*x*x*x; 
}


int main(string[] args) {
	import std.conv, std.stdio, std.range, std.algorithm, std.math;

	if (args.length != 3) {
		stderr.writeln("usage: ", args[0], " <cutof-range> <subsamples>");
		stderr.writeln(" cutof-range is the istance of the furthest supporting point");
		stderr.writeln("             taken into account at the current possition.");
		stderr.writeln(" subsamples  is the number of points calculated between two");
		stderr.writeln("             supporting points to visualize the interpolation function.");
		return 1;
	}

	uint xmax       = args[1].to!uint;
	uint subsamples = args[2].to!uint;

	auto data = iota(xmax*subsamples)
				.map!(i=>1.0*i/subsamples)
				.map!(x=>Dp!double(x,sinc(x)*envelope(1.0*x/xmax),1.0))
				.array;
	//writeln(data);
	auto params = iota(xmax)
				.map!(x=>sinc_yd(x+1))
				.array;

	auto fitter = MultifitNlin!(double,typeof(&sinc_approx))(&sinc_approx, data, params, true);
	fitter.run();

	auto compare = File("compare.dat","w");
	data.each!(d=>compare.writeln(d.c, " ", 
		                          d.v, " ", 
		                          sinc_approx(d.c, fitter.result_params), " ",
		                          sinc(d.c), " ",
		                          envelope(d.c/xmax)));

	double[] result = [0.0] ~ fitter.result_params();
	result.writeln;

	return 0;
}