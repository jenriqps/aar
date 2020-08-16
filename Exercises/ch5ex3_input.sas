
/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

* Getting the data set of policies;

data work.bd_viv(drop=i);
	call streaminit(2020);
	length cd_lendingInstitution $30;
	label 
	id = "ID policy"
	mnt_outsPrincipal = "Outstanding Principal"
	pct_annualYield = "Annual interest rate charged on the loan"
	num_remainingYears = "Remaining years of the loan"
	cd_currency = "Loan currency"
	cd_lendingInstitution = "Lending Institution"
	num_maturityYears = "Number of years to maturity"
	num_defaultmonths = "Months in default"
	mnt_valueHouse = "Value of the house"
	LtV = "Loan to Value Ratio"
	;
	format mnt_outsPrincipal mnt_payment mnt_valueHouse nlnum16.2 LtV pct_annualYield percentn10.2;	
	do i=1 to 1500;
		id = "CV"||put(i,z5.);
		pct_annualYield = rand("Uniform")*0.1+0.05; 
		num_remainingYears = rand("binomial",0.5,30); 
		mnt_outsPrincipal = rand("exponential")*1000000; 
		cd_currency = "MXN";
		if i < 751 then cd_lendingInstitution = "BANAMEX";
		else cd_lendingInstitution = "BANCOMER";
		num_maturityYears = 30 -  num_remainingYears;
		num_defaultmonths = rand("binomial",0.01,12); 
		mnt_payment=mort(mnt_outsPrincipal,.,pct_annualYield,num_maturityYears);
		mnt_valueHouse = mort(.,mnt_payment,pct_annualYield,num_maturityYears)*(rand("Uniform")*0.1+1.2);
		LtV = mnt_outsPrincipal / mnt_valueHouse;
		output;		
	end;
run;

* Getting the Factor Requerimiento de Capital V;

FILENAME REFFILE '/folders/myfolders/aar/Exercises/FactorRequCapitalV.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.FactorRequCapitalV REPLACE;
	GETNAMES=YES;
RUN;

proc datasets lib=work nodetails nolist;
	modify FactorRequCapitalV;
	rename var1=MesesVencidos;
	label MesesVencidos = "Número de meses vencidos";
quit;

