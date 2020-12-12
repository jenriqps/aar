
/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

* Getting the data set of policies;

* Bancomer ;
data work.bd_viv(drop=i label="Policies on Mortgages");
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
		num_remainingYears = rand("binomial",0.5,28); 
		mnt_outsPrincipal = rand("exponential")*1000000; 
		cd_currency = "MXN";
		cd_lendingInstitution = "BANCOMER";
		num_maturityYears = 30 -  num_remainingYears;
		num_defaultmonths = rand("binomial",0.01,12); 
		mnt_payment=mort(mnt_outsPrincipal,.,pct_annualYield,num_maturityYears);
		mnt_valueHouse = mort(.,mnt_payment,pct_annualYield,num_maturityYears)*(rand("Uniform")*0.1+1.2);
		LtV = mnt_outsPrincipal / mnt_valueHouse;
		output;		
	end;
run;


* Banamex ;
data work.bd_viv_2(drop=i);
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
		pct_annualYield = rand("Uniform")*0.1+0.06; 
		num_remainingYears = rand("binomial",0.5,30); 
		mnt_outsPrincipal = rand("exponential")*1100000; 
		cd_currency = "MXN";
		cd_lendingInstitution = "BANAMEX";
		num_maturityYears = 30 -  num_remainingYears;
		num_defaultmonths = rand("binomial",0.02,12); 
		mnt_payment=mort(mnt_outsPrincipal,.,pct_annualYield,num_maturityYears);
		mnt_valueHouse = mort(.,mnt_payment,pct_annualYield,num_maturityYears)*(rand("Uniform")*0.1+1);
		LtV = mnt_outsPrincipal / mnt_valueHouse;
		output;		
	end;
run;

proc append base=work.bd_viv data=work.bd_viv_2;
run;

proc sort data=work.bd_viv out=work.bd_viv;
	by cd_lendingInstitution;
run;

* Getting the Factor Requerimiento de Capital V;

* Change the following path based on the location of your file FactorRequCapitalV.xlsx;
FILENAME REFFILE '/home/jenriqps/aar/Exercises/FactorRequCapitalV.xlsx';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.FactorRequCapitalV REPLACE;
	GETNAMES=YES;
RUN;

* Deleting temporal data sets ;
proc datasets lib=work nodetails nolist;
	delete bd_viv_2;
quit;

