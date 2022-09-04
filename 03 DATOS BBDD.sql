--Datos

USE IrvinB

go

INSERT INTO TBL_Puestos(Nombre_Puesto,Categoria,Salario_Base, Grado_Minimo)
VALUES('Personal de apoyo',1,250000, 'Pre-Grado'),('Administrativo1',1,320000, 'Pre-Grado'),('Técnico Especializado',1,415000,'Pre-Grado'),
	('Administrativo2',2,500000, 'Bachiller'),('Profesional de apoyo',2,580000, 'Bachiller'),('Docente Licenciado',2,620000,'Licenciatura'),
	('Docente Master',2,750000,'Post-Grado'),('Jefe1',2,800000,'Licenciatura'),('Jefe2',2,950000,'Licenciatura'),('Director',2,1500000,'Licenciatura')

--INSERT INTO TBL_Empleados(Id_Empleado,Nombre,Apellido1,Apellido2,Telefono,Email,Provincia,Canton,Distrito,Dir_Exacta,
--	Fecha_Ingreso,Fecha_Nacimiento,Cuenta_Cliente, Id_Puesto)
--VALUES('204440444','Lorena','Enriquez','Orquídea','55555555','lorena@gmail.com','Alajuela','San Ramón','San Isidro','Casa amarilla',
--	'20200405','19900601','CR000000000000006',4),


--('208880888','Lucas','Leiva','Rodríguez','99999999','Lucas@gmail.com','Alajuela','Naranjo','Centro','Casa de Flores',
--	'20210305','19990601','CR000000000000009',9),

--('203330333','Marcia','Lobo','Chespi','44444444','marcia@gmail.com','Alajuela','San Ramón','Centro','Casa verde',
--	'20180123','19900601','CR000000000000005',3),

--('202220222','Juan','Rango','Figueres','33333333','juan@gmail.com','Alajuela','Central','Invu','Casa rosa',
--	'20190123','19900601','CR000000000000004',3),

--('201110111','Pedro','Murcia','Galapago','22222222','pedro@gmail.com','Alajuela','Naranjo','Centro','Casa verde',
--	'20210123','19700201','CR000000000000003',2),

--('101110111','Luis','López','Martinez','11111111','luis@gmail.com','Alajuela','Palmares','Centro','Casa amarilla',
--	'20220106','19800101','CR000000000000002',4),

--('206720526','Irvin','Benavides','Monestel','61327926','irvin@gmail.com','Alajuela','San Ramón','San Rafael','Casa de alto',
--	'20220223','19900601','CR000000000000001',1),

--('205550555','Mikol','Paez','Orquídea','1234134','Mikol@gmail.com','Alajuela','San Ramón','Volio','Casa Celeste',
--	'20200123','19930601','CR000000000000007',5),


--('207770777','Juan','Orquesta','Rancia','77777777','Juan@gmail.com','Alajuela','San Ramón','San Pedro','Casa bonita',
--	'20200305','19910601','CR000000000000008',10)
	
--INSERT INTO TBL_Titulos(Nombre,Institucion,Fecha,Grado_Academico,Id_Empleado)
--VALUES('Bachillerato en Administración','TEC','19961003','Bachiller','204440444'),
--	('Licenciatura en Administración','TEC','20001003','Licenciatura','204440444'),
--	('IT Essentials','Net Acad','20150303','Pre-Grado','206720526'),
--	('Bachillerato en Educación','UCR','20100103','Bachiller','101110111'),
--	('Manipulación de alimentos','INA','20000903','Pre-Grado','201110111'),
--	('Técnico en Electrónica','UTN','20121003','Pre-grado','203330333')

--INSERT INTO TBL_Pensiones(Id_Empleado,Monto)
--VALUES('204440444',80000),('204440444',80000),('101110111',80000),('201110111',80000)

--INSERT INTO TBL_Incapacidades(Id_Empleado,Fecha_Inicio,Fecha_Final)
--VALUES--('204440444','20220117','20220125'),('206720526','20220224','20220228'),
--('206720526','20211225','20220110'),('206720526','20220118','20220124'),
--('206720526','20211228','20220107')

INSERT INTO TBL_Pagos(Nombre,Porcentaje,Monto,Categoria,Anualidad, Carrera_Profesional)
VALUES('Anualidad',1,0.02,0,1,0),('EscalafónCat1',1,0.03,1,1,0),('EscalafónCat2',1,0.01,2,1,0),('Dedicación Exclusiva',1,0.30,2,0,0),
	('Carrera Profesional',0,2273,0,0,1)
	
INSERT INTO TBL_Deducciones(Nombre,Porcentaje,Monto,Categoria,Anualidad, Renta, Pension)
VALUES('Pension Alimenticia',0,0.00,0,0,0,1),('Renta',1,0,0,0,1,0)

INSERT INTO TBL_Deducciones(Nombre,Porcentaje,Monto,Categoria,Anualidad)
VALUES('Régimen de Pensiones del Magisterio',1,0.08,0,0),('Banco Popular',1,0.01,0,0),('CCSS',1,0.03,0,0),
	('Póliza de Vida',0,15450,0,0),('Colegio Profesional',0,5000,2,0)

INSERT INTO TBL_Topes_Renta(Nombre,Monto,Monto_Inicial,Monto_Final,Id_Deduccion)
VALUES('Renta Tope 1',0.10,842000,1236000,2),('Renta Tope 2',0.15,1236000,2169000,2),('Renta Tope 3',0.20,2169000,4337000,2),
	('Renta Tope 4',0.25,4337000,80000000,2)

