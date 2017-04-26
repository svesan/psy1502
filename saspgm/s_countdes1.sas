proc sql;
  create table t1 as
  select outcome, trt, event, pyear
  from ana0
  order by outcome, trt, event
  ;
quit;

*-- Calculate #children, #cases, #proportion;
ods output BinomialCLs = b1;
ods listing close;
proc freq data=t1 ;
  table event /  nopercent nocol missing binomial(exact) alpha=0.05 out=b2;
  by outcome trt;
run;
ods listing ;

proc transpose data=b2 out=b3;
  var count;
  by outcome trt;
run;

*-- Calculate rate ;
proc sql;
  create table b4 as
  select outcome, trt, sum(event) as event, sum(pyear) as pyear,
         100000*sum(event)/sum(pyear) as rate format=comma9.
  from t1
  group by outcome, trt
  order by outcome, trt
  ;
quit;

data b5;
  label citxt='Proportion (95%CI)' col1='Number of children' col2='# OCD/TICS/TD';
  merge b1 b3 b4;by outcome trt;
*  if col1 ne check then put col1= check= _n_=;
  proportion=1-proportion;
  uppercl   =1-uppercl   ;
  lowercl   =1-lowercl   ;
  citxt=put(proportion, 5.3)||' ('||put(lowercl, 5.3)||'-'||put(uppercl,5.3)||')';
run;

proc print data=b5 noobs label;
  var trt event citxt rate;
  by outcome;id outcome;
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
