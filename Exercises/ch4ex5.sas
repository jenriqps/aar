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
proc sort data=SASHELP.STOCKS(where=(date>="01AUG1986"d)) out=_SeriesPlotTaskData;
	by Stock Date;
run;

title "Adjusted Prices";
proc sgplot data=_SeriesPlotTaskData;
	series x=Date y=AdjClose / group=Stock;
	xaxis grid;
	yaxis grid;
	keylegend / location=inside;
run;

data work.transform_t(drop=Stock keep=date ibm intc msft);
	set _SeriesPlotTaskData(where=(stock="IBM") rename=(AdjClose=IBM)); 
	set _SeriesPlotTaskData(where=(stock="Intel") rename=(AdjClose=INTC));
	set _SeriesPlotTaskData(where=(stock="Microsoft") rename=(AdjClose=MSFT));
run;

* Computing the monthly returns;
data work.transform(keep=date RetIBM RetINTC RetMSFT);
	format RetIBM RetINTC RetMSFT percentn16.3;
	label RetIBM="Monthly Return of IBM" RetINTC="Monthly Return of Intel" RetMSFT="Monthly Return of Microsoft";
	set work.transform_t;
	if date >= "01AUG1986"d then 
	do;
	RetIBM=IBM/lag(IBM)-1;
	RetINTC=INTC/lag(INTC)-1;
	RetMSFT=MSFT/lag(MSFT)-1;
	end;
run;	

* Exploring the monthly returns;
title "Monthly Returns";
proc sgplot data=work.transform;
	series x=Date y=RetIBM;
	series x=Date y=RetINTC;	
	series x=Date y=RetMSFT;		
	xaxis grid;
	yaxis grid label="Monthly return";
	keylegend / location=inside;
run;
title;

proc univariate data=work.transform;
	hist RetIBM RetINTC RetMSFT;
	var RetIBM RetINTC RetMSFT;
run;

ods graphics / reset;

* Computing the covariance matrix of the monthly returns;
proc corr data=work.transform cov out=cov;
	var RetIBM RetINTC RetMSFT;
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
%let expected_return = 0.021;
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
   con minIBM: Prop['RetIBM']>=0.4;
   con minMSFT: Prop['RetMSFT']<=0.55;

   /* Declare objective */
   min Risk = sum {i in ASSETS, j in ASSETS} covariance[i,j] * Prop[i] * Prop[j];

   solve ;

   /* Printing the solution */
   print {j in ASSETS: Prop[j]} Prop
     {j in ASSETS: Prop[j]} return;

   print ReturnPort.ub;
   
quit;   
