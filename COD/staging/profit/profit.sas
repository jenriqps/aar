/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

options mprint mlogic minoperator fullstimer;

%global root;
%let root=/folders/myfolders/aar;


%include "&root./COD/staging/profit/configuracion.sas";
%include "&root./COD/staging/profit/macrosProfit.sas";


proc datasets lib=prft kill nolist;
run;

/* Tasa actual de Treasuries */
proc sql noprint;
	select val_parametro into: val_Trsry
	from ext.parametros
	where id_parameter=2
	;	
quit;

%let max_years = 200; 

	data work.curve_int;		
		do num_year=0 to &max_years.;
			val_int = &val_Trsry.; 
			output;
		end;
	run;



/* Escenario base */
%profit_v2(curve=curve_int,sim=0);

/* Escenarios alternativos */

%simAllProfits_v2(maxSim=100);

data prft.profit;
	set work.profit_:;
run;


proc datasets lib=work kill nolist;
run;


proc sql;
	create table prft.pvProfits as
	select 
		cve_scenario
		, sum(mnt_pvAnnualProfit) format comma16.2 as pvAnnualProfit
	from prft.profit
	group by cve_scenario
	;
quit;






