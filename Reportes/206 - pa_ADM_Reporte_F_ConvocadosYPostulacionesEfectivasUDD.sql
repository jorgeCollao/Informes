USE [matricula]
GO
/****** Object:  StoredProcedure [matricula].[pa_ADM_Reporte_F_ConvocadosYPostulacionesEfectivasUDD]    Script Date: 05-12-2016 10:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/************************************************************
 * ROBERTO LARRONDE RYBERTT
 * Fecha: 17-12-2012 9:42:45
 ************************************************************/

--EXEC pa_ADM_Reporte_F_ConvocadosYPostulacionesEfectivasUDD NULL,NULL, 'jmrobles'
--EXEC pa_ADM_Reporte_F_ConvocadosYPostulacionesEfectivasUDD 'CONCEPCION','1500C', NULL
--EXEC pa_ADM_Reporte_F_ConvocadosYPostulacionesEfectivasUDD 'CONCEPCION', NULL, 'JCOLLAO'

ALTER PROCEDURE [matricula].[pa_ADM_Reporte_F_ConvocadosYPostulacionesEfectivasUDD](
    @CODSEDE  VARCHAR(30) = NULL,
    @CODCARR  VARCHAR(30) = NULL,
    @USUARIO  VARCHAR(50) = NULL
)
AS
BEGIN
	DECLARE @ANOPROCESO      INT,
	        @PERIODOPROCESO  INT
	
	SELECT @ANOPROCESO = MATRICULA.FN_OBTIENEANOPERIODO('A', 'M'),
	       @PERIODOPROCESO = 1
	       
	       --@PERIODOPROCESO = MATRICULA.FN_OBTIENEANOPERIODO('P', 'M')
	
	--SET @USUARIO = 'jmrobles'
	
	SET @PERIODOPROCESO = 1
	
	

	    SELECT AMS.NOMBRE AS SEDE,
	           AMC.CODCARR,
	           AMC.COD_DEMRE,
	           AMC.NOMBRE,
	           MP.VACANTE_REGULAR AS CUPO_OFICIAL,
	           MP.VACANTE_SOBRECUPO AS SOBRECUPO,
	           MP.VACANTE_REGULAR + MP.VACANTE_SOBRECUPO AS CO_SC,
	           MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_CUENTACONVOCADOSLE(case amc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE amc.CODCARR END, 1, 0) AS CONVOCADOS,
	           LISTA_ESPERA = (
	               SELECT COUNT(ADP.CODCLI)
	               FROM   ADM_DATOS_POSTULANTES ADP
	               WHERE  ADP.CODCARR = case mc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE mc.CODCARR END
	                      AND ADP.ESTADO = 'P'
	                      AND ADP.POND >= 500.0
	           ),
	           MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_CUENTACONVOCADOSLE(case amc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE amc.CODCARR END, 1, 1) AS POST_EFECTIVAS,
	           POST_X_CUPO = (
	               CASE 
	                    WHEN MP.VACANTE_REGULAR > 0 THEN (
	                             SELECT CAST(
	                                        CAST(COUNT(ADP.CODCLI) AS FLOAT) / CAST(MP.VACANTE_REGULAR AS FLOAT) AS DECIMAL(4, 1)
	                                    )
	                             FROM   ADM_DATOS_POSTULANTES ADP
	                             WHERE  ADP.CODCARR = case mc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE mc.CODCARR END
	                         )
	                    ELSE 0
	               END
	           ),
	           PTJE_POND_PRIMER_CONV = ISNULL(
	               (
	                   SELECT MAX(ADP.POND)
	                   FROM   ADM_DATOS_POSTULANTES ADP
	                   WHERE  ADP.CODCARR = case mc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE mc.CODCARR END
	                          AND ADP.ESTADO = 'A'
	               ),
	               NULL
	           ),
	           --CASE WHEN MP.PTJEPONDANTERIOR > 0 THEN MP.PTJEPONDANTERIOR ELSE NULL END  AS PTJE_POND_ULT_CONV, 
	           PTJE_POND_ULT_CONV = ISNULL(
	               (
	                   SELECT MIN(ADP.POND)
	                   FROM   ADM_DATOS_POSTULANTES ADP
	                   WHERE  ADP.CODCARR = case mc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE mc.CODCARR END
	                          AND ADP.ESTADO = 'A'
	               ),
	               NULL
	           ),
	           CASE WHEN MP.PTJEPONDANTERIOR > 0 THEN MP.PTJEPONDANTERIOR ELSE NULL END AS PJE_ULTIMO_MATRICULADO
	    FROM  
			 MT_CARRER_CLASIFICACION  AS MCC
			 INNER JOIN MT_CARRER     AS MC
	                ON  MC.CODCARR = MCC.CODCARR
	         INNER JOIN ADM_MAE_SEDE AMS
	                ON  AMS.NOMBRE = MC.SEDE
	                    AND (AMS.NOMBRE = @CODSEDE OR @CODSEDE IS NULL)       
	         INNER JOIN [DB_aDMISION].DB_ADMISION.DBO.ADM_MAE_CARRERA AMC
	                ON  AMC.CODCARR = MCC.CODCARR	                       
			 LEFT JOIN MT_PJECORTEPONDERADOCARRERA MP
	                ON      MP.CODCARR = MCC.CODCARR
	                    AND MP.ANO = @ANOPROCESO
	                    AND MP.PERIODO = @PERIODOPROCESO
	    WHERE  
			  MCC.CODTIPO = 2	           
	           AND @ANOPROCESO BETWEEN MCC.ANO_INI AND MCC.ANO_FIN
	           AND (MCC.CODCARR = @CODCARR OR @CODCARR IS NULL) 	          
	           AND (MC.SEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND (
	                   MCC.CODCARR IN (SELECT AUAC.CODCARR
	                                   FROM   ADM_USUARIO_ASIGNACION_CARRERA AUAC
	                                   WHERE  AUAC.CODCARR = AMC.CODCARR
	                                          AND AUAC.ID_USUARIO = @USUARIO)
	                   OR @USUARIO IS NULL
	               )
	    ORDER BY
	           AMS.NOMBRE,
	           AMC.CODCARR
	
END


