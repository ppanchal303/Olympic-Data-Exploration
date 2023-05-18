/*
Olympic data exploration
Database: https://www.kaggle.com/datasets/heesoo37/120-years-of-olympic-history-athletes-and-results?resource=download&select=athlete_events.csv

Author: Pranav Panchal
Date: 06/01/2023
*/

###################
### DATA IMPORT ###
###################
-- Creating schema for the olympic history database
CREATE SCHEMA olympic;

-- Setting the newly created schema as default
USE olympic;

DROP TABLE IF EXISTS athletes;
CREATE TABLE athletes(
	id nvarchar(255), -- INT NOT NULL,
    name nvarchar(255),
    sex nvarchar(255),
    age nvarchar(255),
    height nvarchar(255),
    weight nvarchar(255),
    team nvarchar(255),
    NOC nvarchar(255),
    games nvarchar(255),
    year nvarchar(255),
    season nvarchar(255),
    city nvarchar(255),
    sport nvarchar(255),
    event nvarchar(255),
    medal nvarchar(255)
    -- dummy nvarchar(255)
);

-- Loading data from the csv file into the table created
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/athlete_events.csv'
-- LOAD DATA LOCAL INFILE 'data/athlete_events.csv'
INTO TABLE athletes
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Sanity check
SELECT *
FROM athletes;

-- Creating a new table called 'noc_regions' to store athlete data
DROP TABLE IF EXISTS noc_regions;
CREATE TABLE noc_regions(
	noc nvarchar(255),
    region nvarchar(255),
    notes nvarchar(255)
);

-- Loading data from the csv file into the table created
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/noc_regions.csv'
INTO TABLE noc_regions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Sanity check
SELECT *
FROM noc_regions;

### 1. How many olympics games have been held? ###
SELECT COUNT(DISTINCT(games)) AS total_number_of_olympic_games
FROM athletes;
-- There have been 51 olympic games as per the data

##################################################################################################################

### 2. List down all Olympics games held so far. ###
SELECT 
	COUNT(games) OVER (ORDER BY games) AS SrNo,
    games,
    city
FROM athletes
GROUP BY games
ORDER BY games;

##################################################################################################################

### 3. Mention the total no of nations who participated in each olympics game? ###
SELECT 
	games,
    COUNT(DISTINCT(NOC)) AS number_of_nations
FROM athletes
GROUP BY games
ORDER BY games;

##################################################################################################################

### 4. Which year saw the highest and lowest no of countries participating in olympics? ###
SELECT
	games,
    MAX(nn.number_of_nations) as nations
FROM
	(
		SELECT
			games,
			COUNT(DISTINCT(NOC)) as number_of_nations
		FROM athletes
        GROUP BY games
	) AS nn
GROUP BY games
ORDER BY nations DESC
LIMIT 1;
-- Highest number of countries participated in the 2016 Summer olympics games which hosted 207 different NOC.

SELECT
	games,
    MIN(nn.number_of_nations) as nations
FROM
	(
		SELECT
			games,
			COUNT(DISTINCT(NOC)) as number_of_nations
		FROM athletes
        GROUP BY games
	) AS nn
GROUP BY games
ORDER BY nations ASC
LIMIT 1;
-- Lowest number of countries participated in the 1896 Summer olympics games with just 12 NOC.

WITH all_countries AS(
	SELECT
		ath.games,
        nr.region
	FROM athletes ath
    JOIN noc_regions nr
    ON ath.NOC = nr.NOC
    GROUP BY ath.games, nr.region
    ORDER BY ath.games, nr.region
),
tot_countries AS(
	SELECT
		games,
        count(1) as total_countries
	FROM all_countries
    GROUP BY games
)
SELECT DISTINCT
CONCAT(FIRST_VALUE(games) OVER(ORDER BY total_countries), '-', FIRST_VALUE(total_countries) OVER(ORDER BY total_countries)) AS Lowest_Number_of_Countries,
CONCAT(FIRST_VALUE(games) OVER(ORDER BY total_countries DESC), '-', FIRST_VALUE(total_countries) OVER(ORDER BY total_countries DESC)) AS Highest_Number_of_Countries
FROM tot_countries;

##################################################################################################################

### 5. Which nation has participated in all of the olympic games? ###
-- number of olympic games
-- nation which participated in each games
WITH tot_games AS (
	SELECT 
		COUNT(DISTINCT games) AS total_games
	FROM athletes
),
countries AS (
	SELECT
		ath.games AS game,
		nr.region AS country
	FROM athletes ath
    JOIN noc_regions nr
    ON ath.NOC = nr.NOC
	GROUP BY ath.games, nr.region
),
countries_participated AS (
	SELECT
		country,
        COUNT(*) AS total_participated_games
	FROM countries
	GROUP BY country
    ORDER BY total_participated_games DESC
)
SELECT 
	cp.country,
    cp.total_participated_games
FROM countries_participated cp
JOIN tot_games tg
ON cp.total_participated_games = tg.total_games;

##################################################################################################################

### 6. Identify the sport which was played in all summer olympics. ###
-- total no. of summer olympics
-- games played in each summer olympics
-- equate both above numbers
WITH summer_games AS(
	SELECT 
		COUNT(DISTINCT games) AS number_of_summer_games
	FROM athletes
	WHERE games like '%Summer'
),
times_played AS (
	SELECT
		sport,
		COUNT(DISTINCT games) AS number_of_times_featured_in_olympics
	FROM athletes
	WHERE games like '%Summer'
	GROUP BY sport
	ORDER BY sport
)
SELECT *
FROM times_played tp
JOIN summer_games sg
ON sg.number_of_summer_games = tp.number_of_times_featured_in_olympics
WHERE sg.number_of_summer_games = tp.number_of_times_featured_in_olympics;
	
##################################################################################################################

### 7. Which Sports were just played only once in the olympics? ###
SELECT *
FROM (
	SELECT
		sport,
		COUNT(DISTINCT games) AS number_of_games,
        games
	FROM athletes
	GROUP BY sport
	ORDER BY sport
) AS times_played
WHERE number_of_games = 1;

##################################################################################################################

### 8. Fetch the total no of sports played in each olympic games. ###
SELECT
	games,
    COUNT(DISTINCT sport) AS number_of_sports_played
FROM athletes
GROUP BY games
ORDER BY games;

##################################################################################################################

### 9. Fetch details of the oldest athletes to win a gold medal. ###
SELECT *
FROM (
	SELECT *
	FROM athletes
	WHERE NOT age = 'NA' AND medal like '%Gold%'
) AS age_data
WHERE age = (
			SELECT 
				MAX(age) 
			FROM athletes 
            WHERE NOT age = 'NA' AND medal like '%Gold%'
)
ORDER BY age DESC;

WITH t1 AS(
	SELECT *
	FROM athletes
	WHERE NOT age = 'NA' AND medal like '%Gold%'
),
t2 AS (
	SELECT
		*,
		DENSE_RANK() OVER (ORDER BY age DESC) AS rnk
	FROM t1
)
SELECT *
FROM t2
WHERE rnk <= 1;

##################################################################################################################

### 10. Find the Ratio of male and female athletes participated in all olympic games. ###
WITH ratio_cal AS (
	SELECT 
		sex,
		COUNT(*) AS number_of_participants
	FROM athletes
	GROUP BY sex
),
minimised AS (
	SELECT *,
        number_of_participants/74522 AS ratio
	FROM ratio_cal
	ORDER BY number_of_participants
)
SELECT
CONCAT(FIRST_VALUE(sex) OVER(ORDER BY sex DESC),':',FIRST_VALUE(sex) OVER(ORDER BY sex)) AS gender,
CONCAT(FIRST_VALUE(ratio) OVER(ORDER BY sex DESC),':',FIRST_VALUE(ratio) OVER(ORDER BY sex)) AS ratio
FROM minimised
limit 1;

### 11. Fetch the top 5 athletes who have won the most gold medals. ###
WITH calculated AS(
	SELECT
		*,
		COUNT(medal) AS total_gold_medals,
		DENSE_RANK() OVER (ORDER BY COUNT(medal) DESC) AS ranking
	FROM athletes
	WHERE medal LIKE "%Gold%"
	GROUP BY name
	ORDER BY total_gold_medals DESC
)
SELECT
	name,
    team,
    NOC,
    total_gold_medals
FROM calculated
WHERE ranking <= 5;


### 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze). ###
WITH calculated AS(
	SELECT 
		*,
		COUNT(medal) AS total_medals,
		DENSE_RANK() OVER (ORDER BY COUNT(medal) DESC) AS ranking
	FROM athletes
	WHERE medal NOT LIKE "%NA%"
	GROUP BY name
)
SELECT
	name,
    team,
    NOC,
    total_medals
FROM calculated
WHERE ranking <= 5;

### 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won. ###
WITH calculated AS (
	SELECT
		*,
        COUNT(medal) AS total_medals,
        DENSE_RANK() OVER (ORDER BY COUNT(medal) DESC) AS ranking
	FROM athletes
    WHERE medal NOT LIKE "%NA%"
    GROUP BY NOC
)
SELECT
    c.NOC,
    nc.region,
    c.total_medals
FROM calculated c
JOIN noc_regions nc
ON c.NOC = nc.noc
WHERE ranking <= 5
ORDER BY ranking;

### 14. List down total gold, silver and broze medals won by each country. ###
WITH g_m AS (
	SELECT
		NOC,
        COUNT(medal) AS gold_medal
	FROM athletes
    WHERE medal like "%Gold%"
    GROUP BY NOC
),
s_m AS (
	SELECT
		NOC,
        COUNT(medal) AS silver_medal
	FROM athletes
    WHERE medal like "%Silver%"
    GROUP BY NOC
),
b_m AS (
	SELECT
		NOC,
        COUNT(medal) AS bronze_medal
	FROM athletes
    WHERE medal like "%Bronze%"
    GROUP BY NOC
)
SELECT
	nc.region AS country,
    gold_medal,
    silver_medal,
    bronze_medal
FROM b_m
JOIN s_m ON b_m.NOC = s_m.NOC
JOIN g_m ON s_m.NOC = g_m.NOC
JOIN noc_regions nc ON g_m.NOC = nc.noc
ORDER BY gold_medal DESC, silver_medal DESC, bronze_medal DESC;


SELECT 
	country,
    COALESCE(SUM(gold),0) AS gold_medal,
    COALESCE(SUM(silver),0) AS silver_medal,
    COALESCE(SUM(bronze),0) AS bronze_medal
FROM(
	SELECT
		country,
		CASE WHEN medals = "Gold" THEN total_medals END AS gold,
		CASE WHEN medals = "Silver" THEN total_medals END AS silver,
		CASE WHEN medals = "Bronze" THEN total_medals END AS bronze
	FROM(
		SELECT 
			country,
			medals,
			COUNT(*) AS total_medals
		FROM(
			SELECT
				nc.region AS country,
				CASE
					WHEN medal like "%Gold%" THEN "Gold"
					WHEN medal like "%Silver%" THEN "Silver"
					WHEN medal like "%Bronze%" THEN "Bronze"
					ELSE NULL
				END AS medals
			FROM athletes
			JOIN noc_regions nc
			ON nc.noc = athletes.NOC
			HAVING medals <> "NULL"
		) AS table1
		GROUP BY country, medals
	) AS table2
) AS table3
GROUP BY country
ORDER BY 2 DESC,3 DESC,4 DESC;


SELECT 
	country,
    COALESCE(SUM(gold),0) AS gold_medal,
    COALESCE(SUM(silver),0) AS silver_medal,
    COALESCE(SUM(bronze),0) AS bronze_medal
FROM(
	SELECT
		country,
		CASE WHEN medals = "Gold" THEN total_medals END AS gold,
		CASE WHEN medals = "Silver" THEN total_medals END AS silver,
		CASE WHEN medals = "Bronze" THEN total_medals END AS bronze
	FROM(
		SELECT 
			country,
			medals,
			COUNT(*) AS total_medals
		FROM(
			SELECT
				concat(games, " - ",nc.region) AS country,
				CASE
					WHEN medal like "%Gold%" THEN "Gold"
					WHEN medal like "%Silver%" THEN "Silver"
					WHEN medal like "%Bronze%" THEN "Bronze"
					ELSE NULL
				END AS medals
			FROM athletes
			JOIN noc_regions nc
			ON nc.noc = athletes.NOC
			HAVING medals <> "NULL"
		) AS table1
		GROUP BY country, medals
	) AS table2
) AS table3
GROUP BY country
ORDER BY country;


### 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games. ###
SELECT
	games,
    country,
    COALESCE(SUM(gold),0) AS gold_medal,
    COALESCE(SUM(silver),0) AS silver_medal,
    COALESCE(SUM(bronze),0) AS bronze_medal
FROM(	
    SELECT
		games,
		country,
		CASE WHEN medals = "Gold" THEN total_medals END AS gold,
		CASE WHEN medals = "Silver" THEN total_medals END AS silver,
		CASE WHEN medals = "Bronze" THEN total_medals END AS bronze
	FROM(
		SELECT
			games,
			country,
			medals,
			COUNT(*) AS total_medals
		FROM(
			SELECT
				nc.region AS country,
				games,
				CASE
					WHEN medal like "%Gold%" THEN "Gold"
					WHEN medal like "%Silver%" THEN "Silver"
					WHEN medal like "%Bronze%" THEN "Bronze"
					ELSE NULL
				END AS medals
			FROM athletes
			JOIN noc_regions nc
			ON nc.noc = athletes.NOC
			HAVING medals <> "NULL"
		) AS table1
		GROUP BY games, country, medals
        ORDER BY games, country
	) AS table2
    ORDER BY games, country
) AS table3
GROUP BY games, country
ORDER BY games, gold_medal DESC, silver_medal DESC, bronze_medal DESC;

### 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games. ###
WITH temp AS(
	SELECT
		games,
		country,
		COALESCE(SUM(gold),0) AS gold_medal,
		COALESCE(SUM(silver),0) AS silver_medal,
		COALESCE(SUM(bronze),0) AS bronze_medal
	FROM(	
		SELECT
			games,
			country,
			CASE WHEN medals = "Gold" THEN total_medals END AS gold,
			CASE WHEN medals = "Silver" THEN total_medals END AS silver,
			CASE WHEN medals = "Bronze" THEN total_medals END AS bronze
		FROM(
			SELECT
				games,
				country,
				medals,
				COUNT(*) AS total_medals
			FROM(
				SELECT
					nc.region AS country,
					games,
					CASE
						WHEN medal like "%Gold%" THEN "Gold"
						WHEN medal like "%Silver%" THEN "Silver"
						WHEN medal like "%Bronze%" THEN "Bronze"
						ELSE NULL
					END AS medals
				FROM athletes
				JOIN noc_regions nc
				ON nc.noc = athletes.NOC
				HAVING medals <> "NULL"
			) AS table1
			GROUP BY games, country, medals
			ORDER BY games, country
		) AS table2
		ORDER BY games, country
	) AS table3
	GROUP BY games, country
	ORDER BY games, country
)
SELECT
	DISTINCT games,
	CONCAT(FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY gold_medal DESC), " - ", FIRST_VALUE(gold_medal) OVER (PARTITION BY games ORDER BY gold_medal DESC)) AS max_gold,
    CONCAT(FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY silver_medal DESC), " - ", FIRST_VALUE(silver_medal) OVER (PARTITION BY games ORDER BY silver_medal DESC)) AS max_silver,
	CONCAT(FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY bronze_medal DESC), " - ", FIRST_VALUE(bronze_medal) OVER (PARTITION BY games ORDER BY bronze_medal DESC)) AS max_bronze
FROM temp;


### 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games. ###
WITH temp AS(
	SELECT
		*,
        gold_medal+silver_medal+bronze_medal AS total_medals
	FROM(
		SELECT
			games,
			country,
			COALESCE(SUM(gold),0) AS gold_medal,
			COALESCE(SUM(silver),0) AS silver_medal,
			COALESCE(SUM(bronze),0) AS bronze_medal
		FROM(	
			SELECT
				games,
				country,
				CASE WHEN medals = "Gold" THEN total_medals END AS gold,
				CASE WHEN medals = "Silver" THEN total_medals END AS silver,
				CASE WHEN medals = "Bronze" THEN total_medals END AS bronze
			FROM(
				SELECT
					games,
					country,
					medals,
					COUNT(*) AS total_medals
				FROM(
					SELECT
						nc.region AS country,
						games,
						CASE
							WHEN medal like "%Gold%" THEN "Gold"
							WHEN medal like "%Silver%" THEN "Silver"
							WHEN medal like "%Bronze%" THEN "Bronze"
							ELSE NULL
						END AS medals
					FROM athletes
					JOIN noc_regions nc
					ON nc.noc = athletes.NOC
					HAVING medals <> "NULL"
				) AS table1
				GROUP BY games, country, medals
				ORDER BY games, country
			) AS table2
			ORDER BY games, country
		) AS table3
		GROUP BY games, country
		ORDER BY games, country
	) AS table4
)
SELECT
	DISTINCT games,
	CONCAT(FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY gold_medal DESC), " - ", FIRST_VALUE(gold_medal) OVER (PARTITION BY games ORDER BY gold_medal DESC)) AS max_gold,
    CONCAT(FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY silver_medal DESC), " - ", FIRST_VALUE(silver_medal) OVER (PARTITION BY games ORDER BY silver_medal DESC)) AS max_silver,
	CONCAT(FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY bronze_medal DESC), " - ", FIRST_VALUE(bronze_medal) OVER (PARTITION BY games ORDER BY bronze_medal DESC)) AS max_bronze,
    CONCAT(FIRST_VALUE(country) OVER (PARTITION BY games ORDER BY total_medals DESC), " - ", FIRST_VALUE(total_medals) OVER (PARTITION BY games ORDER BY total_medals DESC)) AS max_medals
FROM temp;

### 18. Which countries have never won gold medal but have won silver/bronze medals? ###
SELECT
	country,
	COALESCE(SUM(gold),0) AS gold_medal,
	COALESCE(SUM(silver),0) AS silver_medal,
	COALESCE(SUM(bronze),0) AS bronze_medal
FROM(	
	SELECT
		country,
		CASE WHEN medals = "Gold" THEN total_medals END AS gold,
		CASE WHEN medals = "Silver" THEN total_medals END AS silver,
		CASE WHEN medals = "Bronze" THEN total_medals END AS bronze
	FROM(
		SELECT
			country,
			medals,
			COUNT(*) AS total_medals
		FROM(
			SELECT
				nc.region AS country,
				games,
				CASE
					WHEN medal like "%Gold%" THEN "Gold"
					WHEN medal like "%Silver%" THEN "Silver"
					WHEN medal like "%Bronze%" THEN "Bronze"
					ELSE NULL
				END AS medals
			FROM athletes
			JOIN noc_regions nc
			ON nc.noc = athletes.NOC
			HAVING medals <> "NULL"
		) AS table1
		GROUP BY country, medals
		ORDER BY country
	) AS table2
	ORDER BY country
) AS table3
GROUP BY country
HAVING gold_medal = 0
ORDER BY 3 DESC, 4 DESC;

### 19. In which Sport/event, India has won highest medals. ###
WITH calculated AS(
	SELECT
		sport,
        event,
		COUNT(medal) AS total_medals,
		DENSE_RANK() OVER (ORDER BY COUNT(medal) DESC) AS ranking
	FROM athletes
	WHERE medal NOT LIKE "%NA%" AND NOC = "IND"
	GROUP BY event
)
SELECT
	sport,
	event,
	total_medals
FROM calculated
WHERE ranking = 1;

### 20. Break down all olympic games where india won medal for Hockey and how many medals in each olympic games. ###
SELECT
	games,
    COUNT(medal) As total_medals
FROM athletes
WHERE medal NOT LIKE "%NA%" AND NOC = "IND" AND sport  = "Hockey"
GROUP BY games
ORDER BY total_medals DESC
