/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

/*
Chapter 1: La estructura financiera y operativa de una compañía de seguros/fianzas
Exercise 2
*/

proc iml;

sigma_p = 0.07;
W = 30;
sigma = {0.08 0.06};
corr = {0.6 0.4};

print "Calculate the Incremental VaR for each of the two investment options at a 95% confidence level.";

alpha = quantile('NORMAL',0.95);

print alpha; 

print "VaR before any new investment";

VaR_p = alpha * sigma_p * W;

print VaR_p;

print "VaR after investment in corporate bonds";

W1 = {30 10};
print W1;
cov1 = corr[1,1]*sigma_p*sigma[1,1];
print cov1;

Sigma1 = J(2,2);
Sigma1[1,1]=sigma_p**2;
Sigma1[2,2]=sigma[1,1]**2;
Sigma1[2,1]=cov1;
Sigma1[1,2]=cov1;

print Sigma1;

VaR_p1 = alpha * (W1 * Sigma1 * t(W1))**0.5;

print VaR_p1;

print "Incremental VaR with investment in corporate bonds";

IVaR1 = VaR_p1- VaR_p;

print IVaR1;


print "VaR after investment in private placement bonds";

W2 = {30 10};
print W2;
cov2 = corr[1,2]*sigma_p*sigma[1,2];
print cov2;

Sigma2 = J(2,2);
Sigma2[1,1]=sigma_p**2;
Sigma2[2,2]=sigma[1,2]**2;
Sigma2[2,1]=cov2;
Sigma2[1,2]=cov2;

print Sigma2;

VaR_p2 = alpha * (W2 * Sigma2 * t(W2))**0.5;

print VaR_p2;

print "Incremental VaR after investment in private placement bonds";

IVaR2 = VaR_p2- VaR_p;

print IVaR2;

IVaR = J(3,2);

IVaR[1,1] = 0;
IVaR[2,1] = 1;
IVaR[3,1] = 2;
IVaR[1,2] = VaR_p;
IVaR[2,2] = VaR_p1;
IVaR[3,2] = VaR_p2;

print IVaR;

create work.IVaR from IVaR;
append from IVaR;
close work.IVaR;

run;

data work.IVaR2(rename=(col2=VaR) drop=col1);
	length Investment $50.;
	format col2 dollar32.2;
	set work.IVaR;
	if col1=1 then Investment = "New investment in corporate Bonds";
	if col1=2 then Investment = "New investment in private placement bonds";
	if col1=0 then call symputx('VaR',col2);
run;

proc sgplot data=WORK.IVAR2;
	vbar Investment / response=VaR fillattrs=(color=CX45deec);
	yaxis grid label="VaR";
	refline 3.454 / axis=y lineattrs=(thickness=2 color=green) label = "VaR before any new investment"
		labelattrs=(color=green);
run;



