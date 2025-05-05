/* Código generado (IMPORT) */
/* Archivo de origen: FEDFUNDS.xlsx */
/* Ruta de origen: /home/jenriqps/aar/Exercises */
/* Código generado el: 5/5/25 13:09 */

%web_drop_table(MYLIB.FEDFUNDS);


%put &_metauser.;
FILENAME REFFILE "/home/&_metauser./aar/Exercises/FEDFUNDS.xlsx";

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=MYLIB.FEDFUNDS;
	GETNAMES=YES;
	SHEET="Monthly";
RUN;

PROC CONTENTS DATA=MYLIB.FEDFUNDS; RUN;


%web_open_table(MYLIB.FEDFUNDS);

proc gplot data=MYLIB.FEDFUNDS;
   plot FEDFUNDS*observation_date / haxis=axis1 vaxis=axis2 /*cframe=ligr*/ ;
   symbol1 c=green i=join;
   axis1 order=('01jan54'd, '01jan65'd, '01jan70'd, '01jan75'd,
                '01jan80'd, '01jan85'd, '01jan90'd, '01jan95'd,
                '01jan00'd, '01jan2005'd, '01jan2010'd, '01jan2015'd, '01jan2020'd, '01may2025'd)
                label=('Date');
   axis2 label=(angle=90 'Fed Fund Rate');
   title1 "Effective Monthly Federal Funds Rate";
run;
quit;


/* Heteroscedastic Modeling of the Fed Funds Rate */


proc model data=MYLIB.FEDFUNDS;
      id observation_date;
      FEDFUNDS = lag(FEDFUNDS) + kappa  * (theta - lag(FEDFUNDS));
      lag_FEDFUNDS = lag( FEDFUNDS );
      label kappa = "Speed of Mean Reversion";
      label theta = "Long term Mean";
   fit FEDFUNDS / fiml breusch=( lag_FEDFUNDS ) out=resid outresid;
run;


proc gplot data=resid;
   plot FEDFUNDS*observation_date / haxis=axis1 vaxis=axis2 ;
   symbol1 c=blue i=join;
   axis1 order=('01jan54'd, '01jan65'd, '01jan70'd, '01jan75'd,
                '01jan80'd, '01jan85'd, '01jan90'd, '01jan95'd,
                '01jan00'd, '01jan2005'd, '01jan2010'd, '01jan2015'd, '01jan2020'd, '01may2025'd)
                label=('Date');
   axis2 label=(angle=90 'Fed Fund Residuals');
   title1 "Effective Monthly Federal Funds Rate";
   title2 "Vasicek Model";
run;
quit;
