/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

%include "&root./COD/configuracion.sas";
ods graphics / reset width=6.4in height=4.8in imagemap noborder;
options  fmtsearch=(ext);


/* 5 Insured people */
title "Characteristics of the insured people";
proc print data=ext.asegurados label;
run;

