begin;

drop table if exists club._schedule_factors;

create table club._schedule_factors (
        team_id			integer,
	year			integer,
        offensive               float,
        defensive		float,
        strength                float,
        schedule_offensive      float,
        schedule_defensive      float,
        schedule_strength       float,
        schedule_offensive_all	float,
        schedule_defensive_all	float,
        primary key (team_id,year)
);

-- defensive
-- offensive
-- strength 
-- schedule_offensive
-- schedule_defensive
-- schedule_strength 

insert into club._schedule_factors
(team_id,year,offensive,defensive)
(
select o.level::integer,o.year,o.exp_factor,d.exp_factor
from club._factors o
left outer join club._factors d
  on (d.level,d.year,d.parameter)=(o.level,o.year,'defense')
where o.parameter='offense'
);

update club._schedule_factors
set strength=offensive/defensive;

----

create temporary table r (
         team_id		integer,
	 team_league_key	text,
         opponent_id		integer,
	 opponent_league_key	text,
         game_date              date,
         year                   integer,
	 field_id		text,
         offensive              float,
         defensive		float,
         strength               float,
	 field			float,
	 o_league		float,
	 d_league		float
);

insert into r
(
team_id,team_league_key,
opponent_id,opponent_league_key,
game_date,year,field_id)
(
select
r.team_id,
r.team_league_key,
r.opponent_id,
r.opponent_league_key,
r.game_date,
r.year,
r.field
from club.results r
where r.year between 2008 and 2015
);

update r
set
offensive=o.offensive,
defensive=o.defensive,
strength=o.strength
from club._schedule_factors o
where (r.opponent_id,r.year)=(o.team_id,o.year);

-- field

update r
set field=f.exp_factor
from club._factors f
where (f.parameter,f.level)=('field',r.field_id);

-- opponent offense_league

update r
set o_league=f.exp_factor
from club._factors f
where (f.parameter,f.level)=('offense_league',r.opponent_league_key);

-- opponent defense_league

update r
set o_league=f.exp_factor
from club._factors f
where (f.parameter,f.level)=('defense_league',r.opponent_league_key);

--

create temporary table rs (
         team_id		integer,
         year                   integer,
         offensive              float,
         defensive              float,
         strength               float,
         offensive_all		float,
         defensive_all		float
);

insert into rs
(team_id,year,
 offensive,defensive,strength,offensive_all,defensive_all)
(
select
team_id,
year,
exp(avg(log(offensive*o_league))),
exp(avg(log(defensive*d_league))),
exp(avg(log(strength*o_league/d_league))),
exp(avg(log(offensive*o_league/field))),
exp(avg(log(defensive*d_league*field)))
from r
group by team_id,year
);

update club._schedule_factors
set
  schedule_offensive=rs.offensive,
  schedule_defensive=rs.defensive,
  schedule_strength=rs.strength,
  schedule_offensive_all=rs.offensive_all,
  schedule_defensive_all=rs.defensive_all
from rs
where
  (_schedule_factors.team_id,_schedule_factors.year)=
  (rs.team_id,rs.year);

commit;
