/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

options mprint mlogic minoperator fullstimer;

%include "&root./COD/staging/cactuarial/macrosCActuarial.sas";
%include "&root./COD/configuracion.sas";


/* We add the reservers per year */

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
