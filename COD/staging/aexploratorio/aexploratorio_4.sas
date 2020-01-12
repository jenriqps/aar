/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

%include "&root./COD/configuracion.sas";
ods graphics / reset width=6.4in height=4.8in imagemap noborder;
options  fmtsearch=(ext);


/*
 * 4 We identify the terms
 */

ods graphics / reset width=8in height=8in imagemap noborder;

title "Panel of the distribution of the scenarios of the annual forward rate";
proc sgpanel data=ext.esctasasinteres(where=(num_year ne 1));
	panelby num_year / uniscale=all columns=5 rows=6;
 	histogram pct_rate / fillattrs=(color=orange transparency=0.7);
 	density pct_rate / lineattrs=(color=red);
run;
title;

