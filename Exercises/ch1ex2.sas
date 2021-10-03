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
	
	* Current portfolio volatility;
	sigma_p = 0.07;
	* Current portfolio asset;
	W = 30;
	* New premium;
	P = 10;
	* Volatility of corporate bonds and private placement returns;
	sigma = {0.08 0.06};
	* Correlation's corporate bonds and private placement returns with current portfolio;
	corr = {0.6 0.4};
	* Bid prices;
	bid = {95.8 86};
	* Ask prices;
	ask = {96.2 98};
	
	print "Calculate the Incremental VaR for each of the two investment options at a 95% confidence level.";
	
	alpha = quantile('NORMAL',0.95);
	
	print "95% quantile of the standard normal distribution";
	print alpha; 
	
	print "VaR before any new investment (Delta-Normal Model)";
	print "VaR_p = alpha * sigma_p * W";
	
	VaR_p = alpha * sigma_p * W;
	
	print VaR_p;

	
	print "VaR after investment in corporate bonds";
	
	W1 = J(1,2);
	print W1;
	
	W1[1,1]=W;
	W1[1,2]=P;


	print "Updated portfolio asset" W1;

	
	cov1 = corr[1,1]*sigma_p*sigma[1,1];
	print "Covariance" cov1;



	
	Sigma1 = J(2,2);
	Sigma1[1,1]=sigma_p**2;
	Sigma1[2,2]=sigma[1,1]**2;
	Sigma1[2,1]=cov1;
	Sigma1[1,2]=cov1;


	print "Covariance matrix" Sigma1;

	
	print "VaR_p1 = alpha * (W1 * Sigma1 * t(W1))**0.5";
	
	VaR_p1 = alpha * (W1 * Sigma1 * t(W1))**0.5;
	
	print VaR_p1;


	
	print "Incremental VaR with investment in corporate bonds";
	print "IVaR1 = VaR_p1- VaR_p";
	
	IVaR1 = VaR_p1- VaR_p;
	
	print IVaR1;

	
	
	print "VaR after investment in private placement bonds";
	
	W2 = W1;
	print "Updated portfolio asset" W2;
	cov2 = corr[1,2]*sigma_p*sigma[1,2];
	print "Covariance" cov2;
	
	Sigma2 = J(2,2);
	Sigma2[1,1]=sigma_p**2;
	Sigma2[2,2]=sigma[1,2]**2;
	Sigma2[2,1]=cov2;
	Sigma2[1,2]=cov2;
	
	print "Covariance matrix" Sigma2;
	
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
	
	print "Calculate the liquidity-adjusted VaR (LVaR) for each of the two investment options prior to XYZ’s investment in either of them";
	
	mid = (ask + bid)/2;
	
	print "Mid prices" mid;
	
	VaR = alpha*sigma*P;
	print "VaR" VaR;
	LVaR = VaR + ((ask-bid)/mid)/2*P;

	print "Liquidity-adjusted VaR (LVaR) = VaR + ((ask-bid)/mid)/2*P" LVaR;
	
	LVaRout = J(4,3);


	LVaRout[1,1]=1;
	LVaRout[2,1]=2;
	LVaRout[3,1]=1;
	LVaRout[4,1]=2;

	LVaRout[1,2]=0;
	LVaRout[2,2]=0;
	LVaRout[3,2]=1;
	LVaRout[4,2]=1;

	LVaRout[1,3]=VaR[1,1];
	LVaRout[2,3]=VaR[1,2];
	LVaRout[3,3]=LVaR[1,1];
	LVaRout[4,3]=LVaR[1,2];

	
	print LVaRout;

	create work.LVaRout from LVaRout;
	append from LVaRout;
	close work.LVaRout;
	
run;

data work.IVaR2(rename=(col2=VaR) drop=col1);
	length Investment $50.;
	format col2 dollar32.2;
	set work.IVaR;
	if col1=1 then Investment = "VaR with new investment in corporate Bonds";
	if col1=2 then Investment = "VaR with new investment in private placement bonds";
	if col1=0 then call symputx('VaR',put(col2,comma32.2));
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

title "Incremental VaR";
proc sgplot data=WORK.IVAR2;
	vbar Investment / response=VaR fillattrs=(color=yellow);
	yaxis grid label="VaR";
	refline &VaR. / axis=y lineattrs=(thickness=5 color=green) label = "VaR before any new investment (&VaR.)"
		labelattrs=(color=green);
run;

data work.LVaRout2(rename=(col3=Amount) drop=col1 col2);
	length Investment $50. RiskMetric $50.;
	format col3 dollar32.2;
	set work.LVaRout;
	if col1=1 then Investment = "Corporate Bonds";
	if col1=2 then Investment = "Private placement bonds";
	if col2=0 then RiskMetric = "VaR";
	if col2=1 then RiskMetric = "LVaR";
run;


proc sgplot data=WORK.LVAROUT2;
	title height=14pt "Risk metrics for the two investments";
	vbar Investment / response=Amount group=RiskMetric groupdisplay=cluster 
		datalabel;
	yaxis grid label="Amount";
	keylegend / location=inside;
run;

ods graphics / reset;
title;


