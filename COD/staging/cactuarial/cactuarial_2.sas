/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

options mprint mlogic minoperator fullstimer;

%include "&root./COD/staging/cactuarial/macrosCActuarial.sas";
%include "&root./COD/configuracion.sas";


/* We join all the reserves in one table at the maximum detail */ 

data cact.reserve;
	set work.res_id_:;
run;

proc datasets lib=work kill nolist;
run;



