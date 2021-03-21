/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

/*
Chapter 3: La influencia del reaseguro en la Administración del Riesgo
Exercise 2
*/

data work.ec(label="Economic Capital");
	label amount_a="Reinsured Block A" amount_b="Reinsured Block B";
	format amount_a amount_b dollar32.2;
	input amount_a amount_b;
	datalines;
170 325
;


proc iml;

start Func1(r);
   return( (170##2 + 325##2 + 2# (-r)#170#325)##0.5);
finish;

start Func2(r);
   return( (170+325)#(1-r));
finish;

/* define a function that has one or more zeros */
start Func(r);
   return( Func1(r) - Func2(r) );
finish;

if num(symget("SYSVER"))>=9.4 then do;
   r1 = do(-1, 1, 0.1);

   ec = Func1(r1);
   print "Method I: Aggregate economic capital with a correlation coefficient of r";
   call Series(r1, ec) option="markers"
	grid={x y} label={"Correlation coefficient" "Aggregate economic capital"} xvalues = do(-1,1,0.1) yvalues = do(50,550,50); 

  	r2 = do(0, 1, 0.1);
	
   ec = Func2(r2);
   print "Method II: Aggregate economic capital with a fixed diversification factor of -r";
   call Series(r2, ec) option="markers"
	grid={x y} label={"Correlation coefficient" "Aggregate economic capital"} xvalues = do(0,1,0.1) yvalues = do(50,1000,50); 

   
   y = Func(r2);
   print "The value of r which equates the aggregate capital required under methods I and II";
   call Series(r2, y) option="markers"
	grid={x y} other="refline 0 / axis=y" xvalues = do(0,1,0.1); 

   y = Func1(r2);

   
end;

intervals = {0   1}; 

Roots = froot("Func", intervals);
print Roots;


quit;


data work.ec(label="Economic Capital");
	label asset="Asset class" amount_a="Reinsured Block A" amount_b="Reinsured Block B" haircut="Liquidity haircut";
	length asset $50;
	format amount_a amount_b dollar32.2 haircut percentn6.1;
	infile datalines delimiter=',';
	input asset $ amount_a amount_b haircut;
	datalines;
Private Placements, 412, 63, 0.3
Treasuries, 84, 424, 0
Corporates AAA, 211, 678, 0.05
Corporates AA, 134, 233, 0.1
Corporates A, 99, 144, 0.15
Corporates BBB, 155, 152, 0.25
Statutory Reserve, 1095, 1694, 0
;


proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		entrytitle "Liquidity profile for Reinsured Block A" / textattrs=(size=14);
		layout region;
		piechart category=asset response=amount_a / datalabellocation=callout 
			dataskin=pressed;
		endlayout;
		endgraph;
	end;

	define statgraph SASStudio.Pie2;
		begingraph;
		entrytitle "Liquidity profile for Reinsured Block B" / textattrs=(size=14);
		layout region;
		piechart category=asset response=amount_b / datalabellocation=callout 
			dataskin=pressed;
		endlayout;
		endgraph;
	end;


run;

ods graphics / reset width=6.4in height=4.8in imagemap noborder;

proc sgrender template=SASStudio.Pie data=WORK.EC;
run;

proc sgrender template=SASStudio.Pie2 data=WORK.EC;
run;


ods graphics / reset;

data work.ec2;
	label amount_a_hct = "Value after haircut" amount_b_hct="Value after haircut";
	format amount_a_hct amount_b_hct dollar32.2;
	set work.ec;
	amount_a_hct = amount_a*(1-haircut);
	amount_b_hct = amount_b*(1-haircut);
run;

proc template;
	define statgraph SASStudio.Pie3;
		begingraph;
		entrytitle "Liquidity profile for Reinsured Block A" / textattrs=(size=14);
		layout region;
		piechart category=asset response=amount_a_hct / datalabellocation=callout 
			dataskin=pressed;
		endlayout;
		endgraph;
	end;

	define statgraph SASStudio.Pie4;
		begingraph;
		entrytitle "Liquidity profile for Reinsured Block B" / textattrs=(size=14);
		layout region;
		piechart category=asset response=amount_b_hct / datalabellocation=callout 
			dataskin=pressed;
		endlayout;
		endgraph;
	end;


run;

ods graphics / reset width=6.4in height=4.8in imagemap noborder;

proc sgrender template=SASStudio.Pie3 data=WORK.EC2;
run;

proc sgrender template=SASStudio.Pie4 data=WORK.EC2;
run;


ods graphics / reset;


proc sql;
	create table work.alpha as
		select 
		sum(amount_a_hct) as alpha_a
		, sum(amount_b_hct) as alpha_b
		from work.ec2
		where asset ne "Statutory Reserve"
		;
	create table work.beta as
		select 
		sum(amount_a_hct) as beta_a
		, sum(amount_b_hct) as beta_b
		from work.ec2
		where asset eq "Statutory Reserve"
		;
	select 
	alpha_a / beta_a label="LRR Block A" format=percent10.3
	, alpha_b / beta_b label="LRR Block B" format=percent10.3
	from work.alpha, work.beta
	;
quit;


