USE master;
-- create table of weak passwords
-- add passwords as needed (could modify to load from file)
CREATE TABLE #passwords
(
    passwd VARCHAR(255)
);
INSERT INTO #passwords
VALUES
('' );
INSERT INTO #passwords
VALUES
('password');
INSERT INTO #passwords
VALUES
('sa');
INSERT INTO #passwords
VALUES
('abc');

-- compare to password table
SELECT @@servername,
       b.name AS LoginName,
       a.passwd AS CrackedPwd,
       b.sysadmin,
       b.denylogin,
       b.hasaccess
FROM #passwords a,
     syslogins b
WHERE pwdCompare(a.passwd, b.PASSWORD, 0) = 1
UNION
-- login and password the same
SELECT @@servername,
       b.name AS LoginName,
       b.name AS CrackedPwd,
       b.sysadmin,
       b.denylogin,
       b.hasaccess
FROM syslogins b
WHERE pwdCompare(b.NAME, b.PASSWORD, 0) = 1
-- null password
UNION
SELECT @@servername,
       s.name,
       NULL,
       s.sysadmin,
       s.denylogin,
       s.hasaccess
FROM syslogins s
WHERE s.password IS NULL
      AND s.isntgroup = 0
      AND s.isntuser = 0
      AND s.[name] NOT LIKE '##MS%';

DROP TABLE #passwords;



-- count of sysadmins
SELECT @@servername,
       loginname AS sysadmins
FROM master..syslogins
WHERE sysadmin = 1;


