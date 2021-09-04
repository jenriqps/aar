/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

/*
Chapter 4: Tipos de Riesgo
Exercise 6
*/

DATA myel;
label treat="Drug treatments" dur="Time in days from the point of randomization to either death or censoring"
status="Variable has a value of 1 for those who died and 0 for those who were censored"
renal="Indicator variable for normal (1) versus impaired (0) renal functioning at the time of randomization"
;
INPUT dur status treat renal;
DATALINES;
8 1 1 1
180 1 2 0
632 1 2 0
852 0 1 0
52 1 1 1
2240 0 2 0
220 1 1 0
63 1 1 1
195 1 2 0
76 1 2 0
70 1 2 0
8 1 1 0
13 1 2 1
1990 0 2 0
1976 0 1 0
18 1 2 1
700 1 2 0
1296 0 1 0
1460 0 1 0
210 1 2 0
63 1 1 1
1328 0 1 0
1296 1 2 0
365 0 1 0
23 1 2 1
;

proc print data=myel;
run;

PROC LIFETEST DATA=myel PLOTS=S(NOCENSOR ATRISK CL CB=EP)  OUTSURV=a alpha=0.05;
TIME dur*status(0);
RUN;

PROC LIFETEST DATA=myel PLOTS=S(NOCENSOR ATRISK CL CB=EP TEST);
TIME dur*status(0);
STRATA treat;
RUN;