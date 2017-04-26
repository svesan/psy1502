*-------------------------------------------------------------------------------------;
* Description of the variables in SOS IVF can be found in the folder                  ;
* /projects/Reproduktion/Reproduktion_IT/Data/Data documentation/codebooks from SOS/  ;
*-------------------------------------------------------------------------------------;


*---------------------------------------------------------------------------;
* Select medical birth register                                             ;
* OBS!! Not sure what is the difference between variable INDATE and INDATUM ;
* Frida has created the INDATE variable from the indatum variable. INDATE   ;
* is the perferred variable to use                                          ;
* DODFOD: All was missing to excluded this variable                         ;
*---------------------------------------------------------------------------;
proc format;
  value yesno  0='N' 1='Y';
  value sexfmt 1='M' 2='F';
run;

proc sql;
  create table mbr1 as
  select lopnr_mor label='Mother ID', lopnr_barn label='Child ID',
         paritet length=3 label='Parity',
         case kon when '1' then 1 when '2' then 2 else .U end as sex length=3 label='Sex' format=sexfmt.,
         case bordf2 when '1' then 1 when '2' then 0 else .U end as singleton length=3 label='Singleton birth (Y/N)' format=yesno.,
         grvbs as gage length=3 label='Gestational age (weeks)',
         datepart(bdate_child) as child_bdat length=4 format=yymmdd10. label='Child birth date',
         datepart(bdate_mother) as mo_bdat length=4 format=yymmdd10. label='Mother birth date'

  from ivfdb.mbr(where=(bdate_child GE "01jan1985"d and lopnr_barn GT .z) )
  ;
run;


*---------------------------------------------------------------------------;
* Select patient register data                                              ;
* OBS!! Not sure what is the difference between variable INDATE and INDATUM ;
* Frida has created the INDATE variable from the indatum variable. INDATE   ;
* is the perferred variable to use                                          ;
*---------------------------------------------------------------------------;
data preg1(where=(diag ne ""));
  keep lopnr preg_source diag_dat diag;
  attrib diag length=$7. label="Diagnosis" diag_dat length=4 format=yymmdd10. label="Date of Diagnosis"
         preg_source length=$1. label="In or out-patient"
  ;
  array  dd $112 dia1-dia22;

  set ivfdb.patient_sluten(in=sluten keep=lopnr indate  dia1-dia22 where=(indate GT "01jan2012"d))
      ivfdb.patient_oppen(keep=lopnr indate dia1-dia22 where=(indate GT "01jan2012"d));

  do i=1 to 22;
    if sluten then preg_source="S";else preg_source="O";
    diag=compress(dd(i), " -");
    diag_dat=datepart(indate);
    output;
  end;
run;


*-----------------------------------------------------------;
* Now, apply the different codes for OCD, TICS, TD          ;
*-----------------------------------------------------------;
data preg2;
  drop d3;
  attrib ott length=3 label="OCD/TICS/TD" d3 length=$3.

  ;
  set preg1;

  d3 = substr(left(diag), 1, 3);

  *- OCD or TICS and TD;
  if d3 = "F42" or d3 = "F95" then ott=1; else ott=0;

  if ott then output;

run;

*-- Select only the first diagnosis;
proc sort data=preg2 nodupkey; by lopnr ott diag_dat;run;
proc sort data=preg2 nodupkey; by lopnr ott;run;

proc format;
  value embftyp 1='Slow freezing' 2='Vitrification';
  value ivficsi 1='IVF' 2='ICSI';
  value frozen  1='Fresh' 2='Frozen';
  value spsrc   4='Retrograde ejaculation' 3='Testis' 2='Epididymis' 1='Ejaculated';
run;

data qivf;
  drop etdate cyclestartdate resultdeliverydate d_method spermrecieve cyclefreshfrozen embryofreezetype;
  attrib et_dat      length=4 label='Embryo Start Date'    format=yymmdd10.
         st_dat      length=4 label='Start date for cycle' format=yymmdd10.
         x_dat       length=4 label='Date delivery. Alive' format=yymmdd10.
         ivficsi     length=3 label='IVF/ICSI'             format=ivficsi.
         spsource    length=3 label='Sperm Source'         format=spsrc.
         freshfrozen length=3 label='Frozen/fresh embryo'  format=frozen.
         freezetype  length=3 label='Slow/fast freeze'     format=embftyp.
         embryo_days length=4 label='Embryo days'
  ;
  set ivfdb.qivf(keep=d_method cyclefreshfrozen etdate lopnr_man lopnr_kvinna oocytowndonated etnumber
                      embryofreezetype spermrecieve cyclestartdate resultdeliverydate);

  et_dat=datepart(etdate);
  st_dat=datepart(cyclestartdate);
  x_dat =datepart(resultdeliverydate);

  embryo_days = et_dat - st_dat;
  ivficsi     = d_method;
  spsource    = spermrecieve ;
  freshfrozen = cyclefreshfrozen;
  freezetype  = embryofreezetype;


  *-- Frida 151117: Et_dat missing then no embryo transfer. Delete!! ;
  if et_dat le .z then delete;

run;

*proc freq;
*  table ivficsi spsource freshfrozen freezetype embryo_days;
*run;

data sosivf1;
  drop bdate_child bdate_mother etdate;
  attrib child_bdat length=4 format=yymmdd10. label="Child DoB"
         mo_bdat    length=4 format=yymmdd10. label="Mother DoB"
         et_dat     length=4 format=yymmdd10. label="ET Date"
  ;
  set ivfdb.ivf_sos(keep=lopnr_barn lopnr_kvinna bdate_child bdate_mother embryon metod
                         etdate embryon uldatum);
  child_bdat=datepart(bdate_child);
  mo_bdat   =datepart(bdate_mother);
  et_dat    =datepart(etdate);
run;

proc cport file='/home/svesan/psy1502.tsp' lib=work;
exclude sasmacr sasgopt preg1;
run;
