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
	
	* Number of simulations;
	S = 10000;
	* Number of steps;
	N = 365;
	dt = 1/N;
	t = do(1/N,1,1/N);
	mu = 0.04;
	sigma = 0.2;
	Z0 = 23;
	a = {-1 1};
	
	Z = j(S,1);
	
	do i = 1 to S;
		* Independent normal numbers;
		dW = j(N,2);
		call randgen(dW,"Normal",0,(dt)**0.5);
		
		* Brownian motions;
		W = sum(dW[,1])||sum(dW[,2]);
		Z[i,1] = (Z0*exp((mu - sigma**2/2) + sigma*a*W`))`;
	end;

	create work.Z from Z;
	append from Z;
	close work.Z;
quit;
run;

data work.Z;
	label Z = "Exchange Rate MXN/USD 1 Year" i = "Simulation";
	set work.Z(rename=(col1=Z));
	i = _n_;
run;


title "Box plot for the exchange rate MXN/USD 1 Year";
proc sgplot data=work.Z;
	vbox Z / fillattrs=(color=red transparency=0.9) DISPLAYSTATS=(mean median std max min datamin datamax);
	yaxis grid;
run;

proc univariate data=work.Z outtable=work.stat;
	var Z;
run;

title "Simulation of many paths for the exchange rate MXN/USD 1 Year";
proc sgplot data=work.Z;
	histogram Z / fillattrs=(color=red transparency=0.9);
	xaxis grid;
	yaxis grid;
run;


