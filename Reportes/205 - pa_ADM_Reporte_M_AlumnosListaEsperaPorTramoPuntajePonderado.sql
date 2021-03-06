
/************************************************************
 * ROBERTO LARRONDE RYBERTT
 * Fecha: 11-10-2012 16:54:20
 ************************************************************/

-- EXEC pa_ADM_Reporte_M_AlumnosListaEsperaPorTramoPuntajePonderado NULL,'2501S',NULL

/****************************************************************************************/
/*
* MODIFICACIONES PROCESO 2015
* FECHA			: 04/08/2014
* AUTOR			: Alexanders Gutierrez Muñoz
* DESCRIPCION	: - Se setea periodo a 1, ya no se obtiene de funcion	
* 
* Modificaciones 2017
* fecha			: 05/12/2015	
* Autor			: Jorge Collao
* Descriipción	: saqué los if @usuario= null... else... y lo reemplacé por or (codcarr in... or @usuario is null)
* se agregó también el join con la tabla mt_Carrer_clasificacion, para obtener desde ahí las carreras vigentes del proceso en vez de sacarlas de la DB_ADMISIÓN
*/


ALTER PROCEDURE [matricula].[pa_ADM_Reporte_M_AlumnosListaEsperaPorTramoPuntajePonderado](
    @CODSEDE     VARCHAR(30) = NULL
   ,@CODCARR     VARCHAR(30) = NULL
   ,@USUARIO     VARCHAR(50) = NULL
)
AS
BEGIN
	DECLARE @ANOPROCESO         INT
	       ,@PERIODOPROCESO     INT
	
	SELECT @ANOPROCESO = MATRICULA.FN_OBTIENEANOPERIODO('A' ,'M')
	      ,@PERIODOPROCESO = 1
	
	--SET @CODSEDE = 'CONCEPCION'
	--SET @USUARIO = NULL --'jmrobles'
	

	    SELECT AMS.NOMBRE               AS SEDE
	          ,MCC.CODCARR
	          ,AMC.COD_DEMRE
	          ,AMC.NOMBRE
	          ,TOTAL = ISNULL(
	               (
	                   SELECT COUNT(CODCLI)
	                   FROM   ADM_DATOS_POSTULANTES ADP
	                   WHERE  ADP.CODCARR = AMC.CODCARR
	                          AND ADP.ESTADO = 'P'
	               )
	              ,0
	           )
	          ,[500 A 549.9] = (
	               SELECT COUNT(CODCLI)
	               FROM   ADM_DATOS_POSTULANTES ADP
	               WHERE  ADP.CODCARR = AMC.CODCARR
	                      AND ADP.ESTADO = 'P'
	                      AND ADP.POND BETWEEN 500.0 AND 549.9
	           )
	          ,[550 A 599.9] = (
	               SELECT COUNT(CODCLI)
	               FROM   ADM_DATOS_POSTULANTES ADP
	               WHERE  ADP.CODCARR = AMC.CODCARR
	                      AND ADP.ESTADO = 'P'
	                      AND ADP.POND BETWEEN 550.0 AND 599.9
	           )
	          ,[600 A 649.9] = (
	               SELECT COUNT(CODCLI)
	               FROM   ADM_DATOS_POSTULANTES ADP
	               WHERE  ADP.CODCARR = AMC.CODCARR
	                      AND ADP.ESTADO = 'P'
	                      AND ADP.POND BETWEEN 600.0 AND 649.9
	           )
	          ,[650 A 699.9] = (
	               SELECT COUNT(CODCLI)
	               FROM   ADM_DATOS_POSTULANTES ADP
	               WHERE  ADP.CODCARR = AMC.CODCARR
	                      AND ADP.ESTADO = 'P'
	                      AND ADP.POND BETWEEN 650.0 AND 699.9
	           )
	          ,[MAYOR A 700] = (
	               SELECT COUNT(CODCLI)
	               FROM   ADM_DATOS_POSTULANTES ADP
	               WHERE  ADP.CODCARR = AMC.CODCARR
	                      AND ADP.ESTADO = 'P'
	                      AND ADP.POND >= 700.0
	           )
	    FROM   MT_CARRER_CLASIFICACION  AS MCC
	           INNER JOIN MT_CARRER     AS MC
	                ON  MC.CODCARR = MCC.CODCARR
	           INNER JOIN ADM_MAE_SEDE AMS
	                ON  AMS.NOMBRE = MC.SEDE
	                    AND (AMS.NOMBRE = @CODSEDE OR @CODSEDE IS NULL)
	           INNER JOIN db_admision.dbo.ADM_MAE_CARRERA AMC
	                ON  AMC.CODCARR = MCC.CODCARR
	    WHERE  MCC.CODTIPO = 2	           
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
	           AMS.NOMBRE
	          ,AMC.CODCARR

	  
	  
END	        


