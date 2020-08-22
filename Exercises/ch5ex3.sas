/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 * Exercise 3 Chapter 5;
 **********************************************************************/

ods graphics / reset imagemap noborder;

ods layout gridded columns=2;

ods region;
title "Annual interest rate charged on the loan";
proc sgplot data=work.bd_viv;
	histogram pct_annualYield / group=cd_lendingInstitution;
run;

ods region;
proc means data=work.bd_viv;
	class cd_lendingInstitution;
	var pct_annualYield;
run;

ods region;
title "Remaining years of the loan";
proc sgplot data=work.bd_viv;
	histogram num_remainingYears / group=cd_lendingInstitution ;
run;

ods region;
proc means data=work.bd_viv;
	class cd_lendingInstitution;
	var num_remainingYears;
run;


ods region;
title "Outstanding Principal";
proc sgplot data=work.bd_viv;
	histogram mnt_outsPrincipal / group=cd_lendingInstitution ;
run;

ods region;
proc means data=work.bd_viv;
	class cd_lendingInstitution;
	var mnt_outsPrincipal;
run;



ods region;
title "Number of years to maturity";
proc sgplot data=work.bd_viv;
	histogram num_maturityYears / group=cd_lendingInstitution ;
run;

ods region;
proc means data=work.bd_viv;
	class cd_lendingInstitution;
	var num_maturityYears;
run;


ods region;
title "Value of the house";
proc sgplot data=work.bd_viv;
	histogram mnt_valueHouse / group=cd_lendingInstitution ;
run;


ods region;
proc means data=work.bd_viv;
	class cd_lendingInstitution;
	var mnt_valueHouse;
run;

ods region;
title "Loan to Value Ratio";
proc sgplot data=work.bd_viv;
	histogram LtV / group=cd_lendingInstitution ;
run;

ods region;
proc means data=work.bd_viv;
	class cd_lendingInstitution;
	var LtV;
run;

ods region;
title "Months in default";
proc sgplot data=work.bd_viv;
	vbar num_defaultmonths / group=cd_lendingInstitution  stat=percent;
run;


ods region;
proc means data=work.bd_viv;
	class cd_lendingInstitution;
	var num_defaultmonths;
run;


ods region;
title "Loan currency";
proc sgplot data=work.bd_viv;
	vbar cd_currency /  stat=percent;
run;

ods region;
title "Lending Institution";
proc sgplot data=work.bd_viv;
	vbar cd_lendingInstitution /  stat=percent;
run;

* Exercise 3.d ;

* Postprocessing the insurance and the capital requirement factor data sets;

proc sql;
	create table work.bd_viv_2 as
		select a.*
		, case 
		when a.LtV > 0.884057 then "l > 88.4057%"
		else "l <= 88.4057%" end as l label="LTV actual"
		, case 
		when num_maturityYears > 60 then "m>60"
		else "m<=60" end as m label = "Madurez (meses)"		
		from work.bd_viv a
		;
	create table work.FACTORREQUCAPITALV_2 as
		select 
		a.*
		, case
		when "Meses vencido"n not like "26%" then input("Meses vencido"n,2.)
		else 26 end as r label = "Meses vencidos"
		, case
		when upcase("Moneda c"n) = "PESOS" then "MXN"
		else "OTRO" end as c label = "Moneda"
		from work.FACTORREQUCAPITALV a
		;
quit;


* Joining the tables to get the capital requirement factor;
proc sql;
	create table work.resultado as
	select a.*
	, b.V 
	, mnt_outsPrincipal*b.V as MRVR format=nlnum16.2
	from work.bd_viv_2 a inner join work.FACTORREQUCAPITALV_2 b
	on (a.num_defaultmonths=b.r and a.cd_currency = b.c and a.l = b."LTV actual"n and a.m = "Madurez (meses)"n)
	;
quit;


/*

data _NULL_;
	dcl odsout obj1();
	obj1.image(file:"C:\Users\jenri\Google Drive\Cosas del trabajo\SAS\SASUniversityEdition\myfolders\aar\Exercises\t647a.png");
run;

*/
