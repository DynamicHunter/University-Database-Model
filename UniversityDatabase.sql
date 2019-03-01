-- Hunter Davis
-- Yuanshun Dong
-- Yosselin Velasco
-- HW 2 Group 4

-- DROP: child then parent


DROP TABLE enrollments;
DROP TABLE university_classes;
DROP TABLE requirements;
DROP TABLE courses;
DROP TABLE program_offerings;
DROP TABLE academic_departments;

DROP TABLE student_programs; -- child
DROP TABLE academic_programs; -- parent
DROP TABLE students; -- parent

-- Drop Lookup Tables

DROP TABLE requirement_types;
DROP TABLE formats;
DROP TABLE semesters;
DROP TABLE grades;
DROP TABLE grade_options;
DROP TABLE statuses;
DROP TABLE degrees;
DROP TABLE levels;

-- Create Lookup Tables First
-- 8 Lookup Tables total, level is referenced twice (insert parenthesis attributes)

-- 1: Levels (Undergraduate, Graduate)
CREATE TABLE levels
(
  level VARCHAR(13),
  CONSTRAINT levels_pk PRIMARY KEY (level)
);
-- 2: Degrees (BS, BA, MS, MBA, PhD)
CREATE TABLE degrees
(
  degree VARCHAR(3),
  CONSTRAINT degrees_pk PRIMARY KEY (degree)
);
-- 3: Statuses (In Progress, Withdrawn, Completed)
CREATE TABLE statuses
(
  status VARCHAR(11),
  CONSTRAINT statuses_pk PRIMARY KEY (status)
);
-- 4: GradeOptions (C/NC, Graded, Audit)
CREATE TABLE grade_options
(
  grade_option VARCHAR(6),
  CONSTRAINT grade_options_pk PRIMARY KEY (grade_option)
);
-- 5: Grades (dependent on gradeOption, grade is W if withdrawn regardless of gradeOption)
CREATE TABLE grades
(
  grade VARCHAR(2),
  CONSTRAINT grades_pk PRIMARY KEY (grade)
);

-- 6: Semesters (Fall, Spring, Winter, Summer)
CREATE TABLE semesters
(
  semester VARCHAR(6),
  CONSTRAINT semesters_pk PRIMARY KEY (semester)
);
-- 7: Formats (Lab, Lecture, Seminar, Activity)
CREATE TABLE formats
(
  format VARCHAR(8),
  CONSTRAINT formats_pk PRIMARY KEY (format)
);
-- 8: requirementTypes (Prerequisite, Corequisite)
CREATE TABLE requirement_types
(
  requirement_type VARCHAR(12),
  CONSTRAINT requirement_types_pk PRIMARY KEY (requirement_type)
);

-- create: parent then child

CREATE TABLE students -- parent
(
  university_id VARCHAR(10) NOT NULL,
  first_name    VARCHAR(20) NOT NULL,
  last_name     VARCHAR(20) NOT NULL,
  date_of_birth DATE,
  CONSTRAINT students_pk PRIMARY KEY (university_id),
  CONSTRAINT students_ck UNIQUE (first_name, last_name)
  --units_completed INT,
  --gpa             FLOAT
  -- units_completed and gpa calculated from the completed classes
  -- We took these out of the database because a higher level program would calculate these values
);

CREATE TABLE academic_programs -- parent
(
  code                INT         NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1),
  subject             VARCHAR(30) NOT NULL,
  level               VARCHAR(13) NOT NULL,
  academic_year       VARCHAR(10),
  degree              VARCHAR(3),
  minimum_total_units INT,
  CONSTRAINT academic_programs_pk PRIMARY KEY (code),
  CONSTRAINT academic_programs_ck UNIQUE (degree, subject),
  CONSTRAINT academic_programs_degrees_fk FOREIGN KEY (degree) REFERENCES degrees (degree),
  CONSTRAINT academic_programs_courses_fk FOREIGN KEY (level) REFERENCES levels (level)
);


CREATE TABLE student_programs -- child
(
  university_id VARCHAR(10) NOT NULL,
  code          INT         NOT NULL,
  selected_on   DATE,
  status        VARCHAR(11), -- 'In Progress', 'Withdrawn', 'Completed'
  status_date   DATE,
  CONSTRAINT student_programs_pk PRIMARY KEY (university_id, code),
  CONSTRAINT student_programs_statuses_fk FOREIGN KEY (status) REFERENCES statuses (status),
  CONSTRAINT student_programs_students_fk FOREIGN KEY (university_id) REFERENCES students (university_id),
  CONSTRAINT student_programs_academic_programs_fk FOREIGN KEY (code) REFERENCES academic_programs (code)
);


CREATE TABLE academic_departments
(
  name         VARCHAR(50) NOT NULL,
  abbreviation VARCHAR(4)  NOT NULL,
  phone        VARCHAR(12),
  location     VARCHAR(8),
  CONSTRAINT academic_departments_pk PRIMARY KEY (abbreviation),
  CONSTRAINT academic_departments_ck UNIQUE (name)
);

CREATE TABLE program_offerings
(
  code         INT,
  abbreviation VARCHAR(4),
  CONSTRAINT program_offerings_pk PRIMARY KEY (code, abbreviation),
  CONSTRAINT program_offerings_academic_programs_fk FOREIGN KEY (code) REFERENCES academic_programs (code),
  CONSTRAINT program_offerings_academic_departments_fk FOREIGN KEY (abbreviation) REFERENCES academic_departments (abbreviation)
);

-- acad dept parent to courses
CREATE TABLE courses
(
  course_number VARCHAR(4)  NOT NULL,
  title         VARCHAR(50) NOT NULL,
  description   LONG VARCHAR, -- should be text?
  level         VARCHAR(13),  -- undergrad or grad
  units         INT,
  abbreviation  VARCHAR(4),
  CONSTRAINT courses_pk PRIMARY KEY (course_number),
  CONSTRAINT courses_ck UNIQUE (title),
  CONSTRAINT courses_academic_departments_fk FOREIGN KEY (abbreviation) REFERENCES academic_departments (abbreviation),
  CONSTRAINT courses_levels_fk FOREIGN KEY (level) REFERENCES levels (level)
);

CREATE TABLE requirements
(
  -- course_number is the course being taken, course_number_required is the pre-requisite to the course_number
  -- requirement_type is not a PK because we will assume it is a pre-requisite if there is no requirement_type
  course_number          VARCHAR(4) NOT NULL,
  course_number_required VARCHAR(4) NOT NULL,
  requirement_type       VARCHAR(12),
  CONSTRAINT requirements_pk PRIMARY KEY (course_number, course_number_required),
  CONSTRAINT requirements_courses_fk1 FOREIGN KEY (course_number) REFERENCES courses (course_number),
  CONSTRAINT requirements_courses_fk2 FOREIGN KEY (course_number_required) REFERENCES courses (course_number),
  -- Lookup Table References
  CONSTRAINT requirements_requirement_types_fk FOREIGN KEY (requirement_type) REFERENCES requirement_types (requirement_type)
);

CREATE TABLE university_classes
(
  class_number  INT         NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1), -- surrogate key
  course_number VARCHAR(4)  NOT NULL,
  semester      VARCHAR(6)  NOT NULL,
  class_year    INT         NOT NULL,
  section       INT,
  format        VARCHAR(8),
  -- Lecture, seminar, lab, activity
  capacity      INT,
  --available_seats INT,
  -- derived from capacity and # students enrolled
  -- We removed derived attributes because we would implement that on the front end of the program
  class_open    BOOLEAN,
  meeting_days  VARCHAR(70) NOT NULL,
  start_time    TIME        NOT NULL,
  end_time      TIME,
  location      VARCHAR(8)  NOT NULL,
  CONSTRAINT university_classes_pk PRIMARY KEY (class_number),
  --CONSTRAINT university_classes_ck1 UNIQUE (course_number, section),
  CONSTRAINT university_classes_ck UNIQUE (course_number, section, semester, class_year, meeting_days, start_time, location),
  CONSTRAINT university_classes_courses_fk FOREIGN KEY (course_number) REFERENCES courses (course_number),
  -- Lookup Table references
  CONSTRAINT university_classes_formats_fk FOREIGN KEY (format) REFERENCES formats (format),
  CONSTRAINT university_classes_semesters_fk FOREIGN KEY (semester) REFERENCES semesters (semester)
);


-- association class b/w student and univ class
CREATE TABLE enrollments
(
  university_id  VARCHAR(10) NOT NULL,
  class_number   INT         NOT NULL,
  grade_option   VARCHAR(6),
  grade          VARCHAR(2),
  /*
  If gradeOption is C/NC, grade must be one of those
  If gradeOption is withdraw, grade must be W or WU
  Or if it's normal, grade must be A,B,C,D,F
  Keep them separate but keep in mind when entering sample data
  */
  date_added     DATE,
  date_withdrawn DATE,
  CONSTRAINT enrollments_pk PRIMARY KEY (university_id, class_number),
  CONSTRAINT enrollments_students_fk FOREIGN KEY (university_id) REFERENCES students (university_id),
  CONSTRAINT enrollments_university_classes_fk FOREIGN KEY (class_number) REFERENCES university_classes (class_number),
  -- Lookup Table references
  CONSTRAINT enrollments_grade_options_fk FOREIGN KEY (grade_option) REFERENCES grade_options (grade_option),
  CONSTRAINT enrollments_grades_fk FOREIGN KEY (grade) REFERENCES grades (grade)
);

-- course parent to univ class

-- Lookup Tables:

INSERT INTO levels
VALUES ('Undergraduate'),
       ('Graduate');

INSERT INTO degrees
VALUES ('BS'),
       ('BA'),
       ('MS'),
       ('MBA'),
       ('PhD');

INSERT INTO statuses
VALUES ('In Progress'),
       ('Withdrawn'),
       ('Completed');

INSERT INTO grade_options
VALUES ('C/NC'),
       ('Graded'),
       ('Audit');

INSERT INTO grades
VALUES ('CR'),
       ('NC'),
       ('A'),
       ('B'),
       ('C'),
       ('D'),
       ('F'),
       ('AU'),
       ('W');

INSERT INTO semesters
VALUES ('Winter'),
       ('Spring'),
       ('Summer'),
       ('Fall');

INSERT INTO formats
VALUES ('Lab'),
       ('Lecture'),
       ('Seminar'),
       ('Activity');

INSERT INTO requirement_types
VALUES ('Prerequisite'),
       ('Corequisite');

-- End of Lookup Tables
/*
INSERT INTO students
VALUES ('123456789', 'Hunter', 'Davis', '11/10/1998');

INSERT INTO student_programs
VALUES ('8/28/2016', '1', '2/24/2019');
*/

INSERT INTO academic_programs
VALUES (DEFAULT, 'Computer Science', 'Undergraduate', '2018', 'BA', 60),
       (DEFAULT, 'Biomedical Engineering', 'Undergraduate', '2017', 'BA', 62),
       (DEFAULT, 'Computer Science', 'Graduate', '2018', 'MS', 30);

INSERT INTO academic_departments
VALUES ('Computer Engineering & Science ', 'CECS', '5624735331', 'ECS'),
       ('Mechanical and Aerospace Engineering', 'MAE', '5629854398', 'ECS');

INSERT INTO courses
VALUES ('323', 'Database Fundamentals', 'Fundamental topics on database management. ', 'Undergraduate', 3, 'CECS'),
       ('326', 'Operating Systems', 'The structure and functions of operating systems.  ', 'Undergraduate', 3, 'CECS'),
       ('327', 'Introduction to Networks', 'Introduction to Distributed Computing and Interprocess Communication. ',
        'Undergraduate', 3, 'CECS'),
       ('328', 'Data Structures and Algorithms',
        'A broad view of data structures and the structure-preserving operations on them. ', 'Undergraduate', 3,
        'CECS'),
       ('341', 'Computer Architecture and Organization', 'Review of logic design. Instruction set architecture.',
        'Undergraduate', 3, 'CECS'),
       ('343', 'Introduction to Software Engineering',
        'Principles of software engineering, UML, modeling large software systems.', 'Undergraduate', 3, 'CECS'),
       ('519', 'Theory of Computation', 'Finite Automata and regular expressions.', 'Graduate', 3, 'CECS'),
       ('520', 'Database Architecture', 'Relational database design theory-a rigorous approach. ', 'Graduate', 3,
        'CECS'),
       ('101A', 'Introduction to Aerospace Engineering',
        'Role of various types of engineering specialties in the development of an actual aerospace vehicle product. ',
        'Undergraduate', 4, 'MAE'),
       ('101B', 'Introduction to Mechanical Engineering', 'Introduction to mechanical engineering as a profession. ',
        'Undergraduate', 4, 'MAE');

INSERT INTO university_classes
VALUES (DEFAULT, '323', 'Spring', 2018, 03, 'Lecture', 35, FALSE, 'Mon&Wed', '10:00', '11:00', 'ECS310'),
       (DEFAULT, '323', 'Spring', 2018, 04, 'Lab', 35, FALSE, 'Mon&Wed', '11:00', '12:00', 'ECS403'),
       (DEFAULT, '326', 'Fall', 2018, 06, 'Lecture', 30, FALSE, 'Friday', '13:00', '14:00', 'VEC420'),
       (DEFAULT, '323', 'Fall', 2018, 07, 'Lab', 30, FALSE, 'Friday', '14:00', '16:00', 'ECS405'),
       (DEFAULT, '341', 'Spring', 2019, 01, 'Seminar', 35, TRUE, 'Tu&Th', '8:00', '9:00', 'ECS307'),
       (DEFAULT, '341', 'Spring', 2019, 02, 'Lab', 35, TRUE, 'Tu&Th', '9:00', '10:00', 'ECS319'),
       (DEFAULT, '101A', 'Spring', 2018, 03, 'Lecture', 100, FALSE, 'Mon&Wed', '10:00', '11:00', 'VEC310'),
       (DEFAULT, '101A', 'Spring', 2018, 04, 'Activity', 35, FALSE, 'Mon&Wed', '10:00', '11:00', 'VEC101'),
       (DEFAULT, '101B', 'Spring', 2018, 05, 'Lecture', 100, FALSE, 'Mon&Wed', '11:00', '12:00', 'VEC310'),
       (DEFAULT, '101B', 'Spring', 2018, 06, 'Activity', 35, FALSE, 'Mon&Wed', '12:00', '13:00', 'VEC101'),
       (DEFAULT, '519', 'Summer', 2018, 07, 'Lecture', 35, FALSE, 'Tu&Th', '17:00', '18:00', 'ECS211'),
       (DEFAULT, '519', 'Summer', 2018, 08, 'Lecture', 35, FALSE, 'Tu&Th', '18:00', '20:00', 'ECS212'),
       (DEFAULT, '520', 'Spring', 2018, 01, 'Lecture', 35, TRUE, 'Mon&Wed', '8:00', '9:00', 'ECS310'),
       (DEFAULT, '520', 'Spring', 2018, 02, 'Lecture', 35, TRUE, 'Mon&Wed', '9:00', '10:00', 'ECS404'),
       (DEFAULT, '328', 'Spring', 2018, 03, 'Lecture', 35, FALSE, 'Tu&Th', '10:00', '11:00', 'ECS314'),
       (DEFAULT, '328', 'Spring', 2018, 04, 'Lecture', 35, FALSE, 'Tu&Th', '11:00', '12:00', 'ECS432'),
       (DEFAULT, '323', 'Winter', 2017, 03, 'Lecture', 35, FALSE, 'Mon&Wed', '10:00', '11:00', 'ECS310'),
       (DEFAULT, '323', 'Winter', 2017, 04, 'Lecture', 35, FALSE, 'Mon&Wed', '10:00', '11:00', 'ECS410'),
       (DEFAULT, '323', 'Summer', 2019, 01, 'Lecture', 35, TRUE, 'Sat', '8:00', '9:00', 'ECS211'),
       (DEFAULT, '323', 'Summer', 2019, 02, 'Lecture', 35, TRUE, 'Sat', '9:00', '10:00', 'ECS212'),
       (DEFAULT, '323', 'Summer', 2019, 02, 'Lecture', 35, TRUE, 'Sat', '9:00', '10:00', 'ECS214');

INSERT INTO students
VALUES ('018805384', 'Davis', 'Hunter', '1/31/1997'),
       ('018807472', 'Yuanshun', 'Dong', '2/21/1998'),
       ('018831753', 'Yosselin', 'Velasco', '6/16/1998'),
       ('018878364', 'Jack', 'Smith', '9/7/1997'),
       ('018831783', 'Tim', 'Wong', '4/6/1997'),
       ('018881624', 'Joseph', 'Adler', '8/31/1996'),
       ('018835379', 'Jessica', 'Farmer', '5/12/1995'),
       ('018875622', 'Jane', 'Goodall', '4/20/1997'),
       ('018834554', 'Marie', 'Curie', '1/14/1998'),
       ('018831543', 'Sarah', 'Boysen', '1/22/1996');

INSERT INTO enrollments
VALUES ('018805384', 5, 'Graded', 'A', '1/22/2018', NULL),
       ('018807472', 5, 'Graded', 'B', '1/22/2018', NULL);

-- End program
