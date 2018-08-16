USE ETL
GO

DECLARE @Path VARCHAR(2000)
	,@NewDTSID nvarchar(38) = '{807516A0-F6C0-4BAC-AD7A-D41B4E0F9BFD}';

SET @Path = 'D:\ETLDevelopment\KenA\BISL ETL\Dev-2016\SSIS\RDW.Dim5\*.dtsx';

DECLARE @MyFiles TABLE (
	MyID INT IDENTITY(1, 1) PRIMARY KEY
	,FullPath VARCHAR(2000)
	);
DECLARE @CommandLine VARCHAR(4000);

SELECT @CommandLine = LEFT('dir "' + @Path + '" /A-D /B /S ', 4000);

INSERT INTO @MyFiles (FullPath)
EXECUTE xp_cmdshell @CommandLine;

DELETE
FROM @MyFiles
WHERE FullPath IS NULL
	OR FullPath = 'File Not Found'
	OR FullPath = 'The system cannot find the path specified.'
	OR FullPath = 'The system cannot find the file specified.';

DROP TABLE IF EXISTS dbo.pkgStats;
CREATE TABLE dbo.pkgStats
(
	PackagePath VARCHAR(900) NOT NULL PRIMARY KEY
	,PackageXML XML NOT NULL
);

DECLARE @FullPath VARCHAR(2000);

DECLARE file_cursor CURSOR
FOR
SELECT FullPath
FROM @MyFiles;

OPEN file_cursor

FETCH NEXT
FROM file_cursor
INTO @FullPath;

WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @sql NVARCHAR(max);

	SET @sql = '
		INSERT	pkgStats (PackagePath,PackageXML)
		select  ''@FullPath'' as PackagePath
		,		cast(BulkColumn as varchar(max)) as PackageXML
		from    openrowset(bulk ''@FullPath'',
								single_blob) as pkgColumn';

	SELECT @sql = REPLACE(@sql, '@FullPath', @FullPath);

	EXEC sp_executesql @sql;

	FETCH NEXT
	FROM file_cursor
	INTO @FullPath;
END

CLOSE file_cursor;

DEALLOCATE file_cursor;

--SELECT *
--FROM pkgStats

;WITH XMLNAMESPACES ('www.microsoft.com/SqlServer/Dts'AS DTS)
SELECT 
	SUBSTRING(t.PackagePath,LEN(t.PackagePath) - CHARINDEX('\',REVERSE(t.PackagePath),0)+2,LEN(t.PackagePath)) AS PackageName,
	CONCAT('SQLTask:Connection="', CM1.cm1.value('@DTS:DTSID', 'nvarchar(38)'), '"', '|SQLTask:Connection="' + @NewDTSID + '"') AS ConnectionID
	--t.PackagePath,
	--P.p.value('@DTS:Name', 'nvarchar(30)') AS Name,
	--P.p.value('(./text())[1]', 'int') AS Version,
	--CM1.cm1.value('@DTS:refId', 'nvarchar(50)') AS refid,
	--,CM2.cm2.value('@DTS:ConnectionString', 'nvarchar(150)') AS ConnectionString
FROM   pkgStats t
CROSS  APPLY t.PackageXML.nodes('/DTS:Executable/DTS:Property') AS P(p)
CROSS  APPLY PackageXML.nodes('/DTS:Executable/DTS:ConnectionManagers/DTS:ConnectionManager') CM1(cm1)
CROSS  APPLY CM1.cm1.nodes('DTS:ObjectData/DTS:ConnectionManager') AS CM2(cm2)
WHERE CM1.cm1.value('@DTS:refId', 'nvarchar(50)') = 'Package.ConnectionManagers[RDWETL.ADONET]'
ORDER BY 1
