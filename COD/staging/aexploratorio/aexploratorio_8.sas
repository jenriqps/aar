/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

%include "&root./COD/configuracion.sas";
ods graphics / reset width=6.4in height=4.8in imagemap noborder;
options  fmtsearch=(ext);


/* We clean the Work library */
	
proc datasets lib=work kill nolist;
run;





