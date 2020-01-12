/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

options  fmtsearch=(ext);

%include "&root./COD/configuracion.sas";

/* We clean the Work library */
	
proc datasets lib=work kill nolist;
run;
	
