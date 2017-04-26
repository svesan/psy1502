proc format;
  value ivficsi 1='IVF' 2='ICSI';
  value trtfmt 1='Standard IVF' 2='IVF frozen' 3='ICSI fresh' 4='ICSI frozen' 5='ICSI surgical';
run;

data t1;
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
run;




proc freq data=t1;
  table metod metod1 metod2;
run;

proc freq data=t1;
  table ivf_icsi surg frozen trt / missing;
run;

title1 'Metod when trt not defined';
proc freq data=t1;
  where trt in (.,.U);
  table metod / missing;
run;
title;

/*
Up to year 2002
1=Standard IVF, stimulerad
2=Standard IVF, ostimulerad
3=ICSI, färsk ejakulerade spermier
4=ICSI, färsk epididymala spermier
5=ICSI, färsk testikulära spermier
6= Standard IVF, fryst
7= ICSI, fryst ejakulerade spermier
8= ICSI fryst, annan typ
9= ICSI, fryst ospecificerad
   0= okänd
   C= ICSI, ospecificerad
   D= Standard IVF, ospecificera
   U= ICSI, fryst ospecificerad
Y= Standard IVF, ospecificerad
Z= ICSI, ospecificerad

From year 2002 and onwards
1=Standard IVF, stimulerad
2=Standard IVF, ostimulerad
3=ICSI, färsk ejakulerade spermier
4=ICSI, färsk epididymala spermier
5=ICSI, färsk testikulära spermier
6= Standard IVF, fryst
7= ICSI, fryst ejakulerade spermier
8= ICSI fryst, annan typ
9= IVF efter blastocystöverföring
10= ICSI efter blastocystöverföring
***/
