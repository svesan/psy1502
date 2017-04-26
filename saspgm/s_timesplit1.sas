*-----------------------------------------------------------------------------;
* Study.......: PSY1502                                                       ;
* Name........: s_timesplit1.sas                                              ;
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

  set anatime0(keep=outcome lopnr_barn entry exit exit_code outcome event) end=eof;
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


*-- Create information about genetic (comorbid) diseases time varying;
data tmp2;
  set bl_covars(keep=lopnr_barn child_bdat comorb_dat comorb);

  if child_bdat le .z then comorb_age=.M;
  else if comorb_dat gt .z then comorb_age = (comorb_dat - child_bdat)/365.25;
  else comorb_age = .N;
run;



*-- Add baseline covariates and calculate calendar period;
proc sql;
* create index lopnr_barn on colaps1;

  create table colaps2 as
  select a.*, b.byear+interval-1 as calendar length=4 label='Calendar period',
         b.byear, b.sex, b.group, b.ivfcode, b.testis, b.ivf_icsi, b.frozen, b.blastocyst,
         b.pat_catb, b.mat_catc, b.mat_cat, b.preterm, b.mor_phist, b.far_phist,
         case when b.infert_yr > 8 then 8 else b.infert_yr end as infertyr length=3 label='Years of Infertility',
         case when comorb_age < a.interval then 0 else 1 end as genetic length=3 label='Genetic disease',
         d.twin, b.parity, b.horm
  from colaps1 as a
  left join bl_covars as b
    on a.lopnr_barn = b.lopnr_barn
  left join tmp2 as c
    on a.lopnr_barn = c.lopnr_barn
  left join famtyp as d
    on a.lopnr_barn = d.lopnr_barn
  ;
quit;

*-- Aggregate data for AD ;
proc summary data=colaps2 nway missing;
  where outcome='I';
  var cens _risk;
  class outcome byear calendar interval sex group ivfcode testis ivf_icsi frozen blastocyst
        infertyr pat_catb mat_catc mat_cat preterm mor_phist far_phist genetic twin parity horm;
  output out=colaps3a(drop=_type_ _freq_) sum= ;
run;

/**** 120806 exclude spectrum
*-- Aggregate data for spectrum ;
proc summary data=colaps2 nway missing;
  where outcome='S';
  var cens _risk;
  class outcome byear interval sex group ivfcode testis ivf_icsi frozen blastocyst
     pat_catb mat_catc mat_cat preterm mor_phist far_phist genetic twin;
  output out=colaps3b(drop=_type_ _freq_) sum= ;
run;
****/

*-- Aggregate data for mental retardation;
proc summary data=colaps2 nway missing;
  where outcome='M';
  var cens _risk;
  class outcome byear calendar interval sex group ivfcode testis ivf_icsi frozen blastocyst
        infertyr pat_catb mat_catc mat_cat preterm mor_phist far_phist genetic twin parity horm;
  output out=colaps3c(drop=_type_ _freq_) sum= ;
run;


*-- Number of children in each cell;
proc sql exec;
  *-- Unique children;
  create table tmp3 as
  select distinct lopnr_barn
  from colaps2;

  *-- Add covariates in colaps datasets;
  create table tmp4 as
  select a.*, b.byear, b.sex, b.group, b.ivfcode, b.testis, b.ivf_icsi,
         b.frozen, b.blastocyst,
         b.pat_catb, b.mat_catc, b.mat_cat, b.preterm, b.mor_phist, b.far_phist, c.twin, b.parity, b.horm
  from tmp3 as a
  left join bl_covars as b
    on a.lopnr_barn=b.lopnr_barn
  left join famtyp as c
    on a.lopnr_barn=c.lopnr_barn
  ;

  *-- Count number of children in each aggregated cell;
  create table tmp5 as
  select byear, sex, group, ivfcode, testis, ivf_icsi,
         frozen, blastocyst,
         pat_catb, mat_catc, mat_cat, preterm, mor_phist, far_phist, twin, parity, horm,
         count(lopnr_barn) as freq_child length=5
  from tmp4
  group by byear, sex, group, ivfcode, testis, ivf_icsi,
         frozen, blastocyst,
         pat_catb, mat_catc, mat_cat, preterm, mor_phist, far_phist, twin, parity, horm
  ;

run;quit;

* a.genetic=b.genetic AND ;
proc sql;
  create table colaps3d as
  select a.*, b.freq_child
  from colaps3a as a
  left join tmp5 as b
  on a.byear=b.byear AND a.sex=b.sex AND a.group=b.group AND a.ivfcode=b.ivfcode AND
     a.testis=b.testis AND a.ivf_icsi=b.ivf_icsi AND
     a.frozen=b.frozen AND a.blastocyst=b.blastocyst AND
     a.pat_catb=b.pat_catb AND a.mat_catc=b.mat_catc AND a.mat_cat=b.mat_cat AND
     a.preterm=b.preterm AND a.mor_phist=b.mor_phist AND a.far_phist=b.far_phist AND
     a.twin=b.twin AND a.parity=b.parity AND a.horm=b.horm
  ;

*  create table colaps3e as
  select a.*, b.freq_child
  from colaps3b as a
  left join tmp5 as b
  on a.byear=b.byear AND a.sex=b.sex AND a.group=b.group AND a.ivfcode=b.ivfcode AND
     a.testis=b.testis AND a.ivf_icsi=b.ivf_icsi AND
     a.frozen=b.frozen AND a.blastocyst=b.blastocyst AND
     a.pat_catb=b.pat_catb AND a.mat_catc=b.mat_catc AND a.mat_cat=b.mat_cat AND
     a.preterm=b.preterm AND a.mor_phist=b.mor_phist AND a.far_phist=b.far_phist AND
     a.twin=b.twin
 ;

  create table colaps3f as
  select a.*, b.freq_child
  from colaps3c as a
  left join tmp5 as b
  on a.byear=b.byear AND a.sex=b.sex AND a.group=b.group AND a.ivfcode=b.ivfcode AND
     a.testis=b.testis AND a.ivf_icsi=b.ivf_icsi AND
     a.frozen=b.frozen AND a.blastocyst=b.blastocyst AND
     a.pat_catb=b.pat_catb AND a.mat_catc=b.mat_catc AND a.mat_cat=b.mat_cat AND
     a.preterm=b.preterm AND a.mor_phist=b.mor_phist AND a.far_phist=b.far_phist AND
     a.twin=b.twin AND a.parity=b.parity AND a.horm=b.horm
 ;
run;quit;


data colaps3miss(label='Aggregated analysis dataset for poisson regr. WITH missing values')
     colaps3(label='Aggregated analysis dataset for poisson regr. with NO missing values');
  length cens 5;
  *drop _risk;
  set colaps3d colaps3f;

  logoffset=log(_risk);

  *-- Assign blastocyst as No if missing;
  if group=4 and blastocyst le .z then blastocyst=0;

  output colaps3miss;
  if preterm>.z and group>.z and pat_catb>.z and mat_catc>.z and
     mor_phist>.z and far_phist>.z and genetic>.z then output colaps3;
run;

/*
proc download data=work.colaps3 out=work.colaps3;run;
proc download data=work.colaps3miss out=work.colaps3miss;run;
proc download incat=work.formats outcat=work.tempcat;run;

endrsubmit;

proc catalog;
  copy in=work.tempcat out=work.formats;
  select __ivl__ / et=format;
run;quit;
*/
proc copy in=work out=tmpdsn;
  select colaps3 colaps3miss;
run;


*-- Cleanup ------------------------------------------------------------------;
title1;footnote;
proc datasets lib=work mt=data nolist;
  delete tmp1-tmp5 colaps3a colaps3b colaps3c colaps3d colaps3e
         colaps3f colaps1 colaps2;
quit;

*-- End of File --------------------------------------------------------------;
