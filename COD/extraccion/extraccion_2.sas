/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

options  fmtsearch=(ext);

%include "&root./COD/configuracion.sas";


/* Input 2 */
/*
 * Insured people
 */

PROC IMPORT DATAFILE=REFFILE
	DBMS=xlsx
	OUT=work.asegurados REPLACE;
	GETNAMES=YES;
	sheet="asegurados";
RUN;

data ext.asegurados(label="Characteristics of the annuities");
	format mnt_annualPayment comma30.2 fec_issueDate fec_currentDate date9.;
	label 
		id_annuity = 'Annuities'
		num_issueAge ='Male Issue Age'
		fec_issueDate ='Issue Date'
		fec_currentDate ='Current Date'
		mnt_annualPayment ='Annual Payment'
		num_originalTotalYearsPayments = 'Original Total Years of Payments'
		num_originalCertainYears = 'Original Certain Years' 	
		num_extraPymt = 'Number of extra payments';
	set work.asegurados;
run;

* We add an index;
proc datasets library=ext nolist nodetails;
	modify asegurados;
	index create id_annuity / nomiss unique;
quit;

