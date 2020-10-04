/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 * Exercise 4 Chapter 5;
 **********************************************************************/

* Declaring a library that reads the XML file;

options mprint mlogic minoperator fullstimer;


filename tb temp;
libname tb xmlv2 "&root./Exercises/DailyTreasuryYieldCurveRateData.xml" automap=replace xmlmap=tb;

* We join two data sets to prepare the time series data set;

proc sql;
	create table work.tb3y as
		select datepart(b.new_date) as date format=date9. label = "Date"
		, a.bc_3year/100 as tbill3y format=percentn10.2 label="Daily Treasury Yield Curve Rates 3 Yr"
		from tb.bc_3year a inner join tb.new_date b
		on (a.properties_ordinal = b.properties_ordinal)
		order by date
		;
quit;


