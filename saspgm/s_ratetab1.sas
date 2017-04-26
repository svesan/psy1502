

proc sql;
  create table s1 as
  select outcome, group, sex, trtb, frozen, testis, ivf_icsi, infert_rel_diag, male_inf, female_inf, event, exit-entry as pyear
  from coxdsn
  where outcome in ('1','2')
  order by outcome
  ;

  create table s2 as select * from s1 where group=3;
  ;
quit;


proc sql;
  create table t0 as
  select outcome, infert_rel_diag, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s1
  group by outcome, infert_rel_diag
  ;
  create table t1 as
  select outcome, male_inf, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s1
  group by outcome, male_inf
  ;
  create table t2 as
  select outcome, female_inf, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s1
  group by outcome, female_inf
  ;
  create table t3 as
  select outcome, group, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s1
  group by outcome, group
  ;

  create table t4 as
  select outcome, ivf_icsi, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s2
  group by outcome, ivf_icsi
  ;

  create table t5 as
  select outcome, frozen, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s2
  group by outcome, frozen
  ;

  create table t6 as
  select outcome, testis, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s2
  group by outcome, testis
  ;

  *-- Repeat by sex ;
  create table r0 as
  select outcome, infert_rel_diag, sex, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s1
  group by outcome, infert_rel_diag, sex
  ;
  create table r1 as
  select outcome, male_inf, sex, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s1
  group by outcome, male_inf, sex
  ;
  create table r2 as
  select outcome, female_inf, sex, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s1
  group by outcome, female_inf, sex
  ;
  create table r3 as
  select outcome, group, sex, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s1
  group by outcome, group, sex
  ;

  create table r4 as
  select outcome, ivf_icsi, sex, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s2
  group by outcome, ivf_icsi, sex
  ;

  create table r5 as
  select outcome, frozen, sex, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s2
  group by outcome, frozen, sex
  ;

  create table r6 as
  select outcome, testis, sex, sum(event) as event, sum(pyear) as pyear, sum(event)*100000/sum(pyear) as rate
  from s2
  group by outcome, testis, sex
  ;

data a;
  keep var outcome sex x order idtxt txt pyear;
  length x txt $20 var $60;
  retain order 0;

  set t0(in=t0)
      t3(in=t3)
      t4(in=t4)
      t5(in=t5)
      t6(in=t6 where=(testis>.z))

      r0(in=r0)
      r3(in=r3)
      r4(in=r4)
      r5(in=r5)
      r6(in=r6 where=(testis>.z))
  ;
  if t0 then do;order=0; var='infert_rel_diag';   sex='0'; x=left(vvalue(infert_rel_diag));end ;
  if t3 then do;order=3; var='group';             sex='0'; x=left(vvalue(group));end ;
  if t4 then do;order=4; var='ivf_icsi';          sex='0'; x=left(vvalue(ivf_icsi));end ;
  if t5 then do;order=5; var='frozen';            sex='0'; x=left(vvalue(frozen));end ;
  if t6 then do;order=6; var='testis';            sex='0'; x=left(vvalue(testis));end ;

  if r0 then do;order=0; var='infert_rel_diag';            x=left(vvalue(infert_rel_diag));end ;
  if r3 then do;order=3; var='group';                      x=left(vvalue(group));end ;
  if r4 then do;order=4; var='ivf_icsi';                   x=left(vvalue(ivf_icsi));end ;
  if r5 then do;order=5; var='frozen';                     x=left(vvalue(frozen));end ;
  if r6 then do;order=6; var='testis';                     x=left(vvalue(testis));end ;

  *-- Set propoper text strings for the table;
  if order=0 then var='infert_rel_diag';
  else if order=3 then var='group';
  else if order=4 then var='ivf_icsi';
  else if order=5 then var='frozen';
  else if order=6 then var='testis';

  txt=put(event, comma6.)||'/'||put(pyear/1000, comma6.)||' ('||put(rate,4.1)||')';

  if sex='0' then idtxt='all   ';
  else if sex='1' then idtxt='male  ';
  else if sex='2' then idtxt='female';
  else abort;

  *put outcome var x sex txt;
run;

proc sort data=a out=a2(keep=order var outcome x idtxt txt);
  by order var outcome x idtxt;
run;


proc transpose data=a2 out=b;
  var txt;
  id idtxt;
  by order var outcome x;
run;

*-- Output comma semicolon separated output for cut-and-paste to word;
data _null_;
  set b end=eof;
  if _n_=1 then put 'Comparison' ';' 'Outcome' ';' 'Category' ';' 'All offspring, Cases/PYR (rate)#'
                    ';' 'Male offspring, Cases/PYR (rate)#'
                    ';' 'Female offspring, Cases/PYR (rate)#';

  put var ';' outcome ';' x ';' all ';' male ';' female;

  if eof then put // '# PYR: 1000 person years, Rate: Cases per 100,000 person years' //;
run;
