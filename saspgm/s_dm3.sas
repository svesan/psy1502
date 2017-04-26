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
  value embftyp 1='Slow freezing' 2='Vitrification';
  value ivficsi 1='IVF' 2='ICSI';
  value frozen  1='Fresh' 2='Frozen';
  value spfsrc  4='Retrograde ejaculation' 3='Testis' 2='Epididymis' 1='Ejaculated';

  value ivficsi 1='IVF' 2='ICSI';
  value trtfmt   1='Standard IVF' 2='IVF frozen' 3='ICSI fresh' 4='ICSI frozen' 5='ICSI surgical';
  value $ztrtfmt '1'='Standard IVF' '2'='IVF frozen' '3'='ICSI fresh'
                 '4'='ICSI frozen' '5'='ICSI surgical';
run;

proc sql;
  create table mbr0 as
  select lopnr_mor label='Mother ID' length=6, lopnr_barn label='Child ID' length=6,
         paritet length=3 label='Parity',
         case kon
           when '1' then '1' when '2' then '2' else ''
         end as sex length=1 label='Sex',
         case bordf2
           when '1' then '1' when '2' then '0' else ''
         end as singleton length=1 label='Singleton birth (Y/N)',
         grvbs as gage length=3 label='Gestational age (weeks)',
         datepart(bdate_child) as child_bdat length=4 format=yymmdd10. label='Child birth date',
         datepart(bdate_mother) as mo_bdat length=4 format=yymmdd10. label='Mother birth date'

  from ivfdb.mbr(where=(bdate_child GE "01jan1985"d and lopnr_barn GT .z) )
  ;
run;

data mbr1;
  drop _a_ _b_;
  retain _b_ 0;
  set mbr0 end=eof;
  _a_=0;
  if lopnr_barn le .z or lopnr_mor le .z then _a_=1;
  _b_=_b_+_a_;
  if eof then put 'WARNING: ' _b_ 'records deleted due to missing ID of child or mother';
  if _a_=1 then delete;
run;

data mbr2;
  length outcome $1;
  set mbr1(in=mbr1) ;
  do outcome='1','2','3','4';
    output;
  end;
run;

*---------------------------------------------------------------------------;
* Select patient register data                                              ;
* OBS!! Not sure what is the difference between variable INDATE and INDATUM ;
* Frida has created the INDATE variable from the indatum variable. INDATE   ;
* is the perferred variable to use                                          ;
*---------------------------------------------------------------------------;
proc sql;drop table npr1, npr2;run;

proc sql;
  create index lopnr_barn on mbr1;

  create view npr1 as
  select a.*
  from ivfdb.patient_sluten(keep=lopnr indate  dia1-dia22) as a
  join mbr1 as b
    on b.lopnr_barn=a.lopnr
    where indate GT "01jan1988"d
  ;
  create view npr2 as
  select a.*
  from ivfdb.patient_oppen(keep=lopnr indate  dia1-dia22) as a
  join mbr1 as b
    on b.lopnr_barn=a.lopnr
    where indate GT "01jan1988"d
  ;
quit;

data npr3(where=(diag ne ""));
  keep lopnr npr_source diag_dat diag;
  attrib diag length=$7. label="Diagnosis" diag_dat length=4 format=yymmdd10. label="Date of Diagnosis"
         npr_source length=$1. label="In or out-patient"
  ;
  array  dd $8 dia1-dia22;

  set npr1(in=sluten keep=lopnr indate dia1-dia22)
      npr2(in=oppen  keep=lopnr indate dia1-dia22);

  if sluten then npr_source="S";else nprg_source="O";

  do i=1 to 22;
    diag=compress(dd(i), " -");
    diag_dat=datepart(indate);
    output;
  end;
run;

*-----------------------------------------------------------;
* Now, apply the different codes for OCD, TICS, TD          ;
* Tourett is F95.9 part of TICS (as AD in ASD)              ;
*-----------------------------------------------------------;
data npr4;
*  keep lopnr ott ocd tic td diag_dat;
  attrib lopnr length=6 label='Child ID';
  keep lopnr outcome diag_dat;
  rename lopnr=lopnr_barn;
*  attrib ott length=3 label="OCD/TICS/TD" length=3
         ocd length=3 label="OCD"         length=3
         tic length=3 label="TICS"        length=3
         td  length=3 label="TD"          length=3
  ;
  set npr3;

  d4 = substr(left(diag), 1, 4);
  d3 = substr(d4, 1, 3);

  *- OCD or TICS and TD;
/*
  if d3 = "F42" or d3 = "F95" then ott=1; else ott=0;
  if d3 = "F42"               then ocd=1; else ocd=0;
  if d3 = "F95"               then tic=1; else tic=0;
  if d4 = "F952"              then td =1; else td =0;

  if ott then output;
*/
  if d3 = 'F42'  then do; outcome='1'; output; end;
  if d3 = 'F95'  then do; outcome='2'; output; end;
  if d4 = 'F952' then do; outcome='3'; output; end;
  if d3 in ('F95','F42') then do; outcome='4'; output; end;
run;

*-- Select only the first diagnosis;
proc sort data=npr4 nodupkey; by outcome lopnr_barn diag_dat;run;
proc sort data=npr4 nodupkey; by outcome lopnr_barn;run;


*-----------------------------------------------------------;
* IVF treatments from MBR up to 1997                        ;
* Tourett is F95.9 part of TICS (as AD in ASD)              ;
*-----------------------------------------------------------;
data sosivf1;
  drop lopnr_kvinna zlopnr_barn zmetod zembryon bdate_child bdate_mother etdate;
  attrib child_bdat length=4  format=yymmdd10. label="Child DoB"
         mo_bdat    length=4  format=yymmdd10. label="Mother DoB"
         et_dat     length=4  format=yymmdd10. label="ET Date"
         lopnr_mor  length=6  label='Mother ID'
         lopnr_barn length=6  label='Child ID'
         embryon    length=$1 label='#Embryon'
         metod      length=$2
  ;
  set ivfdb.ivf_sos(keep=lopnr_barn lopnr_kvinna bdate_child bdate_mother embryon metod
                         etdate embryon
                    rename=(embryon=zembryon metod=zmetod lopnr_barn=zlopnr_barn));

  lopnr_mor  = lopnr_kvinna;
  lopnr_barn = zlopnr_barn;
  child_bdat = datepart(bdate_child);
  mo_bdat    = datepart(bdate_mother);
  et_dat     = datepart(etdate);
  embryon    = zembryon;
  metod      = zmetod ;

  if lopnr_barn le .z then delete;

run;

data sosivf2;
  drop met metod1 metod2;
  attrib ivf_icsi length=3 format=ivficsi. label='IVF/ICSI'
         frozen   length=3 format=yesno.   label='Frozen'
         surg     length=3 format=yesno.   label='Surgery'
         trt      length=3 format=trtfmt.  label='IVF procedure'
  ;
  set sosivf1;

  if et_dat GE '01jan2002'd then metod2=metod;
  else metod1=metod;

  met=input(metod,8.);
  if met in (1,2,6) then ivf_icsi=1;
  else if met in (3,4,5,7,8,9,10) then ivf_icsi=2;
  else if met in (0) then ivf_icsi=.M;
  if met in (3,4,5) then frozen=0;
  else if met in (6,7,8,9) then frozen=1;
  else if met in (0) then frozen=.M;
  if met in (4,5,8) then surg=1;
  else if met in (1,2,3,6,7) then surg=0;
  else if met in (9,0,7) then surg=.M;

  if met in (0) then trt=.M;         /* Unknown        */
  else if met in (1,2) then trt=1;   /* Std IVF        */
  else if met in (6) then trt=2;     /* Do. fryst      */
  else if met in (3) then trt=3;     /* ICSI fresh     */
  else if met in (7) then trt=4;     /* ICSI frozen  can 8+9 be added here  */
  else if met in (4,5,8) then trt=5; /* ICSI surgical    */
  else trt=.U;

  *-- Delete record that is already in QIVF;
  if lopnr_mor=67295 and child_bdat='24OCT2007'd then delete;
run;


*-----------------------------------------------------------;
* Data management of Q-IVF. IVF from 01jan2002              ;
*-----------------------------------------------------------;
data qivf1;
  drop lopnr_kvinna etdate cyclestartdate resultdeliverydate d_method spermreceive
       cyclefreshfrozen embryofreezetype;

  attrib et_dat      length=4 label='Embryo Start Date'    format=yymmdd10.
         st_dat      length=4 label='Start date for cycle' format=yymmdd10.
         x_dat       length=4 label='Date delivery. Alive' format=yymmdd10.
         ivficsi     length=3 label='IVF/ICSI'             format=ivficsi.
         spsource    length=3 label='Sperm Source'         format=spsrc.
         freshfrozen length=3 label='Frozen/fresh embryo'  format=frozen.
         freezetype  length=3 label='Slow/fast freeze'     format=embftyp.
         embryo_days length=4 label='Embryo days'
         lopnr_mor   length=6 label='Mother ID'

         ivf_icsi    length=3 format=ivficsi. label='IVF/ICSI'
         frozen      length=3 format=yesno.   label='Frozen'
         surg        length=3 format=yesno.   label='Surgery'
         trt         length=3 format=trtfmt.  label='IVF procedure'
         embryon     length=$1 label='#Embryon'
  ;
  set ivfdb.qivf(keep=d_method cyclefreshfrozen etdate lopnr_man lopnr_kvinna oocytowndonated
                      etnumber embryofreezetype spermreceive cyclestartdate resultdeliverydate);

  lopnr_mor=lopnr_kvinna;

  et_dat=.U; st_dat=.U; x_dat=.U; embryo_days=.U;
  if etdate > .z then et_dat=datepart(etdate);
  if cyclestartdate > .z then st_dat=datepart(cyclestartdate);
  if resultdeliverydate > .z then x_dat =datepart(resultdeliverydate);

  if et_dat>.z and st_dat>.z then embryo_days = et_dat - st_dat;
  ivficsi     = d_method;
  spsource    = spermreceive ;
  freshfrozen = cyclefreshfrozen;
  freezetype  = embryofreezetype;

  *-- Frida 151117: Et_dat missing then no embryo transfer. Delete!! ;
  if et_dat le .z or et_dat>'01jan2020'd then delete;

  *-- Derive the same variables as in SOSIVF;
  *-- Note: Here we dont separate surgical frozen from surgical fresh;
  ivf_icsi=ivficsi;
  if freshfrozen=2 then frozen=1;
  else if freshfrozen=1 then frozen=0;
  if spsource=1 then surg=0;
  else if spsource in (2,3) then surg=1;
  else surg=.;

  if ivf_icsi=1 and frozen=0 then trt=1;
  else if ivf_icsi=1 and frozen=1 then trt=2;
  else if ivf_icsi=2 and surg  =1 then trt=5;
  else if ivf_icsi=2 and frozen=0 then trt=3;
  else if ivf_icsi=2 and frozen=1 then trt=4;

  *-- Create character variable to agree with sosivf;
  embryon=put(etnumber, 1.);

  *-- Deleting duplicate record;
  if lopnr_mor=280576 and x_dat='17SEP2009'd and embryo_days=0 then delete;
run;

*proc freq data=qivf;
*table surg*frozen;
*run;

*-- Select women and births in qivf;
proc sql;
  *-- First, children born in MBR from 2007 ;
  create table t1 as
  select lopnr_mor, lopnr_barn, child_bdat
  from mbr1
  where child_bdat>'01mar2007'd and lopnr_mor>.z;

  *-- Select distinct women in qivf;
  create table t2 as
  select distinct  lopnr_mor, et_dat
  from qivf
  where et_dat>.z
  order by lopnr_mor
  ;

  *-- Now select the treatments in QIVF for these children and mothers;
  create table t3 as
  select a.lopnr_mor, a.lopnr_barn, b.et_dat, a.child_bdat, a.child_bdat-b.et_dat as diff
  from t1 as a
  join t2 as b
  on a.lopnr_mor=b.lopnr_mor
  having diff>139 and diff<316  /** 20 to 45 weeks */
  order by lopnr_mor, lopnr_barn, a.child_bdat, b.et_dat
  ;
run;quit;

*-- Select the treatment closest to birth;
data t4;
  drop i diff;
  attrib i     length=3 label='Embryo transfer order'
         byear length=4 label='Child birth year'
  ;
  retain i 0;
  set t3; by lopnr_mor lopnr_barn child_bdat et_dat;
  if first.lopnr_barn then i=1;else i=i+1;

  if last.lopnr_barn;
run;

*-- Now join back with QIVF to get additional covariates;
proc sort data=t4;by lopnr_mor et_dat;run;
proc sort data=qivf1;by lopnr_mor et_dat;run;
data qivf;
  merge t4(in=t4)
        qivf1(keep=lopnr_mor et_dat x_dat trt frozen surg ivf_icsi embryon);
  by lopnr_mor et_dat;
  if t4 then do;
    *if first.lopnr_mor ne last.lopnr_mor and x_dat ne child_bdat then delete;
    if first.et_dat ne last.et_dat and x_dat ne child_bdat then delete;
  end;
  else delete;
run;

*-----------------------------------------------------------;
* Combine IVF treatment data from QIVF and SOS              ;
*-----------------------------------------------------------;
proc sort data=sosivf2;by lopnr_mor lopnr_barn;run;
proc sort data=qivf;by lopnr_mor lopnr_barn;run;

data ivfdata(label='IVF data from SOS and Q-IVF');
  set sosivf2
        qivf
  ;
  byear=year(child_bdat);
run;

*-- Merge in data for each woman;
proc sort data=mbr2;by lopnr_mor lopnr_barn;run;
proc sort data=ivfdata;by lopnr_mor lopnr_barn;run;

data mbr3;
  attrib art length=$1 label='ART (Y/N)'
  ;
  merge mbr2
        ivfdata(in=ivfdata)
  ;
  by lopnr_mor lopnr_barn;
  if not ivfdata then do;
    art='N';
    trt=0;
  end;
  else art='Y';
run;

*%put ERROR: Why are there duplicates in IVF?;

*-----------------------------------------------------------;
* Join in patient register data with diagnoses              ;
*-----------------------------------------------------------;
proc sort data=mbr3;by outcome lopnr_barn;run;
proc sort data=npr4;by outcome lopnr_barn;run;

data ana0;
  merge mbr3(in=mbr3)
        npr4(in=npr);
  by outcome lopnr_barn;
  if mbr3 then do;
    if npr then do;
      event=1;
      if diag_dat > .z then pyear=(diag_dat - child_bdat) / 365.25;
      if diag_dat le .z then abort;
    end;
    else do;
      event=0;
      pyear=('31Dec2013'd - child_bdat) / 365.25;
    end;
    logpyear=log(pyear);
  end;
  else delete;
run;



*-- End of File ;
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>;

proc cport file='/home/svesan/psy1502.tsp' lib=work;
  include npr4 qivf ivfdata sosivf;
run;


*-- Calculate #children, #cases, #proportion;
ods output BinomialCLs = b1;
ods listing close;
proc sort data=t1;by trt;run;
proc freq data=t1 ;
  table ott /  nopercent nocol missing binomial(exact) alpha=0.05 out=b2;
  by trt;
run;
ods listing ;

proc transpose data=b2 out=b3;
  var count;
  by trt;
run;

*-- Calculate rate ;

data b4;
  label citxt='Proportion (95%CI)' col1='Number of children' col2='# OCD/TICS/TD';
  merge b1 b3;by trt;
  col1=col1+col2;
  citxt=put(proportion, 5.3)||' ('||put(lowercl, 5.3)||'-'||put(uppercl,5.3)||')';
run;

proc print data=b4 noobs label;
  var trt col1 col2 citxt;
  format col1 col2 comma6.;
  sumvar col1 col2;
run;






proc means data=t1 nway maxdec=0 sum ;
  var pyear ott;
  class trt;
run;

ods graphics on;
proc glimmix data=t1;
  class trt;
  model ott = trt / offset=logpyear dist=poisson link=log;
  lsmeans trt / ilink plots=anom;
  estimate 'IVF frozen vs IVF Std'  trt -1 1 0 0 0 / exp;
  estimate 'ICSI fresh vs IVF Std'  trt -1 0 1 0 0 / exp;
  estimate 'ICSI frozen vs IVF Std' trt -1 0 0 1 0 / exp;
  estimate 'ICSI surg vs IVF Std'   trt -1 0 0 0 1 / exp;
  estimate 'IVF Std vs IVF frozen'  trt  1 -1 0 0 0 / exp;
run;















































































































/**********************
Description of the treatments ... compare with the psy1001 manuscript

data s1;
  retain one 1;
  attrib year length=4 label='Birth Year';
  set sosivf2(keep=et_dat metod child_bdat);
  year=year(child_bdat);
  met=input(metod,8.);

if et_dat>'01jan1982'd and et_dat<'01jan2002'd then do;
  if met=1 then lbl='Standard IVF, stimulerad';
  else if met=2 then lbl='Standard IVF, ostimulerad';
  else if met=3 then lbl='ICSI, farsk ejakulerade spermier';
  else if met=4 then lbl='ICSI, farsk epididymala spermier';
  else if met=5 then lbl='ICSI, farsk testikulara spermier';
  else if met=6 then lbl='Standard IVF, fryst';
  else if met=7 then lbl='ICSI, fryst ejakulerade spermier';
  else if met=8 then lbl='ICSI fryst, annan typ';
  else if met=9 then lbl='ICSI, fryst ospecificerad';
  else if met=0 then lbl='okand';
  else lbl='??';
end;
else if et_dat>'01jan2002'd then do;
  if met=1 then lbl='Standard IVF, stimulerad';
  else if met=2 then lbl='Standard IVF, ostimulerad';
  else if met=3 then lbl='ICSI, farsk ejakulerade spermier';
  else if met=4 then lbl='ICSI, farsk epididymala spermier';
  else if met=5 then lbl='ICSI, farsk testikulara spermier';
  else if met=6 then lbl='Standard IVF, fryst';
  else if met=7 then lbl='ICSI, fryst ejakulerade spermier';
  else if met=8 then lbl='ICSI fryst, annan typ';
  else if met=9 then lbl='IVF efter blastocystoverforing';
  else if met=10 then lbl='ICSI efter blastocystoverforing';
  else lbl='??';
end;
run;

proc summary data=s1 nway;
  var one;
  class year lbl;
  output out=s2 n=count;
run;
proc sort data=s2;by lbl;run;
data s3;
  retain index 0;
  set s2;by lbl;
  if first.lbl then index=index+1;
run;
proc sort data=s3;by year lbl;run;

proc transpose data=s3 out=s4 prefix=t;
  var count;
  id index;
  idlabel lbl;
  by year;
run;

proc print data=s4 noobs label;
  var year t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 ;
  sum year t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 ;
run;

*****/


*--- Check for mother with > 1 father;
proc sql;
  create table v1 as
  select distinct lopnr_kvinna, lopnr_man, etdate
  from ivfdb.qivf1
  order by lopnr_kvinna, lopnr_man
  ;

data v2;
  retain i 0;
  set v1;by lopnr_kvinna;
  if first.lopnr_kvinna then i=1;else i=i+1;
run;

*-- Select women in qivf;
proc sql;
  create table h1 as
  select distinct lopnr_mor
  from qivf1
  where et_dat>.z
  order by lopnr_mor
  ;

*-- Select corresponding women in the MBR with children born after 11jan2007;
  create table h2 as
  select a.lopnr_mor, b.lopnr_barn, b.child_bdat from h1 as a
  join mbr1 as b
  on a.lopnr_mor=b.lopnr_mor
  where b.child_bdat > '11jan2007'd;







*** Number of IVF birth after 2007;
proc sql;
  select byear, count(*)
  from t4
  group by byear
  ;

*-- Check number of OCD cases after qivf;
proc sql;
  create table u0 as select distinct lopnr as lopnr_barn from npr2;

  create table u1 as
  select a.lopnr_barn
  from t4 as a
  join u0 as b
    on a.lopnr_barn=b.lopnr_barn
  ;


title1 'Frequencies of the unique diagnostic codes found in NPR';
title2 'Note: Only one code per individual counted (using first lifelong event)';
proc freq data=npr1;
  table diag;
run;
proc freq data=npr2;
  table diag;
run;

proc sort data=npr2 nodupkey;by lopnr;run;




proc means data=ana0 nway sum maxdec=1;
  var event pyear;
  class trt;
run;
