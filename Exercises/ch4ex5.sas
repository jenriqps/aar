/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

/*
Chapter 4: Tipos de Riesgo
Exercise 5
*/

ods graphics / reset width=6.4in height=4.8in imagemap noborder;


* Exploratory analysis for the stocks;

title "Adjusted Prices";
proc sgplot data=_SeriesPlotTaskData;
	series x=Date y=Close / group=Stock;
	xaxis grid;
	yaxis grid;
	keylegend / location=inside;
run;

data work.transform_t(drop=Stock keep=date DRV DST SPY TTT);
	set _SeriesPlotTaskData(where=(stock="DRV") rename=(Close=DRV)); 
	set _SeriesPlotTaskData(where=(stock="DST") rename=(Close=DST));
	set _SeriesPlotTaskData(where=(stock="SPY") rename=(Close=SPY));
	set _SeriesPlotTaskData(where=(stock="TTT") rename=(Close=TTT));
run;

* Computing the monthly returns;
data work.transform(keep=date RetDRV RetDST RetSPY RetTTT);
	format RetIBM RetINTC RetMSFT percentn16.3;
	label RetDRV="Daily Return of DRV" RetDST="Daily Return of DST" RetSPY="Daily Return of SPY" RetTTT="Daily Return of TTT";
	set work.transform_t;
	if date >= "01AUG1986"d then 
	do;
	RetDRV=DRV/lag(DRV)-1;
	RetDST=DST/lag(DST)-1;
	RetSPY=SPY/lag(SPY)-1;
	RetTTT=TTT/lag(TTT)-1;
	end;
run;	

* Exploring the daily returns;
title "Daily Returns";
proc sgplot data=work.transform;
	series x=Date y=RetDRV;
	series x=Date y=RetDST;	
	series x=Date y=RetSPY;		
	series x=Date y=RetTTT;		
	xaxis grid;
	yaxis grid label="Daily return";
	keylegend / location=inside;
run;
title;

proc univariate data=work.transform;
	hist RetDRV RetDST RetSPY RetTTT;
	var RetDRV RetDST RetSPY RetTTT;
run;

ods graphics / reset;

* Computing the covariance matrix of the monthly returns;
proc corr data=work.transform cov out=cov;
	var RetDRV RetDST RetSPY RetTTT;
run;

proc sql;
	create table work.return(drop=_type_ _name_) as
		select *
		from work.cov 
		where _type_ = "MEAN"
		;
	create table work.cov_mat(drop=_type_) as
		select *
		from work.cov 
		where _type_ = "COV"
		;
quit;

proc transpose data=work.return out=work.return_t(keep=_name_ col1);
run;

* Computing the solution ;
%let expected_return = 0.0001;
proc optmodel;
   /* Declare sets and parameters */
   set <str> ASSETS, OTHER_ASSETS; 
   num return {ASSETS} ;
   num covariance {ASSETS, ASSETS};
   /* Reading the returns and covariances from the previous data sets */
   read data work.return_t into ASSETS=[_name_] return=col1;
   read data work.cov_mat into OTHER_ASSETS=[_NAME_] {r in ASSETS} <covariance[_name_,r]=col(r)>;
   print return covariance;
   /* Declare variables */
   var Prop {ASSETS} >= 0;

   /* Declare constraints */
   con Portfolio: sum {j in ASSETS} Prop[j] = 1;
   con ReturnPort: sum {j in ASSETS} return[j] * Prop[j] = &expected_return.;
   con minTTT: Prop['RetTTT']>=0.4;
   con minSPY: Prop['RetSPY']<=0.55;

   /* Declare objective */
   min Risk = sum {i in ASSETS, j in ASSETS} covariance[i,j] * Prop[i] * Prop[j];

   solve ;

   /* Printing the solution */
   print {j in ASSETS: Prop[j]} Prop
     {j in ASSETS: Prop[j]} return;

   print ReturnPort.ub;
   
quit;   
