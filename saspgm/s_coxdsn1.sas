*-----------------------------------------------------------------------------;
* Study.......: PSY1502                                                       ;
* Name........: s_coxdsn1.sas                                                 ;
* Date........: 2016-03-10                                                    ;
* Author......: svesan                                                        ;
* Purpose.....: Create dataset for Cox regression                             ;
* Note........: 160426 added infertility and renamed to s_coxdsn1             ;
* Note........: 160427 bug fix                                                ;
*-----------------------------------------------------------------------------;
* Data used...: bl_covars surv1                                               ;
* Data created: cox1                                                          ;
*-----------------------------------------------------------------------------;
* OP..........: Linux/ SAS ver 9.04.01M2P072314                               ;
*-----------------------------------------------------------------------------;

*-- External programs --------------------------------------------------------;

*-- SAS macros ---------------------------------------------------------------;

*-- SAS formats --------------------------------------------------------------;

*-- Main program -------------------------------------------------------------;
* filename saspgm '/home/svesan/ki/ABS/mep/sasproj/PSY/PSY1502/saspgm'; * libname on skjold;

data tmp1;
  drop _ia _ma _ia1 _ma1 _ib _mb _ib1 _mb1 _ta _ta1;
  retain _ia _ma _ia1 _ma1 _ib _mb _ib1 _mb1  _ta _ta1 0;

  set surv1(keep=outcome lopnr_barn entry exit  outcome event) end=eof;
  cens=1-event;

  *-- Delete records where exit age is missing;
  if exit le .z then do;
    if outcome='1' then do;
      _ia=_ia+1;
      if cens=1 then _ia1=_ia1+1;
    end;
    else if outcome='2' then do;
      _ma=_ma+1;
      if cens=1 then _ma1=_ma1+1;
    end;
    else if outcome='3' then do;
      _ta=_ta+1;
      if cens=1 then _ta1=_ta1+1;
    end;

    if eof then put 'WARNING: ' _ia ', ' _ma 'and ' _ta 'excluded from OCD, TICS and TD analyses since exit age missing ' /
                    '         ' _ia1 ', ' _ma1 'and ' _ta1 'cases';
    delete;
  end;
run;


*-- Add baseline covariates and calculate calendar period;
proc sql;
  create table tmp2 as
  select a.outcome, a.lopnr_barn, a.entry, a.exit, a.event,
         b.byear, b.sex, b.group, b.trt, b.trtb, b.testis, b.ivf_icsi, b.frozen,
         b.mage, b.page, b.mat_cat, b.pat_cat, b.preterm, b.embryon,
         case when b.infert_yr > 8 then 8 else b.infert_yr end as infertyr length=3 label='Years of Infertility',
         b.twin, b.mat_phist, b.pat_phist,
         b.infert_rel_diag, b.infert_diag, b.infcat
  from tmp1 as a
  left join bl_covars as b
    on a.lopnr_barn = b.lopnr_barn
  ;
quit;


*- Dataset with and without missing values on covariates;
data coxdsn_miss(label='Aggregated analysis dataset for poisson regr. WITH missing values')
     coxdsn(label='Aggregated analysis dataset for poisson regr. with NO missing values');
  set tmp2;

  *-- 160427 Bug fix. Earlier cut at trt=1;
  if trt=0 then group=1;
  else if trt>0 then group=3;

  if trt=0 then trtb=0;

  if trt le .z then delete;
  else do;
    output coxdsn_miss;;

    if preterm>.z and mat_cat>.z and pat_cat>.z and infertyr>.z
       then output coxdsn;
  end;

run;

*--- If any, remove duplicates;
proc sort data=coxdsn nodupkey;by outcome lopnr_barn ;run;

data _null_;
  set coxdsn(keep=lopnr_barn entry exit);
  if entry=exit then put lopnr_barn= 'ERROR: Entry = exit';
  if entry>exit then put lopnr_barn= 'ERROR: Entry after exit';
  if entry<1 then put lopnr_barn= 'ERROR: Entry before age 1';
  if entry>29 then put lopnr_barn= 'ERROR: Entry after age 29';
run;

*-- OCD outcome;
data coxocd;
  set coxdsn(where=(outcome='1'));
run;

%tor(data=coxocd, dname=coxocd, rfile=coxocd.R,
     var=entry exit event byear embryon infertyr,
     class=sex group trt trtb testis ivf_icsi frozen mage page mat_cat pat_cat mat_phist pat_phist preterm twin infert_rel_diag infcat);


*-- TIC outcome;
data coxtic;
  set coxdsn(where=(outcome='2'));
run;

%tor(data=coxtic, dname=coxtic, rfile=coxtic.R,
     var=entry exit event byear embryon infertyr mage page,
     class=sex group trt trtb testis ivf_icsi frozen mat_cat pat_cat mat_phist pat_phist preterm twin infert_rel_diag infcat);


*-- TD outcome;
data coxtd;
  set coxdsn(where=(outcome='3'));
run;

%tor(data=coxtd, dname=coxtd, rfile=coxtd.R,
     var=entry exit event byear embryon infertyr mage page,
     class=sex group trt trtb testis ivf_icsi frozen mat_cat pat_cat mat_phist pat_phist preterm twin infert_rel_diag infcat);


*-- Any outcome;
data coxott;
  set coxdsn(where=(outcome='4'));
run;

%tor(data=coxott, dname=coxott, rfile=coxott.R,
     var=entry exit event byear embryon infertyr mage page,
     class=sex group trt trtb testis ivf_icsi frozen mat_cat pat_cat mat_phist pat_phist preterm twin infert_rel_diag infcat);


*-- ALL outcome;
%tor(data=coxdsn, dname=coxdsn, rfile=coxdsn.R,
     var=entry exit event byear embryon infertyr mage page,
     class=outcome sex group trt trtb testis ivf_icsi frozen mat_cat pat_cat mat_phist pat_phist preterm twin infert_rel_diag infcat);


*-- Cleanup ------------------------------------------------------------------;
title1;footnote;
proc datasets lib=work mt=data nolist;
  delete tmp1-tmp3;
quit;

*-- End of File --------------------------------------------------------------;
