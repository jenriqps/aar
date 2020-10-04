/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

options mprint mlogic minoperator fullstimer;

%include "&root./COD/staging/cfinancieros/macrosCFinancieros.sas";
%include "&root./COD/configuracion.sas";

/* 0 We clean the previous data sets */

proc datasets lib=cfin kill nolist;
run;
