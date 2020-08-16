/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

ods graphics / reset imagemap noborder;

title "Annual interest rate charged on the loan";
proc sgplot data=work.bd_viv;
	histogram pct_annualYield / group=cd_lendingInstitution fillattrs=(color=brown transparency=0.7);
run;

title "Remaining years of the loan";
proc sgplot data=work.bd_viv;
	histogram num_remainingYears / group=cd_lendingInstitution fillattrs=(color=brown transparency=0.7);
run;
title "Outstanding Principal";
proc sgplot data=work.bd_viv;
	histogram mnt_outsPrincipal / group=cd_lendingInstitution fillattrs=(color=brown transparency=0.7);
run;

title "Number of years to maturity";
proc sgplot data=work.bd_viv;
	histogram num_maturityYears / group=cd_lendingInstitution fillattrs=(color=brown transparency=0.7);
run;

title "Value of the house";
proc sgplot data=work.bd_viv;
	histogram mnt_valueHouse / group=cd_lendingInstitution fillattrs=(color=brown transparency=0.7);
run;

title "Loan to Value Ratio";
proc sgplot data=work.bd_viv;
	histogram LtV / group=cd_lendingInstitution fillattrs=(color=brown transparency=0.7);
run;

title "Months in default";
proc sgplot data=work.bd_viv;
	vbar num_defaultmonths / group=cd_lendingInstitution fillattrs=(color=green transparency=0.97) stat=percent;
run;

title "Loan currency";
proc sgplot data=work.bd_viv;
	vbar cd_currency / fillattrs=(color=green transparency=0.97) stat=percent;
run;

title "Lending Institution";
proc sgplot data=work.bd_viv;
	vbar cd_lendingInstitution / fillattrs=(color=green transparency=0.97) stat=percent;
run;
