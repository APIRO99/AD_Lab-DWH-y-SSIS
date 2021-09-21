USE master
GO


DECLARE @EliminarDB BIT = 1;
--Eliminar BDD si ya existe y si @EliminarDB = 1
if (((select COUNT(1) from sys.databases where name = 'RepuestosWebDWH')>0) AND (@EliminarDB = 1))
begin
	EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'RepuestosWebDWH'
	
	
	use [master];
	ALTER DATABASE [RepuestosWebDWH] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
		
	DROP DATABASE [RepuestosWebDWH]
	print 'RepuestosWebDWH ha sido eliminada'
end


CREATE DATABASE RepuestosWebDWH
GO

USE RepuestosWebDWH
GO

--Enteros
 --User Defined Type _ Surrogate Key
	--Tipo para SK entero: Surrogate Key
	CREATE TYPE [UDT_SK] FROM INT

	--Tipo para PK entero
	CREATE TYPE [UDT_PK] FROM INT
	GO

--Cadenas
	--Tipo para cadenas largas
	CREATE TYPE [UDT_VarcharLargo] FROM VARCHAR(500)

	--Tipo para cadenas medianas
	CREATE TYPE [UDT_VarcharMediano] FROM VARCHAR(300)

	--Tipo para cadenas cortas
	CREATE TYPE [UDT_VarcharCorto] FROM VARCHAR(100)

	--Tipo para cadenas cortas
	CREATE TYPE [UDT_UnCaracter] FROM CHAR(1)
	GO

--Decimal
	--Tipo Decimal 12,2
	CREATE TYPE [UDT_Decimal12.2] FROM DECIMAL(12,2)

	--Tipo Decimal 6,2
	CREATE TYPE [UDT_Decimal6.2] FROM DECIMAL(6,2)

	--Tipo Decimal 5,2
	CREATE TYPE [UDT_Decimal5.2] FROM DECIMAL(5,2)
    --Tipo Decimal 2,2
	CREATE TYPE [UDT_Decimal2.2] FROM DECIMAL(2,2)

--Fechas
	CREATE TYPE [UDT_DateTime] FROM DATETIME
	Go

--Schemas para separar objetos
	CREATE SCHEMA Fact
	GO

	CREATE SCHEMA Dimension
	GO

--------------------------------------------------------------------------------------------
-------------------------------MODELADO CONCEPTUAL------------------------------------------
--------------------------------------------------------------------------------------------
--Tablas Dimensiones

	CREATE TABLE Dimension.Fecha (
		DateKey INT PRIMARY KEY
	)
	GO

	CREATE TABLE Dimension.Partes (
		SK_Partes [UDT_SK] PRIMARY KEY IDENTITY
	)
	GO

	CREATE TABLE Dimension.Geografia (
		SK_Geografia [UDT_SK] PRIMARY KEY IDENTITY
	)
	GO

	CREATE TABLE Dimension.Clientes (
		SK_Clientes [UDT_SK] PRIMARY KEY IDENTITY
	)
	GO


--Tablas Fact

	CREATE TABLE Fact.Orden (
		SK_Orden [UDT_SK] PRIMARY KEY IDENTITY,
		SK_Partes [UDT_SK] REFERENCES Dimension.Partes(SK_Partes),
		SK_Geografia [UDT_SK] REFERENCES Dimension.Geografia(SK_Geografia),
		SK_Clientes [UDT_SK] REFERENCES Dimension.Clientes(SK_Clientes),
		DateKey INT REFERENCES Dimension.Fecha(DateKey)
	)
	GO

--Metadata

	-- Metadata Partes
	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension Partes ofrece una vista desnormalizada de la tablas de origen Partes, Categoria y Linea. Dejando todo en una unica dimension para un modelo estrella', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Partes';
	GO

	-- Metadata Geografia
	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension Geografia ofrece una vista desnormalizada de las tablas de origen Pais, Region y Ciudad. Dejando todo en una única dimensión para un modelo estrella', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Geografia';
	GO

	-- Metadata Clientes
	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension Clinetes provee una vista desnormalizada de la tabla origen Clientes. Dejando todo en una única dimensión para un modelo estrella', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Clientes';
	GO

	-- Metadata Fecha
	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La dimension fecha es generada de forma automatica y no tiene datos origen, se puede regenerar enviando un rango de fechas al stored procedure USP_FillDimDate', 
     @level0type = N'SCHEMA', 
     @level0name = N'Dimension', 
     @level1type = N'TABLE', 
     @level1name = N'Fecha';
	GO

	-- Metadata Orden
	EXEC sys.sp_addextendedproperty 
     @name = N'Desnormalizacion', 
     @value = N'La tabla de hechos es una union proveniente de las tablas de Orden, Detalle_Orden, Descuento y StatusOrden', 
     @level0type = N'SCHEMA', 
     @level0name = N'Fact', 
     @level1type = N'TABLE', 
     @level1name = N'Orden';
	GO

--------------------------------------------------------------------------------------------
---------------------------------MODELADO LOGICO--------------------------------------------
--------------------------------------------------------------------------------------------
--Transformación en modelo lógico (mas detalles)

	--DimFecha	
	ALTER TABLE Dimension.Fecha ADD [Date] DATE NOT NULL
    ALTER TABLE Dimension.Fecha ADD [Day] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [DaySuffix] CHAR(2) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [Weekday] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekDayName] VARCHAR(10) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekDayName_Short] CHAR(3) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekDayName_FirstLetter] CHAR(1) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [DOWInMonth] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [DayOfYear] SMALLINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekOfMonth] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [WeekOfYear] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [Month] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MonthName] VARCHAR(10) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MonthName_Short] CHAR(3) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MonthName_FirstLetter] CHAR(1) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [Quarter] TINYINT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [QuarterName] VARCHAR(6) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [Year] INT NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MMYYYY] CHAR(6) NOT NULL
	ALTER TABLE Dimension.Fecha ADD [MonthYear] CHAR(7) NOT NULL
    ALTER TABLE Dimension.Fecha ADD IsWeekend BIT NOT NULL
  
	------- DimPartes -------
	--Tabla  Partes 
	ALTER TABLE Dimension.Partes ADD ID_Partes [UDT_PK]
	ALTER TABLE Dimension.Partes ADD NombreParte [UDT_VarcharCorto]
	ALTER TABLE Dimension.Partes ADD DescripcionParte [UDT_VarcharLargo]
	ALTER TABLE Dimension.Partes ADD PrecioParte [UDT_Decimal12.2]
	--Tabla Categoria
	ALTER TABLE Dimension.Partes ADD ID_Categoria [UDT_PK]
	ALTER TABLE Dimension.Partes ADD NombreCategoria [UDT_VarcharCorto]
	ALTER TABLE Dimension.Partes ADD DescripcionCategoria [UDT_VarcharLargo]
	-- Tabla Linea
	ALTER TABLE Dimension.Partes ADD ID_Linea [UDT_PK]
	ALTER TABLE Dimension.Partes ADD NombreLinea [UDT_VarcharCorto]
	ALTER TABLE Dimension.Partes ADD DescripcionLinea [UDT_VarcharLargo]

	------- DimGeografia -------
	-- Tabla Ciudad
	ALTER TABLE Dimension.Geografia ADD ID_Ciudad [UDT_PK]
	ALTER TABLE Dimension.Geografia ADD NombreCiudad [UDT_VarcharCorto]
	ALTER TABLE Dimension.Geografia ADD CodigoPostal INT
	-- Tabla Region
	ALTER TABLE Dimension.Geografia ADD ID_Region [UDT_PK]
	ALTER TABLE Dimension.Geografia ADD NombreRegion [UDT_VarcharCorto]
	-- Tabla Pais
	ALTER TABLE Dimension.Geografia ADD ID_Pais [UDT_PK]
	ALTER TABLE Dimension.Geografia ADD NombrePais [UDT_VarcharCorto]


	--DimClientes
    -- Tabla Clientes
	ALTER TABLE Dimension.Clientes ADD ID_Cliente [UDT_PK]
	ALTER TABLE Dimension.Clientes ADD PrimerNombre [UDT_VarcharCorto]
	ALTER TABLE Dimension.Clientes ADD SegundoNombre [UDT_VarcharCorto]
	ALTER TABLE Dimension.Clientes ADD PrimerApellido [UDT_VarcharCorto]
	ALTER TABLE Dimension.Clientes ADD SegundoApellido [UDT_VarcharCorto]
	ALTER TABLE Dimension.Clientes ADD Genero [UDT_UnCaracter]
	ALTER TABLE Dimension.Clientes ADD Correo_Electronico [UDT_VarcharCorto]
	ALTER TABLE Dimension.Clientes ADD FechaNacimiento [UDT_DateTime]

    ------- Fact -------
	-- Tabla Orden
	ALTER TABLE Fact.Orden ADD ID_Orden [UDT_PK]
    ALTER TABLE Fact.Orden ADD Total_Orden [UDT_Decimal12.2]
	ALTER TABLE Fact.Orden ADD Fecha_Orden [UDT_DateTime]
    -- Tabla StatusOrden
    ALTER TABLE Fact.Orden ADD ID_StatusOrden [UDT_PK]
	ALTER TABLE Fact.Orden ADD NombreStatus [UDT_VarcharCorto]
    -- Tabla Descuento
    ALTER TABLE Fact.Orden ADD ID_Descuento [UDT_PK]
	ALTER TABLE Fact.Orden ADD NombreDescuento [UDT_VarcharMediano]
    ALTER TABLE Fact.Orden ADD PorcentajeDescuento [UDT_Decimal2.2]
    -- Tabla Detalle_orden
	ALTER TABLE Fact.Orden ADD ID_DetalleOrden [UDT_PK]
    ALTER TABLE Fact.Orden ADD Cantidad INT
    


--Indices Columnares
	CREATE NONCLUSTERED COLUMNSTORE INDEX [NCCS-Precio] ON [Fact].[Orden]
	(
	   [Total_Orden]
	)WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)
	GO

--Queries para llenar datos
/*
--Dimensiones

	--DimCarrera
	INSERT INTO Dimension.Carrera
	(ID_Carrera, 
	 ID_Facultad, 
	 NombreCarrera, 
	 NombreFacultad
	)
	SELECT C.ID_Carrera, 
			F.ID_Facultad, 
			C.Nombre, 
			F.Nombre
	FROM Admisiones.dbo.Facultad F
		INNER JOIN Admisiones.dbo.Carrera C ON(C.ID_Facultad = F.ID_Facultad);
	
	SELECT * FROM Dimension.Carrera

	--DimCandidato
	INSERT INTO Dimension.Candidato
	([ID_Candidato], 
	 [ID_Colegio], 
	 [ID_Diversificado], 
	 [NombreCandidato], 
	 [ApellidoCandidato], 
	 [Genero], 
	 [FechaNacimiento], 
	 [NombreColegio], 
	 [NombreDiversificado]
	)
	SELECT C.ID_Candidato, 
			CC.ID_Colegio, 
			D.ID_Diversificado, 
			C.Nombre as NombreCandidato, 
			C.Apellido as ApellidoCandidato, 
			C.Genero, 
			C.FechaNacimiento, 
			CC.Nombre as NombreColegio, 
			D.Nombre as NombreDiversificado
	FROM Admisiones.DBO.Candidato C
		INNER JOIN Admisiones.DBO.ColegioCandidato CC ON(C.ID_Colegio = CC.ID_Colegio)
		INNER JOIN Admisiones.DBO.Diversificado D ON(C.ID_Diversificado = D.ID_Diversificado);

		SELECT * FROM Dimension.Candidato


	--DimDescuento
	INSERT INTO Dimension.Descuento (
	  [ID_Descuento], 
	  [Descripcion], 
	  [PorcentajeDescuento]
	)
	SELECT DBODESC.ID_Descuento as ID_Descuento,
		   DBODESC.Descripcion as Descripcion,
		   DBODESC.PorcentajeDescuento as PorcentajeDescuento
	FROM Admisiones.DBO.Descuento DBODESC

		SELECT * FROM Dimension.Descuento


	--DimMateria
	INSERT INTO Dimension.Materia (
	  [ID_Materia], 
	  [NombreMateria], 
	  [ID_Examen],
	  [ID_ExamenDetalle],
	  [NotaArea]
	)
	SELECT M.ID_Materia as ID_Materia,
		   M.NombreMateria as NombreMateria,
		   ED.ID_Examen as ID_Examen,
		   ED.ID_ExamenDetalle as ID_ExamenDetalle,
		   ED.NotaArea as NotaArea
		   
	FROM Admisiones.DBO.Materia M
		 INNER JOIN Admisiones.DBO.Examen_detalle ED ON( ED.ID_Materia = M.ID_Materia)

		SELECT * FROM Dimension.Materia

--------------------------------------------------------------------------------------------
-----------------------CORRER CREATE de USP_FillDimDate PRIMERO!!!--------------------------
--------------------------------------------------------------------------------------------

	DECLARE @FechaMaxima DATETIME=DATEADD(YEAR,2,GETDATE())
	--Fecha
	IF ISNULL((SELECT MAX(Date) FROM Dimension.Fecha),'1900-01-01')<@FechaMaxima
	begin
		EXEC USP_FillDimDate @CurrentDate = '2016-01-01', 
							 @EndDate     = @FechaMaxima
	end
	SELECT * FROM Dimension.Fecha
	
	--Fact
	INSERT INTO [Fact].[Examen]
	([SK_Candidato], 
	 [SK_Carrera], 
	 [SK_Materia], 
	 [SK_Descuento], 
	 [DateKey], 
	 [ID_Examen], 
	 [Precio], 
	 [NotaTotal]
	)
	SELECT  --Columnas de mis dimensiones en DWH
			SK_Candidato, 
			SK_Carrera,
			SK_Materia,
			SK_Descuento,
			F.DateKey, 
			R.ID_Examen, 
			R.Precio, 
			R.Nota
				 
	FROM Admisiones.DBO.Examen R
		--Referencias a DWH
		INNER JOIN Dimension.Candidato C ON(C.ID_Candidato = R.ID_Candidato)
		INNER JOIN Dimension.Carrera CA ON(CA.ID_Carrera = R.ID_Carrera)
		INNER JOIN Dimension.Descuento DE ON(DE.ID_Descuento = R.ID_Descuento)
		INNER JOIN Dimension.Materia MAT ON(MAT.ID_Examen = R.ID_Examen)
		INNER JOIN Dimension.Fecha F ON(CAST((CAST(YEAR(R.FechaPrueba) AS VARCHAR(4)))+left('0'+CAST(MONTH(R.FechaPrueba) AS VARCHAR(4)),2)+left('0'+(CAST(DAY(R.FechaPrueba) AS VARCHAR(4))),2) AS INT)  = F.DateKey);



--------------------------------------------------------------------------------------------
------------------------------------Resultado Final-----------------------------------------
--------------------------------------------------------------------------------------------	

	SELECT *
	FROM	Fact.Examen AS E INNER JOIN
			Dimension.Candidato AS C ON E.SK_Candidato = C.SK_Candidato INNER JOIN
			Dimension.Carrera AS CA ON E.SK_Carrera = CA.SK_Carrera INNER JOIN
			Dimension.Materia AS MAT ON E.SK_Materia = MAT.SK_Materia INNER JOIN
			Dimension.Descuento AS DE ON E.SK_Descuento = DE.SK_Descuento INNER JOIN
			Dimension.Fecha AS F ON E.DateKey = F.DateKey


*/