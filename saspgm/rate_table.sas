

proc sql;
  create table s1 as
  select outcome, group, sex, trtb, frozen, testis, ivf_icsi, male_inf, female_inf, event, exit-entry as pyear
  from coxdsn
  where outcome in ('1','2')
  order by outcome
  ;

  create table s2 as select * from s1 where group=3;
  ;
quit;


proc sql;
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
  length x txt $20;
  set t1(in=t1)
      t2(in=t2)
      t3(in=t3)
      t4(in=t4)
      t5(in=t5)
      t6(in=t6)
      t6(in=t6)
      r1(in=d1)
      r2(in=d2)
      r3(in=d3)
      r4(in=d4)
      r5(in=d5)
      r6(in=d6)
      r6(in=d6)
  ;
  if t1 then do;var='male_inf';  sex=0; x=left(vvalue(male_inf));end ;
  if t2 then do;var='female_inf';sex=0; x=left(vvalue(female_inf));end ;
  if t3 then do;var='group';     sex=0; x=left(vvalue(group));end ;
  if t4 then do;var='ivf_icsi';  sex=0; x=left(vvalue(ivf_icsi));end ;
  if t5 then do;var='frozen';    sex=0; x=left(vvalue(frozen));end ;
  if t6 then do;var='testis';    sex=0; x=left(vvalue(testis));end ;

  if d1 then do;var='male_inf';  x=left(vvalue(male_inf));end ;
  if d2 then do;var='female_inf';x=left(vvalue(female_inf));end ;
  if d3 then do;var='group';     x=left(vvalue(group));end ;
  if d4 then do;var='ivf_icsi';  x=left(vvalue(ivf_icsi));end ;
  if d5 then do;var='frozen';    x=left(vvalue(frozen));end ;
  if d6 then do;var='testis';    x=left(vvalue(testis));end ;

  txt=put(event, comma6.)||' ('||put(rate,4.1)||')';

  put outcome var x sex txt;
run;
proc sort data=a;by outcome var x sex;run;

proc transpose data=a out=b;
  var txt;
  id sex;
  by outcome var x;
run;
