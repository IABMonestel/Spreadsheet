Use IrvinB
go

--01--SP que recorre empleados para agregar pagos al salario base
CREATE OR ALTER PROCEDURE SP_DETALLES_PAGOS(@Id_Empleado Varchar(12),@Salario_Base Decimal(10,2),
			@Categoria SmallInt,@Id_Detalle_Planilla Int, @Fecha_Ingreso DateTime)
AS

DECLARE @Salario_Bruto Decimal(10,2) = 0--Salario bruto del empleado
DECLARE @Categoria_Pago SmallInt --A que categoría se aplica el pago
DECLARE @CodigoPago Int --Código del Pago
DECLARE @Porcentaje Bit --Indica si es porcentaje
DECLARE @Monto_Pago Decimal(10,2) = 0--Monto del pago
DECLARE @Anualidad Bit --Indica si el rubro se paga por años laborados
DECLARE @AniosLaborados SmallInt = 0 --Anios laborados por el empleado
DECLARE @Carrera_Profesional Bit --Indica si el rubro es la carrera profesional
DECLARE @Puntos Int --Puntos de carrera profesional
--Obtener pagos en favor del empleado
BEGIN
	
	--Calcular anios laborados
	SET @AniosLaborados = DATEDIFF(DAY, @Fecha_Ingreso, GETDATE()) / 365
	print @AniosLaborados + @Fecha_Ingreso

	Declare pagos_cursor CURSOR FOR
	SELECT Codigo,Porcentaje,Monto,Categoria,Anualidad, Carrera_Profesional
	FROM TBL_Pagos
	WHERE Activo = 1

	OPEN pagos_cursor
	FETCH NEXT FROM pagos_cursor 
	INTO @CodigoPago, @Porcentaje, @Monto_Pago, @Categoria_Pago, @Anualidad, @Carrera_Profesional

	WHILE @@FETCH_STATUS = 0
	BEGIN		
		IF(@Monto_Pago != 0)
		BEGIN
			IF(@Categoria_Pago = @Categoria OR @Categoria_Pago = 0)
			BEGIN
				IF(@Porcentaje = 0)--no es porcentaje
					BEGIN
					IF((@Anualidad = 1) AND (@AniosLaborados >= 1))
						BEGIN
							INSERT INTO TBL_Detalle_Pagos(Codigo,Id_Historial,Monto)
							VALUES(@CodigoPago, @Id_Detalle_Planilla, ((@Monto_Pago)) * @AniosLaborados)
							SET @Salario_Bruto = @Salario_Bruto + ((@Monto_Pago) * @AniosLaborados)
						END
						ELSE
						BEGIN
							IF(@Anualidad = 0 AND @Carrera_Profesional = 0)
								BEGIN
								INSERT INTO TBL_Detalle_Pagos(Codigo,Id_Historial,Monto)
								VALUES(@CodigoPago, @Id_Detalle_Planilla, (@Monto_Pago))
								SET @Salario_Bruto = @Salario_Bruto + (@Monto_Pago)
							END
							ELSE 
								IF(@Carrera_Profesional = 1)
									BEGIN
										SET @Puntos = (SELECT Puntos_Carrera_Profesional FROM TBL_Empleados WHERE Id_Empleado = @Id_Empleado)
										IF(@Puntos > 0)
										BEGIN
											INSERT INTO TBL_Detalle_Pagos(Codigo,Id_Historial,Monto)
											VALUES(@CodigoPago, @Id_Detalle_Planilla, (@Monto_Pago*@Puntos))
											SET @Salario_Bruto = @Salario_Bruto + (@Monto_Pago*@Puntos)
										END
									END
						END
				END			
				ELSE--Es porcentaje
				BEGIN
					IF((@Anualidad = 1) AND (@AniosLaborados >= 1))
					BEGIN
						INSERT INTO TBL_Detalle_Pagos(Codigo,Id_Historial,Monto)
						VALUES(@CodigoPago, @Id_Detalle_Planilla, ((@Salario_Base * @Monto_Pago)) * @AniosLaborados)
						SET @Salario_Bruto = @Salario_Bruto + ((@Salario_Base * @Monto_Pago) * @AniosLaborados)
					END
					ELSE
					BEGIN
						IF(@Anualidad = 0)
						BEGIN
							INSERT INTO TBL_Detalle_Pagos(Codigo,Id_Historial,Monto)
							VALUES(@CodigoPago, @Id_Detalle_Planilla, (@Salario_Base * @Monto_Pago))
							SET @Salario_Bruto = @Salario_Bruto + (@Salario_Base * @Monto_Pago)
						END
					END
				END
			END
		END
		--Update
		UPDATE TBL_Detalle_Historial_Planillas SET Salario_Bruto = (@Salario_Bruto + @Salario_Base),
		Salario_Neto = (@Salario_Bruto + @Salario_Base) 
		WHERE Id_Detalle = @Id_Detalle_Planilla

		FETCH NEXT FROM pagos_cursor INTO @CodigoPago, @Porcentaje, @Monto_Pago, @Categoria_Pago, @Anualidad, @Carrera_Profesional
	END
	CLOSE pagos_cursor
	DEALLOCATE pagos_cursor	
END

go

--02--SP que recorre empleados para calcular deducciones
CREATE OR ALTER PROCEDURE SP_DETALLES_DEDUCCIONES(@Id_Empleado Varchar(12),@Salario_Bruto Decimal(10,2),
			@Categoria SmallInt,@Id_Detalle_Planilla Int, @Fecha_Ingreso DateTime)
AS

DECLARE @Categoria_Pago SmallInt --A que categoría se aplica el pago
DECLARE @CodigoPago Int --Código del Pago
DECLARE @Porcentaje Bit --Indica si es porcentaje
DECLARE @Monto_Pago Decimal(10,2) = 0--Monto del pago
DECLARE @Anualidad Bit --Indica si el rubro se paga por años laborados
DECLARE @AniosLaborados SmallInt --Anios laborados por el empleado
DECLARE @Total_Deducciones Decimal(10,2) = 0 --Monto a rebajar por deducciones

--Obtener deducciones del empleado
BEGIN
	
	--Calcular anios laborados
	SET @AniosLaborados = DATEDIFF(DAY, @Fecha_Ingreso, GETDATE()) / 365

	Declare pagos_cursor CURSOR FOR
	SELECT Codigo,Porcentaje,Monto,Categoria
	FROM TBL_Deducciones
	WHERE Activo = 1

	OPEN pagos_cursor
	FETCH NEXT FROM pagos_cursor 
	INTO @CodigoPago, @Porcentaje, @Monto_Pago, @Categoria_Pago

	WHILE @@FETCH_STATUS = 0
	BEGIN		
		IF(@Monto_Pago != 0)
		BEGIN
			IF(@Categoria_Pago = @Categoria OR @Categoria_Pago = 0)
			BEGIN
				IF(@Porcentaje = 0)
				BEGIN
					INSERT INTO TBL_Detalle_Deducciones(Codigo,Id_Historial,Monto)
					VALUES(@CodigoPago, @Id_Detalle_Planilla, @Monto_Pago)
					--SET @Salario_Bruto = @Salario_Bruto - @Monto_Pago
					SET @Total_Deducciones = @Total_Deducciones + @Monto_Pago
				END
			
				ELSE--Es porcentaje
				BEGIN
					IF(@Anualidad = 1 AND @AniosLaborados > 0)
					BEGIN
						INSERT INTO TBL_Detalle_Deducciones(Codigo,Id_Historial,Monto)
						VALUES(@CodigoPago, @Id_Detalle_Planilla, ((@Salario_Bruto * @Monto_Pago)) * @AniosLaborados)
						--SET @Salario_Bruto = @Salario_Bruto + ((@Salario_Bruto * @Monto_Pago) * @AniosLaborados)
						SET @Total_Deducciones = @Total_Deducciones + ((@Salario_Bruto * @Monto_Pago) * @AniosLaborados)
					END
					ELSE
					BEGIN
						INSERT INTO TBL_Detalle_Deducciones(Codigo,Id_Historial,Monto)
						VALUES(@CodigoPago, @Id_Detalle_Planilla, (@Salario_Bruto * @Monto_Pago))
						--SET @Salario_Bruto = @Salario_Bruto - (@Salario_Bruto* @Monto_Pago)
						SET @Total_Deducciones = @Total_Deducciones + (@Salario_Bruto * @Monto_Pago)
					END
				END
			END
		END
		--Update Salario_Neto = (@Salario_Bruto) 
		--UPDATE TBL_Detalle_Historial_Planillas SET Salario_Neto = (@Total_Deducciones - Salario_Neto) 
		--WHERE Id_Detalle = @Id_Detalle_Planilla

		FETCH NEXT FROM pagos_cursor INTO @CodigoPago, @Porcentaje, @Monto_Pago, @Categoria_Pago
	END
	CLOSE pagos_cursor
	DEALLOCATE pagos_cursor	

	--Update Salario_Neto = (@Salario_Bruto) 
	UPDATE TBL_Detalle_Historial_Planillas SET Salario_Neto = (Salario_Neto - @Total_Deducciones) 
	WHERE Id_Detalle = @Id_Detalle_Planilla
END

go

--03--SP Dias de incapacidad--Recalcula salario base si existen incapacidades
CREATE OR ALTER PROCEDURE SP_DIAS_INCAPACIDAD(@Id_Empleado Varchar(12), @Salario_Base Decimal(10,2)
			,@Id_Detalle_Planilla Int, @Mes SmallInt, @Anio SmallInt, @MENSAJE VARCHAR(500) OUT)
AS

DECLARE @Fecha_Inicio_Incapacidad DateTime --Fecha de inicio de la incapacidad
DECLARE @Fecha_Final_Incapacidad DateTime --Fecha de fin de la incapacidad
DECLARE @Total_Incapacidades Decimal(10,2) = 0--Fecha total de incapacidades
DECLARE @Dias_Incapacidad Int = 0
DECLARE @Mes_Sig Int = @Mes --en caso de que ingrese enero
DECLARE @Mes_TrasAnte Int = @Mes-2  --en caso de que ingrese enero

BEGIN	
	IF(@Mes = 1)
		BEGIN
			SET @Mes = 13
			SET @Anio = @Anio -1
			SET @Mes_Sig = 1
			SET @Mes_TrasAnte = @Mes - 2
		END
	IF(@Mes = 2)
		BEGIN
			SET @Mes_TrasAnte = 12
		END

	--Obtener dias de incapacidad
	Declare incapacidades_cursor CURSOR FOR
	SELECT Fecha_Inicio,Fecha_Final
	FROM TBL_Incapacidades
	WHERE Id_Empleado = @Id_Empleado --AND
	--MONTH(Fecha_Inicio) = (@Mes-1) OR MONTH(Fecha_Final) = (@Mes-1) OR 
	--(@Mes BETWEEN MONTH(Fecha_Inicio) AND MONTH(Fecha_Final)) AND
	--YEAR(Fecha_Inicio) = @Anio	

	OPEN incapacidades_cursor
	FETCH NEXT FROM incapacidades_cursor INTO @Fecha_Inicio_Incapacidad, @Fecha_Final_Incapacidad
	
	WHILE @@FETCH_STATUS = 0
	BEGIN		
		IF(DATEDIFF(DAY,@Fecha_Inicio_Incapacidad, @Fecha_Final_Incapacidad) > 3)--Más de tres días de incapacidad
		BEGIN--Incapacidad en el mismo inicio y fin mes
			IF(MONTH(@Fecha_Inicio_Incapacidad) = (@Mes-1) AND MONTH(@Fecha_Final_Incapacidad) = (@Mes-1))
				BEGIN
					SET @Total_Incapacidades = @Total_Incapacidades + ((1+DATEDIFF(DAY,@Fecha_Inicio_Incapacidad, @Fecha_Final_Incapacidad)) * 
					(@Salario_Base / 30))--Consultar por días que cuenta el dateDiff
				END
			--inicio un mes, fin en el siguiente
			IF(MONTH(@Fecha_Inicio_Incapacidad) = (@Mes-1) AND MONTH(@Fecha_Final_Incapacidad) = (@Mes_Sig))
				BEGIN
					SET @Dias_Incapacidad = (DAY(EOMONTH(@Fecha_Inicio_Incapacidad)) - DAY(@Fecha_Inicio_Incapacidad)) +1					
					SET @Total_Incapacidades = @Total_Incapacidades + (@Dias_Incapacidad * 
					(@Salario_Base / 30))--Consultar por días que cuenta el dateDiff
				END
			--incapacidad entre meses
			IF(MONTH(@Fecha_Inicio_Incapacidad) = (@Mes_TrasAnte) AND MONTH(@Fecha_Final_Incapacidad) = (@Mes_Sig+1))
				BEGIN
					SET @Salario_Base = 0
					--No Trabajó en todo el mes
				END
			--incapacidad fecha de inicio mes trasanterior
			IF(MONTH(@Fecha_Inicio_Incapacidad) = (@Mes_TrasAnte) AND MONTH(@Fecha_Final_Incapacidad) = (@Mes-1))
				BEGIN
					SET @Dias_Incapacidad = DAY(@Fecha_Final_Incapacidad)
					SET @Total_Incapacidades = @Total_Incapacidades + (@Dias_Incapacidad * 
					(@Salario_Base / 30))--Consultar por días que cuenta el dateDiff
				END
			--print 'irvin'
		END			
		SET @Dias_Incapacidad = 0
		FETCH NEXT FROM incapacidades_cursor INTO @Fecha_Inicio_Incapacidad, @Fecha_Final_Incapacidad
	END
	CLOSE incapacidades_cursor
	DEALLOCATE incapacidades_cursor
	SET @Salario_Base = @Salario_Base - @Total_Incapacidades
	UPDATE TBL_Detalle_Historial_Planillas SET Salario_Base = @Salario_Base WHERE Id_Detalle = @Id_Detalle_Planilla

	--SET @MENSAJE = CONVERT(VARCHAR(15),@Salario_Base)

	--print @MENSAJE 
END

go

--04--Calcular Renta SP_SP
CREATE OR ALTER PROCEDURE SP_RENTA(@Id_Empleado Varchar(12),@Salario_Bruto Decimal(10,2),
			@Id_Detalle_Planilla Int)
AS

DECLARE @CodigoPago Int --Código del Pago
DECLARE @Monto_Pago Decimal(10,2) = 0--Monto del pago
DECLARE @Total_Renta Decimal(10,2) = 0 --Monto total de renta
DECLARE @Monto_Inicial Decimal(10,2) = 0 --Monto Inicial del pago
DECLARE @Monto_Final Decimal(10,2) = 0 --Monto Final del pago

--Obtener rentas del empleado
BEGIN

	Declare renta_cursor CURSOR FOR
	SELECT Monto, Monto_Inicial, Monto_Final
	FROM TBL_Topes_Renta
	WHERE Activo = 1

	OPEN renta_cursor
	FETCH NEXT FROM renta_cursor 
	INTO @Monto_Pago, @Monto_Inicial, @Monto_Final

	WHILE @@FETCH_STATUS = 0
	BEGIN		
		IF(@Salario_Bruto > @Monto_Inicial)
		BEGIN
			IF(@Salario_Bruto > @Monto_Final)
			BEGIN
				SET @Total_Renta =  @Total_Renta + ((@Monto_Final - @Monto_Inicial) * @Monto_Pago)
			END
			ELSE
			BEGIN
				SET @Total_Renta =  @Total_Renta + ((@Salario_Bruto - @Monto_Inicial) * @Monto_Pago)
			END
		END		
		FETCH NEXT FROM renta_cursor 
		INTO @Monto_Pago, @Monto_Inicial, @Monto_Final
	END
	CLOSE renta_cursor 
	DEALLOCATE renta_cursor 

	IF(@Total_Renta > 0)
	BEGIN
		--Update
		UPDATE TBL_Detalle_Historial_Planillas SET Salario_Neto = (Salario_Neto - @Total_Renta) 
		WHERE Id_Detalle = @Id_Detalle_Planilla

		SET @CodigoPago = (SELECT Codigo FROM TBL_Deducciones WHERE Renta = 1)

		INSERT INTO TBL_Detalle_Deducciones(Codigo,Id_Historial,Monto)
			VALUES(@CodigoPago, @Id_Detalle_Planilla, @Total_Renta)
		
		--Reiniciar valor
		SET @Total_Renta = 0
	END
END

go

--05--Crear planilla ordinaria SP_SP
CREATE OR ALTER PROCEDURE SP_PLANILLA_ORDINARIA 
	
	@ANIO SMALLINT,--año de planilla
	@MES SMALLINT,--mes de planilla
	@MENSAJE VARCHAR(500) OUT --mensaje de salida

AS 

DECLARE @Id_Empleado Varchar(12)--Id del empleado
DECLARE @NombrePuesto Varchar(100)--Nombre de puesto del empleado
DECLARE @Salario_Base Decimal(10,2)--Salario Base del empleado
DECLARE @Categoria SmallInt--Categoría del empleado
DECLARE @Salario_Bruto Decimal(10,2) = 0 --Salario Bruto del empleado
DECLARE @Salario_Neto Decimal(10,2) = 0 --Salario Neto del empleado
DECLARE @CodigoPago Int --Código del Pago
DECLARE @Porcentaje Bit --Indica si es porcentaje
DECLARE @Monto_Pago Decimal(10,2) --Monto del pago
DECLARE @Categoria_Pago SmallInt --A que categoría se aplica el pago
DECLARE @Grado_Academico Varchar(30) --Grado académico de los títulos del empleado
DECLARE @Id_Empleado_Titulo Varchar(12) --Id del empleado del título
DECLARE @Puntos SmallInt = 0 --Contador de puntos
DECLARE @Total_Pensiones Decimal(10,2) = 0 --Monto total de pensiones que debe pagar el empleado
DECLARE @Fecha_Inicio_Incapacidad DateTime
DECLARE @Fecha_Final_Incapacidad DateTime
DECLARE @Fecha_Ingreso DateTime --Fecha ingreso del empleado
DECLARE @Total_Incapacidades Decimal(10,2) = 0 --Monto total de incapacidades que debe pagar el empleado
DECLARE @Total_Deducciones Decimal(10,2) = 0 --Monto total de deducciones que debe pagar el empleado
DECLARE @Return Int = -1 --Valor de retorno
DECLARE @Id_Planilla Int
DECLARE @Id_Detalle_Planilla Int
DECLARE @RC Int --Retorno Procedimiento
DECLARE @Bandera Bit = 0
DECLARE @Dias_Laborados Int = 0 --Días que trabajo el empleado
DECLARE @MENSAJE_I Varchar(500) --Mensaje de errores internos

--BEGIN TRY
IF EXISTS(SELECT 1 FROM TBL_Empleados WHERE Activo = 1 AND Id_Puesto IS NOT NULL)
BEGIN
IF NOT EXISTS(SELECT 1 FROM TBL_Historial_Planillas WHERE Mes = @MES AND Anio = @ANIO AND Ordinaria = 1 AND Anulada = 0)
BEGIN
--BEGIN TRANSACTION PLANILLA_ORDINARIA

	--Insertar Planilla nueva
	INSERT INTO TBL_Historial_Planillas(Anio, Mes, Cancelada)
	VALUES(@ANIO,@MES,0)
	SET @Id_Planilla = SCOPE_IDENTITY() 	
	
	DECLARE empleados_cursor CURSOR FOR
	SELECT Id_Empleado, Fecha_Ingreso, Puntos_Carrera_Profesional
	FROM TBL_Empleados
	WHERE Activo = 1 AND Id_Puesto IS NOT NULL--OJO
	--MONTH(Fecha_Ingreso) <= (MONTH(GETDATE())) AND

	OPEN empleados_cursor
	FETCH NEXT FROM empleados_cursor
	INTO @Id_Empleado, @Fecha_Ingreso, @Puntos

	WHILE @@FETCH_STATUS = 0
	BEGIN
		--Obtiene el nombre del puesto
		SET @NombrePuesto = (SELECT p.Nombre_Puesto FROM TBL_Empleados E INNER JOIN TBL_Puestos P ON
						E.Id_Puesto = p.Id_Puesto 
						WHERE E.Id_Empleado = @Id_Empleado)
		--Selecciona salario base del empleado
		SET @Salario_Base = (SELECT p.Salario_Base FROM TBL_Empleados E INNER JOIN TBL_Puestos P ON
						E.Id_Puesto = p.Id_Puesto
						WHERE E.Id_Empleado = @Id_Empleado)
		--Categoria del puesto
		SET @Categoria = (SELECT p.Categoria FROM TBL_Empleados E INNER JOIN TBL_Puestos P ON
						E.Id_Puesto = p.Id_Puesto
						WHERE E.Id_Empleado = @Id_Empleado)

		--Crear detalle historial para empleado
	
		INSERT INTO TBL_Detalle_Historial_Planillas(Id_Empleado,Id_Hist_Planilla,Salario_Base,Salario_Bruto,Salario_Neto,Nombre_Puesto)
		VALUES(@Id_Empleado,@Id_Planilla,@Salario_Base,0.00,0.00,@NombrePuesto)
		SET @Id_Detalle_Planilla = SCOPE_IDENTITY() 

		--//--
		--Incapacidades--Calcular solo si tiene fecha ingreso menor a fecha actual en el mismo mes
		IF((MONTH(@Fecha_Ingreso) = MONTH(GETDATE())) AND (YEAR(@Fecha_Ingreso) = YEAR(GETDATE())))
			BEGIN
				SET @Dias_Laborados = (DAY(EOMONTH(GETDATE())) - DAY(@Fecha_Ingreso))
				UPDATE TBL_Detalle_Historial_Planillas SET Salario_Base = (@Dias_Laborados * (Salario_Base / 30)) WHERE
				Id_Detalle = @Id_Detalle_Planilla
			END
		ELSE
			BEGIN--calcula incapacidades
				IF EXISTS(SELECT 1 FROM TBL_Incapacidades WHERE Id_Empleado = @Id_Empleado)
				BEGIN
					EXECUTE @RC = [dbo].[SP_DIAS_INCAPACIDAD] 
					   @Id_Empleado
					  ,@Salario_Base
					  ,@Id_Detalle_Planilla
					  ,@Mes
					  ,@Anio
					  ,@MENSAJE_I OUTPUT
				END
			END
		--//--
		SET @Salario_Base = (SELECT Salario_Base FROM TBL_Detalle_Historial_Planillas
						WHERE Id_Detalle = @Id_Detalle_Planilla)

		IF(@Salario_Base > 0)
		BEGIN
			SET @Bandera = 1
		END
		ELSE
		BEGIN
			SET @Bandera = 0
			SET @MENSAJE_I = 'Empleado con salario base 0 después de calcular incapacidades'
		END
		--//--
		--Pagos en favor del empleado
		IF(@Bandera = 1)
		BEGIN
		EXECUTE @RC = [dbo].[SP_DETALLES_PAGOS] 
			   @Id_Empleado
			  ,@Salario_Base
			  ,@Categoria
			  ,@Id_Detalle_Planilla
			  ,@Fecha_Ingreso
	
		END
		--Obtener salario bruto 
		SET @Salario_Bruto  = (SELECT Salario_Bruto FROM TBL_Detalle_Historial_Planillas WHERE Id_Empleado = @Id_Empleado AND Id_Detalle = @Id_Detalle_Planilla)

		--//--
		--Calcular Deducciones
		--Pensiones
		IF EXISTS(SELECT 1 FROM TBL_Pensiones WHERE Id_Empleado = @Id_Empleado)
			BEGIN
				SET @Total_Pensiones = (SELECT SUM(Monto) FROM TBL_Pensiones WHERE Id_Empleado = @Id_Empleado)
				--Insert Rubro
				SET @CodigoPago = (SELECT Codigo FROM TBL_Deducciones WHERE Pension = 1)
				INSERT INTO TBL_Detalle_Deducciones(Codigo,Id_Historial,Monto)
						VALUES(@CodigoPago, @Id_Detalle_Planilla, @Total_Pensiones)

				--Update--Monto pensiones
				UPDATE TBL_Detalle_Historial_Planillas SET Salario_Neto = @Salario_Bruto - @Total_Pensiones 
				WHERE Id_Detalle = @Id_Detalle_Planilla

			END		

		--Comprobar Neto después de rebajar pensión
		SET @Salario_Neto  = (SELECT Salario_Neto FROM TBL_Detalle_Historial_Planillas WHERE Id_Empleado = @Id_Empleado AND Id_Detalle = @Id_Detalle_Planilla)
		IF(@Salario_Neto > 0)
		BEGIN
			SET @Bandera = 1
		END
		ELSE
		BEGIN
			SET @Bandera = 0
			SET @MENSAJE_I = 'Empleado con salario base 0 después de rebajar pensión'
		END

		IF(@Bandera = 1)
		BEGIN
		--Obtener salario bruto 
		SET @Salario_Bruto  = (SELECT Salario_Bruto FROM TBL_Detalle_Historial_Planillas WHERE Id_Empleado = @Id_Empleado AND Id_Detalle = @Id_Detalle_Planilla)
		--Las demás deducciones
		EXECUTE @RC = [dbo].[SP_DETALLES_DEDUCCIONES] 
			   @Id_Empleado
			  ,@Salario_Bruto
			  ,@Categoria
			  ,@Id_Detalle_Planilla
			  ,@Fecha_Ingreso
		END

		--Comprobar Neto después de rebajar deducciones
		SET @Salario_Neto  = (SELECT Salario_Neto FROM TBL_Detalle_Historial_Planillas WHERE Id_Empleado = @Id_Empleado AND Id_Detalle = @Id_Detalle_Planilla)
		IF(@Salario_Neto > 0)
		BEGIN
			SET @Bandera = 1
		END
		ELSE
		BEGIN
			SET @Bandera = 0
			SET @MENSAJE_I = 'Empleado con salario base 0 después de calcular deducciones'
		END
		
		IF(@Bandera = 1)
		BEGIN
		--Obtener salario bruto 
		SET @Salario_Bruto  = (SELECT Salario_Bruto FROM TBL_Detalle_Historial_Planillas WHERE Id_Empleado = @Id_Empleado AND Id_Detalle = @Id_Detalle_Planilla)
		--Renta
		EXECUTE @RC = [dbo].[SP_RENTA] 
			   @Id_Empleado
			  ,@Salario_Bruto
			  ,@Id_Detalle_Planilla
		END
		ELSE
		BEGIN
		--concatenar mensajes de error
		SET @MENSAJE = CONCAT(@MENSAJE, ' Para empleado Id: ', @Id_Empleado , ' : ', @MENSAJE_I)
		END

		--Reiniciar valores
		SET @Salario_Neto = 0
		SET @Total_Deducciones = 0
		SET @Total_Pensiones = 0
		SET @Total_Incapacidades = 0
		SET @Salario_Bruto = 0
		FETCH NEXT FROM empleados_cursor
		INTO @Id_Empleado, @Fecha_Ingreso, @Puntos

	END
	CLOSE empleados_cursor
	DEALLOCATE empleados_cursor
	
	SET @Return = 0
	SET @MENSAJE = CONCAT(@MENSAJE,' --Planilla calculada con éxito-- ')
	
	--Fin transacción
--COMMIT TRANSACTION PLANILLA_ORDINARIA
END
ELSE
	SET @MENSAJE = 'ERROR en planilla ordinaria'
END
ELSE
BEGIN
SET @MENSAJE = 'ERROR, No hay empleados activos'
SET @Return = -1
END
RETURN @Return
--END TRY
--BEGIN CATCH
--	ROLLBACK TRANSACTION PLANILLA_ORDINARIA
--	SELECT @MENSAJE = 'ERROR en planilla ordinaria'
--	RETURN -1
--END CATCH

go

--Crear planilla extraordinaria
CREATE OR ALTER PROCEDURE SP_PLANILLA_EXTRAORDINARIA 
	
	@ANIO SMALLINT,
	@MES SMALLINT,
	@ID_EMPLEADO VARCHAR(12),
	@MENSAJE VARCHAR(1000) OUT

AS 

--DECLARE @Id_Empleado Varchar(12)--Id del empleado
DECLARE @NombrePuesto Varchar(100)--Nombre de puesto del empleado
DECLARE @Salario_Base Decimal(10,2)--Salario Base del empleado
DECLARE @Categoria SmallInt--Categoría del empleado
DECLARE @Salario_Bruto Decimal(10,2) = 0 --Salario Bruto del empleado
DECLARE @Salario_Neto Decimal(10,2) = 0 --Salario Neto del empleado
DECLARE @CodigoPago Int --Código del Pago
DECLARE @Porcentaje Bit --Indica si es porcentaje
DECLARE @Monto_Pago Decimal(10,2) --Monto del pago
DECLARE @Categoria_Pago SmallInt --A que categoría se aplica el pago
DECLARE @Grado_Academico Varchar(30) --Grado académico de los títulos del empleado
--DECLARE @Id_Empleado_Titulo Varchar(12) --Id del empleado del título
--DECLARE @Puntos SmallInt = 0 --Contador de puntos
DECLARE @Total_Pensiones Decimal(10,2) = 0 --Monto total de pensiones que debe pagar el empleado
DECLARE @Fecha_Inicio_Incapacidad DateTime
DECLARE @Fecha_Final_Incapacidad DateTime
DECLARE @Fecha_Ingreso DateTime --Fecha ingreso del empleado
DECLARE @Total_Incapacidades Decimal(10,2) = 0 --Monto total de incapacidades que debe pagar el empleado
DECLARE @Total_Deducciones Decimal(10,2) = 0 --Monto total de deducciones que debe pagar el empleado
DECLARE @Return Int = -1 --Valor de retorno
DECLARE @Id_Planilla Int
DECLARE @Id_Detalle_Planilla Int
DECLARE @RC Int --Retorno Procedimiento Interno
DECLARE @Bandera Bit = 0
DECLARE @Dias_Laborados Int = 0 --Días que trabajo el empleado
DECLARE @Activo Bit = 0 --Empleado activo 


BEGIN TRY--condicion
IF ((SELECT Count(*) FROM TBL_Empleados) > 0 )
BEGIN
	IF EXISTS(SELECT 1 FROM TBL_Historial_Planillas WHERE Mes = @MES AND Anio = @ANIO AND Ordinaria = 1 AND Anulada = 0 )
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM TBL_Historial_Planillas H Inner Join TBL_Detalle_Historial_Planillas DHP 
			ON H.Id_Historial = DHP.Id_Hist_Planilla 
			WHERE Anio = @ANIO AND Mes = @MES AND Id_Empleado = @ID_EMPLEADO AND Ordinaria = 1 AND Anulada = 0)

		BEGIN
		BEGIN TRANSACTION PLANILLA_EXTRAORDINARIA		
	
	--print @Id_Planilla
	--Selecciona datos de empleado
		SET @NombrePuesto = (SELECT p.Nombre_Puesto FROM TBL_Empleados E INNER JOIN TBL_Puestos P ON
						E.Id_Puesto = p.Id_Puesto 
						WHERE E.Id_Empleado = @Id_Empleado)

		SET @Salario_Base = (SELECT p.Salario_Base FROM TBL_Empleados E INNER JOIN TBL_Puestos P ON
						E.Id_Puesto = p.Id_Puesto
						WHERE E.Id_Empleado = @Id_Empleado)

		SET @Categoria = (SELECT p.Categoria FROM TBL_Empleados E INNER JOIN TBL_Puestos P ON
						E.Id_Puesto = p.Id_Puesto
						WHERE E.Id_Empleado = @Id_Empleado)

		SET @Fecha_Ingreso = (SELECT Fecha_Ingreso FROM TBL_Empleados WHERE Id_Empleado = @ID_EMPLEADO)

		--SET @Puntos = (SELECT Puntos_Carrera_Profesional FROM TBL_Empleados WHERE Id_Empleado = @ID_EMPLEADO)

		SET @Activo = (SELECT Activo FROM TBL_Empleados WHERE Id_Empleado = @ID_EMPLEADO)

		--Crear detalle historial para empleado
		IF(@Salario_Base IS NOT NULL AND @Activo = 1)
		BEGIN
		--Insertar Planilla nueva
		INSERT INTO TBL_Historial_Planillas(Anio, Mes, Ordinaria, Cancelada)
		VALUES(@ANIO,@MES,0,0)
		SET @Id_Planilla = SCOPE_IDENTITY() 

		INSERT INTO TBL_Detalle_Historial_Planillas(Id_Empleado,Id_Hist_Planilla,Salario_Base,Salario_Bruto,Salario_Neto,Nombre_Puesto)
		VALUES(@Id_Empleado,@Id_Planilla,@Salario_Base,0.00,0.00,@NombrePuesto)
		SET @Id_Detalle_Planilla = SCOPE_IDENTITY() 

		--//--
		--Incapacidades--Calcular solo si tiene fecha ingreso del mes actual y menor a dia actual
		IF((MONTH(@Fecha_Ingreso) = MONTH(GETDATE())) AND (YEAR(@Fecha_Ingreso) = YEAR(GETDATE())))
			BEGIN
				SET @Dias_Laborados = (DAY(EOMONTH(GETDATE())) - DAY(@Fecha_Ingreso))
				print @Dias_Laborados
				UPDATE TBL_Detalle_Historial_Planillas SET Salario_Base = (@Dias_Laborados * (Salario_Base / 30)) WHERE
				Id_Detalle = @Id_Detalle_Planilla
			END
		ELSE
			BEGIN
				EXECUTE @RC = [dbo].[SP_DIAS_INCAPACIDAD] 
				   @Id_Empleado
				  ,@Salario_Base
				  ,@Id_Detalle_Planilla
				  ,@Mes
				  ,@Anio
				  ,@MENSAJE OUTPUT
			END
		--//--Comprobar que tenga salario base
		SET @Salario_Base = (SELECT Salario_Base FROM TBL_Detalle_Historial_Planillas
						WHERE Id_Detalle = @Id_Detalle_Planilla)

		IF(@Salario_Base > 0)
		BEGIN
			SET @Bandera = 1
		END
		ELSE
		BEGIN
			SET @Bandera = 0
		END
		--//--
		--Pagos en favor del empleado
		IF(@Bandera = 1)
		BEGIN
		EXECUTE @RC = [dbo].[SP_DETALLES_PAGOS] 
			   @Id_Empleado
			  ,@Salario_Base
			  ,@Categoria
			  ,@Id_Detalle_Planilla
			  ,@Fecha_Ingreso
	
		END
		--Obtener salario bruto 
		SET @Salario_Bruto  = (SELECT Salario_Bruto FROM TBL_Detalle_Historial_Planillas WHERE Id_Empleado = @Id_Empleado AND Id_Detalle = @Id_Detalle_Planilla)

		--//--

		IF(@Salario_Bruto > 0)
		BEGIN
			SET @Bandera = 1
		END
		ELSE
		BEGIN
			SET @Bandera = 0
		END

		IF(@Bandera = 1)
		BEGIN
		--Calcular Deducciones
		--Pensiones
		IF EXISTS(SELECT 1 FROM TBL_Pensiones WHERE Id_Empleado = @Id_Empleado)
			BEGIN
				SET @Total_Pensiones = (SELECT SUM(Monto) FROM TBL_Pensiones WHERE Id_Empleado = @Id_Empleado)
				--Insert Rubro
				IF((@Salario_Bruto - @Total_Pensiones) >= 0 )--Comprueba que el salario cubra el gasto
				BEGIN
					SET @CodigoPago = (SELECT Codigo FROM TBL_Deducciones WHERE Pension = 1)
					INSERT INTO TBL_Detalle_Deducciones(Codigo,Id_Historial,Monto)
							VALUES(@CodigoPago, @Id_Detalle_Planilla, @Total_Pensiones)

					--Update--Monto pensiones
					UPDATE TBL_Detalle_Historial_Planillas SET Salario_Neto = (@Salario_Bruto - @Total_Pensiones) 
					WHERE Id_Detalle = @Id_Detalle_Planilla
				END
				ELSE
				BEGIN
					--Update--Monto pensiones
					UPDATE TBL_Detalle_Historial_Planillas SET Salario_Neto = 0 
					WHERE Id_Detalle = @Id_Detalle_Planilla
					SET @MENSAJE = -1--'ERROR, Salario bruto no cubre monto de pension. Restan: ' + (@Total_Pensiones - @Salario_Bruto)
					SET @Return = -1
				END
			END		
		END

		--Comprobar Neto después de rebajar pensión
		SET @Salario_Neto  = (SELECT Salario_Neto FROM TBL_Detalle_Historial_Planillas WHERE Id_Empleado = @Id_Empleado AND Id_Detalle = @Id_Detalle_Planilla)
		IF(@Salario_Neto > 0)
		BEGIN
			SET @Bandera = 1
		END
		ELSE
		BEGIN
			SET @Bandera = 0
		END

		IF(@Bandera = 1)
		BEGIN
		--Obtener salario bruto 
		SET @Salario_Bruto  = (SELECT Salario_Bruto FROM TBL_Detalle_Historial_Planillas WHERE Id_Empleado = @Id_Empleado AND Id_Detalle = @Id_Detalle_Planilla)
		--Las demás deducciones
		EXECUTE @RC = [dbo].[SP_DETALLES_DEDUCCIONES] 
			   @Id_Empleado
			  ,@Salario_Bruto
			  ,@Categoria
			  ,@Id_Detalle_Planilla
			  ,@Fecha_Ingreso
		END

		--Comprobar Neto después de rebajar deducciones
		SET @Salario_Neto  = (SELECT Salario_Neto FROM TBL_Detalle_Historial_Planillas WHERE Id_Empleado = @Id_Empleado AND Id_Detalle = @Id_Detalle_Planilla)
		IF(@Salario_Neto > 0)
		BEGIN
			SET @Bandera = 1
		END
		ELSE
		BEGIN
			SET @Bandera = 0
		END

		IF(@Bandera = 1)
		BEGIN
		--Obtener salario bruto 
		SET @Salario_Bruto  = (SELECT Salario_Bruto FROM TBL_Detalle_Historial_Planillas WHERE Id_Empleado = @Id_Empleado AND Id_Detalle = @Id_Detalle_Planilla)
		--Renta
		EXECUTE @RC = [dbo].[SP_RENTA] 
			   @Id_Empleado
			  ,@Salario_Bruto
			  ,@Id_Detalle_Planilla
		END
		IF(@Bandera = 1)
		BEGIN
			SET @Return = 0
			SET @MENSAJE = @Id_Planilla
		END
	END
		ELSE
		BEGIN
			SET @Return = -2
			SET @MENSAJE = -1--'Empleado no tiene puesto asignado'
		END
	--Fin transacción
		COMMIT TRANSACTION PLANILLA_EXTRAORDINARIA
		END
		ELSE
			SET @MENSAJE = -3--'ERROR en planilla ordinaria. Empleado incluido en planilla ordinaria.'
		END
	ELSE
	BEGIN
		SET @Return = -1
		SET @MENSAJE = -4--'ERROR, No Existe planilla ordinaria para mes y año '
	END
END
ELSE
BEGIN
	SET @MENSAJE = -5--'No hay empleados activos'
	SET @Return = -1
END
RETURN @Return
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION PLANILLA_EXTRAORDINARIA
	SELECT @MENSAJE = 'ERROR en planilla extraordinaria'
	RETURN -1
END CATCH

go

CREATE OR ALTER PROCEDURE SP_AIGNAR_PUESTO 
		@Id_Empleado Varchar(12)
		,@Id_Puesto SmallInt
		,@Mensaje Varchar(500) OUT AS

DECLARE @Grado Varchar(30) --Grado del empleado
DECLARE @Retorno Int = 0

BEGIN TRY
BEGIN TRANSACTION ASIGNAR_PUESTO

IF EXISTS(SELECT 1 FROM TBL_Puestos WHERE Activo = 1 AND Id_Puesto = @Id_Puesto)
	BEGIN
		SET @Grado = (SELECT Grado_Minimo FROM TBL_Puestos WHERE Id_Puesto = @Id_Puesto)
		IF(@Grado != 'Pre-Grado')--Se necesita comprobar carrera profesional
			BEGIN
			IF EXISTS(SELECT 1 FROM TBL_Titulos WHERE Grado_Academico = @Grado AND Id_Empleado = @Id_Empleado)
				BEGIN
					UPDATE TBL_Empleados SET Id_Puesto = @Id_Puesto WHERE Id_Empleado = @Id_Empleado
					SET @Mensaje = 'Puesto asignado con éxito'
				END
			ELSE
				BEGIN
					SET @Mensaje = 'Error, empleado no cumple requisitos'
					SET @Retorno = -1
				END
			END
		ELSE
		BEGIN
			UPDATE TBL_Empleados SET Id_Puesto = @Id_Puesto WHERE Id_Empleado = @Id_Empleado
			SET @Mensaje = 'Puesto asignado con éxito'
		END
	END
ELSE
BEGIN
	SET @Mensaje = 'Puesto no disponible'
	SET @Retorno = -1
END
COMMIT TRANSACTION
RETURN @Retorno
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION ASIGNAR_PUESTO
	SELECT @Mensaje = 'ERROR en Asignar Puesto'
	RETURN -1
END CATCH

go

--.Trigger actualizar puntos carrera profesional empleados agregar atestado    
CREATE OR ALTER TRIGGER TR_ACTUALIZAR_PUNTOS ON TBL_Titulos
 FOR INSERT

AS  
BEGIN
DECLARE @Grado Varchar(30)
DECLARE @Id_Empleado Varchar(12) 

DECLARE cursor_temp CURSOR FOR 
SELECT Id_Empleado, Grado_Academico 
FROM INSERTED

OPEN cursor_temp
FETCH NEXT FROM cursor_temp
INTO @Id_Empleado, @Grado 

WHILE (@@FETCH_STATUS = 0)
BEGIN--Asigna puntos según grado de atestado
	IF (@Grado = 'Pre-Grado')
	BEGIN
		UPDATE TBL_Empleados SET Puntos_Carrera_Profesional = (Puntos_Carrera_Profesional + 1) WHERE Id_Empleado = @Id_Empleado
	END
	
	IF(@Grado = 'Bachiller')
	BEGIN
		UPDATE TBL_Empleados SET Puntos_Carrera_Profesional = (Puntos_Carrera_Profesional + 2) WHERE Id_Empleado = @Id_Empleado
	END
		
	IF(@Grado = 'Licenciatura')
	BEGIN
		UPDATE TBL_Empleados SET Puntos_Carrera_Profesional = (Puntos_Carrera_Profesional + 3) 
		WHERE Id_Empleado = @Id_Empleado
	END
			
	IF(@Grado = 'Post-grado')
	BEGIN
		UPDATE TBL_Empleados SET Puntos_Carrera_Profesional = (Puntos_Carrera_Profesional + 4) WHERE Id_Empleado = @Id_Empleado
	END
				
FETCH NEXT FROM cursor_temp
INTO @Id_Empleado, @Grado 
END

CLOSE cursor_temp
DEALLOCATE cursor_temp

END

GO--empleados que pertenecen a una planilla
CREATE OR ALTER FUNCTION FN_EMPLEADOS_PLANILLA_ORDINARIA (
		@ID AS INT) RETURNS TABLE AS

RETURN (SELECT E.Id_Empleado, H.Id_Historial, H.Mes, H.Anio 

FROM TBL_Empleados E Left Join TBL_Detalle_Historial_Planillas DHP 
ON E.Id_Empleado = DHP.Id_Empleado Left Join TBL_Historial_Planillas H
ON DHP.Id_Hist_Planilla = H.Id_Historial

WHERE H.Id_Historial = @ID AND H.Ordinaria = 1 AND Anulada = 0
 )

GO
--los que no pertenecen a la planilla
--SELECT * from TBL_Empleados E Left Join FN_EMPLEADOS_PLANILLA_ORDINARIA(67) B
--ON E.Id_Empleado = B.Id_Empleado
--WHERE Id_Historial is NULL

--Puestos disponibles para un empleado según carrera profesional

--SELECT Id_Puesto, Nombre_Puesto, Categoria, Salario_Base, Activo, Grado_Minimo 
--FROM TBL_Puestos P Inner Join TBL_Titulos T
--ON P.Grado_Minimo = T.Grado_Academico 
--WHERE T.Id_Empleado = '206720526' AND P.Activo = 1
--GROUP BY Nombre_Puesto, Id_Puesto, Categoria, Salario_Base, Activo, Grado_Minimo