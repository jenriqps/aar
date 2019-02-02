/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

options mprint mlogic minoperator fullstimer;

%global root;
%let root=/folders/myfolders/aar;

%include "&root./COD/staging/cactuarial/macrosCActuarial.sas";
%include "&root./COD/staging/cactuarial/configuracion.sas";


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


/* Unimos todas las reservas en un tabla, máxima granularidad */ 

data cact.reserve;
	set work.res_id_:;
run;

proc datasets lib=work kill nolist;
run;



/* Agregamos las reservas por anio */

proc sql;
	create table cact.reserve_year as
		select num_year, sum(mnt_reserveTotal) format comma16.2 as mnt_reserveTotal
		from cact.reserve
		group by num_year
		;
quit;


proc sql;	
		create table cact.projCF_year as
		select num_year, sum(mnt_projPymtTot) format comma16.2 as mnt_projPymtTot 
		from cact.reserve
		group by num_year
		;
quit;

proc datasets library=cact;
	modify reserve_year;
	format 
		mnt_reserveTotal dollar32.;
	label 
		num_year="Year" 
		mnt_reserveTotal="Total Reserve"
		;
	modify projcf_year;
	format 
		mnt_projPymtTot dollar32.;
	label 
		num_year="Year" 
		mnt_projPymtTot="Total Projected Payments"
		;	
quit;
