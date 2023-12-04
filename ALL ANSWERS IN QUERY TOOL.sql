CREATE TABLE ball (
    id INt,
    inning INT,
    over INT,
    ball INT,
    batsman VARCHAR(255),
    non_striker VARCHAR(255),
    bowler VARCHAR(255),
    batsman_runs INT,
    extra_runs INT,
    total_runs INT,
    is_wicket BOOLEAN,
    dismissal_kind VARCHAR(255),
    player_dismissed VARCHAR(255),
    fielder VARCHAR(255),
    extras_type VARCHAR(255),
    batting_team VARCHAR(255),
    bowling_team VARCHAR(255)
);

CREATE TABLE match (
    id int,
    city VARCHAR(255),
    date DATE,
    player_of_match VARCHAR(255),
    venue VARCHAR(255),
    neutral_venue BOOLEAN,
    team1 VARCHAR(255),
    team2 VARCHAR(255),
    toss_winner VARCHAR(255),
    toss_decision VARCHAR(50),
    winner VARCHAR(255),
    result VARCHAR(50),
    result_margin VARCHAR(50),
    eliminator varchar,
    method VARCHAR(50),
    umpire1 VARCHAR(255),
    umpire2 VARCHAR(255)
);

copy ball from 'C:\postgre\IPL_Ball.csv' delimiter ',' csv header;
copy match from 'C:\postgre\IPL_matches.csv' delimiter ',' csv header;
select count(*) from ball 
select count(*) from match 

-- Task 1: Get 2-3 players with high Strike Rate (S.R) who have faced at least 500 balls
-- : AGRESSIVE BATSMAN 

SELECT batsman,sum(batsman_runs) as total_runs,count(*) ball_faced,
(sum(batsman_runs)/count(*))*100 as strk_rate from ball
where extras_type <> 'wides'
group by batsman
having count(*) >= 500
order by strk_rate desc limit 10 

--- create table diliviriesv_02

CREATE TABLE deliveries_v02 AS
SELECT d.*, i.venue, i.date
FROM ball  d
LEFT JOIN match i ON d.id = i.id;

--- create table diliviriesv_03
CREATE TABLE deliveries_v03 AS
SELECT *, 
       CASE 
           WHEN total_runs >= 4 THEN 'boundary'
           WHEN total_runs = 0 THEN 'dot'
           ELSE 'other'
       END AS ball_result
FROM deliveries_v02;

-- alter table deliveries_v02 for year 
ALTER TABLE deliveries_v02
ADD COLUMN year INT;

-- Update the new column with the extracted year
SET SQL_SAFE_UPDATES = 0;
UPDATE deliveries_v02
SET year = EXTRACT(YEAR FROM date);

-- 2  Get 2-3 players with good Average who have played more than 2 IPL seasons:

select batsman, count(distinct year)as no_of_seasons ,
avg(batsman_runs) as avg_runs,sum(batsman_runs) as total_runs
from deliveries_v02 group by batsman
having count(distinct year) > 2
order by no_of_seasons desc limit 10 

-- 3 Get 2-3 Hard-hitting players

--who have scored most runs in boundaries and have played more than 2 IPL seasons.
select batsman,count(ball_result) as boundries ,count(distinct year)as no_of_seasons
from deliveries_v03 where ball_result = 'boundary'
group by batsman
having count(distinct year ) > 2
order by boundries desc limit 10

-- 4  Get 2-3 bowlers with good economy who have bowled at least 500 balls in IPL so far.
select bowler,count(*) as balls_balled ,sum(total_runs) as runs_given,

sum(total_runs)/count(*) as economy from deliveries_v03
where extras_type <> 'wides'
group by bowler having count(*) >= 500
order by economy desc 
limit 10 

-- 5 Now you need to get 2-3 bowlers with the best strike rate and who have bowled at 
-- least 500 balls in IPL so far.To do that you have to 

select bowler,count(*) as balls_balled ,sum(total_runs) as runs_given,
sum(total_runs)/count(*) as economy,sum(case when  is_wicket then 1 else 0 end) AS wickets_taken from deliveries_v03
where extras_type <> 'wides'
group by bowler having count(*) >= 500
order by wickets_taken desc 
limit 10 

--6-- Now you need to get 2-3 All_rounders with the best batting as well 
 as bowling strike rate and  who have faced at least 500 balls in IPL so far and have bowled minimum 300 balls.

CREATE TABLE allrounder AS (
wITH BATSMAN AS (SELECT batsman,sum(batsman_runs) as total_runs,count(*) ball_faced,
(sum(batsman_runs)/count(*))*100 as strk_rate from ball
where extras_type <> 'wides'
group by batsman
having count(*) >= 500
-- order by total_runs desc limit 10
				),
 BOWLER AS (select bowler,count(*) as balls_balled ,sum(total_runs) as runs_given,
sum(total_runs)/count(*) as economy from deliveries_v03
where extras_type <> 'wides'
group by bowler   having count(*) >= 300
 -- order by balls_balled desc 
--limit 10
		   )
SELECT * FROM BATSMAN B, BOWLER BOWL
WHERE B.batsman = BOWL.BOWLER
)
select * from allrounder

WITH AllrounderRanking AS (
    SELECT
        batsman,
        total_runs,
        ball_faced,
        strk_rate,
        bowler,
        balls_balled,
        runs_given,
        economy,
        DENSE_RANK() OVER (ORDER BY total_runs DESC) AS batsman_rank,
        DENSE_RANK() OVER (ORDER BY balls_balled DESC) AS bowler_rank
    FROM allrounder
)

SELECT
    batsman,
    total_runs,
    ball_faced,
    strk_rate,
    bowler,
    balls_balled,
    runs_given,
    economy,
    batsman_rank,
    bowler_rank
FROM AllrounderRanking
WHERE batsman_rank <= 10 or bowler_rank <= 10
ORDER BY batsman_rank, bowler_rank;

-- additional problems 

-- Get the count of cities that have hosted an IPL match ans- 33
select * from ipl_matches
select count(distinct(city)) from ipl_matches

-- Create table deliveries_v02 with all the columns of the table ‘deliveries’ 

create table deliviries as (select * from ipl_ball) and an additional column ball_result containing values boundary, dot or 
other depending on the total_run (boundary for >= 4, dot for 0 and other for any other number)
 (Hint 1 : CASE WHEN statement is used to get condition based results)
 (Hint 2: To convert the output data of the select statement into a table, you can use a subquery.
  Create table table_name as [entire select statement].

CREATE TABLE deliveries_v02 AS
SELECT *, 
       CASE 
           WHEN total_runs >= 4 THEN 'boundary'
           WHEN total_runs = 0 THEN 'dot'
           ELSE 'other'
       END AS ball_result
FROM deliviries;



-- Write a query to fetch the total number of boundaries and dot balls from the deliveries_v02 table.

select count(ball_result)  from deliveries_v02 where ball_result = 'boundary'
select count(ball_result)  from deliveries_v02 where ball_result = 'dot'

-- Write a query to fetch the total number of boundaries scored by each team from the deliveries_v02 table
--  and order it in descending order of the number of boundaries scored.

select batting_team,count(ball_result) as boundry_scored from deliveries_v02 where ball_result = 'boundary'
group by batting_team
order by boundry_scored desc

-- Write a query to fetch the total number of dot balls bowled by each team and 
-- order it in descending order of the total number of dot balls bowled.
select batting_team,count(ball_result) as dot_balls from deliveries_v02
 where ball_result = 'dot'
group by batting_team
order by dot_balls desc

-- Write a query to fetch the total number of dismissals by dismissal kinds where 
-- dismissal kind is not NA

select count(dismissal_kind)  from deliveries_v02 where dismissal_kind <> 'NA'
-- Write a query to get the top 5 bowlers who conceded 
-- maximum extra runs from the deliveries table
select bowler,sum(extra_runs) as extra_runs from deliveries_v02
group by bowler
order by extra_runs desc limit 5 

-- Write a query to create a table named deliveries_v03 with all the columns of deliveries_v02 table
-- and two additional column (named venue and match_date) of venue and date from table matches
CREATE TABLE deliveries_v03 AS
SELECT d.*, i.venue, i.date
FROM deliveries_v02  d
LEFT JOIN ipl_matches i ON d.id = i.id;

-- Write a query to fetch the total runs scored for each venue and 
-- order it in the descending order of total runs scored.
select venue,sum(total_runs) as total_runs from deliveries_v03
group by venue
order by total_runs desc

-- Write a query to fetch the year-wise total runs scored at 
-- Eden Gardens and order it in the descending order of total runs scored.
SELECT 
     year,
    SUM(total_runs) AS total_runs_scored
FROM deliveries_v03
WHERE venue = 'Eden Gardens'
GROUP BY year
ORDER BY total_runs_scored DESC;





















