/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/


%global root;
%let root=/folders/myfolders/aar;

%include "&root./COD/staging/aexploratorio/configuracion.sas";
ods graphics / reset width=6.4in height=4.8in imagemap noborder;


proc datasets lib=aexpl kill nolist;
run;

/*
 * Tabla de mortalidad
 */

title 'Mortality table';
proc sgplot data=ext.tablamortalidad;
	step x=val_age y=val_1000qx / lineattrs=(color=orange);
	xaxis grid;
	yaxis grid;
run;
title;


/*
 * Escenarios de la curva de interés
 */

title 'Scenarios of the annual forward rate';
proc sgplot data=ext.esctasasinteres;
	series x=num_year y=pct_rate / group=cve_scenario;
run;
title;

title 'Heatmap of the scenarios of the annual forward rate';
proc sgplot data=ext.esctasasinteres;
	heatmap x=num_year y=pct_rate / colorstat=freq nxbins=50 nybins=10 showybins showxbins;
run;
title;

/*
 * Identificamos los diferentes nodos
 */

ods graphics / reset width=8in height=8in imagemap noborder;

title "Panel of the distribution of the scenarios of the annual forward rate";
proc sgpanel data=ext.esctasasinteres(where=(num_year ne 1));
	panelby num_year / uniscale=all columns=5 rows=6;
 	histogram pct_rate / fillattrs=(color=orange transparency=0.7);
 	density pct_rate / lineattrs=(color=red);
run;
title;

ods graphics / reset width=6.4in height=4.8in imagemap noborder;

%macro histogramas();

	proc sql noprint;
		create table work.years as
		select distinct num_year
		from ext.esctasasinteres
		;
		select count(*) into: num
		from work.years
		;
		select num_year into: year1-
		from work.years
		;	
	quit;
	
	%do i=1 %to &num.;
	title "Histograma de las tasas generadas en el año &&&&year&&i.";

/* Dejar lo siguiente porque a veces falla proc univariate (los histogramas) */	
	/*
	proc sgplot data=ext.esctasasinteres;
		where num_year=&&&&year&&i.;
		histogram pct_rate;
	run;
*/
	proc univariate data=ext.esctasasinteres(where=(num_year=&&&&year&&i.));
		var pct_rate;
		histogram pct_rate/normal grid;
	run;	

	%end;
%mend;

*%histogramas;

/* Asegurados */
title "Characteristics of the insured people";
proc print data=ext.asegurados label;
run;

title "Buble plot of the characteristics of the insured people";
proc sgplot data=ext.asegurados;
	bubble x=num_issueAge y=num_originalTotalYearsPayments size=num_originalCertainYears / colorresponse=mnt_annualPayment;
	xaxis grid;
	yaxis grid;
run;

title "Characteristics of the financial assets";
proc print data=ext.activosfinancieros label;
run;

title "Callable bonds";
proc sgplot data=ext.activosfinancieros;
	vbar flg_callable  / response=pct_portfolio group=cod_asset;
	yaxis grid;
run;

title "Annual Yield";
proc sgplot data=ext.activosfinancieros;
	vbar dsc_asset  / response=pct_annualYield group=cod_asset;
	yaxis grid;
run;

title "Years of call protection";
proc sgplot data=ext.activosfinancieros;
	vbar dsc_asset  / response=num_YrsCallProtection group=cod_asset;
	yaxis grid;
run;

title "Remaining years";
proc sgplot data=ext.activosfinancieros;
	vbar dsc_asset  / response=num_remainingYears group=cod_asset;
	yaxis grid;
run;





