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
		SK_Partes [UDT_SK] PRIMARY KEY IDENTITY,
		--Columnas SCD Tipo 2
		[FechaInicioValidez] DATETIME NOT NULL DEFAULT(GETDATE()),
		[FechaFinValidez] DATETIME NULL,
		--Columnas Linaje
		ID_Batch UNIQUEIDENTIFIER NULL,
		ID_SourceSystem VARCHAR(20)	
	)
	GO

	CREATE TABLE Dimension.Geografia (
		SK_Geografia [UDT_SK] PRIMARY KEY IDENTITY,
		--Columnas SCD Tipo 2
		[FechaInicioValidez] DATETIME NOT NULL DEFAULT(GETDATE()),
		[FechaFinValidez] DATETIME NULL,
		--Columnas Linaje
		ID_Batch UNIQUEIDENTIFIER NULL,
		ID_SourceSystem VARCHAR(20)	
	)
	GO

	CREATE TABLE Dimension.Clientes (
		SK_Clientes [UDT_SK] PRIMARY KEY IDENTITY,
		--Columnas SCD Tipo 2
		[FechaInicioValidez] DATETIME NOT NULL DEFAULT(GETDATE()),
		[FechaFinValidez] DATETIME NULL,
		--Columnas Linaje
		ID_Batch UNIQUEIDENTIFIER NULL,
		ID_SourceSystem VARCHAR(20)	
	)
	GO


--Tablas Fact
	CREATE TABLE Fact.Orden (
		SK_Orden [UDT_SK] PRIMARY KEY IDENTITY,
		SK_Partes [UDT_SK] REFERENCES Dimension.Partes(SK_Partes),
		SK_Geografia [UDT_SK] REFERENCES Dimension.Geografia(SK_Geografia),
		SK_Clientes [UDT_SK] REFERENCES Dimension.Clientes(SK_Clientes),
		DateKey INT REFERENCES Dimension.Fecha(DateKey),
		--Columnas Linaje
		ID_Batch UNIQUEIDENTIFIER NULL,
		ID_SourceSystem VARCHAR(20)	
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



/*
--Queries para llenar datos
--Dimensiones
	--DimClientes
	INSERT INTO Dimension.Clientes
	(
		ID_Cliente,
		Genero,
		PrimerNombre,
		SegundoNombre,
		PrimerApellido,
		SegundoApellido,
		Correo_Electronico,
		FechaNacimiento
	)
    SELECT
    	CLIENT.ID_Cliente,
    	CLIENT.Genero,
    	CLIENT.PrimerNombre,
    	CLIENT.SegundoNombre,
    	CLIENT.PrimerApellido,
    	CLIENT.SegundoApellido,
    	CLIENT.Correo_Electronico,
    	CLIENT.FechaNacimiento
        FROM RepuestosWeb.dbo.Clientes AS CLIENT
	
	SELECT * FROM Dimension.Clientes
	
	--DimGeografia
	INSERT INTO Dimension.Geografia (
		ID_Ciudad,
		ID_Region,
		ID_Pais,
		NombreCiudad,
		CodigoPostal,
		NombreRegion,
		NombrePais 
	)
	SELECT 
		CITY.ID_Ciudad AS ID_Ciudad,
		REG.ID_Region AS ID_Region,
		COUNTRY.ID_Pais AS ID_Pais,
		CITY.Nombre AS NombreCiudad,
		CITY.CodigoPostal AS CodigoPostal,
		REG.Nombre AS NombreRegion,
		COUNTRY.Nombre AS NombrePais
		FROM
		RepuestosWeb.dbo.Ciudad AS CITY
		INNER JOIN RepuestosWeb.dbo.Region AS REG ON CITY.ID_Region = REG.ID_Region
		INNER JOIN RepuestosWeb.dbo.Pais AS COUNTRY ON REG.ID_Pais = COUNTRY.ID_Pais

	Select * FROM Dimension.Geografia
	
	--DimPartes
	INSERT INTO Dimension.Partes (
		ID_Partes,
		ID_Categoria,
		ID_Linea,
		NombreParte,
		DescripcionParte,
		NombreCategoria,
		DescripcionCategoria,
		NombreLinea,
		DescripcionLinea,
		PrecioParte
	)
	SELECT 
		PT.ID_Partes AS ID_Partes,
		PT.Nombre AS NombreParte,
		PT.Descripcion AS DescripcionParte,
		PT.Precio AS PrecioParte,
		CAT.ID_Categoria AS ID_Categoria,
		CAT.Nombre AS NombreCategoria,
		CAT.Descripcion AS DescripcionCategoria,
		LN.ID_Linea AS ID_Linea,
		LN.Nombre AS NombreLinea,
		LN.Descripcion AS DescripcionLinea
		FROM 
			RepuestosWeb.dbo.Partes AS PT
			INNER JOIN RepuestosWeb.dbo.Categoria AS CAT  ON PT.ID_Categoria = CAT.ID_Categoria
			INNER JOIN RepuestosWeb.dbo.Linea AS LN  ON CAT.ID_Linea = LN.ID_Linea

	SELECT * FROM Dimension.Partes
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
	
	--FACT Table
	INSERT INTO Fact.Orden 
	(
		SK_Clientes,
		SK_Geografia,
		SK_Partes,
		ID_Orden,
		ID_Cliente,
		ID_StatusOrden,
		ID_Descuento,
		ID_DetalleOrden,
		Total_Orden,
		PorcentajeDescuento,
		Cantidad,
		NombreDescuento,
		NombreStatus,
		Fecha_Orden,
		DateKey
	)
	SELECT 
		c.SK_Clientes,
		g.SK_Geografia,
		p.SK_Partes,
		o.ID_Orden,
		o.ID_Cliente,
		s.ID_StatusOrden,
		d.ID_Descuento,
		do.ID_DetalleOrden,
		o.Total_Orden,
		d.PorcentajeDescuento,
		do.Cantidad,
		d.NombreDescuento,
		s.NombreStatus,
		o.Fecha_Orden,
		f.DateKey
	FROM
	RepuestosWeb.dbo.Orden as o
	INNER JOIN RepuestosWeb.dbo.Detalle_orden as do
		ON(o.ID_Orden = do.ID_Orden)
	INNER JOIN RepuestosWeb.dbo.Descuento as d
		ON(do.ID_Descuento = d.ID_Descuento)
	INNER JOIN RepuestosWeb.dbo.StatusOrden as s 
		ON(o.ID_StatusOrden = s.ID_StatusOrden)
	--Referencias a DWH
	INNER JOIN Dimension.Clientes as c 
		ON(O.ID_Cliente = c.ID_Cliente)
	INNER JOIN Dimension.Geografia as g 
		ON(O.ID_Ciudad = g.ID_Ciudad)
	INNER JOIN Dimension.Partes as p 
		ON (do.ID_Partes = p.ID_Partes)
	INNER JOIN Dimension.Fecha as f 
		ON (CAST((CAST(YEAR(o.Fecha_Orden) AS VARCHAR(4)))+left('0'+CAST(MONTH(o.Fecha_Orden) AS VARCHAR(4)),2)+left('0'+(CAST(DAY(o.Fecha_Orden) AS VARCHAR(4))),2) AS INT) = f.DateKey)

	SELECT * FROM Fact.ID_Orden

*/