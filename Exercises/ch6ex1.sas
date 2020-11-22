
/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

/*
Chapter 6: Ética profesional del actuario
Exercise 1
*/

options threads;

* Path of the folder with the text files;
%let dir=/folders/myfolders/aar/Exercises/ch6ex1_data/;

* Getting the names of the text files in the path folder;
data files (keep=filename file_no_ext full_path label="All Text Sources");
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
data _NULL_;
	set files end=last;
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
	put myfilepaths myfiles;
	retain myfilepaths myfiles;
run;

* Checking the macrovariables;
%put &=filelist;
%put &=filenames;
%put &=filecount;

/*
%macro test;
%do i=1 %to 8;
%put %scan(&filenames,&i,%STR( ));
%end;
%mend test;
%test;
*/


%macro extract; 
	%do i=1 %to &filecount;
	data extract_result_&i(where=(length(source_text)>1));
	infile %scan(&filelist,&i,%STR( )) length=linelen lrecl=5000 pad;
	varlen=linelen-0;
	input source_text $varying500. varlen;
	length sourcetable $50;
	sourcetable=%scan(&filenames,&i,%STR( ));
	
	keep sourcetable source_text;
	run;
	
	proc print data=extract_result_&i;
	run;
	%end;
%mend extract;
%extract;

data work.extract_result(index=(sourcetable));
	set extract_result_:;
run;

* Identiying corporations, associations, organizations, etc.;
%macro parsing; 
	%do i=1 %to &filecount;
	data parsing_result_&i;
	infile %scan(&filelist,&i,%STR( )) length=linelen lrecl=5000 pad;
	varlen=linelen-0;
	input source_text $varying500. varlen;
	length sourcetable $50;
	sourcetable=%scan(&filenames,&i,%STR( ));

	*Identifying corporations;	
	Corp_Pattern = "/(\b[A-Z]\w+\s[A-Z]\w+(\s[A-Z]\w+)*\b)|(\b(\w+\s+)*\w+\s+\ucorp(oration)?\b|\uinc\.?\b|\uco\.?\b|LLC\b|Company\b)/o";
	
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

data work.parsing_result(index=(sourcetable));
	set parsing_result_:;
run;

proc freq data=work.parsing_result;
	table found/out=work.parsing_result_1;
run;

proc freq data=work.parsing_result;
	table found*sourcetable/out=work.parsing_result_2;
run;

* Computing the distance between paragraphs of different essays;
proc sql;
	create table work.merge_fuzzy as
		select 
		a.sourcetable as sourcetable_1
		, A.source_text as source_text_1
		, b.sourcetable as sourcetable_2
		, B.source_text as source_text_2
		, compged(A.source_text,B.source_text) as ged
		from work.extract_result A inner join work.extract_result B
		on (A.sourcetable ne B.sourcetable)
		;
quit;



