/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

options mprint mlogic minoperator fullstimer;


%include "&root./COD/staging/cactuarial/macrosCActuarial.sas";
%include "&root./COD/configuracion.sas";


proc datasets lib=cact kill nolist;
run;

* Obtenemos la tasa de interés para el cálculo de las reservas;
proc sql noprint;
	select val_parametro into: i_reserve
	from ext.parametros
	where id_parameter = 14
	;
quit;


%reserve_v2(id_annuity=1,val_i=&i_reserve.)
%reserve_v2(id_annuity=2,val_i=&i_reserve.)
%reserve_v2(id_annuity=3,val_i=&i_reserve.)
;


