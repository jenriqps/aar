/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

/*
Anexo 6.3.3 CUSF
*/

ods graphics / reset imagemap noborder;


proc iml;
	* Fixing the seed of random numbers for replicability;
	call randseed(2020);
	* Number of steps;
	N = 365;
	dt = 1/N;
	t = do(1/N,1,1/N);
	mu = 0.04;
	sigma = 0.2;
	Z0 = 23;
	a = {-1 1};
	* Independent normal numbers;
	dW = j(N,2);
	call randgen(dW,"Normal",0,(dt)**0.5);
	
	* Brownian motions;
	W = cusum(dW[,1])||cusum(dW[,2]);

	create work.W from W;
	append from W;
	close work.W;
	
	Z = (Z0*exp((mu - sigma**2/2)*t + sigma*a*W`))`;
	
	*print Z;	

	create work.Z from Z;
	append from Z;
	close work.Z;
quit;
run;



data work.W;
	label W1 = "Brownian Motion W1" W2 = "Brownian Motion W2" i = "Day";
	set work.w(rename=(col1=W1 col2=W2));
	i = _n_;
run;

title "Brownian motions to simulate the exchange rate MXN/USD";
proc sgplot data=work.W;
	series x=i y=W1;
	series x=i y=W2;
 	xaxis grid;
	yaxis grid label="Brownian Motion";
run;

data work.Z;
	label Z = "Exchange Rate MXN/USD" i = "Day";
	set work.Z(rename=(col1=Z));
	i = _n_;
run;

title "Simulation of one path for the exchange rate MXN/USD";
proc sgplot data=work.Z;
	series x=i y=Z;
	xaxis grid;
	yaxis grid label="MXN/USD";
run;
