/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

%include "&root./COD/configuracion.sas";
ods graphics / reset width=6.4in height=4.8in imagemap noborder;
options  fmtsearch=(ext);

%let radix = 1000000;



/*
 * 3 Scenarios of the annual forward rate
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


