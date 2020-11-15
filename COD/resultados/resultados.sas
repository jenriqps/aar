/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/


options mprint mlogic minoperator fullstimer;
ods graphics / reset width=6.4in height=4.8in imagemap noborder;

%include "&root./COD/configuracion.sas";
%include "&root./COD/staging/profit/macrosProfit.sas";

options  fmtsearch=(ext);


ods graphics / reset imagemap noborder;
ods layout gridded columns=2;
ods region;
title "Liabilities - Reserves";
title2 "by Year";
proc sgplot data=cact.reserve_year;
	needle x=num_year y=mnt_reserveTotal/lineattrs=(color=pink pattern=2 thickness=1) markers markerattrs=(color=purple SYMBOL=circlefilled); 
	xaxis grid;
	yaxis grid;
run;
title;

ods graphics / reset imagemap noborder;
ods region;
title "Liabilities - Projected Payments";
title2 "by Year";
proc sgplot data=cact.projcf_year;
	needle x=num_year y=mnt_projPymtTot/lineattrs=(color=yellow pattern=2 thickness=1) markers markerattrs=(color=orange SYMBOL=circlefilled); 
	xaxis grid;
	yaxis grid;
run;
title;
ods layout end;

* Asset #1;

proc sort data=cfin.asset(where=(id=1 and num_year>0)) out=cfin.assetSort;
	by cve_scenario num_year;
run;

data cfin.asset2paths;
	label num_flag="Is the asset value equal to zero? (0: No, 1: Yes, .: It does not exist))";
	set cfin.assetSort(where=(id=1 and num_year>0 and num_year<13));
	if val_assetValue > 0 then num_flag = 0; 
	if val_assetValue = 0 and lag(num_flag)=0 and cve_scenario=lag(cve_scenario) then num_flag=1; 
run;

ods graphics / width=10in height=6in imagemap noborder;
title "Assets - Paths of asset value scenarios of Asset #1 (Coupon bond)";
title2 "Is the asset value equal to zero? (0: No, 1: Yes, .: It does not exist))";
%sankeybarchart
 (data=cfin.asset2paths
 ,subject=cve_scenario
 ,yvar=num_flag
 ,xvar=num_year
 ,barwidth=0.5
 ,completecases=no
 ,debug=no 
 );

ods graphics / reset imagemap noborder;
ods layout gridded columns=2;
ods region;
title 'Assets - Heatmap of the asset value scenarios of Asset #1 (Coupon bond)';
proc sgplot data=cfin.asset(where=(id=1 and num_year>0));
	heatmap x=num_year y=val_assetValue / colorstat=freq nxbins=14 /*nybins=10*/ showybins showxbins;
	xaxis grid;
	yaxis grid;	
run;
title;

ods graphics / reset imagemap noborder;
ods region;
title 'Assets - Heatmap of the cash flow scenarios of Asset #1 (Coupon bond)';
proc sgplot data=cfin.asset(where=(id=1 and num_year>0));
	heatmap x=num_year y=val_cashFlow / colorstat=freq nxbins=14 /*nybins=10*/ showybins showxbins;
	xaxis grid;
	yaxis grid;
run;
title;
ods layout end;


* Asset #2;
ods graphics / reset imagemap noborder;
title 'Assets - Paths of asset value scenarios of Asset #2 (Zero-coupon bond)';
proc sgplot data=cfin.asset(where=(id=2 and num_year>0));
	series x=num_year y=val_assetValue / group=cve_scenario;
run;
title;

ods graphics / reset imagemap noborder;
ods layout gridded columns=2;
ods region;
title 'Assets - Heatmap of the asset value scenarios of Asset #2 (Zero-coupon bond)';
proc sgplot data=cfin.asset(where=(id=2 and num_year>0));
	heatmap x=num_year y=val_assetValue / colorstat=freq /*nxbins=14 nybins=10*/ showybins showxbins;
	xaxis grid;
	yaxis grid;
run;
title;

ods graphics / reset imagemap noborder;
ods region;
title 'Assets - Heatmap of the cash flow scenarios of Asset #2 (Zero-coupon bond)';
proc sgplot data=cfin.asset(where=(id=2 and num_year>0));
	heatmap x=num_year y=val_cashFlow / colorstat=freq /*nxbins=14 nybins=10*/ showybins showxbins;
run;
title;
ods layout end;


* Asset #3;

ods graphics /reset imagemap noborder;
ods layout gridded columns=2;
ods region;
title 'Assets - Heatmap of the asset value scenarios of Asset #3 (Mortgage bond)';
proc sgplot data=cfin.asset(where=(id=3 and num_year>0));
	heatmap x=num_year y=val_assetValue / colorstat=freq /*nxbins=14 nybins=10*/ showybins showxbins;
	xaxis grid;
	yaxis grid;
run;
title;

ods graphics / reset imagemap noborder;
ods region;
title 'Assets - Heatmap of the cash flow scenarios of Asset #3 (Mortgage bond)';
proc sgplot data=cfin.asset(where=(id=3 and num_year>0));
	heatmap x=num_year y=val_cashFlow / colorstat=freq /*nxbins=14 nybins=10*/ showybins showxbins;
	xaxis grid;
	yaxis grid;
run;
title;
ods layout end;


* Todos los activos;
ods graphics / reset imagemap noborder;
ods layout gridded columns=2;
ods region;
title 'Total Assets';
proc sgplot data=cfin.assets_year(where=(num_year>0));
	heatmap x=num_year y=val_assetTotal / colorstat=freq /*nxbins=14 nybins=10*/ showybins showxbins;
	xaxis grid;
	yaxis grid;
run;
title;

ods graphics / reset imagemap noborder;
ods region;
title 'Total Asset Cash Flows';
proc sgplot data=cfin.assetscf_year(where=(num_year>0));
	heatmap x=num_year y=val_assetCFTotal / colorstat=freq /*nxbins=14 nybins=10*/ showybins showxbins;
	xaxis grid;
	yaxis grid;
run;
title;
ods layout end;





ods graphics / reset width=8in height=9in imagemap noborder;
title "Profit - Investment Income";
title2 "by Year";
proc sgpanel data=prft.profit;
	panelby num_year / uniscale=all columns=3 rows=10;
 	histogram mnt_investIncome / fillattrs=(color=red transparency=0.8);
run;
title;

title "Profit - Benefits plus Expenses";
title2 "by Year";
proc sgpanel data=prft.profit;
	panelby num_year / uniscale=all columns=3 rows=10;
 	histogram mnt_benefitsPlusExpenses / fillattrs=(color=red transparency=0.8);
run;
title;



title "Profit -  Increase in Reserves";
title2 "by Year";
proc sgpanel data=prft.profit;
	panelby num_year / uniscale=all columns=3 rows=10;
 	histogram mnt_increaseReserves / fillattrs=(color=red transparency=0.8);
run;
title;

title "Profit - Annual Profits";
title2 "by Year";
proc sgpanel data=prft.profit;
	panelby num_year / uniscale=all columns=3 rows=10;
 	histogram mnt_annualProfit / fillattrs=(color=red transparency=0.8);
run;
title;


title "Profit - Present Value of Annual Profits";
title2 "by Year";
proc sgpanel data=prft.profit;
	panelby num_year / uniscale=all columns=3 rows=10;
 	histogram mnt_pvAnnualProfit / fillattrs=(color=blue transparency=0.8);
run;
title;


proc sql noprint;
	select pvAnnualProfit format 16.2 into: pvProfitBase trimmed
	from prft.pvprofits
	where cve_scenario = 0
	;
	select pvAnnualProfit format comma16. into: pvProfitBasef trimmed
	from prft.pvprofits
	where cve_scenario = 0
	;
quit;

* Statistics on the PV of profits;
proc sort data=prft.profit out=work.profit_s;
	by num_year;
run;

proc means data=work.profit_s noprint;
	by num_year;
	var mnt_pvAnnualProfit;
	output out=work.profit_sum;
run;

* Binning of PV of annual profits;
proc hpbin data=prft.PVPROFITS numbin=16 pseudo_quantile computequantile;
input pvAnnualProfit;
run;

proc hpbin data=prft.PVPROFITS;
input pvAnnualProfit;
run;


/*
* Cálculo de VaR y CTE
*/

proc sql noprint;
	* Nivel de confianza;
	select val_parametro into: confLevel trimmed
	from ext.parametros
	where id_parameter = 15
	;
	* Definición del percentil;
	select val_parametro into: pctdef trimmed
	from ext.parametros
	where id_parameter = 16
	;
quit;

%put &confLevel.;
%let confLevel = %trim(&confLevel.);
%put &confLevel.;

proc univariate data=prft.pvprofits(where=(cve_scenario ne 0)) pctldef=&pctdef. noprint;
	var pvAnnualProfit;
	output out = prft.percentiles pctlpts = &confLevel PCTLPRE=p_;
run;

proc sql noprint;
	select p_&confLevel. format 16.2 into: VaR%trim(&confLevel.) trimmed
	from prft.percentiles
	;
	select mean(pvAnnualProfit) format 16.2 into: CTE&confLevel. trimmed
	from prft.pvprofits
	where cve_scenario ne 0
	and pvAnnualProfit < &&VaR&confLevel.
	;
quit;

proc sql;
	ods layout gridded columns=2;
	ods region;
	title "VaR al &confLevel.% de confianza y horizonte hasta que se acaben los pasivos";
	select p_&confLevel. format comma16. into: VaR&confLevel.f trimmed
	from prft.percentiles
	;
	ods region;
	title "CTE al &confLevel.% de confianza y horizonte hasta que se acaben los pasivos";
	select mean(pvAnnualProfit) format comma16. into: CTE&confLevel.f trimmed
	from prft.pvprofits
	where cve_scenario ne 0
	and pvAnnualProfit < &&VaR&confLevel.
	;
	ods layout end;
quit;

ods graphics / reset width=6.4in height=6in imagemap noborder;
title 'Histograma';
title2 'Escenario base, VaR y CTE';
proc sgplot data=prft.pvprofits(where=(cve_scenario ne 0));
 	histogram pvAnnualProfit / fillattrs=(color=blue transparency=0.97);
 	density pvAnnualProfit / lineattrs=(color=red);
 	refline &pvProfitBase. / axis=x lineattrs=(color=green pattern=15) label = ("Esc. Base=&pvProfitBasef.");
 	refline &&VaR&confLevel. / axis=x lineattrs=(color=yellow pattern=15) label = ("VaR=&&VaR&confLevel.f");
 	refline &&CTE&confLevel. / axis=x lineattrs=(color=red pattern=15) label = ("CTE=&&CTE&confLevel.f"); 	
	xaxis grid;
	yaxis grid;
run;

* We export the results to an Excel file;
proc export data=prft.pvprofits dbms=xlsx outfile="&root./DAT/staging/profit/pvprofits.xlsx" replace;
run;


