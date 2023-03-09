CREATE DATABASE imdb;
USE imdb;

SELECT * FROM actor_name_clean;

-- 1. CREATE A TABLE THAT MAPs EACH INDIVIDUAL WITH THE MOVIES THEY ARE KNOWN FOR:
CREATE TABLE nconst_known_for
AS (
SELECT
  nconst, SUBSTRING_INDEX(SUBSTRING_INDEX(knownForTitles, ',' , 1), ', ', -1) knownForTitle FROM actor_name_clean
UNION ALL
SELECT
  nconst, SUBSTRING_INDEX(SUBSTRING_INDEX(knownForTitles, ',' , 2), ',', -1) knownForTitle FROM actor_name_clean

UNION ALL
SELECT
  nconst, SUBSTRING_INDEX(SUBSTRING_INDEX(knownForTitles, ',' , 3), ',', -1) knownForTitle FROM actor_name_clean

UNION ALL
SELECT
  nconst, SUBSTRING_INDEX(SUBSTRING_INDEX(knownForTitles, ',' , 4), ',', -1) knownForTitle FROM actor_name_clean
);

SELECT * FROM nconst_known_for WHERE nconst = 'nm0000002';
-- NOTE: Substring index = get everything after the first instance (2), and keep last one (-1)

-- 2. CREATE A TABLE THAT MAPS THE MOVIES AND THE CORRESPONDING RATINGS:
CREATE TABLE nconst_knownfor_rating
AS 
(SELECT nconst, knownForTitle, averageRating, numVotes
FROM nconst_known_for nkf
LEFT JOIN title_ratings tr
ON nkf.knownForTitle = tr.tconst);

-- 3. AVERAGE RATING FOR THE MOVIES A PERSON HAS DONE, WEIGHTED WITH NUMBER OF VOTE COUNTS
CREATE TABLE nconst_ratings
AS 
	(SELECT 
		nconst,
		(sum(averageRating * numVotes)/ sum(numVotes)) as nconst_rating
	FROM(
		SELECT *, ROW_NUMBER() OVER (PARTITION BY nconst ORDER BY averageRating DESC) rn
		FROM nconst_knownfor_rating) x
	GROUP BY nconst);
-- nconst_rating = average rating of the top 4 titles they are known for, weighted by number of votes

-- 4. SCORE OF EACH TITLE BASED ON THE RATING OF THE MAIN CREW (NCONST_RATING)
CREATE TABLE tconst_ratings_by_crew
AS (
SELECT tpc.tconst, avg(nconst_rating)
FROM title_principle_crew tpc
LEFT JOIN nconst_ratings nr
ON tpc.nconst = nr.nconst
GROUP BY tconst);

SELECT * FROM tconst_ratings_by_crew;

-- 5. 




	




    

    


    



