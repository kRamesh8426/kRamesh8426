
-- Create the "PCPs" table
CREATE TABLE pcps (
	npi INT PRIMARY KEY,
	pcp_first_name VARCHAR(45) NOT NULL,
    pcp_last_name VARCHAR(45) NOT NULL,
    pcp_initial VARCHAR(45)
);

select * from pcps;

------------------------------------------------------
-- Create the "payers" table
CREATE TABLE payers (
	payer_id INT PRIMARY KEY,
	payer VARCHAR(45) NOT NULL  
);

select * from payers;

------------------------------------------------------

-- Create the "member_months" table
CREATE TABLE member_months (
	muid INT,
	first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    dob DATE NOT NULL,
    gender VARCHAR(50) NOT NULL,
    subscriber_id VARCHAR(50) NOT NULL,
    medicare_id VARCHAR(50) NOT NULL,
    payer_name  VARCHAR(50) NOT NULL,
    npi int NOT NULL,
    eligible_month DATE,
	-- PRIMARY KEY (muid, eligible_month),
	-- FOREIGN KEY (muid) REFERENCES members_unique (muid),
	FOREIGN KEY (npi) REFERENCES pcps (npi));

select * from member_months ;

COPY members_unique  FROM 'C:\Users\LENOVO\Desktop\Tables\Member_months.csv' DELIMITER ',' HEADER ;

------------------------------------------------------

-- Create the "members_unique" table
CREATE TABLE members_unique (
	muid int PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    dob DATE NOT NULL,
    gender VARCHAR(50) NOT NULL,
    age VARCHAR(50),
    subscriber_id VARCHAR(50) NOT NULL,
    medicare_id VARCHAR(50) NOT NULL,
    payer_id  INT,
    npi int NOT NULL,
    is_active varchar(10) ,
    latest_eligible_month date,
    FOREIGN KEY (payer_id) REFERENCES payers (payer_id),
	FOREIGN KEY (npi) REFERENCES pcps (npi)
);

select * from members_unique ;

---------------------------------------------------------------------------

-- insert "members_unique" table from MEMBERS_UNIQUE


INSERT INTO MEMBERS_UNIQUE (MUID,
							FIRST_NAME,
							LAST_NAME,
							DOB,
							GENDER,
							SUBSCRIBER_ID,
							MEDICARE_ID,
							NPI)
		SELECT MUID,
				FIRST_NAME,
				LAST_NAME,
				DOB,
				GENDER,
				SUBSCRIBER_ID,
				MEDICARE_ID,
				npi
		FROM MEMBER_MONTHS 
		ON CONFLICT (muid) DO NOTHING;


SELECT MUID,
	COUNT(MUID) CNT,
	MAX(ELIGIBLE_MONTH) AS ELIGIBLE_MONTH,
	ARRAY_AGG(ELIGIBLE_MONTH ORDER BY ELIGIBLE_MONTH DESC) ELIGIBLE_MONTHS
FROM MEMBER_MONTHS
GROUP BY MUID
ORDER BY CNT ASC;

---------------------------------------------------------------------------

-- update query "age"

UPDATE members_unique
SET age = concat(date_part('year', age(current_date, dob)), ' years');

---------------------------------------------------------------------------

-- update query "latest_eligible_month"
UPDATE members_unique
SET latest_eligible_month = subquery.latest_month
FROM (
  SELECT muid, max(ELIGIBLE_MONTH) as latest_month
  FROM MEMBER_MONTHS group by muid
) AS subquery
WHERE members_unique.muid = subquery.muid;


----------------------------------------------------------------------------

-- update query "payer_id"

UPDATE members_unique
SET payer_id = payers.payer_id 
FROM payers
JOIN member_months ON payers.payer = member_months.payer_name
WHERE members_unique.muid = member_months.muid
AND LATEST_ELIGIBLE_MONTH =
		(SELECT MAX(ELIGIBLE_MONTH)
			FROM MEMBER_MONTHS);

---------------------------------------------------------------------------
CREATE TYPE ACTIVE_STATUS AS ENUM ('Y', 'N') DEFAULT 'N';

ALTER table members_unique 
ALTER COLUMN is_active TYPE ACTIVE_STATUS using is_active::ACTIVE_STATUS ;

-- update query "is_active"

UPDATE MEMBERS_UNIQUE
SET IS_ACTIVE = 'Y'
WHERE LATEST_ELIGIBLE_MONTH =
		(SELECT MAX(ELIGIBLE_MONTH)
			FROM MEMBER_MONTHS);


----------------------------------------------------------------------------

-- update query "npi"

UPDATE members_unique
SET npi = subquery.npi
FROM (
  SELECT muid,npi,max(ELIGIBLE_MONTH)
  FROM MEMBER_MONTHS group by muid,npi
) AS subquery
WHERE members_unique.muid = subquery.muid
and members_unique.muid =1;

----------------------------------------------------------------------------

SELECT pid, query
FROM pg_stat_activity
WHERE state = 'active';


SELECT pg_cancel_backend(4100);
SELECT pg_terminate_backend(4100);
Truncate members_unique;



SELECT 
   table_name, 
   column_name, 
   data_type 
FROM 
   information_schema.columns
WHERE 
   table_name = 'members_unique';

























