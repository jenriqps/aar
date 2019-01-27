/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/


options mprint mlogic minoperator fullstimer;
ods graphics / reset width=6.4in height=4.8in imagemap noborder;

%global root;
%let root=/folders/myfolders/aar;

%include "&root./COD/staging/profit/configuracion.sas";
%include "&root./COD/staging/profit/macrosProfit.sas";

ods graphics / reset width=8in height=9in imagemap noborder;
title "Profit";
proc sgpanel data=prft.profit;
	panelby num_year / uniscale=all columns=3 rows=10;
 	histogram mnt_pvAnnualProfit / fillattrs=(color=blue transparency=0.8);
run;
title;


proc sql noprint;
	select pvAnnualProfit format 16.2 into: pvProfitBase
	from prft.pvprofits
	where cve_scenario = 0
	;
	select pvAnnualProfit format comma16. into: pvProfitBasef
	from prft.pvprofits
	where cve_scenario = 0
	;
quit;

ods output quantiles=prft.quantiles;
proc univariate data=prft.pvprofits(where=(cve_scenario ne 0));
	var pvAnnualProfit;
run;

proc sql noprint;
	title 'VaR al 90% de confianza y horizonte hasta que se acaben los pasivos';
	select estimate format 16.2 into: VaR90
	from prft.quantiles
	where Quantile="10%"
	;
	title 'CTE al 90% de confianza y horizonte hasta que se acaben los pasivos';
	select mean(pvAnnualProfit) format 16.2 into: CTE90
	from prft.pvprofits
	where cve_scenario ne 0
	and pvAnnualProfit <= &VaR90.
	;
quit;

proc sql;
	title 'VaR al 90% de confianza y horizonte hasta que se acaben los pasivos';
	select estimate format comma16. into: VaR90f
	from prft.quantiles
	where Quantile="10%"
	;
	title 'CTE al 90% de confianza y horizonte hasta que se acaben los pasivos';
	select mean(pvAnnualProfit) format comma16. into: CTE90f
	from prft.pvprofits
	where cve_scenario ne 0
	and pvAnnualProfit <= &VaR90.
	;
quit;

ods graphics / reset width=6.4in height=6in imagemap noborder;
title 'Histograma, escenario base, VaR y CTE';
proc sgplot data=prft.pvprofits(where=(cve_scenario ne 0));
 	histogram pvAnnualProfit / fillattrs=(color=blue transparency=0.97);
 	density pvAnnualProfit / lineattrs=(color=red);
 	refline &pvProfitBase. / axis=x lineattrs=(color=green pattern=15) label = ("Esc. Base=&pvProfitBasef.");
 	refline &VaR90. / axis=x lineattrs=(color=yellow pattern=15) label = ("VaR90=&VaR90f.");
 	refline &CTE90. / axis=x lineattrs=(color=red pattern=15) label = ("CTE90=&CTE90f."); 	
	xaxis grid;
	yaxis grid;
run;


