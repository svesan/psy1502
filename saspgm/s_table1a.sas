proc sql;
  create table t1 as
  select outcome format=$outc., trt, event, pyear
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
         100000*sum(event)/sum(pyear) as rate format=comma9. label='Case/100,000'
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
  low_cl    =1-uppercl   ;
  upp_cl    =1-lowercl   ;
  citxt=put(proportion, 5.3)||' ('||put(low_cl, 5.3)||'-'||put(upp_cl,5.3)||')';
run;

title 'Table X. #children, #cases, proportion';
proc print data=b5 noobs label;
  var trt col1 col2 rate citxt;
  by outcome;id outcome;
  format col1 col2 comma9.;
  sum col1 col2;
run;
