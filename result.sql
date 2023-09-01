-- Checking Data
Select * from country;
Select * from League;
Select * from matches limit 1200, 50;
Select * from Player limit 100, 30;
Select * from player_attributes limit 500, 20;
Select * from Team limit 100, 30;
Select * from team_attributes limit 100, 10;

-- Data Cleaning
Select count(*) from team where coalesce(id, team_api_id, team_fifa_api_id, team_long_name, team_short_name) is null;
Select count(*) from matches where date is null;
Select count(*) from player where coalesce(id, player_api_id, player_name, player_fifa_api_id, birthday, height, weight) is null;

-- Analyssuiiiii
-- All matches played by Manchester United with the result
Select * from team where team_long_name = "Manchester United";   /* team_api_id = 10260 */

SELECT m.season, m.date, h.team_long_name as "home team", a.team_long_name as "away team", m.home_team_goal, m.away_team_goal, 
case when m.home_team_api_id = 10260 and m.home_team_goal > m.away_team_goal then "Man Utd Won"
when m.home_team_api_id = 10260 and m.home_team_goal < m.away_team_goal then "Man Utd Lost"
when m.away_team_api_id = 10260 and m.home_team_goal > m.away_team_goal then "Man Utd Lost"
when m.away_team_api_id = 10260 and m.home_team_goal < m.away_team_goal then "Man Utd Won"
else "Draw" end as "Result"
from matches m left join team h on m.home_team_api_id = h.team_api_id left join team a on m.away_team_api_id = a.team_api_id
where home_team_api_id = 10260 or away_team_api_id = 10260;

--  season wise Manchester United won, loss and draw
SELECT m.season,
case when m.home_team_api_id = 10260 and m.home_team_goal > m.away_team_goal then "Man Utd Won"
when m.home_team_api_id = 10260 and m.home_team_goal < m.away_team_goal then "Man Utd Lost"
when m.away_team_api_id = 10260 and m.home_team_goal > m.away_team_goal then "Man Utd Lost"
when m.away_team_api_id = 10260 and m.home_team_goal < m.away_team_goal then "Man Utd Won"
else "Draw" end as "Result", count(m.date) as count
from matches m left join team h on m.home_team_api_id = h.team_api_id left join team a on m.away_team_api_id = a.team_api_id
where home_team_api_id = 10260 or away_team_api_id = 10260
group by m.season, Result
ORDER BY m.season, Result;

-- home and away goals by season Manchester United
SELECT
m.season,
SUM(CASE WHEN m.home_team_api_id = 10260  THEN home_team_goal END) AS home_goals,
SUM(CASE WHEN m.away_team_api_id = 10260  THEN away_team_goal END) AS away_goals
FROM matches m
LEFT JOIN Team AS HT on HT.team_api_id = m.home_team_api_id
LEFT JOIN Team AS AT on AT.team_api_id = m.away_team_api_id
WHERE m.home_team_api_id = 10260 or m.away_team_api_id = 10260
GROUP BY m.season;

-- average goals of last season (2015/2016)
Select season, round(avg(home_team_goal + away_team_goal),2) as "Average Goals" from matches where season = "2015/2016";

-- teams with more than average goals last season (2015/2016)
Select round(avg(home_team_goal + away_team_goal),2) as "Average Goals" from matches where season = "2015/2016" into @average;

with home as (Select m.season, m.home_team_api_id, avg(m.home_team_goal) as homeAvg
from matches m
where m.season = "2015/2016"
group by m.home_team_api_id),

away as (Select m.season, m.away_team_api_id, avg(m.away_team_goal) as awayAvg
from matches m
where m.season = "2015/2016"
group by m.away_team_api_id)

select h.season, h.home_team_api_id as team_id, t.team_long_name, a.awayAvg, (h.homeAvg + a.awayAvg)/2 as totalAvg, @average 
from home h join away a on h.home_team_api_id = a.away_team_api_id join team t on h.home_team_api_id = t.team_api_id
where (h.homeAvg + a.awayAvg)/2 > @average;

-- no. of teams by countries

Select c.name, l.name as leagueName, count(distinct m.home_team_api_id) as "number of countries"
from matches m join country c on m.country_id = c.id join league l on m.league_id = l.id
group by m.country_id, m.league_id;


-- Games with more than 10 goals

Select m.season, m.date, a.team_long_name as "homeTeam", a.team_long_name as "awayTeam", m.home_team_goal as "homeGoal", m.away_team_goal as "awayGoals", (m.home_team_goal + m.away_team_goal) as "totalGoals"
from matches m left join team h on m.home_team_api_id = h.team_api_id left join team a on m.away_team_api_id  = a.team_api_id
where (home_team_goal + away_team_goal) >= 10 order by totalGoals desc, m.season desc, m.date asc;


-- Comparing different leagues what percentage of matches ended in a draw?

select l.name, count(*) as totalMatches,
count(case when  m.home_team_goal = m.away_team_goal then 1 else null end) as drawnMatches,
(count(case when  m.home_team_goal = m.away_team_goal then 1 else null end) * 100 / count(*)) as "draw %"
from matches m join league l on m.league_id = l.id
group by m.league_id;

-- Average home and away goals by season by Manchester United

Select season, 
avg(case when home_team_api_id = 10260 then home_team_goal end) as averageHomeGoals,
avg(case when away_team_api_id = 10260 then away_team_goal end) as averageAwayGoals
from matches
group by season;

-- match date to day, month, year

Select date, extract(year from date) as year, monthname(date) as month, day(date) as dateDigit, dayname(date) as day from matches;

-- all matches that happend in weekdays

Select date(date), h.team_long_name as homeTeam, a.team_long_name as awayTeam , dayname(date) as day
from matches m join team h on m.home_team_api_id = h.team_api_id join team a on m.away_team_api_id = a.team_api_id
where dayname(date) not in ("Sunday", "Saturday")
order by m.date desc;

-- All manchester derbies records
-- man utd -> team_api_id = 10260 and man city -> team_api_id = 8456

with cte as (Select date(date) as date, season, 
case when home_team_api_id = 10260 then "Manchester United" else "Manchester City" end as homeTeam,
case when away_team_api_id = 8456 then "Manchester City" else "Manchester United" end as awayTeam,
home_team_goal, away_team_goal
from matches
where (home_team_api_id = 10260 or away_team_api_id = 10260) and (home_team_api_id = 8456 or away_team_api_id = 8456))

Select *,
case when home_team_goal > away_team_goal then homeTeam
when home_team_goal < away_team_goal then awayTeam
else "Draw" end as Result
from cte;

-- All manchester derbies total records

with cte as (Select date(date) as date, season, 
case when home_team_api_id = 10260 then "Manchester United" else "Manchester City" end as homeTeam,
case when away_team_api_id = 8456 then "Manchester City" else "Manchester United" end as awayTeam,
home_team_goal, away_team_goal
from matches
where (home_team_api_id = 10260 or away_team_api_id = 10260) and (home_team_api_id = 8456 or away_team_api_id = 8456)),

newCTE as (Select *,
case when home_team_goal > away_team_goal then homeTeam
when home_team_goal < away_team_goal then awayTeam
else "Draw" end as Result
from cte)

Select result, count(*) as occurance from newCte GROUP BY result;


-- 5 oldest player

Select player_name, date(birthday) as DOB, TIMESTAMPDIFF(year, date(birthday), date(now())) as age
from player
order by age desc
limit 5;

-- top 5 youngest player

Select player_name, date(birthday) as DOB, TIMESTAMPDIFF(year, date(birthday), date(now())) as age
from player
order by age asc
limit 5;

-- Reproducing the 2011/2012 English Premier League final standings

with cte as (Select m.season,  h.team_long_name as homeTeam, a.team_long_name as awayTeam, m.home_team_goal, m.away_team_goal
from matches m left join team h on m.home_team_api_id = h.team_api_id left join team a on m.away_team_api_id = a.team_api_id
where league_id = 1729 and season = "2011/2012"),
	
    home as (select homeTeam as team, home_team_goal as GF, away_team_goal as GA, (home_team_goal - away_team_goal) as gd ,
	case when (home_team_goal - away_team_goal) = 0 then 1
	when (home_team_goal - away_team_goal) > 0 then 3
	else 0 end as Points
	from cte),
	
    away as (select awayTeam as team, away_team_goal as GF, home_team_goal as GA, (away_team_goal - home_team_goal) as gd ,
	case when (away_team_goal - home_team_goal) = 0 then 1
	when (away_team_goal - home_team_goal) > 0 then 3
	else 0 end as Points
	from cte)
    
select 
team, 
count(*) as matches, 
count(case when points = 3 then 1 end) as win, 
count(if(points = 1, 1, null)) as draw, 
count(case when points = 0 then 1 end) as loss,
sum(GF) as GF,
sum(GA) as GA,
sum(gd) as gd, sum(points) as points
from
(
    select team, GF, GA, gd, points
    from home
    union all
    select team, GF, GA, gd, points
    from away
) t
group by team
order by points desc, gd desc, GF desc;