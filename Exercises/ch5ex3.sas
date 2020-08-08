* http://www2.ssn.unam.mx:8080/mapas-de-intensidades/;

/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/


data work.bd_viv(drop=i);
	label 
	id = "ID of the insurance"
	mnt_outsPrincipal = "Outstanding Principal"
	pct_annualYield = "Annual interest rate charged on the loan"
	num_remainingYears = "Remaining years of the loan"
	cd_currency = "Currency of the loan"
	cd_institution = "Institution that gives the loan"
	;
	format mnt_outsPrincipal nlnum16.2 pct_annualYield percentn10.2;	
	do i=1 to 1000;
		id = "CV"||put(i,z5.);
		pct_annualYield = rand("Uniform")*0.1+0.05; 
		num_remainingYears = rand("binomial",0.5,30); 
		mnt_outsPrincipal = rand("exponential")*1000000; 
		cd_currency = "MXN";
		cd_institution = "BANAMEX";
		num_maturityYears = 30 -  num_remainingYears;
		num_duemonths = rand("binomial",0.05,12); 
		output;		
	end;
run;