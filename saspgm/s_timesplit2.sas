*-----------------------------------------------------------------------------;
* Study.......: PSY1502                                                       ;
* Name........: s_timesplit2.sas                                              ;
* Date........: 2016-03-04                                                    ;
* Author......: svesan                                                        ;
* Purpose.....: Split the data for poisson regression                         ;
* Note........:                                                               ;
*-----------------------------------------------------------------------------;
* Data used...: bl_covars surv1                                               ;
* Data created: ana0                                                          ;
*-----------------------------------------------------------------------------;
* OP..........: Linux/ SAS ver 9.04.01M2P072314                               ;
*-----------------------------------------------------------------------------;

*-- External programs --------------------------------------------------------;
%inc saspgm(mebpoisint5) / nosource; *-- Macro to split time;

*-- SAS macros ---------------------------------------------------------------;

*-- SAS formats --------------------------------------------------------------;

*-- Main program -------------------------------------------------------------;

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
/*  else if exit GE 28  then do;
    if outcome='I' then do;
      _ib=_ib+1;
      if cens=1 then _ib1=_ib1+1;
    end;
    else if outcome='M' then do;
      _mb=_mb+1;
      if cens=1 then _mb1=_mb1+1;
    end;

    if eof then put 'WARNING: ' _ib 'and ' _mb 'excluded from AD and MR analyses since age > 28 at exit ' /
                    '         ' _ib1 'and ' _mb1 'cases';
    delete;
  end;

  if eof then put 'WARNING: ' _ia 'and ' _ma 'excluded from AD and MR analyses since exit age missing ' /
                    '         ' _ia1 'and ' _ma1 'cases';

  if eof then put 'WARNING: ' _ib 'and ' _mb 'excluded from AD and MR analyses since age > 27 at exit  ' /
                  '         ' _ib1 'and ' _mb1 'cases';
*/
run;
/*
title1 'Censoring description';
title2 'Note: Children > 28 years of age censored at age 28';
title3 'Program: s_timesplit10.sas';
proc freq data=tmp1;
  table outcome*exit_code / nocol nopercent;
run;
*/

/*
rsubmit;
proc upload data=tmp1;run;
proc upload data=bl_covars;run;
proc upload incat=work.formats outcat=work.formats;run;

%inc saspgm(mebpoisint5) / nosource; *-- Macro to split time;
*/
options stimer;
*-- To run it most efficient start split time then add all baseline characteristics;
%mebpoisint(data=tmp1, out=colaps1, entry=entry, exit=exit, event=cens,
            split_start=1, split_end=29, split_step=2, droplimits=Y, logrisk=N,
            id=lopnr_barn, bystmt=outcome);

options nofmterr;

*-- Add baseline covariates and calculate calendar period;
proc sql;
* create index lopnr_barn on colaps1;

  create table colaps2 as
  select a.*, b.byear+interval-1 as calendar length=4 label='Calendar period',
         b.byear, b.sex, b.trt, b.testis, b.ivf_icsi, b.frozen,
         b.mat_cat, b.preterm, b.embryon,
         case when b.infert_yr > 8 then 8 else b.infert_yr end as infertyr length=3 label='Years of Infertility',
         b.twin
  from colaps1 as a
  left join bl_covars as b
    on a.lopnr_barn = b.lopnr_barn
  ;
quit;

*-- Aggregate data for each outcome ;
proc summary data=colaps2 nway missing;
  var cens _risk;
  class outcome byear calendar interval sex trt testis ivf_icsi frozen
        infertyr mat_cat preterm twin embryon;
  output out=colaps3a(drop=_type_ _freq_) sum= ;
run;


data colaps3miss(label='Aggregated analysis dataset for poisson regr. WITH missing values')
     colaps3(label='Aggregated analysis dataset for poisson regr. with NO missing values');
  length cens 5;
  *drop _risk;
  set colaps3a;

  logoffset=log(_risk);

*  *-- Assign blastocyst as No if missing;
*  if group=4 and blastocyst le .z then blastocyst=0;

  output colaps3miss;
  if preterm>.z and mat_cat>.z then output colaps3;
run;


proc download data=work.colaps3 out=work.colaps3;run;
proc download data=work.colaps3miss out=work.colaps3miss;run;
proc download incat=work.formats outcat=work.tempcat;run;

endrsubmit;

proc catalog;
  copy in=work.tempcat out=work.formats;
  select __ivl__ / et=format;
run;quit;

proc copy in=work out=tmpdsn;
  select colaps3 colaps3miss;
run;

libname ut '/home/svesan/hd';
proc copy in=work out=ut;select formats colaps3 colaps3miss;
run;


*-- Cleanup ------------------------------------------------------------------;
title1;footnote;
proc datasets lib=work mt=data nolist;
  delete tmp1-tmp5 colaps3a colaps3b colaps3c colaps3d colaps3e
         colaps3f colaps1 colaps2;
quit;

*-- End of File --------------------------------------------------------------;
