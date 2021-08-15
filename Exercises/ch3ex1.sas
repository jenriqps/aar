/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/
/*
Chapter 3: La influencia del reaseguro en la Administración del Riesgo
Exercise 1
*/
ods graphics / reset width=6.4in height=4.8in imagemap noborder;
%let conf = 0.98;
%let nperc = 196;
%let alpha = 0.65;
%let priority = 12;
%let capacity = 40;
%let n = 200;

data work.simLosses(label="Sample of simulated losses");
	label i="Simulation" L0="Simulated loss";
	format L0 dollar32.2;
	input i L0;
	datalines;
195 43.8
196 47.5
197 50.2
198 57.5
199 65.6
200 90.0
;

	/*
	Calculate the 98% CTE of the net losses after reinsurance recoveries for each reinsurance option
	*/
data work.simLosses2(label="Sample of simulated retained losses");
	format i 4. L0 L1 L2 dollar32.2;
	label L1="Retained loss under the Quota Share contract" 
		L2="Retained loss under the Stop Loss contract"
		VaR_flg="VaR's flag";
	set work.simLosses;
	L1=&alpha. * L0;
	L2=L0 - min(L0-&priority., &capacity.);

	if i=&nperc. then
		VaR_flg=1;
	else
		VaR_flg=0;
run;

title "Retained losses";

proc sgplot data=work.simLosses2;
	scatter x=i y=L0 / legendlabel="No reinsurance" 
		markerattrs=(symbol=circlefilled);
	scatter x=i y=L1 / markerattrs=(symbol=circlefilled);
	scatter x=i y=L2 / markerattrs=(symbol=circlefilled);
	xaxis grid;
	yaxis grid;
run;

title;

proc sql;
	create table work.simLosses3(label="Sample of simulated retained losses and their VaR") as 
		select a.* 
		, sum(VaR_flg*L0) as VaR0 label="No reinsurance VaR" format=dollar32.2
		, sum(VaR_flg*L1) as VaR1 label="Quota Share VaR" format=dollar32.2
		, sum(VaR_flg*L2) as VaR2 label="Stop Loss VaR" format=dollar32.2
		from work.simLosses2 a;
quit;

proc sql;
	create table work.CTE0(label="No reinsurance CTE") as 
		select a.* 
		, mean(L0) as CTE label="CTE no reinsurance" format=dollar32.6
		, var(L0) as Variance
		, ((calculated Variance + &conf.* (calculated CTE-VaR0)**2)/(&n.*(1-&conf.)))**0.5 as stdError
		, calculated CTE + calculated stdError as upper format=dollar32.6
		, calculated CTE - calculated stdError as lower format=dollar32.6
		from work.simLosses3 a 
		where L0 > VaR0;
	create table work.CTE1(label="Quote Share CTE") as 
		select a.* 
		, mean(L1) as CTE label="CTE with Quota Share" format=dollar32.6
		, var(L1) as Variance
		, ((calculated Variance + &conf.* (calculated CTE-VaR1)**2)/(&n.*(1-&conf.)))**0.5 as stdError
		, calculated CTE + calculated stdError as upper format=dollar32.6
		, calculated CTE - calculated stdError as lower format=dollar32.6
		from work.simLosses3 a 
		where L1 > VaR1;
	create table work.CTE2(label="Stop loss CTE") as select 
		a.* 
		, mean(L2) as CTE label="CTE with Stop Loss" format=dollar32.6
		, var(L2) as Variance
		, ((calculated Variance + &conf.* (calculated CTE-VaR2)**2)/(&n.*(1-&conf.)))**0.5 as stdError
		, calculated CTE + calculated stdError as upper format=dollar32.6
		, calculated CTE - calculated stdError as lower format=dollar32.6
		from work.simLosses3 a 
		where L2 > VaR2;
quit;

proc sql;
	create table work.graph(label="CTE") as 
		select 
		"No reinsurace" as scenario length=50 label="Scenario"
		, cte label="CTE" format=dollar32.6
		, upper
		, lower 
		from work.CTE0 
		union 
		select 
		"Quota Share" as scenario length=50
		, cte label="CTE" format=dollar32.6
		, upper
		, lower 
		from work.CTE1 
		union 
		select 
		"Stop loss" as scenario length=50
		, cte label="CTE" format=dollar32.6
		, upper
		, lower 
		from work.CTE2;
quit;

title "Confidence intervals for the CTE";
proc sgplot data=work.graph noautolegend;
	vbarbasic scenario / response=cte stat=mean colorresponse=cte;
	scatter x=scenario y=upper / markerattrs=(symbol=trianglefilled color=green size=14);
	scatter x=scenario y=lower / markerattrs=(symbol=trianglefilled color=green size=14);
	xaxis grid label="Options";
	yaxis grid label="CTE";
run;
title;
