/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

/*
Chapter 4: Tipos de Riesgo
Exercise 3
*/

title "Chapter 4: Tipos de Riesgo. Exercise 3";

* Asset allocation ;
data work.assetallocation(label="XYZ’s current asset allocation");
	label bondrating="Bond Rating" mktvalue="Market value of assets ($ million)";
	format mktvalue dollar32.2;
	input bondrating $ mktvalue;
	datalines;
AA 27
A 15
BBB 0
;	

* Credit migration probabilities ;
data work.migrprob(label="One-year credit migration probabilities for bonds with various ratings");
	label initRating="Initial Rating" RecovRate="Recovery rate";
	format AA A BBB Default RecovRate 4.2;
	input initRating $ AA A BBB Default RecovRate;
	datalines;
AA 0.85 0.13 0.01 0.01 0.40 
A 0.12 0.82 0.04 0.02 0.25 
BBB 0.05 0.10 0.76 0.09 0.20
; 


proc iml;
	* Exporting the asset allocation to a matrix ;
	use work.assetallocation;
	read all var {bondrating mktvalue};
	close work.assetallocation; 	
	
	print "Asset allocation";
	print bondrating mktvalue;

	* Exporting the migration probabilities to a matrix;
	use work.migrprob;
	read all var _NUM_ into migrprob[colname=numVars];
	close work.migrprob; 	

	print "Migration probabilities";
	print migrprob;
	
	print "Calculate the expected credit losses from default in the next year
	using the credit migration model.";
	
	rec = migrprob[,1];
	print "Loss given default";
	lgd = 1 - rec;
	print lgd;
	print "Probability of default";
	pd = migrprob[,5];
	print pd;
	print "Exposure at default";
	ead = mktvalue;
	print ead;
	
	print "Expected credit loss";
	ECL = sum((pd#ead)#lgd);
	
	print ECL;

	print "Calculate the expected amount of bonds that need to be sold
	after one year in order to satisfy the RAS. ";
	amount = sum(pd#ead)+sum(migrprob[,4]#ead);
	
	print amount;

	* Simulations;
	
	print "Simulate 1,000,000 credit losses and plot the distribution.";
	
	N = 1000000;

	defAA = j(N,1);
	call randgen(defAA,"Bernoulli",pd[1]);
	*print defAA;

	defA = j(N,1);
	call randgen(defA,"Bernoulli",pd[2]);
	*print defA;

	defBBB = j(N,1);
	call randgen(defBBB,"Bernoulli",pd[3]);
	*print defBBB;
	
	ead2 = repeat(t(ead),N,1);
	lgd2 = repeat(t(lgd),N,1);
	
	*print lgd2;
	
	CL0 =  ((defAA||defA||defBBB)#ead2)#lgd2;

	*print CL0;
	
	
	CL = CL0[,+];
		
	*print CL;

	ECL = mean(CL);
	
	print ECL;
	
	create work.CL from CL;
	append from CL;
	close work.CL;
	

run;

proc datasets lib=work nolist;
	modify CL;
	rename col1=CL;
	label cl = "Credit loss";
quit;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=WORK.CL;
	title height=14pt "Credit losses";
	vbar CL / fillattrs=(color=CXf1eb28) datalabel stat=percent;
	yaxis grid;
run;

ods graphics / reset;
title;

proc freq data=work.cl;
	table cl;
run;
