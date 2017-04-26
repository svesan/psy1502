*---------------------------------------------------------------------------;
* Select patient register data                                              ;
* In the view, set length to manage dataset size                            ;
*---------------------------------------------------------------------------;
proc datasets lib=work nolist;
  delete  dd1 dd2;
quit;

proc sql;
  drop index lopnr_barn on mbr1;
  create index lopnr_barn on mbr1;
quit;

proc sql;
  create view dd1 as
  select a.lopnr as lopnr length=6, indate length=4 format=yymmdd10. label='Diag date',
  substr(left(dia1),1,6) as dia1 length=6,
  substr(left(dia2),1,6) as dia2 length=6,
  substr(left(dia3),1,6) as dia3 length=6,
  substr(left(dia4),1,6) as dia4 length=6,
  substr(left(dia5),1,6) as dia5 length=6,
  substr(left(dia6),1,6) as dia6 length=6,
  substr(left(dia7),1,6) as dia7 length=6,
  substr(left(dia8),1,6) as dia8 length=6,
  substr(left(dia9),1,6) as dia9 length=6,
  substr(left(dia10),1,6) as dia10 length=6,
  substr(left(dia11),1,6) as dia11 length=6,
  substr(left(dia12),1,6) as dia12 length=6,
  substr(left(dia13),1,6) as dia13 length=6,
  substr(left(dia14),1,6) as dia14 length=6,
  substr(left(dia15),1,6) as dia15 length=6,
  substr(left(dia16),1,6) as dia16 length=6,
  substr(left(dia17),1,6) as dia17 length=6,
  substr(left(dia18),1,6) as dia18 length=6,
  substr(left(dia19),1,6) as dia19 length=6,
  substr(left(dia20),1,6) as dia20 length=6,
  substr(left(dia21),1,6) as dia21 length=6,
  substr(left(dia22),1,6) as dia22 length=6,
  case when upcase(substr(left(lan_text),1,2))='SK' then '1' else '0' end as skane length=1
  from ivfdb.patient_sluten(keep=lopnr indate  dia1-dia22 lan_text) as a
  ;

  create view dd2 as
  select a.lopnr as lopnr length=6, indate length=4 format=yymmdd10. label='Diag date',
  substr(left(dia1),1,6) as dia1 length=6,
  substr(left(dia2),1,6) as dia2 length=6,
  substr(left(dia3),1,6) as dia3 length=6,
  substr(left(dia4),1,6) as dia4 length=6,
  substr(left(dia5),1,6) as dia5 length=6,
  substr(left(dia6),1,6) as dia6 length=6,
  substr(left(dia7),1,6) as dia7 length=6,
  substr(left(dia8),1,6) as dia8 length=6,
  substr(left(dia9),1,6) as dia9 length=6,
  substr(left(dia10),1,6) as dia10 length=6,
  substr(left(dia11),1,6) as dia11 length=6,
  substr(left(dia12),1,6) as dia12 length=6,
  substr(left(dia13),1,6) as dia13 length=6,
  substr(left(dia14),1,6) as dia14 length=6,
  substr(left(dia15),1,6) as dia15 length=6,
  substr(left(dia16),1,6) as dia16 length=6,
  substr(left(dia17),1,6) as dia17 length=6,
  substr(left(dia18),1,6) as dia18 length=6,
  substr(left(dia19),1,6) as dia19 length=6,
  substr(left(dia20),1,6) as dia20 length=6,
  substr(left(dia21),1,6) as dia21 length=6,
  substr(left(dia22),1,6) as dia22 length=6,
  case when upcase(substr(left(lan_text),1,2))='SK' then '1' else '0' end as skane length=1
  from ivfdb.patient_oppen(keep=lopnr indate  dia1-dia22 lan_text) as a
  ;
quit;

*-- Diagnoses in long format;
data dd3;
  keep lopnr npr_source icd diag_dat diag;
  attrib diag       length=$6. label="Diagnosis"
         diag_dat   length=4 format=yymmdd10. label="Date of Diagnosis"
         npr_source length=$1. label="In or out-patient"
         icd        length=$3. label='ICD'
  ;
  array  dd $6 dia1-dia22;

  set dd1(in=sluten keep=lopnr indate dia1-dia22 skane)
      dd2(in=oppen  keep=lopnr indate dia1-dia22 skane);

  if sluten then npr_source="S";
  else npr_source="O";

  diag_dat=datepart(indate);
  yr=year(diag_dat);

  *-- Derive ICD code;
  if yr <= 1968 then icd = '7';
  else if 1969 <= yr <= 1986 then icd = '8';
  else if 1987 <= yr <= 1996 then icd = '9';
  else if skane='1' and 1987 <= yr <= 1997 then icd = '9';
  else if skane='1' and 1998 <= yr then icd = '10';
  else if 1997 <= yr then icd = '10';

  * Re-assigning some overlap to ICD10;
  if icd = 9
     and yr > 1996
     and anyalpha(substr(dia1,1,1)) = 1
     and substr(dia1,1,1) NE 'V' then icd = '10';

  diag='x';i=0;
  do until(diag='' or i GE 22);
    i=i+1;
    diag=compress(dd(i), " -");
    if diag ne '' then output;
  end;
run;

proc sort data=dd3;by lopnr diag_dat;run;

*-- Dataset with codes for psychiatric history;
data dd4(sortedby=lopnr diag_dat);
  keep lopnr phist diag_dat;
  attrib phist length=3;
  set dd3(keep=lopnr diag diag_dat);by lopnr diag_dat;
  phist=0;

  rank=rank(substr(left(diag),1,1));
  if 65<=rank<=90 then do;
    *-- Code start with F;
    if substr(left(diag),1,1) = 'F' then phist=1;
  end;
  else if rank=50 or rank=51 then do;
    *-- Code start with 2 or 3;
    tmp3=input(substr(left(diag),1,3),3.);

    if (295 <= tmp3 <= 318) then phist=1;
  end;

  if phist=1;
run;
proc sort data=dd4;by lopnr diag_dat;run;
proc sort data=dd4 nodupkey;by lopnr;run;