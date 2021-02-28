/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

/*
Chapter 4: Tipos de Riesgo
Exercise 5
*/


data work.hurricaneloss;
label year="Year" loss = "Loss (1000)";
format year date9. loss comma32.;
input year date9. loss comma32.;
datalines;
01JAN1949 41,409  
01JAN1950 49,397  
01JAN1954 52,600 
02JAN1954 513,586 
03JAN1954 545,778 
01JAN1955 18,383 
02JAN1955 102,942  
01JAN1956 14,474 
01JAN1957 123,680 
01JAN1958 19,030 
01JAN1959 29,112 
02JAN1959 47,905  
01JAN1960 329,511 
01JAN1961 15,351 
02JAN1961 361,200 
01JAN1964 40,596  
02JAN1964 77,809  
03JAN1964 227,338 
04JAN1964 6,766
05JAN1964 1,638,000 
01JAN1966 16,983 
01JAN1967 103,217 
01JAN1968 7,123 
01JAN1969 421,680 
01JAN1970 750,389 
01JAN1971 10,562 
02JAN1971 30,146 
01JAN1972 198,446 
01JAN1973 59,917 
01JAN1974 25,304 
01JAN1975 192,013 
01JAN1976 33,727 
01JAN1979 140,136 
02JAN1979 863,881 
01JAN1980 63,123  
;


ods noproctitle;
ods graphics / imagemap=on;

* Exploration of the data;

proc sort data=WORK.HURRICANELOSS out=Work.preProcessedData;
	by year;
run;

proc timeseries data=Work.preProcessedData plots=(series histogram cycles corr) 
		print=(descstats trends);
	id year interval=year;
	var loss / accumulate=total transform=none dif=0;
run;

proc delete data=Work.preProcessedData;
run;

* Estimation of the distribution ;

proc severity data=work.hurricaneloss print=all;
   loss loss / lefttruncated=5000;
   dist _all_;
   nloptions maxiter=100000;
run;


data work.test;
	x = quantile('TWEEDIE',0.95,2.49920,0.00707);
run;

/*
2.49920,204900,0.00707
*/
