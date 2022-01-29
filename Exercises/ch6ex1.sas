
/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

/*
Chapter 6: Ética profesional del actuario
Exercise 1
*/

options threads mprint mlogic minoperator fullstimer;

* Path of the folder with the text files;
%let dir=/home/&_metauser./aar/Exercises/ch6ex1_data/;

* Getting the names of the text files in the path folder;
* dread function returns the name of a directory member;
* dopen function opens a directory, and returns a directory identifier value;
data work.files(keep=filename file_no_ext full_path label="All Text Sources");
	length filename file_no_ext full_path $1000;
   	rc=filename("dir","&dir");
   	did=dopen("dir");
   	if did ne 0 then do;
    	do i=1 to dnum(did);
       		filename=dread(did,i);
			file_no_ext=scan(filename,1,".");
       		full_path="&dir"||filename;
      	if lowcase(scan(filename, -1, "."))="txt" then output;
    	end;
  	end;
  	else do;
    	put "ERROR: Failed to open the directory &dir";
    	stop;
  	end;
run;

proc sort data=files;
	by full_path;
run;

* Saving the file names in macrovariables for future use;
* strip function returns a character string with all leading and trailing blanks removed;
data _NULL_;
	set work.files end=last;
	length myfilepaths $10000. myfiles $10000.;
	if _N_=1 then do;
	myfilepaths="'"||strip(full_path)||"'";
	myfiles="'"||strip(file_no_ext)||"'";
	end;
	else do; 
	myfilepaths="'"||strip(full_path)||"'"||' '||strip(myfilepaths);
	myfiles="'"||strip(file_no_ext)||"'"||' '||strip(myfiles);
	end;
	if last then do;
		call symput('filelist',myfilepaths);
		call symput('filenames',myfiles);
		call symput('filecount',_N_);
	end;
	retain myfilepaths myfiles;
run;

* Checking the macrovariables with file properties;
%put &=filelist;
%put &=filenames;
%put &=filecount;

%macro extract; 
/*
Purpose: 
*/
	%do i=1 %to &filecount;
	data extract_result_&i(where=(length(source_text)>1));
	label sourcetable="Document ID" source_text="Document";
	infile %scan(&filelist,&i,%STR( )) length=linelen lrecl=5000 pad;
	varlen=linelen-0;
	input source_text0 $varying10000. varlen;
	length sourcetable $50 source_text $10000;
	sourcetable=%scan(&filenames,&i,%STR( ));
	source_text = tranwrd(source_text0,"Lesson","Leeson");
	keep sourcetable source_text;
	run;
	
	proc print data=extract_result_&i;
	run;
	%end;
%mend extract;
%extract;

proc sql;
	drop table work.extract_result;
quit;

data work.extract_result(index=(sourcetable));
	set extract_result_:;
run;

* Deleting temporal files;
proc datasets lib=work nodetails nolist;
	delete extract_result_:;
quit;

* Identiying corporations, associations, organizations, etc.;
%macro parsing; 
	%do i=1 %to &filecount;
	data parsing_result_&i;
	infile %scan(&filelist,&i,%STR( )) length=linelen lrecl=5000 pad;
	varlen=linelen-0;
	input source_text0 $varying10000. varlen;
	length sourcetable $50 source_text $10000;
	sourcetable=%scan(&filenames,&i,%STR( ));
	source_text = tranwrd(source_text0,"Lesson","Leeson");

	*Identifying main entities;
	* You can improve the next code if it is needed;
	Corp_Pattern = "/(\bBaring\w+\b)|(\bJap\w+\b)|(\bSinga\w+\b)|(\bIngla\w+\b)|(\b[A-Z]\w+\s[A-Z]\w+(\s[A-Z]\w+)*\b)|(\b(\w+\s+)*\w+\s+\ucorp(oration)?\b|\uinc\.?\b|\uco\.?\b|LLC\b|Company\b)/o";
	
	pattern_ID = PRXPARSE(Corp_Pattern);
	start = 1;
	stop = length(source_text);
	CALL PRXNEXT(pattern_ID, start, stop, source_text, position, length);
	   do while (position > 0);
	   	  line=_N_;
	      found = substr(source_text, position, length); 
	      output;
	      CALL PRXNEXT(pattern_ID, start, stop, source_text, position, length);
		  retain source_text start stop position length found;
	   end;
	
	keep sourcetable line position length found source_text;
	run;
	
	proc print data=parsing_result_&i;
	run;
	%end;
%mend parsing;
%parsing;

proc sql;
	drop table work.parsing_result;
quit;

data work.parsing_result(index=(sourcetable));
	label found = "Entity" sourcetable="Document";
	set parsing_result_:;
run;

* Deleting temporal files;
proc datasets lib=work nodetails nolist;
	delete parsing_result_:;
quit;


proc freq data=work.parsing_result;
	table found/out=work.parsing_result_freq;
run;

* Plotting the frequencies of entities;
proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		entrytitle "Frecuencia de entidades identificadas en los ensayos" / textattrs=(size=14);
		entryfootnote halign=left 
			"Las entidades fueron identificadas en los ensayos con expresiones regulares." / textattrs=(size=12);
		layout region;
		piechart category=found / stat=pct dataskin=matte;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap noborder;

proc sgrender template=SASStudio.Pie data=WORK.PARSING_RESULT;
run;

ods graphics / reset;

ods graphics / reset width=11in height=4.8in imagemap noborder;

proc freq data=work.parsing_result;
	ods select MosaicPlot;
	table found*sourcetable/out=work.parsing_result_freq2 plots=mosaicplot;
run;

ods graphics / reset;

* Computing the distance between paragraphs of different essays;
proc sql;
	create table work.merge_fuzzy as
		select 
		a.sourcetable as sourcetable_1 label="Document base"
		, A.source_text as source_text_1 label="Paragraph of document base"
		, b.sourcetable as sourcetable_2 label="Document to compare"
		, B.source_text as source_text_2 label="Paragraph of document to compare"
		, compged(A.source_text,B.source_text) as ged format=comma9. label="General Edit Distance (more distance is more different text)"
		from work.extract_result A left join work.extract_result B
		on (A.sourcetable ne B.sourcetable)
		;
quit;

* Identifying suspects;
ods graphics / reset width=6.4in height=4.8in imagemap noborder;
title "Histogram of General Edit Distance";
proc sgplot data=work.merge_fuzzy;
	histogram ged / fillattrs=(color=orange transparency=0.5);
 	xaxis grid;
	yaxis grid;
run;

* The next paragraphs are the same but from different essays. The length is long (they are not titles, subtitles, etc). ;
PROC SQL;
CREATE TABLE WORK.query AS
SELECT sourcetable_1 , source_text_1 , sourcetable_2 , source_text_2 , ged 
FROM WORK.MERGE_FUZZY WHERE ged = 0 and length(source_text_1) > 100;
RUN;
QUIT;



