/************************************************************
 * DESCRIPCIÓN			: REALIZA LA CARGA DE DATOS HISTÓRICOS QUE ALIMNETAN
 *							AL REPORTE DEL RECTOR
 * SE USA EN			: SISTEMA DE REPORTES, DEBE GATILLARSE MANUALMENTE							
 * AUTOR				: JORGE COLLAO QUEZADA							 
 * FECHA				: 12-10-2016 12:15:38
 ************************************************************/
ALTER  PROCEDURE pa_ADM_Reporte_Rector_CargaDatosHistoricosDePeriodo(@DIAUNO DATETIME ,@AÑO INT ,@CODCARR VARCHAR(30) = NULL)
AS
BEGIN
	IF @AÑO < 2016
	BEGIN
	    SELECT 'NO HAY DATOS HISTORICOS ANTES DEL 2016'
	END
	ELSE
	BEGIN

	DECLARE @FECHA_BISIESTO VARCHAR(6)
	
	SET @FECHA_BISIESTO = (
	        CASE 
	             WHEN @AÑO % 400 = 0 THEN '29-02-'-- 'Año Bisiesto'
	             WHEN @AÑO % 100 = 0 THEN '28-02-'--'Año NO Bisiesto'
	             WHEN @AÑO % 4 = 0 THEN '29-02-'--'Año Bisiesto'
	             ELSE '28-02-'--'Año NO Bisiesto'
	        END
	    )


	    DELETE 
	    FROM   ADM_HISTORICO_POR_DIA
	    WHERE  ANO = @AÑO
	    AND (CODCARR=@CODCARR OR @CODCARR IS NULL)
	    

	    INSERT INTO ADM_HISTORICO_POR_DIA
	    SELECT T.DIA
			,T.FECHA
			,T.AÑO
			,T.PERIODO
	    	,T.CODCARPR
	    	,T.HORA_INI
	    	,T.HORA_FIN
	    	,T.MATRICULADOS_PSU
	    	,T.MATRICULADOS_AE
	    	,T.MATRICULADOS_PSU+T.MATRICULADOS_BACH AS MATRICULADOS_TOTAL
	    	,T.MATRICULADOS_BACH
	    	,T.CODSEDE
	    	,T.MATRICULADOS_PSU_CIERRE
	    	,T.MATRICULADOS_AE_CIERRE
	    	,T.MATRICULADOS_BACH_CIERRE 
	    FROM 
	    (
	    SELECT DISTINCT(
	               SELECT CASE 
	                           WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) <= 0 THEN 1
	                           ELSE DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) + 1
	                      END
	           )                         AS DIA
	          ,CASE 
	                WHEN DATEDIFF(DAY ,@DIAUNO ,m.FECHA_REGISTRO) <= 0 THEN CONVERT(VARCHAR(10) ,@diauno ,103)
	                ELSE CONVERT(VARCHAR(10) ,m.FECHA_REGISTRO ,103)
	           END                       AS FECHA
	          ,@AÑO                      AS AÑO
	          ,1                         AS PERIODO
	          ,case A.CODCARPR 
				WHEN '1632S' THEN '1633S'
				WHEN '1631S' THEN '1635S'
				ELSE a.CODCARPR
				END AS CODCARPR 
	          
	          ,(
	               SELECT CASE 
	                           WHEN M.FECHA_REGISTRO <= @DIAUNO THEN '00:00'
	                           ELSE CASE 
	                                     WHEN DATEPART(hour ,m.fecha_registro) < 10 THEN '0'
	                                     ELSE ''
	                                END + CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M.FECHA_REGISTRO)) + ':00'
	                      END
	           )                         AS HORA_INI
	          ,(
	               SELECT CASE 
	                           WHEN M.FECHA_REGISTRO <= @DIAUNO THEN '00:59'
	                           ELSE CASE 
	                                     WHEN DATEPART(hour ,m.fecha_registro) < 10 THEN '0'
	                                     ELSE ''
	                                END + CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M.FECHA_REGISTRO)) + ':59'
	                      END
	           )                         AS HORA_FIN
	          ,(-----------------------------------------------------------------------------------------------------------------------------
	               SELECT COUNT(CODCLI)
	               FROM   (
	                          SELECT distinct (A1.CODCLI)
	                          FROM   MT_ALUMNO A1
	                                 INNER JOIN MT_MATRICULAS AS M1
	                                      ON  M1.CODCLI = A1.CODCLI
	                                          AND M1.ITEM = 1
	                                          AND M1.REMATRICULA IS NULL
	                                          AND M1.ANO = A1.ANO
	                       			LEFT JOIN MT_ALUMNO_CAMBIOVIAADMISION AS mac 
										ON mac.CODCLI = A1.CODCLI         
	                                INNER JOIN MT_VIADMISION AS V
	                                      ON V.COD_VIA = CASE 
																WHEN isnull(mac.COD_VIA_ANTERIOR,0)=0 THEN a1.COD_VIA 
																ELSE
																	CASE 
																		WHEN DATEDIFF(DAY,m1.FECHA_REGISTRO,mac.FECHA_CAMBIO)>=0 THEN mac.COD_VIA_ANTERIOR 
																												                ELSE mac.COD_VIA 
																	END
															END            
	                                          AND V.CODTIPOADMISION = 1
	                --                          AND m1.CODCLI  NOT IN (SELECT RS.CODCLI
																	--FROM   RA_SITU AS RS
																	--		INNER JOIN RA_TIPOSITU AS RT
																	--			ON  RS.TIPOSITU = RT.CODIGO
																	--				AND rs.EMISION <= '20-01-' + LTRIM(CONVERT(VARCHAR ,@AÑO))
																	--WHERE  RT.ESTACAD IN ('ELIMINADO' ,'TITULADO' ,'RETRACTADO' ,'EGRESADO')
																	--		AND 
																	--			(
																	--				M.FECHA_REGISTRO > RS.FECHAREG
																	--				OR
																	--				(
																	--				M.FECHA_REGISTRO=RS.FECHAREG AND DATEPART(HOUR,M.FECHA_REGISTRO)>=DATEPART(HOUR,RS.FECHAREG)		
																	--				)
																	--			)																			
																	--)   
               
	                          WHERE  A1.ANO = @AÑO
	                                 AND A1.PERIODO = 1
	                                 AND A1.CODCARPR = A.CODCARPR
	                                 AND M1.FECHA_REGISTRO <= @FECHA_BISIESTO + LTRIM(RTRIM(STR(@AÑO)))--*
	                                 AND CASE 
	                                          WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) <= 0 THEN 1
	                                          ELSE DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO)+1
	                                     END = CASE 
	                                                WHEN DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO) <= 0 THEN 1
	                                                ELSE DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO)+1
	                                           END
	                                 AND CASE 
	                                          WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) < 0 THEN '00:00'
	                                          ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M.FECHA_REGISTRO))
	                                     END + ':00' = CASE 
	                                                        WHEN DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO) < 0 THEN '00:00'
	                                                        ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M1.FECHA_REGISTRO))
	                                                   END + ':00'
	                                         
	                           
									 

	                      )T
	           )  AS MATRICULADOS_PSU---------------------------------------------------------------------------------------------------------
	          ,(
	               SELECT COUNT(A1.CODCLI)
	               FROM   MT_ALUMNO A1
	                      INNER JOIN MT_MATRICULAS AS M1
	                           ON  M1.CODCLI = A1.CODCLI
	                               AND M1.ITEM = 1
	                               AND M1.REMATRICULA IS NULL
	                               AND M1.ANO = A1.ANO
	                --               AND m1.CODCLI  NOT IN (SELECT RS.CODCLI
																	--FROM   RA_SITU AS RS
																	--		INNER JOIN RA_TIPOSITU AS RT
																	--			ON  RS.TIPOSITU = RT.CODIGO
																	--				AND rs.EMISION <= '20-01-' + LTRIM(CONVERT(VARCHAR ,@AÑO))
																	--WHERE  RT.ESTACAD IN ('ELIMINADO' ,'TITULADO' ,'RETRACTADO' ,'EGRESADO')
																	--		AND 
																	--			(
																	--				m1.fecha_registro > rs.FECHAREG
																	--				OR
																	--				(
																	--					m1.fecha_registro=rs.FECHAREG AND DATEPART(hour,m1.fecha_registro)>=DATEPART(hour,rs.FECHAREG)		
																	--				)
																	--			)
																			
																	--)   
						 LEFT JOIN MT_ALUMNO_CAMBIOVIAADMISION AS mac 
							   ON mac.CODCLI = A1.CODCLI         									       	                               
	               WHERE  A1.ANO = @AÑO
	                      AND A1.PERIODO = 1
	                      AND A1.CODCARPR = A.CODCARPR
	                      AND CASE 
	                               WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) <= 0 THEN 1
	                               ELSE DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO)+1
	                          END = CASE 
	                                     WHEN DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO) <= 0 THEN 1
	                                     ELSE DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO)+1
	                                END
	                      AND CASE 
	                               WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) < 0 THEN '00:00'
	                               ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M.FECHA_REGISTRO))
	                          END + ':00' = CASE 
	                                             WHEN DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO) < 0 THEN '00:00'
	                                             ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M1.FECHA_REGISTRO))
	                                        END + ':00'
						 AND CASE 
											WHEN isnull(mac.COD_VIA_ANTERIOR,0)=0 THEN a1.COD_VIA 
												ELSE
													CASE 
														WHEN DATEDIFF(DAY,m1.FECHA_REGISTRO,mac.FECHA_CAMBIO)>0 THEN mac.COD_VIA_ANTERIOR 
														ELSE mac.COD_VIA 
													END
									END  IN (10
											,24
											,33
											,41
											,44
											,45
											,46
											,47
											,51
											,36
											,20
											,22
											,23
											,25
											,26
											,8
											,28										
									)  	                                        	                   
	                      
	                      
	                      
	           )                         AS MATRICULADOS_AE

	          ,(
	          	
	          	SELECT COUNT(A1.CODCLI)
	               FROM   MT_ALUMNO A1
	                      INNER JOIN MT_MATRICULAS AS M1
	                           ON  M1.CODCLI = A1.CODCLI
	                               AND M1.ITEM = 1
	                               AND M1.REMATRICULA IS NULL
	                               AND M1.ANO = A1.ANO	                                
						 LEFT JOIN MT_ALUMNO_CAMBIOVIAADMISION AS mac 
							   ON mac.CODCLI = A1.CODCLI         
									AND CASE 
											WHEN isnull(mac.COD_VIA_ANTERIOR,0)=0 THEN a1.COD_VIA 
												ELSE
													CASE 
														WHEN DATEDIFF(DAY,m1.FECHA_REGISTRO,mac.FECHA_CAMBIO)>0  /*AND DATEPART(HOUR,MAC.FECHA_CAMBIO)<DATEPART(DAY,M1.FECHA_REGISTRO) */   THEN mac.COD_VIA_ANTERIOR 
														ELSE mac.COD_VIA 
													END
									END  = 19 
									--AND m1.CODCLI  NOT IN (SELECT RS.CODCLI
									--								FROM   RA_SITU AS RS
									--										INNER JOIN RA_TIPOSITU AS RT
									--											ON  RS.TIPOSITU = RT.CODIGO
									--												AND rs.EMISION <= '20-01-' + LTRIM(CONVERT(VARCHAR ,@AÑO))
									--								WHERE  RT.ESTACAD IN ('ELIMINADO' ,'TITULADO' ,'RETRACTADO' ,'EGRESADO')
									--										AND 
									--											(
									--												m.fecha_registro > rs.FECHAREG
									--												OR
									--												(
									--												m.fecha_registro=rs.FECHAREG AND DATEPART(hour,m.fecha_registro)>=DATEPART(hour,rs.FECHAREG)		
									--												)
									--											)
																			
									--								)         	                               
	               WHERE  A1.ANO = @AÑO
	                      AND A1.PERIODO = 1
	                      AND A1.CODCARPR = A.CODCARPR
	                      AND M1.FECHA_REGISTRO <= @FECHA_BISIESTO + LTRIM(RTRIM(STR(@AÑO)))--*
	                      AND CASE 
	                               WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) <= 0 THEN 1
	                               ELSE DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO)+1
	                          END = CASE 
	                                     WHEN DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO) <= 0 THEN 1
	                                     ELSE DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO)+1
	                                END
	                      AND CASE 
	                               WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) < 0 THEN '00:00'
	                               ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M.FECHA_REGISTRO))
	                          END + ':00' = CASE 
	                                             WHEN DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO) < 0 THEN '00:00'
	                                             ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M1.FECHA_REGISTRO))
	                                        END + ':00'
	              
	           )                         AS MATRICULADOS_BACH
	          ,A.CODSEDE
	           
	           --------------------------------------------------------
	          ,(
	               SELECT COUNT(CODCLI)
	               FROM   (
	                          SELECT (A1.CODCLI)
	                          FROM   MT_ALUMNO A1
	                                 INNER JOIN MT_MATRICULAS AS M1
	                                      ON  M1.CODCLI = A1.CODCLI
	                                          AND M1.ITEM = 1
	                                          AND M1.REMATRICULA IS NULL
	                                          AND M1.ANO = A1.ANO
	                                 INNER JOIN MT_VIADMISION AS V
	                                      ON  V.COD_VIA = A1.COD_VIA
	                                          AND V.CODTIPOADMISION = 1
	                          WHERE  A1.ANO = @AÑO
	                                 AND A1.PERIODO = 1
	                                 AND A1.CODCARPR = A.CODCARPR
	                                 AND M.FECHA_REGISTRO <= @FECHA_BISIESTO + LTRIM(RTRIM(STR(@AÑO)))
	                          
	                          
	                          UNION
	                          
	                          
	                          SELECT (A1.CODCLI)
	                          FROM   MT_ALUMNO A1
	                                 INNER JOIN MT_MATRICULAS AS M1
	                                      ON  M1.CODCLI = A1.CODCLI
	                                          AND M1.ITEM = 1
	                                          AND M1.REMATRICULA IS NULL
	                                          AND M1.ANO = A1.ANO
	                          WHERE  A1.ANO = @AÑO
	                                 AND A1.PERIODO = 1
	                                 AND A1.CODCARPR = A.CODCARPR
	                                 AND M.FECHA_REGISTRO <= @FECHA_BISIESTO + LTRIM(RTRIM(STR(@AÑO)))
	                                 AND A1.COD_VIA = 29
	                      )T
	           )  AS MATRICULADOS_PSU_CIERRE -->falta corregir esto para que considere las mismas restricciones de retractados y cambios de vía sólo suma el total de las matriculas
	          ,(
	               SELECT COUNT(A1.CODCLI)
	               FROM   MT_ALUMNO A1
	                      INNER JOIN MT_MATRICULAS AS M1
	                           ON  M1.CODCLI = A1.CODCLI
	                               AND M1.ITEM = 1
	                               AND M1.REMATRICULA IS NULL
	                               AND M1.ANO = A1.ANO
	               WHERE  A1.ANO = @AÑO
	                      AND A1.PERIODO = 1
	                      AND A1.CODCARPR = A.CODCARPR
	                      AND M.FECHA_REGISTRO <= '30-04-' + LTRIM(RTRIM(STR(@AÑO)))
	                      AND A1.COD_VIA IN (10
	                                        ,24
	                                        ,33
	                                        ,41
	                                        ,44
	                                        ,45
	                                        ,46
	                                        ,47
	                                        ,51
	                                        ,36
	                                        ,20
	                                        ,22
	                                        ,23
	                                        ,25
	                                        ,26
	                                        ,8
	                                        ,28)
	           )                         AS MATRICULADOS_AE_CIERRE -->falta corregir esto para que considere las mismas restricciones de retractados y cambios de vía sólo suma el total de las matriculas
	          ,(
	               SELECT COUNT(A1.CODCLI)
	               FROM   MT_ALUMNO A1
	                      INNER JOIN MT_MATRICULAS AS M1
	                           ON  M1.CODCLI = A1.CODCLI
	                               AND M1.ITEM = 1
	                               AND M1.REMATRICULA IS NULL
	                               AND M1.ANO = A1.ANO
	               WHERE  A1.ANO = @AÑO
	                      AND A1.PERIODO = 1
	                      AND A1.CODCARPR = A.CODCARPR
	                      AND M1.FECHA_REGISTRO <= '30-04-' + LTRIM(RTRIM(STR(@AÑO)))
	                      AND A1.COD_VIA = 19
	           )                         AS MATRICULADOS_BACH_CIERRE -->falta corregir esto para que considere las mismas restricciones de retractados y cambios de vía sólo suma el total de las matriculas
	    FROM   MT_ALUMNO                 AS A
	           INNER JOIN MT_MATRICULAS  AS M
	                ON  M.CODCLI = A.CODCLI
	                    AND M.ITEM = 1
	                    AND M.REMATRICULA IS NULL
	                    AND M.ANO = A.ANO
	                    AND m.PERIODO=1
	           INNER JOIN MT_CARRER_CLASIFICACION AS mcc 
					ON a.CODCARPR=mcc.CODCARR
						AND mcc.CODTIPO=2
						AND a.ANO BETWEEN mcc.ANO_INI AND mcc.ANO_FIN		  		
	    WHERE  A.ANO = @AÑO
	           AND A.PERIODO = 1
	           AND A.PERIODO_MAT = A.PERIODO
	           AND (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           	                     
	    )
	    T
	    
	    /*
	     * ELIMINA LOS RETRACTADOS
	     */
	    
	    
	    
	    DECLARE @RETRACTADOS TABLE(
		            DIA INT
		           ,FECHA DATETIME
		           ,AÑO INT
		           ,PERIODO INT
		           ,CODCARR VARCHAR(50)
		           ,HORA_INI VARCHAR(5)
		           ,HORA_FIN VARCHAR(5)
		           ,CANTIDAD INT
		           ,AE INT
		           ,BACH INT
		        )
	    

	    INSERT INTO @RETRACTADOS
	    SELECT T1.DIA
			,T1.FECHA
			,T1.AÑO
			,T1.PERIODO
	    	,T1.CODCARPR
	    	,T1.HORA_INI
	    	,T1.HORA_FIN
	    	,T1.MATRICULADOS_PSU
	    	,T1.AE
	    	,T1.BACH
	    	
	    	

	    FROM 
	    (
	    SELECT DISTINCT(
	               SELECT CASE 
	                           WHEN DATEDIFF(DAY ,@DIAUNO ,R.FECHAREG) <= 0 THEN 1
	                           ELSE DATEDIFF(DAY ,@DIAUNO ,R.FECHAREG) + 1
	                      END
	           )                         AS DIA
	          ,CASE 
	                WHEN DATEDIFF(DAY ,@DIAUNO ,R.FECHAREG) <= 0 THEN CONVERT(VARCHAR(10) ,@diauno ,103)
	                ELSE CONVERT(VARCHAR(10) ,R.FECHAREG ,103)
	           END                       AS FECHA
	          ,@AÑO                      AS AÑO
	          ,1                         AS PERIODO
	          ,case A.CODCARPR 
				WHEN '1632S' THEN '1633S'
				WHEN '1631S' THEN '1635S'
				ELSE a.CODCARPR
				END AS CODCARPR 
	          
	          ,(
	               SELECT CASE 
	                           WHEN R.FECHAREG <= @DIAUNO THEN '00:00'
	                           ELSE CASE 
	                                     WHEN DATEPART(hour ,R.FECHAREG) < 10 THEN '0'
	                                     ELSE ''
	                                END + CONVERT(VARCHAR(5) ,DATEPART(HOUR ,R.FECHAREG)) + ':00'
	                      END
	           )                         AS HORA_INI
	          ,(
	               SELECT CASE 
	                           WHEN R.FECHAREG <= @DIAUNO THEN '00:59'
	                           ELSE CASE 
	                                     WHEN DATEPART(hour ,R.FECHAREG) < 10 THEN '0'
	                                     ELSE ''
	                                END + CONVERT(VARCHAR(5) ,DATEPART(HOUR ,R.FECHAREG)) + ':59'
	                      END
	           )                         AS HORA_FIN	        
	          ,(-----------------------------------------------------------------------------------------------------------------------------
	               SELECT COUNT(CODCLI)
	               FROM   (
	                          SELECT distinct (A1.CODCLI)
	                          FROM   MT_ALUMNO A1
	                                 INNER JOIN MT_MATRICULAS AS M1
	                                      ON  M1.CODCLI = A1.CODCLI
	                                          AND M1.ITEM = 1
	                                          AND M1.REMATRICULA IS NULL
	                                          AND M1.ANO = A1.ANO
	                       			LEFT JOIN MT_ALUMNO_CAMBIOVIAADMISION AS mac 
										ON mac.CODCLI = A1.CODCLI         
	                                INNER JOIN MT_VIADMISION AS V
	                                      ON V.COD_VIA = CASE 
																WHEN isnull(mac.COD_VIA_ANTERIOR,0)=0 THEN a1.COD_VIA 
																ELSE
																	CASE 
																		WHEN DATEDIFF(DAY,m1.FECHA_REGISTRO,mac.FECHA_CAMBIO)>=0 THEN mac.COD_VIA_ANTERIOR 
																												                ELSE mac.COD_VIA 
																	END
															END            
	                                          AND V.CODTIPOADMISION = 1
									INNER JOIN RA_SITU AS rs ON RS.CODCLI=A1.CODCLI
									INNER JOIN RA_TIPOSITU AS rt ON RT.CODIGO=RS.TIPOSITU
									AND RT.ESTACAD 	 IN ('ELIMINADO' ,'TITULADO' ,'RETRACTADO' ,'EGRESADO')
									
	                          WHERE  A1.ANO = @AÑO
	                                 AND A1.PERIODO = 1
	                                 AND A1.CODCARPR = A.CODCARPR
	                                 AND M1.FECHA_REGISTRO <= @FECHA_BISIESTO + LTRIM(RTRIM(STR(@AÑO)))--*
	                                  AND CASE 
	                                          WHEN DATEDIFF(DAY ,@DIAUNO ,R.FECHAREG) <= 0 THEN 1
	                                          ELSE DATEDIFF(DAY ,@DIAUNO ,R.FECHAREG)+1
	                                     END = CASE 
	                                                WHEN DATEDIFF(DAY ,@DIAUNO ,RS.FECHAREG) <= 0 THEN 1
	                                                ELSE DATEDIFF(DAY ,@DIAUNO ,RS.FECHAREG)+1
	                                           END
	                                 AND CASE 
	                                          WHEN DATEDIFF(DAY ,@DIAUNO ,R.FECHAREG) < 0 THEN '00:00'
	                                          ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,R.FECHAREG))
	                                     END + ':00' = CASE 
	                                                        WHEN DATEDIFF(DAY ,@DIAUNO ,RS.FECHAREG) < 0 THEN '00:00'
	                                                        ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,RS.FECHAREG))
	                                                   END + ':00'                

	                      )T
	           )  AS MATRICULADOS_PSU---------------------------------------------------------------------------------------------------------
	         ,(-----------------------------------------------------------------------------------------------------------------------------
	               SELECT COUNT(CODCLI)
	               FROM   (
	                          SELECT distinct (A1.CODCLI)
	                          FROM   MT_ALUMNO A1
	                                 INNER JOIN MT_MATRICULAS AS M1
	                                      ON  M1.CODCLI = A1.CODCLI
	                                          AND M1.ITEM = 1
	                                          AND M1.REMATRICULA IS NULL
	                                          AND M1.ANO = A1.ANO
	                       			LEFT JOIN MT_ALUMNO_CAMBIOVIAADMISION AS mac 
										ON mac.CODCLI = A1.CODCLI         
	                                INNER JOIN MT_VIADMISION AS V
	                                      ON V.COD_VIA = CASE 
																WHEN isnull(mac.COD_VIA_ANTERIOR,0)=0 THEN a1.COD_VIA 
																ELSE
																	CASE 
																		WHEN DATEDIFF(DAY,m1.FECHA_REGISTRO,mac.FECHA_CAMBIO)>=0 THEN mac.COD_VIA_ANTERIOR 
																												                ELSE mac.COD_VIA 
																	END
															END            
	                                          AND V.CODTIPOADMISION = 1
									INNER JOIN RA_SITU AS rs ON RS.CODCLI=A1.CODCLI
									INNER JOIN RA_TIPOSITU AS rt ON RT.CODIGO=RS.TIPOSITU
									AND RT.ESTACAD 	 IN ('ELIMINADO' ,'TITULADO' ,'RETRACTADO' ,'EGRESADO')
																	   
									
	                          WHERE  A1.ANO = @AÑO
	                                 AND A1.PERIODO = 1
	                                 AND A1.CODCARPR = A.CODCARPR
	                                 AND M1.FECHA_REGISTRO <= @FECHA_BISIESTO + LTRIM(RTRIM(STR(@AÑO)))--*
	                                  AND CASE 
	                                          WHEN DATEDIFF(DAY ,@DIAUNO ,R.FECHAREG) <= 0 THEN 1
	                                          ELSE DATEDIFF(DAY ,@DIAUNO ,R.FECHAREG)+1
	                                     END = CASE 
	                                                WHEN DATEDIFF(DAY ,@DIAUNO ,RS.FECHAREG) <= 0 THEN 1
	                                                ELSE DATEDIFF(DAY ,@DIAUNO ,RS.FECHAREG)+1
	                                           END
	                                 AND CASE 
	                                          WHEN DATEDIFF(DAY ,@DIAUNO ,R.FECHAREG) < 0 THEN '00:00'
	                                          ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,R.FECHAREG))
	                                     END + ':00' = CASE 
	                                                        WHEN DATEDIFF(DAY ,@DIAUNO ,RS.FECHAREG) < 0 THEN '00:00'
	                                                        ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,RS.FECHAREG))
	                                                   END + ':00'
							
							AND CASE 
											WHEN isnull(mac.COD_VIA_ANTERIOR,0)=0 THEN a1.COD_VIA 
												ELSE
													CASE 
														WHEN DATEDIFF(DAY,m1.FECHA_REGISTRO,mac.FECHA_CAMBIO)>0 THEN mac.COD_VIA_ANTERIOR 
														ELSE mac.COD_VIA 
													END
									END  IN (10
											,24
											,33
											,41
											,44
											,45
											,46
											,47
											,51
											,36
											,20
											,22
											,23
											,25
											,26
											,8
											,28										
									)  	 	                                                       
	                                                               

	                      )T
	           )  AS AE---------------------------------------------------------------------------------------------------------
	           
	            ,(
	          	
	          	SELECT COUNT(A1.CODCLI)
	               FROM   MT_ALUMNO A1
	                      INNER JOIN MT_MATRICULAS AS M1
	                           ON  M1.CODCLI = A1.CODCLI
	                               AND M1.ITEM = 1
	                               AND M1.REMATRICULA IS NULL
	                               AND M1.ANO = A1.ANO	                                
						 LEFT JOIN MT_ALUMNO_CAMBIOVIAADMISION AS mac 
							   ON mac.CODCLI = A1.CODCLI         
									AND CASE 
											WHEN isnull(mac.COD_VIA_ANTERIOR,0)=0 THEN a1.COD_VIA 
												ELSE
													CASE 
														WHEN DATEDIFF(DAY,m1.FECHA_REGISTRO,mac.FECHA_CAMBIO)>0   THEN mac.COD_VIA_ANTERIOR 
														ELSE mac.COD_VIA 
													END
									END  = 19 
							INNER JOIN RA_SITU AS rs ON RS.CODCLI=A1.CODCLI
									INNER JOIN RA_TIPOSITU AS rt ON RT.CODIGO=RS.TIPOSITU
									AND RT.ESTACAD 	 IN ('ELIMINADO' ,'TITULADO' ,'RETRACTADO' ,'EGRESADO')		    	                               
	               WHERE  A1.ANO = @AÑO
	                      AND A1.PERIODO = 1
	                      AND A1.CODCARPR = A.CODCARPR
	                      AND M1.FECHA_REGISTRO <= @FECHA_BISIESTO + LTRIM(RTRIM(STR(@AÑO)))--*
	                       AND CASE 
	                                WHEN DATEDIFF(DAY ,@DIAUNO ,R.FECHAREG) <= 0 THEN 1
	                                ELSE DATEDIFF(DAY ,@DIAUNO ,R.FECHAREG)+1
	                            END = CASE 
	                                    WHEN DATEDIFF(DAY ,@DIAUNO ,RS.FECHAREG) <= 0 THEN 1
	                                    ELSE DATEDIFF(DAY ,@DIAUNO ,RS.FECHAREG)+1
	                                END
	                        AND CASE 
	                                WHEN DATEDIFF(DAY ,@DIAUNO ,R.FECHAREG) < 0 THEN '00:00'
	                                ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,R.FECHAREG))
	                            END + ':00' = CASE 
	                                            WHEN DATEDIFF(DAY ,@DIAUNO ,RS.FECHAREG) < 0 THEN '00:00'
	                                            ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,RS.FECHAREG))
	                                        END + ':00'   
	              
	           )                         AS BACH
	           
	           
	    FROM   MT_ALUMNO                 AS A
	           INNER JOIN MT_MATRICULAS  AS M
	                ON  M.CODCLI = A.CODCLI
	                    AND M.ITEM = 1
	                    AND M.REMATRICULA IS NULL
	                    AND M.ANO = A.ANO
	                    AND m.PERIODO=1
	           INNER JOIN MT_CARRER_CLASIFICACION AS mcc 
					ON a.CODCARPR=mcc.CODCARR
						AND mcc.CODTIPO=2
						AND a.ANO BETWEEN mcc.ANO_INI AND mcc.ANO_FIN		
INNER JOIN RA_SITU AS r ON R.CODCLI=A.CODCLI
INNER JOIN RA_TIPOSITU AS tIPO ON TIPO.CODIGO=R.TIPOSITU
AND TIPO.ESTACAD 	 IN ('ELIMINADO' ,'TITULADO' ,'RETRACTADO' ,'EGRESADO')						  		
	    WHERE  A.ANO = @AÑO
	           AND A.PERIODO = 1
	           AND A.PERIODO_MAT = A.PERIODO
	           AND (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           	                     
	    )
	    T1

		-----------------------------------------------------------------------------------------------
		UPDATE ADM_HISTORICO_POR_DIA
		SET    MAT_PSU      = H.MAT_PSU  -  R.CANTIDAD
			  ,MAT_ESP      = H.MAT_ESP  -  R.AE
			  ,MAT_BACH     = H.MAT_BACH -  R.BACH
		FROM   @RETRACTADOS R
			   INNER JOIN ADM_HISTORICO_POR_DIA AS H
					ON  R.DIA = H.DIA
						--  AND H.FECHA = R.FECHA
						AND H.PERIODO = R.PERIODO
						AND H.CODCARR = R.CODCARR
						AND H.HORA_INI = R.HORA_INI
						AND H.HORA_FIN = R.HORA_FIN
						AND h.ANO=@AÑO
	    
	    ---------------------------------------------------------------------------------------------------
	    
	   
	   /*
	    * ACTUALIZA LA MATRÍCULA AL CIERRE 
	    */
	    update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=113, MAT_CIERRE_ESP=18, MAT_CIERRE_BACH=0 WHERE CODCARR='1100C' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=78, MAT_CIERRE_ESP=6, MAT_CIERRE_BACH=0 WHERE CODCARR='1200C' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=27, MAT_CIERRE_ESP=4, MAT_CIERRE_BACH=0 WHERE CODCARR='1300C' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=41, MAT_CIERRE_ESP=4, MAT_CIERRE_BACH=0 WHERE CODCARR='1400C' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=22, MAT_CIERRE_ESP=7, MAT_CIERRE_BACH=0 WHERE CODCARR='1401C' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=87, MAT_CIERRE_ESP=9, MAT_CIERRE_BACH=0 WHERE CODCARR='1500C' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=18, MAT_CIERRE_ESP=2, MAT_CIERRE_BACH=0 WHERE CODCARR='1502C' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=87, MAT_CIERRE_ESP=12, MAT_CIERRE_BACH=0 WHERE CODCARR='1700C' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=146, MAT_CIERRE_ESP=17, MAT_CIERRE_BACH=0 WHERE CODCARR='1801C' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=113, MAT_CIERRE_ESP=10, MAT_CIERRE_BACH=0 WHERE CODCARR='1900C' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=24, MAT_CIERRE_ESP=2, MAT_CIERRE_BACH=0 WHERE CODCARR='1901C' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=44, MAT_CIERRE_ESP=2, MAT_CIERRE_BACH=0 WHERE CODCARR='1902C' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=29, MAT_CIERRE_ESP=2, MAT_CIERRE_BACH=0 WHERE CODCARR='1903C' AND ANO=2016


		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=125, MAT_CIERRE_ESP=170, MAT_CIERRE_BACH=147 WHERE CODCARR='1100S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=98, MAT_CIERRE_ESP=47, MAT_CIERRE_BACH=16 WHERE CODCARR='1200S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=46, MAT_CIERRE_ESP=26, MAT_CIERRE_BACH=2 WHERE CODCARR='1300S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=58, MAT_CIERRE_ESP=26, MAT_CIERRE_BACH=2 WHERE CODCARR='1301S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=33, MAT_CIERRE_ESP=6, MAT_CIERRE_BACH=0 WHERE CODCARR='1304S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=112, MAT_CIERRE_ESP=23, MAT_CIERRE_BACH=1 WHERE CODCARR='1400S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=99, MAT_CIERRE_ESP=21, MAT_CIERRE_BACH=0 WHERE CODCARR='1401S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=136, MAT_CIERRE_ESP=37, MAT_CIERRE_BACH=1 WHERE CODCARR='1500S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=35, MAT_CIERRE_ESP=12, MAT_CIERRE_BACH=0 WHERE CODCARR='1501S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=29, MAT_CIERRE_ESP=6, MAT_CIERRE_BACH=0 WHERE CODCARR='1502S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=28, MAT_CIERRE_ESP=5, MAT_CIERRE_BACH=0 WHERE CODCARR='1504S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=27, MAT_CIERRE_ESP=7, MAT_CIERRE_BACH=1 WHERE CODCARR='1603S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=195, MAT_CIERRE_ESP=22, MAT_CIERRE_BACH=0 WHERE CODCARR='1635S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=43, MAT_CIERRE_ESP=0, MAT_CIERRE_BACH=0 WHERE CODCARR='1633S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=40, MAT_CIERRE_ESP=1, MAT_CIERRE_BACH=0 WHERE CODCARR='1634S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=64, MAT_CIERRE_ESP=17, MAT_CIERRE_BACH=36 WHERE CODCARR='1700S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=72, MAT_CIERRE_ESP=17, MAT_CIERRE_BACH=0 WHERE CODCARR='1800S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=83, MAT_CIERRE_ESP=6, MAT_CIERRE_BACH=0 WHERE CODCARR='1801S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=90, MAT_CIERRE_ESP=15, MAT_CIERRE_BACH=0 WHERE CODCARR='1900S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=54, MAT_CIERRE_ESP=3, MAT_CIERRE_BACH=0 WHERE CODCARR='1901S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=71, MAT_CIERRE_ESP=18, MAT_CIERRE_BACH=0 WHERE CODCARR='1902S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=65, MAT_CIERRE_ESP=6, MAT_CIERRE_BACH=0 WHERE CODCARR='1903S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=67, MAT_CIERRE_ESP=12, MAT_CIERRE_BACH=0 WHERE CODCARR='1904S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=23, MAT_CIERRE_ESP=6, MAT_CIERRE_BACH=1 WHERE CODCARR='2500S' AND ANO=2016
		update ADM_HISTORICO_POR_DIA set MAT_CIERRE_PSU=36, MAT_CIERRE_ESP=4, MAT_CIERRE_BACH=1 WHERE CODCARR='2501S' AND ANO=2016


		--bachilleratos nuevos que absorven 1632S-->1633S y 1631S-->1635S
		



	    
	     
	    	    
	    /*
	     * FIN DE ELIMINACIÓN DE RETRACTADOS
	     */
	    
	    
	    
	    
	    IF @@ERROR <> 0
	    BEGIN
	        SELECT 'PROBLEMAS AL GENERAR LOS DATOS NUEVOS, BORRANDO LO YA GENERADO...'
	        DELETE 
	        FROM   ADM_HISTORICO_POR_DIA
	        WHERE  ANO = @AÑO
	    END
	    ELSE
	    BEGIN
	        SELECT 'FINALIZADO CON ÉXITO - INFORME RECTOR'
	    END
	END
---------------------------------------------------------------------------


SELECT 'INSERTANDO PARA INFORME 1'
DELETE 
FROM   ADM_DATAHISTORICA
WHERE  ANO_ADM = @AÑO

INSERT INTO ADM_DATAHISTORICA
SELECT C.CODCARR,
      @AÑO             AS 'AÑO_ADMISION',
      MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_CUENTACONVOCADOSLE(C.CODCARR, 1, 0) AS 
      CONVOCADOS,
      MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_CUENTACONVOCADOSLE(C.CODCARR, 0, 1) AS 
      LISTA_ESPERA,
      MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_PJEPONDMAXMINCONVOCADOSLE(C.CODCARR, 1, 0, 1) AS 
      PTJEPOND_PRIMERCONVOCADO,
      MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_PJEPONDMAXMINCONVOCADOSLE(C.CODCARR, 1, 0, 0) AS 
      PTJEPOND_ULTIMOCONVOCADO,
      PTJEPROM_PRIMERCONVOCADO = COALESCE(
          (
              SELECT TOP 1 COALESCE(
                         CONVERT(DECIMAL(6, 2), (P.PAAVERBAL + P.PAAMATEMAT) / 2),
                         0
                     )
              FROM   ADM_DATOS_POSTULANTES P
              WHERE  P.CODCARR = C.CODCARR
              ORDER BY
                     P.LUGAR ASC
          ),
          0
      ),
      PTJEPROM_ULTIMOCONVOCADO = COALESCE(
          (
              SELECT TOP 1 COALESCE(
                         CONVERT(DECIMAL(6, 2), (P.PAAVERBAL + P.PAAMATEMAT) / 2),
                         0
                     )
              FROM   ADM_DATOS_POSTULANTES P
              WHERE  P.CODCARR = C.CODCARR
              ORDER BY
                     P.LUGAR DESC
          ),
          0
      )
FROM MT_CARRER_CLASIFICACION AS     C
WHERE  C.CODTIPO= 2
    
    
    SELECT 'FIN INSERCIÓN PARA INFORME 1'  	
	
END

