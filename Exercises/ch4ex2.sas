/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

/*
Chapter 4: Tipos de Riesgo
Exercise 2
*/


proc iml;

	print "a) You first calculate the simulated total loss...";
	
	print "1) Demonstrate that the correlated uniform values using the Gaussian copula are v1 = 0.950; v2 = 0.171. Show your work.";

	R = {1 0.25,0.25 1};
	print "Correlation matrix", R;

	L = t(root(R));
	print "L is a lower triangular matrix of the Cholevski factorization of the correlation matrix", L;
	
	u = {0.95 0.08};
	print "Two independent uniform pseudorandom numbers", u;
	
	z = quantile('NORMAL',u);
	
	print "P[Z<=z]=u, z=?", z;
	
	LZ = L*Z`;
	
	print LZ;
	
	v = cdf('NORMAL',LZ);
	
	print "v = P[Z<=LZ]", v;

	print "2) Calculate the simulated total loss due to Equity and Credit risk factors using the correlated uniform values from 1). Show your work.";
	
	
	
	L_equity = quantile('NORMAL',v[1],0,500);
	L_credit = quantile('NORMAL',v[2],0,1000);
	
	print "v1 = P[Z<=z] = P[(Z+0)*500<=(z+0)*500] → l_equity = z*500", l_equity;
	
	print "v2 = P[Z<=z] = P[(Z+0)*1000<=(z+0)*1000] → l_credit = z*1000", l_credit;
	
	
	TotalLoss = l_equity + l_credit;
	
	print "TotalLoss = l_equity + l_credit ", TotalLoss;
	
	print "You now calculate the simulated total loss due to Equity and Credit risk factors by using a t-copula with 2 degrees of freedom...";
	
	print "1) Demonstrate that the correlated uniform values using the tcopula are v1 = 0.972; v2 = 0.071. Show your work.";
	
	t=LZ*(1/(0.325/2))**0.5;
	
	print "t = LZ x (1/(v/2))^0.5", t;
	
	vt = cdf('T',t,2);
	
	print vt;
	
	print "2) Calculate the simulated total loss due to Equity and Credit risk factors using the correlated uniform values from 1). Show your work.";

	lt_equity = quantile('NORMAL',vt[1],0,500);
	lt_credit = quantile('NORMAL',vt[2],0,1000);
	
	print "vt1 = P[Z<=z] = P[(Z+0)*500<=(z+0)*500] → lt_equity = z*500", lt_equity;
	print "vt2 = P[Z<=z] = P[(Z+0)*1000<=(z+0)*1000] → lt_equity = z*1000", lt_credit;
	
	TotalLosst = lt_equity + lt_credit;
	
	print "TotalLosst = lt_equity + lt_credit ", TotalLosst;

run;