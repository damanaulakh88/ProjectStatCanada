options nosource nonotes errors=0;

FILENAME REFFILE '/folders/myshortcuts/myfolder/Dataset1.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.IMPORT;
	GETNAMES=YES;
RUN;

data work.dataset1_temp;
set work.dataset1;
alt=strip(put(alt_geo_code,10.));
run;

proc sql;
create table new1 as select *,
case 
when alt like'59%'  or alt like'48%' or alt like'47%' or alt like '46%' then 'Western Canada'
when alt like '35%' or alt like'24%'  then 'Central Canada'
when alt like '13%' or alt like '11%' or alt like '12%' or alt like '10%' then'Atlantic Canada'
when alt like '60%' or alt like'61%' or alt like '62%' then 'Northern Canada'
else 'Other'
end as region
from work.dataset1_temp;
quit;

/* a.	Proportion of population by “Aboriginal Identity” and “Non-Aboriginal Identity” */

data new2(keep= region total_abor abor nonabor);
set new1;
where (RT="Total - Population by Registered or Treaty Indian status" and AGE="Total - Age"
       and SEX="Total - Sex" and INCOME ="Total - Income statistics"
       and ALT_GEO_CODE IN (10,11,12,13,24,35,46,47,48,59,60,61,62,));
run;


proc sql;
create table proportion as
select a.region ,
       (a.abor/a.total_abor)*100 as Abor_Propotion,
       (a.nonabor/a.total_abor)*100 as NonAbor_Propotion
   from (
     select region, sum(total_abor) as total_abor,
        sum(abor) as abor,
        sum(nonabor) as nonabor
          from new2 
          group by region
        ) a;
quit;

/*b.	Average Total Income for “Aboriginal Identity” and “Non-Aboriginal Identity”*/

data new3(keep= region abor nonabor);
set new1;
where (RT="Total - Population by Registered or Treaty Indian status" and AGE="Total - Age"
       and SEX="Total - Sex" and INCOME ="Average total income ($)"
       and ALT_GEO_CODE IN (10,11,12,13,24,35,46,47,48,59,60,61,62,));
run;


proc sql;
create table average_income as
select region ,
       avg(abor) as Average_Income_Aboriginal,
       avg(nonabor) as Average_Income_NonAboriginal
       from new3
       group by region; 
quit;

/*c.	Proportion of male vs. female population by “Aboriginal Identity” and “Non-Aboriginal Identity”*/


data new4(keep= region sex total_abor abor nonabor);
set new1;
where (RT="Total - Population by Registered or Treaty Indian status" and AGE="Total - Age"
       and SEX in ("Male","Female") and INCOME ="Total - Income statistics"
       and ALT_GEO_CODE IN (10,11,12,13,24,35,46,47,48,59,60,61,62,));
run;


proc sql;
create table proportion_m_vs_f as
select b.region,
       b.sex,
       (b.sum_abor/b.total_abor)*100 as Percent_Abor,
       (b.sum_nonabor/b.total_abor)*100 as Percent_NonAbor
       
   from ( select region,
       		sex,
       		sum(total_abor) as Total_Abor,
       		sum(abor) as Sum_Abor,
       		sum(nonabor) as Sum_NonAbor
          from new4
            group by region,sex
         )b;
quit;

/* d.	Age group with most number of individuals with “Aboriginal identity”  */

data new5(keep= region age abor);
set new1;
where (RT="Total - Population by Registered or Treaty Indian status" and AGE <> "Total - Age"
       and SEX="Total - Sex" and INCOME ="Total - Income statistics"
       and ALT_GEO_CODE IN (10,11,12,13,24,35,46,47,48,59,60,61,62,));
run;

proc sql;
create table age_group_abor as
select c.region,
       c.age,
       c.sum_abor as Abor_Individual
  from (select region,
               age,
               sum(abor) as Sum_Abor
        from new5
        group by region,age
       )c
  group by c.region
  having c.sum_abor=max(c.sum_abor);
quit;

               
          

