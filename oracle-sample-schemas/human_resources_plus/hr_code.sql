Rem
Rem $Header: hr_code.sql 29-aug-2002.11:44:01 hyeh Exp $
Rem
Rem hr_code.sql
Rem
Rem Copyright (c) 2001, 2015, Oracle Corporation.  All rights reserved.  
Rem 
Rem Permission is hereby granted, free of charge, to any person obtaining
Rem a copy of this software and associated documentation files (the
Rem "Software"), to deal in the Software without restriction, including
Rem without limitation the rights to use, copy, modify, merge, publish,
Rem distribute, sublicense, and/or sell copies of the Software, and to
Rem permit persons to whom the Software is furnished to do so, subject to
Rem the following conditions:
Rem 
Rem The above copyright notice and this permission notice shall be
Rem included in all copies or substantial portions of the Software.
Rem 
Rem THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
Rem EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
Rem MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
Rem NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
Rem LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
Rem OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
Rem WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
Rem
Rem    NAME
Rem      hr_code.sql - Create procedural objects for HRPLUS schema
Rem
Rem    DESCRIPTION
Rem      Create a statement level trigger on EMPLOYEES
Rem      to allow DML during business hours.
Rem      Create a row level trigger on the EMPLOYEES table,
Rem      after UPDATES on the department_id or job_id columns.
Rem      Create a stored procedure to insert a row into the
Rem      JOB_HISTORY table.  Have the above row level trigger
Rem      row level trigger call this stored procedure. 
Rem
Rem    NOTES
Rem
Rem    CREATED by Nancy Greenberg - 06/01/00
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    hyeh        08/29/02 - hyeh_mv_comschema_to_rdbms
Rem    ahunold     05/11/01 - disable
Rem    ahunold     03/03/01 - HR simplification, REGIONS table
Rem    ahunold     02/20/01 - Created
Rem    mw2q        01/04/22 - HR renamed to HRPLUS
Rem

SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100
SET ECHO OFF

REM **************************************************************************

REM procedure and statement trigger to allow dmls during business hours:
CREATE OR REPLACE PROCEDURE secure_dml
IS
BEGIN
  IF TO_CHAR (SYSDATE, 'HH24:MI') NOT BETWEEN '08:00' AND '18:00'
        OR TO_CHAR (SYSDATE, 'DY') IN ('SAT', 'SUN') THEN
	RAISE_APPLICATION_ERROR (-20205, 
		'You may only make changes during normal office hours');
  END IF;
END secure_dml;
/

CREATE OR REPLACE TRIGGER secure_employees
  BEFORE INSERT OR UPDATE OR DELETE ON employees
BEGIN
  secure_dml;
END secure_employees;
/

ALTER TRIGGER secure_employees DISABLE;

REM **************************************************************************
REM procedure to add a row to the JOB_HISTORY table and row trigger 
REM to call the procedure when data is updated in the job_id or 
REM department_id columns in the EMPLOYEES table:

CREATE OR REPLACE PROCEDURE add_job_history
  (  p_emp_id          job_history.employee_id%type
   , p_start_date      job_history.start_date%type
   , p_end_date        job_history.end_date%type
   , p_job_id          job_history.job_id%type
   , p_department_id   job_history.department_id%type 
   )
IS
BEGIN
  INSERT INTO job_history (employee_id, start_date, end_date, 
                           job_id, department_id)
    VALUES(p_emp_id, p_start_date, p_end_date, p_job_id, p_department_id);
END add_job_history;
/

CREATE OR REPLACE TRIGGER update_job_history
  AFTER UPDATE OF job_id, department_id ON employees
  FOR EACH ROW
BEGIN
  add_job_history(:old.employee_id, :old.hire_date, sysdate, 
                  :old.job_id, :old.department_id);
END;
/

COMMIT;


REM **************************************************************************
REM procedure to display today dates information in Oracle


CREATE OR REPLACE PROCEDURE today_is AS
BEGIN
-- display the current system date in long format
  DBMS_OUTPUT.PUT_LINE( 'Today is ' || TO_CHAR(SYSDATE, 'DL') );
END today_is;
/


REM **************************************************************************
REM including OR REPLACE is more convenient when updating a subprogram
REM IN is the default for parameter declarations so it could be omitted

CREATE OR REPLACE PROCEDURE award_bonus (emp_id IN NUMBER, bonus_rate IN NUMBER)
  AS
-- declare variables to hold values from table columns, use %TYPE attribute
   emp_comm        employees.commission_pct%TYPE;
   emp_sal         employees.salary%TYPE;
-- declare an exception to catch when the salary is NULL
   salary_missing  EXCEPTION;
BEGIN  -- executable part starts here
-- select the column values into the local variables
   SELECT salary, commission_pct INTO emp_sal, emp_comm FROM employees
    WHERE employee_id = emp_id;
-- check whether the salary for the employee is null, if so, raise an exception
   IF emp_sal IS NULL THEN
     RAISE salary_missing;
   ELSE
     IF emp_comm IS NULL THEN
-- if this is not a commissioned employee, increase the salary by the bonus rate
-- for this example, do not make the actual update to the salary
-- UPDATE employees SET salary = salary + salary * bonus_rate
--   WHERE employee_id = emp_id;
       DBMS_OUTPUT.PUT_LINE('Employee ' || emp_id || ' receives a bonus: '
                            || TO_CHAR(emp_sal * bonus_rate) );
     ELSE
       DBMS_OUTPUT.PUT_LINE('Employee ' || emp_id
                            || ' receives a commission. No bonus allowed.');
     END IF;
   END IF;
EXCEPTION  -- exception-handling part starts here
   WHEN salary_missing THEN
      DBMS_OUTPUT.PUT_LINE('Employee ' || emp_id ||
                           ' does not have a value for salary. No update.');
   WHEN OTHERS THEN
      NULL; -- for other exceptions do nothing
END award_bonus;
/

REM **************************************************************************
REM Creating a Stored Procedure With the AUTHID Clause

CREATE OR REPLACE PROCEDURE create_log_table
-- use AUTHID CURRENT _USER to execute with the privileges and
-- schema context of the calling user
  AUTHID CURRENT_USER AS
  tabname       VARCHAR2(30); -- variable for table name
  temptabname   VARCHAR2(30); -- temporary variable for table name
  currentdate   VARCHAR2(8);  -- varible for current date
BEGIN
-- extract, format, and insert the year, month, and day from SYSDATE into
-- the currentdate variable
  SELECT TO_CHAR(EXTRACT(YEAR FROM SYSDATE)) ||
     TO_CHAR(EXTRACT(MONTH FROM SYSDATE),'FM09') ||
     TO_CHAR(EXTRACT(DAY FROM SYSDATE),'FM09') INTO currentdate FROM DUAL;
-- construct the log table name with the current date as a suffix
  tabname := 'log_table_' || currentdate;

-- check whether a table already exists with that name
-- if it does NOT exist, then go to exception handler and create table
-- if the table does exist, then note that table already exists
  SELECT TABLE_NAME INTO temptabname FROM USER_TABLES
    WHERE TABLE_NAME = UPPER(tabname);
  DBMS_OUTPUT.PUT_LINE('Table ' || tabname || ' already exists.');

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    -- this means the table does not exist because the table name
    -- was not found in USER_TABLES
      BEGIN
-- use EXECUTE IMMEDIATE to create a table with tabname as the table name
        EXECUTE IMMEDIATE 'CREATE TABLE ' || tabname
                         || '(op_time VARCHAR2(10), operation VARCHAR2(50))' ;
        DBMS_OUTPUT.PUT_LINE(tabname || ' has been created');
      END;

END create_log_table;
/

REM **************************************************************************
REM Creating a Stored Function That Returns a String

CREATE OR REPLACE FUNCTION last_first_name (empid NUMBER)
  RETURN VARCHAR2 IS
  lastname   employees.last_name%TYPE; -- declare a variable same as last_name
  firstname  employees.first_name%TYPE; -- declare a variable same as first_name
BEGIN
  SELECT last_name, first_name INTO lastname, firstname FROM employees
    WHERE employee_id = empid;
  RETURN ( 'Employee: ' || empid || ' - ' || UPPER(lastname)
                                 || ', ' || UPPER(firstname) );
END last_first_name;
/

REM **************************************************************************
REM Creating a Stored Function That Returns a Number
REM function calculates the salary ranking of the employee based on the current
REM minimum and maximum salaries for employees in the same job category

CREATE OR REPLACE FUNCTION emp_sal_ranking (empid NUMBER)
  RETURN NUMBER IS
  minsal        employees.salary%TYPE; -- declare a variable same as salary
  maxsal        employees.salary%TYPE; -- declare a variable same as salary
  jobid         employees.job_id%TYPE; -- declare a variable same as job_id
  sal           employees.salary%TYPE; -- declare a variable same as salary
BEGIN
-- retrieve the jobid and salary for the specific employee ID
  SELECT job_id, salary INTO jobid, sal FROM employees WHERE employee_id = empid;
-- retrieve the minimum and maximum salaries for employees with the same job ID
  SELECT MIN(salary), MAX(salary) INTO minsal, maxsal FROM employees
      WHERE job_id = jobid;
-- return the ranking as a decimal, based on the following calculation
  RETURN ((sal - minsal)/(maxsal - minsal));
END emp_sal_ranking;
/

REM **************************************************************************
REM Creating a Package Specification

CREATE OR REPLACE PACKAGE emp_actions AS  -- package specification

  PROCEDURE hire_employee (lastname VARCHAR2,
    firstname VARCHAR2, email VARCHAR2, phoneno VARCHAR2,
    hiredate DATE, jobid VARCHAR2, sal NUMBER, commpct NUMBER,
    mgrid NUMBER, deptid NUMBER);
  PROCEDURE remove_employee (empid NUMBER);
  FUNCTION emp_sal_ranking (empid NUMBER) RETURN NUMBER;
END emp_actions;
/

REM **************************************************************************
REM Creating a Package Body

CREATE OR REPLACE PACKAGE BODY emp_actions AS  -- package body

-- code for procedure hire_employee, which adds a new employee
  PROCEDURE hire_employee (lastname VARCHAR2,
    firstname VARCHAR2, email VARCHAR2, phoneno VARCHAR2, hiredate DATE,
    jobid VARCHAR2, sal NUMBER, commpct NUMBER, mgrid NUMBER, deptid NUMBER) IS
    min_sal    employees.salary%TYPE; -- variable to hold minimum salary for jobid
    max_sal    employees.salary%TYPE; -- variable to hold maximum salary for jobid
    seq_value  NUMBER;  -- variable to hold next sequence value
  BEGIN
    -- get the next sequence number in the employees_seq sequence
    SELECT employees_seq.NEXTVAL INTO seq_value FROM DUAL;
    -- use the next sequence number for the new employee_id
    INSERT INTO employees VALUES (seq_value, lastname, firstname, email,
     phoneno, hiredate, jobid, sal, commpct, mgrid, deptid);
     SELECT min_salary INTO min_sal FROM jobs WHERE job_id = jobid;
     SELECT max_salary INTO max_sal FROM jobs WHERE job_id = jobid;
     IF sal > max_sal THEN
       DBMS_OUTPUT.PUT_LINE('Warning: ' || TO_CHAR(sal)
                 || ' is greater than the maximum salary '
                 || TO_CHAR(max_sal) || ' for the job classification ' || jobid );
     ELSIF sal < min_sal THEN
       DBMS_OUTPUT.PUT_LINE('Warning: ' || TO_CHAR(sal)
                 || ' is less than the minimum salary '
                 || TO_CHAR(min_sal) || ' for the job classification ' || jobid );
     END IF;
  END hire_employee;

-- code for procedure remove_employee, which removes an existing employee
  PROCEDURE remove_employee (empid NUMBER) IS
     firstname employees.first_name%TYPE;
     lastname  employees.last_name%TYPE;
  BEGIN
    SELECT first_name, last_name INTO firstname, lastname FROM employees
      WHERE employee_id = empid;
    DELETE FROM employees WHERE employee_id = empid;
    DBMS_OUTPUT.PUT_LINE('Employee: ' || TO_CHAR(empid) || ', '
                      || firstname || ', ' || lastname || ' has been deleted.');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Employee ID: ' || TO_CHAR(empid) || ' not found.');
  END remove_employee;

-- code for function emp_sal_ranking, which calculates the salary ranking of the
-- employee based on the minimum and maximum salaries for the job category
  FUNCTION emp_sal_ranking (empid NUMBER) RETURN NUMBER IS
    minsal        employees.salary%TYPE; -- declare a variable same as salary
    maxsal        employees.salary%TYPE; -- declare a variable same as salary
    jobid         employees.job_id%TYPE; -- declare a variable same as job_id
    sal           employees.salary%TYPE; -- declare a variable same as salary
  BEGIN
-- retrieve the jobid and salary for the specific employee ID
    SELECT job_id, salary INTO jobid, sal FROM employees
       WHERE employee_id = empid;
-- retrieve the minimum and maximum salaries for the job ID
    SELECT min_salary, max_salary INTO minsal, maxsal FROM jobs
       WHERE job_id = jobid;
-- return the ranking as a decimal, based on the following calculation
    RETURN ((sal - minsal)/(maxsal - minsal));
  END emp_sal_ranking;
END emp_actions;
/

REM **************************************************************************
REM Create Employee Audit Table

CREATE TABLE emp_audit (
              emp_audit_id NUMBER(6),
              up_date DATE,
              new_sal NUMBER(8,2),
              old_sal NUMBER(8,2) );

CREATE OR REPLACE TRIGGER audit_sal
   AFTER UPDATE OF salary ON employees FOR EACH ROW
DECLARE 
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
-- bind variables are used here for values
   INSERT INTO emp_audit VALUES( :old.employee_id, SYSDATE, 
                                 :new.salary, :old.salary );
  COMMIT;
END;
/

REM **************************************************************************
REM DBMS_SQL example


CREATE OR REPLACE PROCEDURE new_employee (i_FIRST    IN VARCHAR2,
                                          i_LAST     IN VARCHAR2,
                                          i_email    IN VARCHAR2,
                                          i_phone    IN VARCHAR2,
                                          i_hired    IN DATE,
                                          i_job      IN VARCHAR2,
                                          i_deptno   IN NUMBER DEFAULT 0)
AS
   v_sql           VARCHAR2 (1000);

   cursor_var      NUMBER := DBMS_SQL.OPEN_CURSOR;
   rows_complete   NUMBER := 0;
   next_emp_id     NUMBER := employees_seq.NEXTVAL;
BEGIN
   IF i_deptno != 0
   THEN
      v_sql :=
            'INSERT INTO EMPLOYEES ( '
         || 'employee_id, first_name, last_name, email, '
         || 'phone_number, hire_date, job_id, department_id) '
         || 'VALUES( '
         || ':next_emp_id, :first, :last, :email, :phone, :hired, '
         || ':job_id, :dept)';
   ELSE
      v_sql :=
            'INSERT INTO EMPLOYEES ( '
         || 'employee_id, first_name, last_name, email, '
         || 'phone_number, hire_date, job_id) '
         || 'VALUES( '
         || ':next_emp_id, :first, :last, :email, :phone, :hired, '
         || ':job_id)';
   END IF;

   DBMS_SQL.PARSE (cursor_var, v_sql, DBMS_SQL.NATIVE);
   DBMS_SQL.BIND_VARIABLE (cursor_var, ':next_emp_id', next_emp_id);
   DBMS_SQL.BIND_VARIABLE (cursor_var, ':first', i_FIRST);
   DBMS_SQL.BIND_VARIABLE (cursor_var, ':last', i_LAST);
   DBMS_SQL.BIND_VARIABLE (cursor_var, ':email', i_email);
   DBMS_SQL.BIND_VARIABLE (cursor_var, ':phone', i_phone);

   DBMS_SQL.BIND_VARIABLE (cursor_var, ':hired', i_hired);

   DBMS_SQL.BIND_VARIABLE (cursor_var, ':job_id', i_job);

   IF i_deptno != 0
   THEN
      DBMS_SQL.BIND_VARIABLE (cursor_var, ':dept', i_deptno);
   END IF;

   rows_complete := DBMS_SQL.EXECUTE (cursor_var);
   DBMS_SQL.CLOSE_CURSOR (cursor_var);
   COMMIT;
END;
/

REM **************************************************************************
REM DBMS_UTILITY example

CREATE OR REPLACE PROCEDURE comma_to_table (
    p_list      VARCHAR2
)
IS
    r_lname     DBMS_UTILITY.LNAME_ARRAY;
    v_length    BINARY_INTEGER;
BEGIN
    DBMS_UTILITY.COMMA_TO_TABLE(p_list,v_length,r_lname);
    FOR i IN 1..v_length LOOP
        DBMS_OUTPUT.PUT_LINE(r_lname(i));
    END LOOP;
END;
/


REM **************************************************************************
REM BULK COLLECT Example

CREATE OR REPLACE PROCEDURE increase_salary_bulk
IS
 TYPE EmployeeSet IS TABLE OF employees%ROWTYPE;
   underpaid EmployeeSet;
     -- Holds set of rows from EMPLOYEES table.
   CURSOR c1 IS SELECT first_name, last_name FROM employees;
   TYPE NameSet IS TABLE OF c1%ROWTYPE;
   some_names NameSet;
     -- Holds set of partial rows from EMPLOYEES table.
BEGIN
-- With one query,
-- bring all relevant data into collection of records.
   SELECT * BULK COLLECT INTO underpaid FROM employees
      WHERE salary < 5000 ORDER BY salary DESC;
-- Process data by examining collection or passing it to
-- eparate procedure, instead of writing loop to FETCH each row.
   DBMS_OUTPUT.PUT_LINE
     (underpaid.COUNT || ' people make less than 5000.');
   FOR i IN underpaid.FIRST .. underpaid.LAST
   LOOP
     DBMS_OUTPUT.PUT_LINE
       (underpaid(i).last_name || ' makes ' || underpaid(i).salary);
   END LOOP;
-- You can also bring in just some of the table columns.
-- Here you get the first and last names of 10 arbitrary employees.
   SELECT first_name, last_name
     BULK COLLECT INTO some_names
     FROM employees
     WHERE ROWNUM < 11;
   FOR i IN some_names.FIRST .. some_names.LAST
   LOOP
      DBMS_OUTPUT.PUT_LINE
        ('Employee = ' || some_names(i).first_name
         || ' ' || some_names(i).last_name);
   END LOOP;
END;
/

REM **************************************************************************
REM Nested Procedure

CREATE OR REPLACE PROCEDURE nested_swap_procedure
IS
    first_number    NUMBER;
    second_number   NUMBER;

    PROCEDURE swapn (num_one IN OUT NUMBER, num_two IN OUT NUMBER) IS
      temp_num    NUMBER;
    BEGIN
      temp_num := num_one;
      num_one := num_two;
      num_two := temp_num ;
    END;

  BEGIN

    first_number := 10;
    second_number := 20;
    DBMS_OUTPUT.PUT_LINE('First Number = ' || TO_CHAR (first_number));
    DBMS_OUTPUT.PUT_LINE('Second Number = ' || TO_CHAR (second_number));

    --Swap the values
    DBMS_OUTPUT.PUT_LINE('Swapping the two values now.');
    swapn(first_number, second_number);

    --Display the results
    DBMS_OUTPUT.PUT_LINE('First Number = ' || to_CHAR (first_number));
    DBMS_OUTPUT.PUT_LINE('Second Number = ' || to_CHAR (second_number));
  END;
/
