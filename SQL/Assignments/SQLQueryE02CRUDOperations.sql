-- Excercises - Database Operations



-- Setup Database to use for Assignments
CREATE DATABASE assignments;
USE assignments;



-- Excercise 1 - Create Table
CREATE TABLE courses (
	course_id INT IDENTITY,
	course_name VARCHAR(60),
	course_author VARCHAR(40),
	course_status VARCHAR(10),
	course_published_dt DATE
);
ALTER TABLE courses
ADD CONSTRAINT pk_courses_course_id PRIMARY KEY CLUSTERED (course_id);



-- Exercise 2 - Inserting Data
INSERT INTO courses
    (course_name, course_author, course_status, course_published_dt)
VALUES
    ('Programming using Python', 'Bob Dillon', 'published', '2020-09-30'),
	('Data Engineering using Python', 'Bob Dillon', 'published', '2020-07-15'),
	('Data Engineering using Scala', 'Elvis Presley', 'draft', NULL),
	('Programming using Scala', 'Elvis Presley', 'published', '2020-05-12'),
	('Programming using Java', 'Mike Jack', 'inactive', '2020-08-10'),
	('Web Applications - Python Flask', 'Bob Dillon', 'inactive', '2020-07-20'),
	('Web Applications - Java Spring', 'Mike Jack', 'draft', NULL),
	('Pipeline Orchestration - Python', 'Bob Dillon', 'draft', NULL),
	('Streaming Pipelines - Python', 'Bob Dillon', 'published', '2020-10-05'),
	('Web Applications - Scala Play', 'Elvis Presley', 'inactive', '2020-09-30'),
	('Web Applications - Python Django', 'Bob Dillon', 'published', '2020-06-23'),
	('Server Automation - Ansible', 'Uncle Sam', 'published', '2020-07-05');

SELECT * FROM courses;
DROP TABLE courses;



-- Exercise 3 - Updating Data
UPDATE courses
SET course_status = 'published', course_published_dt = getdate()
WHERE course_status = 'draft' AND (course_name LIKE '%Python%' OR course_name LIKE '%Scala%');



-- Exercise 4 - Deleting Data
DELETE FROM courses
WHERE NOT course_status = 'published';



--Validation
SELECT course_author, count(1) AS course_count
FROM courses
WHERE course_status = 'published'
GROUP BY course_author


