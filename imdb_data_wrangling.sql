CREATE DATABASE imdb;
USE imdb;

SELECT * FROM actor_name_clean;

-- 1. CREATE A TABLE THAT MAPS EACH INDIVIDUAL WITH THE MOVIES THEY ARE KNOWN FOR:
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

SELECT * FROM nconst_known_for;

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

SELECT * FROM nconst_ratings;

-- 4. SCORE OF EACH TITLE BASED ON THE RATING OF THE MAIN CREW (NCONST_RATING)
CREATE TABLE tconst_ratings_by_crew
AS (
SELECT tpc.tconst, avg(nconst_rating)
FROM title_principle_crew tpc
LEFT JOIN nconst_ratings nr
ON tpc.nconst = nr.nconst
GROUP BY tconst);

SELECT * FROM tconst_ratings_by_crew;

-- 5. DATA CLEANING
ALTER TABLE nconst_nominees_list_446 DROP COLUMN MyUnknownColumn;
ALTER TABLE actor_name_clean DROP COLUMN MyUnknownColumn;
ALTER TABLE title_principle_crew DROP COLUMN `Unnamed: 0`;
ALTER TABLE tconst_ratings_by_crew RENAME COLUMN `avg(nconst_rating)` TO rating_of_crew;
ALTER TABLE nconst_ratings RENAME COLUMN nconst_rating TO rating_of_bestwork; 
-- weighted average for their 4 best works, weighted with votes count

SET SQL_SAFE_UPDATES = 0;
UPDATE nconst_nominees_list_446 SET Nominees = 1; -- 446 names that had been nominated
UPDATE oscars_nominees_imdb_list SET Nominees = 1; -- 3470 titles that had been nominated
UPDATE oscars_winner_imdb_list SET Winner = 1; -- 709 titles that had won

-- 6. CREATE TABLE THAT COUNTS THE CREW WHO ARE NOMINATED IN A TITLE 
-- (i.e. IF A TITLE HAS A STAR-STUDDED CAST)
CREATE TABLE tconst_with_nom_crew
AS 
(SELECT x.tconst, sum(x.nom_crew) as ct_nom_crew  -- count of nominated crew in a title
FROM
	(SELECT tconst, nl.Nominees as nom_crew
	FROM  title_principle_crew tpc
	LEFT JOIN nconst_nominees_list_446 nl
	ON tpc.nconst = nl.nconst) x
GROUP BY x.tconst);

UPDATE tconst_with_nom_crew
SET ct_nom_crew = 0
WHERE ct_nom_crew IS NULL;

SELECT * FROM tconst_with_nom_crew;

-- 7. CREATE FINAL DATABASE:
CREATE TABLE imdb_megadata_2
AS
	(SELECT  a.*,
					tr.averageRating as ave_rating,
					tr.numVotes as num_votes,
					cc.ct_nom_crew as count_nom_crew,
					tc.rating_of_crew as crew_star_meter,
					ond.Nominees as nominated,
					ow.Winner as won
	FROM all_titles_2 a
	LEFT JOIN title_ratings tr ON a.tconst = tr.tconst
	LEFT JOIN tconst_with_nom_crew cc ON a.tconst = cc.tconst
	LEFT JOIN tconst_ratings_by_crew tc ON a.tconst = tc.tconst
	LEFT JOIN oscars_winner_imdb_list ow ON a.tconst = ow.tconst
	LEFT JOIN oscars_nominees_imdb_list ond ON a.tconst = ond.tconst);
    
    SELECT * FROM imdb_megadata_2
    WHERE tconst = "tt6710474";
    
    SELECT * FROM all_titles;
    
-- 8. CHECK DIRECTOR
SELECT tconst, nconst, category
FROM title_principle_crew
WHERE category = 'director'
ORDER BY tconst ASC;

-- 9. SLICE DATA
CREATE TABLE title_by_year
AS
(SELECT tconst, startYear, ave_rating 
FROM imdb_megadata_2
WHERE startYear > 1980
AND ave_rating > 6
AND num_votes > 1000);

-- 10. COMBINE TITLES WITH HIGH RATINGS (1980s - 2020s)
CREATE TABLE imega3
AS
(SELECT imeg.*, 
 all_males_ratings,
 all_males_v_counts,
 all_females_ratings,
 all_females_v_counts,
 under_18_all_ratings,
 under_18_all_v_counts,
 under_18_males_ratings,
 under_18_males_v_counts,
 under_18_females_ratings,
 under_18_females_v_counts,
 f18_29_all_ratings,
 f18_29_all_v_counts,
 f18_29_males_ratings,
 f18_29_males_v_counts,
 f18_29_females_ratings,
 f18_29_females_v_counts,
 f30_44_all_ratings,
 f30_44_all_v_counts,
 f30_44_males_ratings,
 f30_44_males_v_counts,
 f30_44_females_ratings,
 f30_44_females_v_counts,
 f45_all_ratings,
 f45_all_v_counts,
 f45_males_ratings,
 f45_males_v_counts,
 f45_females_ratings,
 f45_females_v_counts
FROM title_80s_20s t82
LEFT JOIN imdb_megadata_2 imeg
ON t82.tconst = imeg.tconst);

SELECT * FROM imega3;

SELECT ISNULL (nominated , 0)
FROM imega3;

SELECT COUNT(*) FROM imdb_megadata_2
WHERE isAdult != 0; 


    










    

    


    



