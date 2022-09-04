USE MASTER
go
--Crear base de datos Planilla
CREATE DATABASE IrvinB
go
--Cambiar directorio a base de datos Planilla
USE IrvinB
go
--Crear tabla Puestos
CREATE TABLE TBL_Puestos(
	Id_Puesto SmallInt IDENTITY(1,1) constraint PK_Puestos PRIMARY KEY,
	Nombre_Puesto Varchar(100) not null constraint UQ_NombrePuesto_Puestos UNIQUE,
	Categoria SmallInt not null constraint CK_Categoria check (Categoria BETWEEN 1 AND 2),--
	Salario_Base Decimal(10,2) not null constraint CH_SalarioBase check(Salario_Base > 0),
	Activo Bit not null default 1,
	Grado_Minimo Varchar(30) not null constraint CH_Grado_Minimo check(Grado_Minimo in
	('Bachiller','Pre-Grado','Licenciatura','Post-Grado'))
)

--Crear tabla Empleado
CREATE TABLE TBL_Empleados(
	Id_Empleado Varchar(12) constraint PK_Empleados primary key,
	Nombre Varchar(20) not null,
	Apellido1 Varchar(20) not null,
	Apellido2 Varchar(20) not null,
	Id_Puesto SmallInt, constraint FK_IdPuesto foreign key (Id_Puesto) references TBL_Puestos(Id_Puesto),
	Telefono Varchar(8) not null,
	Email Varchar(50) not null,
	Provincia Varchar(10) constraint CH_ProEmpleado check(Provincia in
	('San José','Alajuela','Heredia','Cartago','Guanacaste','Limón','Puntarenas')),
	Canton Varchar(25),
	Distrito Varchar(25),
	Dir_Exacta Varchar(80),
	Fecha_Ingreso Datetime not null constraint DF_Fecha_Ingreso default getDate(),
	--constraint CH_Fecha_Ingreso check(Fecha_Ingreso >= getDate()),
	Fecha_Nacimiento Datetime not null,
	Activo Bit not null default 1,
	Cuenta_Cliente Varchar(17) not null constraint UQ_Cuenta_Cliente UNIQUE,
	Puntos_Carrera_Profesional SmallInt not null constraint DF_Carrera_Profesional default 0
)

--Crear tabla títulos
CREATE TABLE TBL_Titulos(
	Id_Titulo Int IDENTITY(1,1) constraint PK_Titulos PRIMARY KEY,
	Nombre Varchar(100) not null,
	Institucion Varchar(30) not null,
	Fecha Datetime not null,
	Grado_Academico Varchar(30) not null constraint CH_Grado check(Grado_Academico in
	('Bachiller','Pre-Grado','Licenciatura','Post-Grado')),
	Id_Empleado Varchar(12), constraint FK_IdEmpleado foreign key (Id_Empleado) references TBL_Empleados(Id_Empleado)
)

--Crear tabla Pensiones
CREATE TABLE TBL_Pensiones(
	Codigo Int IDENTITY(1,1) constraint PK_Pensiones PRIMARY KEY,
	Id_Empleado Varchar(12), constraint FK_IdEmpleadoP foreign key (Id_Empleado) references TBL_Empleados(Id_Empleado),
	Monto Decimal(10,2) not null
)

--Crear tabla Incapacidades
CREATE TABLE TBL_Incapacidades(
	Codigo Int IDENTITY(1,1) constraint PK_Incapacidades PRIMARY KEY,
	Id_Empleado Varchar(12), constraint FK_IdEmpleadoI foreign key (Id_Empleado) references TBL_Empleados(Id_Empleado),
	Fecha_Inicio Datetime not null constraint DF_Fecha_Inicio default getDate(), 
	--constraint CH_Fecha_Inicio check(Fecha_Inicio >= getDate()),
	Fecha_Final Datetime not null 
)
--Check fecha final > fecha inicio
Alter table TBL_Incapacidades ADD CONSTRAINT CH_Fecha_Final
check (Fecha_Final > Fecha_Inicio)

--Crear tabla Rubros pagos
CREATE TABLE TBL_Pagos(
	Codigo Int IDENTITY(1,1) constraint PK_Pagos PRIMARY KEY,
	Nombre Varchar(50) not null constraint UQ_NombrePagos_Pagos UNIQUE,
	Porcentaje Bit not null constraint DF_Porcentaje default 0,
	Monto Decimal(10,2) not null constraint CH_Decimal check(Monto >= 0),
	Activo Bit not null constraint DF_Activo default 1,
	Categoria SmallInt not null constraint CH_Categoria_Pago check(Categoria Between 0 AND 2),
	--Indica a que categoria de empleado aplicar el rubro 0 general, 1 solo cat 1, o 2 solo cat 2 
	Anualidad Bit not null constraint DF_Pago_Anualidad default 0,
	Carrera_Profesional Bit not null constraint DF_Rubro_Carrera_Profesional default 0
)

--Crear tabla Rubros deducciones
CREATE TABLE TBL_Deducciones(
	Codigo Int IDENTITY(1,1) constraint PK_Deducciones PRIMARY KEY,
	Nombre Varchar(50) not null constraint UQ_NombreDeduc_Deduc UNIQUE,
	Porcentaje Bit not null constraint DF_PorcentajeDedu default 0,
	Monto Decimal(10,2) not null constraint CH_Monto check(Monto >= 0),
	Activo Bit not null constraint DF_ActivoDedu default 1,
	Categoria SmallInt not null constraint CH_Categoria_Dedu check(Categoria Between 0 AND 2),
	Anualidad Bit not null constraint DF_Pago_Deduccion default 0,
	Renta Bit constraint DF_Renta default 0,
	Pension Bit constraint DF_Pension default 0,
)

--Crear tabla Historial Planillas
CREATE TABLE TBL_Historial_Planillas(
	Id_Historial Int IDENTITY(1,1) constraint PK_Historial_Planilla PRIMARY KEY,
	Anio SmallInt not null constraint CH_Anio check(Anio Between YEAR(getdate()) AND YEAR(getDate()) + 1),
	Mes SmallInt not null constraint CH_Mes check(Mes Between MONTH(getdate()) and MONTH(getDate()) + 1),
	Ordinaria Bit not null constraint DF_Ordinaria default 1,
	Anulada Bit not null constraint DF_Anulada default 0,
	Cancelada Bit not null constraint DF_Cancelada default 0,
)

--Crear tabla Detalle Historial Planilla
CREATE TABLE TBL_Detalle_Historial_Planillas(
	Id_Detalle Int IDENTITY(1,1) constraint PK_Detalle_Planilla PRIMARY KEY,
	Id_Empleado Varchar(12), constraint FK_IdEmpleadoDet foreign key (Id_Empleado) references TBL_Empleados(Id_Empleado),
	Id_Hist_Planilla Int not null, constraint FK_Id_Hist_Pla foreign key (Id_Hist_Planilla) references TBL_Historial_Planillas(Id_Historial),
	Salario_Base Decimal(10,2) not null constraint CH_Salario_Base check(Salario_Base >= 0),
	Salario_Bruto Decimal(10,2) not null constraint CH_Salario_Bruto check(Salario_Bruto >= 0),
	Salario_Neto Decimal(10,2) not null constraint CH_Salario_Neto check(Salario_Neto >= 0),
	Nombre_Puesto Varchar(100) not null
)

--Crear tabla Detalle Pagos
CREATE TABLE TBL_Detalle_Pagos(
	Id_Detalle_Pago Int IDENTITY(1,1) constraint PK_Detalle_Pago PRIMARY KEY,
	Codigo Int, constraint FK_Codigo_Pago foreign key (Codigo) references TBL_Pagos(Codigo),
	Id_Historial Int not null, constraint FK_IdHist_Planilla foreign key (Id_Historial) references TBL_Detalle_Historial_Planillas(Id_Detalle),
	Monto Decimal(10,2) not null constraint CH_MontoPagos check(Monto >= 0)
)

--Crear tabla Detalle Deducciones
CREATE TABLE TBL_Detalle_Deducciones(
	Id_Detalle_Deduccion Int IDENTITY(1,1) constraint PK_Detalle_Deduccion PRIMARY KEY,
	Codigo Int, constraint FK_Codigo_Deduccion foreign key (Codigo) references TBL_Deducciones(Codigo),
	Id_Historial Int not null, constraint FK_IdHist_Planilla_Dedu foreign key (Id_Historial) references TBL_Detalle_Historial_Planillas(Id_Detalle),
	Monto Decimal(10,2) not null constraint CH_MontoDeducciones check(Monto > 0)
)

--Crear tabla topes de renta
CREATE TABLE TBL_Topes_Renta(
	Codigo Int IDENTITY(1,1) constraint PK_Topes_Renta PRIMARY KEY,
	Nombre Varchar(50) not null constraint UQ_Nombre_Tope UNIQUE,
	Monto Decimal(10,2) not null constraint CH_MontoRenta check(Monto >= 0),
	Activo Bit not null constraint DF_ActivoTope default 1,
	Monto_Inicial Decimal(10,2) not null constraint CH_TopeIRenta check(Monto_Inicial >= 0),
	Monto_Final Decimal(10,2) not null constraint CH_TopeFRenta check(Monto_Final >= 0),
	Id_Deduccion Int, constraint FK_Id_Deduccion foreign key (Id_Deduccion) references TBL_Deducciones(Codigo)
)