// Programa   : DPPOSCMD
// Fecha/Hora : 13/06/2017 15:04:37
// Propósito  : Tomar Comanda Restaurante
// Creado Por : Juan Navas
// Llamado por: <DPXBASE>
// Aplicación : Gerencia
// Tabla      : <TABLA>

#INCLUDE "DPXBASE.CH"

PROCE MAIN(nOption,cNumero,cCodigo,cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle,cTableA,nValCam,cTipDoc)
   LOCAL aDataM,aFechas,cFileMem:="USER\BRPLANTILLADOC.MEM",V_nPeriodo:=4,cCodPar
   LOCAL V_dDesde:=CTOD(""),V_dHasta:=CTOD("")
   LOCAL cServer:=oDp:cRunServer,aVars:={}
   LOCAL lConectar:=.F.,cSql
   LOCAL aData2:={},aGrupo:={}
   LOCAL aTree :={},dFechaDiv:=CTOD("")
   LOCAL cCodSuc,cDocTip,cDocNum,cCodCli:=SPACE(10)

   oDp:cRunServer:=NIL


   IF !Empty(cServer)

     MsgRun("Conectando con Servidor "+cServer+" ["+ALLTRIM(SQLGET("DPSERVERBD","SBD_DOMINI","SBD_CODIGO"+GetWhere("=",cServer)))+"]",;
            "Por Favor Espere",{||lConectar:=EJECUTAR("DPSERVERDBOPEN",cServer)})

     IF !lConectar
        RETURN .F.
     ENDIF

   ENDIF

// ? nOption,cNumero,cCodigo,cWhere,"nOption,cNumero,cCodigo,cWhere"

   IF Type("oPosCmd")="O" .AND. oPosCmd:oWnd:hWnd>0
      EJECUTAR("BRRUNNEW",oPosCmd,GetScript())
      RETURN oPosCmd
   ENDIF

   IF nValCam=NIL
     dFechaDiv :=SQLGET("VIEW_HISMONMAXVALOR","MAX_FECHA,MAX_VALOR","MAX_CODIGO"+GetWhere("=",oDp:cMonedaExt))
     nValCam   :=DPSQLROW(2,0)
   ENDIF

   cTitle:="["+IF(nOption=1," Incluir "," Modificar")+"]"
   cTitle:="Registro de Comandas " +IF(Empty(cTitle),"",cTitle)

   oDp:oFrm:=NIL

   DEFAULT cCodSuc :=oDp:cSucursal,;
           nPeriodo:=4,;
           dDesde  :=oDp:dFecha,;
           dHasta  :=oDp:dFecha,;
           cWhere  :="",;
           cCodigo :="PRY-001",;
           cTableA :="DPAUDELIMODCNF",;
           cNumero :=""

   DEFAULT cTipDoc:="NEN",;
           nOption:=1

   cWhere:="AEM_CLAVE"+GetWhere("=",cCodigo)

   aDataM:={}

   aData2:=GetDataLic(.T.)

   cSql :=oDp:cWhere


   aDataM:=ASQL(" SELECT MOV_CODVEN,VEN_NOMBRE,MOV_ITEM_A,SUM(MOV_CANTID) AS MOV_CANTID,SUM(MOV_MTODIV) AS MOV_MTODIV "+;
                " FROM DPMOVINV_CROSSD "+;
                " LEFT JOIN DPVENDEDOR ON MOV_CODVEN=VEN_CODIGO "+;
                " GROUP BY MOV_CODVEN ")

   IF Empty(aDataM)         
      AADD(aDataM,{"","","" ,0,0})
   ENDIF

/*
   IF Empty(aData)
      MensajeErr("no hay "+cTitle,"Información no Encontrada")
      RETURN .F.
   ENDIF
*/
   oDp:oDbLic:=NIL

   oDpLbx:=GetDpLbx(oDp:nNumLbx)

   IF ValType(oDpLbx)="O" .AND. ValType(oDpLbx:aCargo)<>"A"
     oDpLbx:aCargo:=oDp:aCargo
   ENDIF

   IF ValType(oDpLbx)="O" .AND. ValType(oDpLbx:aCargo)="A"

     cCodSuc:=oDpLbx:aCargo[1] // 1Sucursal
     cDocTip:=oDpLbx:aCargo[2] // 2Tipo.Doc
     cDocNum:=oDpLbx:aCargo[3] // 3Número.Doc
     cCodCli:=oDpLbx:aCargo[4] // 4Número.Doc

//     oDpLbx:oWnd:Minimize()
     oDpLbx:lFullSize:=.F.

   ENDIF

   //  cTitle:=cTitle // +" ["+oDp:cMonedaExt+" "+ALLTRIM(TRAN(nValCam,oDp:cPictValCam))+"]"

   aTree :={} // EJECUTAR("DPINVREOAUTOTREE")
   aGrupo:=ASQL([ SELECT PER_CODIGO,PER_NOMBRE,PER_CODGRU,0 AS LOGICO,COUNT(*),SUM(MOV_CANTID) AS MOV_CANTID  FROM DPPERSONAL ]+;
                " LEFT JOIN DPMOVINV_TIN ON PER_CODIGO=MOV_CODPER "+;
                " WHERE PER_ACTIVO= 1"+;
                " GROUP BY PER_CODIGO "+;
                " ORDER BY PER_CODIGO")


   IF Empty(aGrupo)
      aGrupo:=EJECUTAR("SQLARRAYEMPTY",oDp:cSql)
   ENDIF

   ViewData(aDataM,cTitle,oDp:cWhere)

   oDp:oFrm:=oPosCmd
           
RETURN .T.  

FUNCTION ViewData(aDataM,cTitle,cWhere_)
   LOCAL oBrw,oCol,oTable,aTotal:=ATOTALES(aDataM),aTree2,aTree3
   LOCAL oFont,oFontB,I,U,X,Y,Z,oFontT
   LOCAL aPeriodos:=ACLONE(oDp:aPeriodos)
   LOCAL aCoors:=GetCoors( GetDesktopWindow() )

   DEFINE FONT oFont   NAME "Tahoma" SIZE 0, -12
   DEFINE FONT oFontB  NAME "Tahoma" SIZE 0, -12 BOLD
   DEFINE FONT oFontT  NAME "Tahoma" SIZE 0, -14 BOLD

   DpMdi(cTitle,"oPosCmd","DPPOSCMD.EDT")

   oPosCmd:Windows(0,0,aCoors[3]-160,aCoors[4]-10,.T.) // Maximizado
   oPosCmd:lMsgBar  :=.F.
   oPosCmd:cPeriodo :="" // aPeriodos[nPeriodo]
   oPosCmd:cCodSuc  :=cCodSuc
   oPosCmd:cNumero  :=cNumero
   oPosCmd:nPeriodo :=nPeriodo
   oPosCmd:cNombre  :=""
   oPosCmd:dDesde   :=dDesde
   oPosCmd:cServer  :=cServer
   oPosCmd:dHasta   :=dHasta
   oPosCmd:cWhere   :=cWhere
   oPosCmd:cWhere_  :=cWhere_
   oPosCmd:cWhereQry:=""
   oPosCmd:cSql     :=oDp:cSql
   oPosCmd:oWhere   :=TWHERE():New(oPosCmd)
   oPosCmd:cCodPar  :=cCodPar // Código del Parámetro
   oPosCmd:lWhen    :=.T.
   oPosCmd:cTextTit :="" // Texto del Titulo Heredado
   oPosCmd:oDb      :=oDp:oDb
   oPosCmd:cBrwCod  :=""
   oPosCmd:lTmdi    :=.T.
   oPosCmd:cWhereCli:=""
   oPosCmd:cTitleCli:=NIL
   oPosCmd:cCodigo  :=cCodigo
   oPosCmd:cMemo    :=""
   oPosCmd:cTableA  :=cTableA
   oPosCmd:cNombre  :="Definición de Proyecto de Pruebas"
   oPosCmd:oSplitV  :=nil
   oPosCmd:aTree    :=aTree
   oPosCmd:nAddBar  :=50+50+5+4+10+10+0
   oPosCmd:cCodCli  :=cCodCli // SPACE(10)
   oPosCmd:cCodInv  :=SPACE(20)
   oPosCmd:cWhereInv:="" // Filtrar productos
   oPosCmd:aData2   :=ACLONE(aData2)
   oPosCmd:aDataM   :=ACLONE(aDataM)
   oPosCmd:aVacio   :=ACLONE(aData)
   oPosCmd:aGrupo   :=ACLONE(aGrupo)
   oPosCmd:oImg     :=NIL
   oPosCmd:lValRif  :=.F.
   oPosCmd:nTotal   :=0
   oPosCmd:dFecha   :=oDp:dFecha
   oPosCmd:cHora    :=oDp:cHora
   oPosCmd:nValCam  :=nValCam
   oPosCmd:nCantOrg :=1
   oPosCmd:oMtoBs   :=NIL
   oPosCmd:cTipCli  :="DPCLIENTES" // Tabla de Clientes
   oPosCmd:aItems1  :={"Interna","Externa","Remota","Telefónica"},;
   oPosCmd:aItems2  :={"AM","PM","Tiempo Completo"}
   oPosCmd:cTipo    :=oPosCmd:aItems2[1]
//   oPosCmd:cModo    :="MeoPosCmd:aItems1[1]
   oPosCmd:cDescri  :=SPACE(250)
   oPosCmd:oMesa    :=NIL
   oPosCmd:cModo    :="Mesa"
   oPosCmd:cMesa    :=SQLGET("dpmovinv_crossd","MOV_CODVEN",[ WHERE 1=1 ORDER BY CONCAT(MOV_FECHA,MOV_HORA) DESC LIMIT 1 ])

   IF Empty(oPosCmd:cMesa)
      oPosCmd:cMesa    :=SQLGET("dpvendedor","VEN_CODIGO",[ LEFT(VEN_SITUAC,1)="A" ORDER BY VEN_CODIGO DESC LIMIT 1])
   ENDIF

   oPosCmd:cCodPer :=SQLGET("dpmovinv_crossd","MOV_CODPER",[ WHERE 1=1 ORDER BY CONCAT(MOV_FECHA,MOV_HORA) DESC LIMIT 1 ])

   IF Empty(oPosCmd:cCodPer)
      oPosCmd:cCodPer:=SQLGET("dppersonal","PER_CODIGO",[ PER_ACTIVO=1 ORDER BY PER_CODIGO DESC LIMIT 1])
   ENDIF


   oPosCmd:nCantid  :=1         // Cantidad
   oPosCmd:cZonaNL  :="N"
   oPosCmd:dFecha   :=oDp:dFecha
   oPosCmd:oBtnInv  :=NIL

   oPosCmd:cDocTip:=cDocTip // 2Tipo.Doc
   oPosCmd:cDocNum:=cDocNum // 3Número.Doc

   oPosCmd:nNumLbx :=oDp:nNumLbx
   oPosCmd:oDpLbx  :=GetDpLbx(oPosCmd:nNumLbx)

   oPosCmd:lFindCodPer :=.F.
   oPosCmd:lVerProducto:=.F.
   oPosCmd:nOption     :=nOption

   oPosCmd:lHtml    :=.T.
   oPosCmd:lAuto    :=.T.

   oPosCmd:nMtoBase   :=0 // Monto Base
   oPosCmd:nMtoNeto   :=0 // Monto Neto
   oPosCmd:nMtoIva    :=0 // Monto IVA
   oPosCmd:nMtoBs     :=0 // Monto Bs

//   oPosCmd:nColUndMed:=11
//   oPosCmd:nColCantid:=7  // 10 // Monto Neto
//   oPosCmd:nColDolar :=4  // 11 // Precio USD
//   oPosCmd:nColPrecio:=5  // 12 // Precio Bs
//   oPosCmd:nColLista :=10 // 12 // Lista de Precios

   oPosCmd:nColItem   :=1
   oPosCmd:nColMesa   :=2
   oPosCmd:nColMesero :=3
   oPosCmd:nColCodInv :=4
   oPosCmd:nColDescri :=5
   oPosCmd:nColUndMed :=6
   oPosCmd:nColCantid :=7
   oPosCmd:nColPrecio :=08
   oPosCmd:nColMtoAdd :=09
   oPosCmd:nColIVA    :=10
   oPosCmd:nColTotalD :=11


   oPosCmd:oDPMOVINV   :=OpenTable("SELECT * FROM DPMOVINV_CROSSD",.F.)

   oPosCmd:dDesde    :=oDp:dDesde
//   oPosCmd:cCodPer   :=SPACE(06)

//   oPosCmd:nHoras_Ent:=0         // Horas Entradas
//   oPosCmd:nHoras_Sal:=0         // Horas Salidas
   oPosCmd:nHorasT   :=0         // Total Horas

   oPosCmd:nCantid  :=1         // Cantidad

   oPosCmd:cNomCli  :=SPACE(100)
   // oPosCmd:cNumero  :=STRZERO(1,10)
   oPosCmd:lValRif  :=.F.
   oPosCmd:nTotal   :=0
   oPosCmd:cTipDoc  :=cTipDoc // "CTZ"
   oPosCmd:lIva     :=SQLGET("DPTIPDOCCLI","TDC_IVA","TDC_TIPO"+GetWhere("=",cTipDoc))
   oPosCmd:oBrwG    :=NIL

   oPosCmd:dFechaDiv :=CTOD("") // SQLGET("VIEW_HISMONMAXVALOR","MAX_FECHA,MAX_VALOR","MAX_CODIGO"+GetWhere("=",oDp:cMonedaExt))
   oPosCmd:nMontoDiv :=0        // DPSQLROW(2,0)
   oPosCmd:cTitleDiv :=""       // 	oDp:cMonedaExt+" "+DTOC(oPosCmd:dFechaDiv)+" "+ALLTRIM(TRAN( oPosCmd:nMontoDiv,"999,999,999,999.99"))

//   oPosCmd:oDesde:VarPut(oDp:dFecha,.T.)
//   oPosCmd:oCodPer:VarPut(CTOEMPTY(oPosCmd:cCodPer),.T.)

   IF !oPosCmd:nOption=1
      oTable:=OpenTable("SELECT * FROM DPMOVINV_TIN WHERE MOV_CODSUC"+GetWhere("=",oPosCmd:cCodSuc)+" AND MOV_DOCUME"+GetWhere("=",oPosCmd:cNumero),.T.)

      oPosCmd:dDesde :=oTable:MOV_FECHA
      oPosCmd:dHasta :=oTable:MOV_FCHVEN
      oPosCmd:cCodCli:=oTable:MOV_CODCTA
      oPosCmd:cCodPer:=oTable:MOV_CODPER
      oPosCmd:cCodInv:=oTable:MOV_CODIGO

      oPosCmd:cNombre:=SQLGET("DPRIF","RIF_NOMBRE","RIF_ID"+GetWhere("=",oPosCmd:cCodCli))
      // oPosCmd:oNomCli:VarPut(oPosCmd:cNombre,.T.)

/*      
      oPosCmd:cHoraP_Ent:=oTable:MOV_ITEM_A
      oPosCmd:cHoraP_Sal:=oTable:MOV_ITEM_C
      oPosCmd:cHoraA_Ent:=oTable:MOV_FCHHOR
      oPosCmd:cHoraA_Sal:=oTable:MOV_HORA
      oPosCmdn:nHoras_Sal:=oTable:MOV_CXUND
      oPosCmdn:nHoras_Ent:=oTable:MOV_CXUNDE
      oPosCmdn:nHorasT  :=oTable:MOV_CANTID
*/

      oPosCmd:cMemo     :=ALLTRIM(SQLGET("DPMEMO","MEM_MEMO,MEM_DESCRI","MEM_NUMERO"+GetWhere("=",oTable:MOV_NUMMEM)))
      oPosCmd:cDescri   := DPSQLROW(2,SPACE(250))


// ? oPosCmd:cNombre,"oPosCmd:cNombre"
// ? oPosCmd:cCodCli,"oPosCmd:cCodCli",oTable:MOV_CODCTA,"oTable:MOV_CODCTA"
//   oTable:Browse()

      oTable:End()
      oPosCmdn:oTable:=oTable

   ELSE

      oPosCmd:oTable:=NIL

      oPosCmd:dDesde:=oDp:dFecha
      oPosCmd:dHasta:=oDp:dFecha
	
   ENDIF

   IF Empty(oPosCmd:aTree)

      AEVAL(aGrupo,{|a,n| a[4]=(oPosCmd:cCodPer=a[1])})
      oPosCmd:oBrwG:=TXBrowse():New( oPosCmd:oWnd)
      oPosCmd:oBrwG:SetArray( aGrupo, .F. )
      oPosCmd:oBrwG:SetFont(oFont)

      oPosCmd:oBrwG:lFooter     := .F.
      oPosCmd:oBrwG:lHScroll    := .F.
      oPosCmd:oBrwG:nHeaderLines:= 2
      oPosCmd:oBrwG:nDataLines  := 1
      oPosCmd:oBrwG:nFooterLines:= 1

      oCol:=oPosCmd:oBrwG:aCols[1]
      oCol:cHeader      :='Código'
      oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrwG:aArrayData ) }
      oCol:nWidth       :=50

      oCol:=oPosCmd:oBrwG:aCols[2]
      oCol:cHeader      :='Descripción Contorno'
      oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrwG:aArrayData ) }
      oCol:nWidth       :=200

      oCol:=oPosCmd:oBrwG:aCols[3]
      oCol:cHeader      :="Unidad"
      oCol:nWidth       :=45
      oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrwG:aArrayData ) }
      oCol:cFooter      :="0"
      oCol:cEditPicture :='999,999'
      oCol:bStrData     :={|nMonto,oCol|nMonto:= oPosCmd:oBrwG:aArrayData[oPosCmd:oBrwG:nArrayAt,3],;
                                        oCol  := oPosCmd:oBrwG:aCols[3],;
                                        FDP(nMonto,oCol:cEditPicture)}

      oCol:=oPosCmd:oBrwG:aCols[4]
      oCol:cHeader      := "Cambio"
      oCol:nWidth       := 49
      oCol:AddBmpFile("BITMAPS\checkverde.bmp")
      oCol:AddBmpFile("BITMAPS\checkrojo.bmp")
      oCol:bBmpData    := { |oBrw|oBrw:=oPosCmd:oBrwG,IIF(oBrw:aArrayData[oBrw:nArrayAt,4],1,2) }
      oCol:nDataStyle  := oCol:DefStyle( AL_LEFT, .F.)
      oCol:bStrData    :={||""}

      oCol:=oPosCmd:oBrwG:aCols[5]
      oCol:cHeader      :="Cant"
      oCol:nWidth       :=45
      oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrwG:aArrayData ) }
      oCol:cFooter      :="0.00"
      oCol:cEditPicture :='999,999'
      oCol:bStrData     :={|nMonto,oCol|nMonto:= oPosCmd:oBrwG:aArrayData[oPosCmd:oBrwG:nArrayAt,5],;
                                        oCol  := oPosCmd:oBrwG:aCols[5],;
                                        FDP(nMonto,oCol:cEditPicture)}

      oCol:=oPosCmd:oBrwG:aCols[6]
      oCol:cHeader      :="Precio"
      oCol:nWidth       :=45
      oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrwG:aArrayData ) }
      oCol:cFooter      :="0.00"
      oCol:cEditPicture :='999,999'
      oCol:bStrData     :={|nMonto,oCol|nMonto:= oPosCmd:oBrwG:aArrayData[oPosCmd:oBrwG:nArrayAt,6],;
                                        oCol  := oPosCmd:oBrwG:aCols[6],;
                                        FDP(nMonto,oCol:cEditPicture)}
      oCol:=oPosCmd:oBrwG:aCols[6]
 
      oPosCmd:oBrwG:bClrStd      := {|oBrw,nClrText,aData|oBrw:=oPosCmd:oBrwG,aData:=oBrw:aArrayData[oBrw:nArrayAt],;
                                        oPosCmd:nClrText,;
                                       {nClrText,iif( oBrw:nArrayAt%2=0, oPosCmd:nClrPane1, oPosCmd:nClrPane2 ) } }

      oPosCmd:oBrwG:bClrHeader   := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
      oPosCmd:oBrwG:bClrFooter   := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

      oPosCmd:oBrwG:bLDblClick   :={|oBrw|oPosCmd:RUNCLICKBRWG() }
      oPosCmd:oBrwG:bGotFocus    :={||oPosCmd:oBrwFocus:=oPosCmd:oBrwG}

      oPosCmd:oBrwG:CreateFromCode()

//      oPosCmd:oBrwG:bChange:={||oPosCmd:BRWCHANGEG()}

   ENDIF

   oPosCmd:oBrwF:=TXBrowse():New( oPosCmd:oWnd)
   oPosCmd:oBrwF:SetArray( aDataM, .F. )
   oPosCmd:oBrwF:SetFont(oFont)

   oPosCmd:oBrwF:lFooter     := .T.
   oPosCmd:oBrwF:lHScroll    := .T.
   oPosCmd:oBrwF:nHeaderLines:= 2
   oPosCmd:oBrwF:nDataLines  := 1
   oPosCmd:oBrwF:nFooterLines:= 1

   oPosCmd:aDataM   :=ACLONE(aDataM)
   oPosCmd:nClrText :=0
   oPosCmd:nClrPane1:=16774120
   oPosCmd:nClrPane2:=16771538

   AEVAL(oPosCmd:oBrwF:aCols,{|oCol|oCol:oHeaderFont:=oFont})

   oCol:=oPosCmd:oBrwF:aCols[1]
   oCol:cHeader      :='Mesa'+CRLF+"Pedido"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrwF:aArrayData ) }
   oCol:nWidth       :=80

   oCol:=oPosCmd:oBrwF:aCols[2]
   oCol:cHeader      :='Nombre'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrwF:aArrayData ) }
   oCol:nWidth       :=80

   oCol:=oPosCmd:oBrwF:aCols[3]
   oCol:cHeader      :='Modo'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrwF:aArrayData ) }
   oCol:nWidth       :=80


   oCol:=oPosCmd:oBrwF:aCols[4]
   oCol:cHeader      :="Total"+CRLF+"Bs"
   oCol:nWidth       :=60+20
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrwF:aArrayData ) }
   oCol:cFooter      :="0"
   oCol:cEditPicture :='999,999'
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPosCmd:oBrwF:aArrayData[oPosCmd:oBrwF:nArrayAt,4],;
                                     oCol  := oPosCmd:oBrwF:aCols[4],;
                                     FDP(nMonto,oCol:cEditPicture)}

   oCol:=oPosCmd:oBrwF:aCols[5]
   oCol:cHeader      :="Total"+CRLF+"$"
   oCol:nWidth       :=60+20
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrwF:aArrayData ) }
   oCol:cFooter      :="0"
   oCol:cEditPicture :='999,999'
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPosCmd:oBrwF:aArrayData[oPosCmd:oBrwF:nArrayAt,5],;
                                     oCol  := oPosCmd:oBrwF:aCols[5],;
                                     FDP(nMonto,oCol:cEditPicture)}

   oPosCmd:oBrwF:bKeyDown:={|nKey| IF(nKey=46, oPosCmd:BRWDELITEM(),NIL)}


   oPosCmd:oBrwF:bClrStd               := {|oBrw,nClrText,aData|oBrw:=oPosCmd:oBrwF,aData:=oBrw:aArrayData[oBrw:nArrayAt],;
                                           oPosCmd:nClrText,;
                                          {nClrText,iif( oBrw:nArrayAt%2=0, oPosCmd:nClrPane1, oPosCmd:nClrPane2 ) } }

   oPosCmd:oBrwF:bClrHeader            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oPosCmd:oBrwF:bClrFooter            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

   oPosCmd:oBrwF:bLDblClick:={|oBrw|oPosCmd:RUNCLICK() }

   oPosCmd:oBrwF:bChange:={||oPosCmd:BRWCHANGEF()}
   oPosCmd:oBrwF:CreateFromCode()

   oPosCmd:oBrwFocus:=oPosCmd:oBrwF

   oPosCmd:oBrwF:bGotFocus:={||oPosCmd:oBrwFocus:=oPosCmd:oBrwF}
   
   /*
   // 2DO Browse, Productos
   */
   oPosCmd:oBrw:=TXBrowse():New( oPosCmd:oWnd)

   oPosCmd:oBrw:SetArray( aData2, .F. )
   oPosCmd:oBrw:SetFont(oFont)

   oPosCmd:oBrw:lFooter     := .F.
   oPosCmd:oBrw:lHScroll    := .T.
   oPosCmd:oBrw:nHeaderLines:= 2
   oPosCmd:oBrw:nDataLines  := 1
   oPosCmd:oBrw:nFooterLines:= 1

   AEVAL(oPosCmd:oBrw:aCols,{|oCol|oCol:oHeaderFont:=oFont})

   oCol:=oPosCmd:oBrw:aCols[1]
   oCol:cHeader      :='Núm'+CRLF+"Item"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrw:aArrayData ) }
   oCol:nWidth       :=80

   oCol:=oPosCmd:oBrw:aCols[2]
   oCol:cHeader      :='Mesa'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrw:aArrayData ) }
   oCol:nWidth       :=40

   oCol:=oPosCmd:oBrw:aCols[3]
   oCol:cHeader      :='Mesero'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrw:aArrayData ) }
   oCol:nWidth       :=40

   oCol:=oPosCmd:oBrw:aCols[4]
   oCol:cHeader      :='Producto'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrw:aArrayData ) }
   oCol:nWidth       :=80

   oCol:=oPosCmd:oBrw:aCols[5]
   oCol:cHeader      :='Descripción'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrw:aArrayData ) }
   oCol:nWidth       :=150

   oCol:=oPosCmd:oBrw:aCols[6]
   oCol:cHeader      :='Unidad'+CRLF+"Medida"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oPosCmd:oBrw:aArrayData ) }
   oCol:nWidth       :=70

// oPosCmd:nColCantid:=7

   oCol:=oPosCmd:oBrw:aCols[oPosCmd:nColCantid]
   oCol:cHeader      :='Cant.'
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oPosCmd:oBrw:aArrayData ) }
   oCol:nWidth       := 70
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:cEditPicture :='9,999.99'
   oCol:nEditType    :=1
// oCol:bOnPostEdit  :={|oCol,uValue|oPosCmd:PUTCANTID(oCol,uValue,oPosCmd:nColCantid)}
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt,oPosCmd:nColCantid],;
                                     oCol  := oPosCmd:oBrw:aCols[oPosCmd:nColCantid],;
                                     FDP(nMonto,oCol:cEditPicture)}
//   oCol:oDataFont:=oFontT
//   oCol:oHeadFont:=oFontT
// oPosCmd:nColPrecio:=8

   oCol:=oPosCmd:oBrw:aCols[oPosCmd:nColPrecio]
   oCol:cHeader      :='Precio'+CRLF+"$"
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oPosCmd:oBrw:aArrayData ) }
   oCol:nWidth       := 80
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:cEditPicture :='9,999,999.99'
   oCol:nEditType    :=1
// oCol:bOnPostEdit  :={|oCol,uValue|oPosCmd:PUTCANTID(oCol,uValue,oPosCmd:nColPrecio)}
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt,oPosCmd:nColPrecio],;
                                     oCol  := oPosCmd:oBrw:aCols[oPosCmd:nColPrecio],;
                                     FDP(nMonto,oCol:cEditPicture)}

   oCol:=oPosCmd:oBrw:aCols[oPosCmd:nColMtoAdd]
   oCol:cHeader      :='Adicional'+CRLF+"$"
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oPosCmd:oBrw:aArrayData ) }
   oCol:nWidth       := 80
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:cEditPicture :='9,999,999.99'
   oCol:nEditType    :=1
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt,oPosCmd:nColMtoAdd],;
                                     oCol  := oPosCmd:oBrw:aCols[oPosCmd:nColMtoAdd],;
                                     FDP(nMonto,oCol:cEditPicture)}

   oCol:=oPosCmd:oBrw:aCols[oPosCmd:nColIVA]
   oCol:cHeader      :='IVA'
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oPosCmd:oBrw:aArrayData ) }
   oCol:nWidth       := 80
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:cEditPicture :='9,999,999.99'
// oCol:nEditType    :=1
//   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt,oPosCmd:nColMtoAdd],;
//                                     oCol  := oPosCmd:oBrw:aCols[oPosCmd:nColMtoAdd],;
//                                     FDP(nMonto,oCol:cEditPicture)}



   oCol:=oPosCmd:oBrw:aCols[oPosCmd:nColTotalD]
   oCol:cHeader      :='Total'+CRLF+"$"
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oPosCmd:oBrw:aArrayData ) }
   oCol:nWidth       := 80
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:cEditPicture :='99,999.99'
   oCol:nEditType    :=1
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt,oPosCmd:nColTotalD],;
                                     oCol  := oPosCmd:oBrw:aCols[oPosCmd:nColTotalD],;
                                     FDP(nMonto,oCol:cEditPicture)}

   oCol:oDataFont:=oFontT
   oCol:oHeadFont:=oFontT

   oPosCmd:oBrw:bClrStd               := {|oBrw,nClrText,aData|oBrw:=oPosCmd:oBrw,aData:=oBrw:aArrayData[oBrw:nArrayAt],;
                                           oPosCmd:nClrText,;
                                          {nClrText,iif( oBrw:nArrayAt%2=0, oPosCmd:nClrPane1, oPosCmd:nClrPane2 ) } }

   oPosCmd:oBrw:bClrHeader            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oPosCmd:oBrw:bClrFooter            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

   oPosCmd:oBrw:bLDblClick:={|oBrw2|oPosCmd:RUNCLICKBRW2() }

//   oPosCmd:oBrw:bChange:={||oPosCmd:BRWCHANGE2()}
   oPosCmd:oBrw:CreateFromCode()

   oPosCmd:oBrwFocus:=oPosCmd:oBrw
   oPosCmd:oBrw:bGotFocus:={||oPosCmd:oBrwFocus:=oPosCmd:oBrw}

   oPosCmd:nAddCol:=70+20+20+40

   // 22/08/2024
   oPosCmd:nAddBar:=oPosCmd:nAddBar-10
   oPosCmd:nAddCol:=oPosCmd:nAddCol-80

   IF !oPosCmd:oBrwG=NIL
      oPosCmd:oTree:=oPosCmd:oBrwG
   ENDIF

   oPosCmd:oTree:Move(50-2+oPosCmd:nAddBar,0    ,400+oPosCmd:nAddCol,200,.T.)
 
   oPosCmd:oBrwF:Move(250+5+oPosCmd:nAddBar,0   ,400+oPosCmd:nAddCol,400,.T.)
   oPosCmd:oBrw:Move(50  +oPosCmd:nAddBar,400+5+oPosCmd:nAddCol,400+400,400,.T.)

   @ 45+205+oPosCmd:nAddBar,0 SPLITTER oPosCmd:oSplitH ;
          HORIZONTAL ;
          PREVIOUS CONTROLS oPosCmd:oTree,oPosCmd:oSplitV ;
          HINDS CONTROLS oPosCmd:oBrwF;
          TOP MARGIN 10 ;
          BOTTOM MARGIN 20 ;
          SIZE (205+200-8)+oPosCmd:nAddCol, 5 PIXEL ;
          OF oPosCmd:oWnd;
          COLOR CLR_YELLOW

  @ 50, (83+300+20)-5+oPosCmd:nAddCol  SPLITTER oPosCmd:oSplitV ;
          VERTICAL ;
          PREVIOUS CONTROLS oPosCmd:oBrwF,oPosCmd:oTree,oPosCmd:oSplitH ;
          HINDS CONTROLS oPosCmd:oBrw ;
          LEFT MARGIN 100 ;
          RIGHT MARGIN 120+120 ;
          SIZE 4, oPosCmd:oWnd:nHeight()-10  PIXEL ;
          OF oPosCmd:oWnd ;
          _3DLOOK ;
          COLOR CLR_BLUE

  oPosCmd:oSplitH:aPrevCtrols := { oPosCmd:oTree,oPosCmd:oSplitV }

  oPosCmd:oFocus:=NIL

  oPosCmd:Activate({||oPosCmd:ViewDatBar()})

  oPosCmd:bValid   :={|| EJECUTAR("BRWSAVEPAR",oPosCmd)}
  oPosCmd:BRWRESTOREPAR()

  oPosCmd:oWnd:Maximize()

  IF Empty(oPosCmd:cMesa)
     oPosCmd:oFocus:=oPosCmd:oMesa
  ENDIF

  IF Empty(oPosCmd:cCodPer)
     oPosCmd:oFocus:=oPosCmd:oCodPer
  ENDIF

  IF Empty(oPosCmd:oFocus)
     oPosCmd:oFocus:=oPosCmd:oCodInv
  ENDIF

  IF !Empty(oPosCmd:oFocus)
     DPFOCUS(oPosCmd:oFocus)
  ENDIF

//  oPosCmd:oDesde:VarPut(oDp:dFecha,.T.)
//  oPosCmd:oCodPer:VarPut(CTOEMPTY(oPosCmd:cCodPer),.T.)
//  oPosCmd:oTipo:ForWhen(.T.)

  IF !Empty(oPosCmd:cCodCli)
    oPosCmd:VALDPCLIENTES()
    oPosCmd:CALHORASAMPM()
  ENDIF


RETURN .T.

/*
// Barra de Botones
*/
FUNCTION ViewDatBar()
   LOCAL oCursor,oBar,oBtn,oFont,oCol,oFontB,oFontC,oFontT
   LOCAL oDlg:=IF(oPosCmd:lTmdi,oPosCmd:oWnd,oPosCmd:oDlg)
   LOCAL nLin:=0
   LOCAL nWidth:=oPosCmd:oBrwF:nWidth()
   LOCAL nAltoBrw:=150,nCol:=0,nColM:=0
   LOCAL nAdd:=0

   oPosCmd:oWnd:Maximize() // ZOOM
 
   oPosCmd:oBrwF:GoBottom(.T.)
   oPosCmd:oBrwF:Refresh(.T.)

   DEFINE CURSOR oCursor HAND

//   IF !oDp:lBtnText 
  DEFINE BUTTONBAR oBar SIZE 52-5,60-15+oPosCmd:nAddBar+2 OF oDlg 3D CURSOR oCursor
//   ELSE 
//     DEFINE BUTTONBAR oBar SIZE oDp:nBtnWidth,oDp:nBarnHeight+6 OF oDlg 3D CURSOR oCursor 
//   ENDIF 


   DEFINE FONT oFont   NAME "Tahoma"      SIZE 0, -09 BOLD
   DEFINE FONT oFontB  NAME "Tahoma"      SIZE 0, -12 BOLD
   DEFINE FONT oFontT  NAME "Tahoma"      SIZE 0, -14 BOLD
   DEFINE FONT oFontC  NAME "Courier New" SIZE 0, -14 BOLD


   oPosCmd:oBar:=oBar

   // Emanager no Incluye consulta de Vinculos
   oPosCmd:oFontBtn   :=oFont    
   oPosCmd:nClrPaneBar:=oDp:nGris
   oPosCmd:oBrw:oLbx  :=oPosCmd

 DEFINE BUTTON oPosCmd:oBtnSave;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\facturavta.BMP",NIL,"BITMAPS\facturavta.BMP";
          TOP PROMPT "Factura";
          WHEN .T.;
          ACTION oPosCmd:GUARDARDOC("FAV")

   oPosCmd:oBtnSave:cToolTip:="Facturar"

   DEFINE BUTTON oPosCmd:oBtnSave;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\notaentrega.BMP",NIL,"BITMAPS\notaentregag.BMP";
          TOP PROMPT "Entrega";
          WHEN .T.;
          ACTION oPosCmd:GUARDARDOC("NEN")

   oPosCmd:oBtnSave:cToolTip:="Nota de Entrega"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\ZOOM.BMP";
          TOP PROMPT "Zoom";
          ACTION IF(oPosCmd:oWnd:IsZoomed(),oPosCmd:oWnd:Restore(),oPosCmd:oWnd:Maximize())

   oBtn:cToolTip:="Maximizar"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XFIND.BMP";
            TOP PROMPT "Buscar"; 
              ACTION  EJECUTAR("BRWSETFIND",oPosCmd:oBrwFocus)

   oBtn:cToolTip:="Buscar"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CLIENTE.BMP";
            TOP PROMPT "Cliente"; 
              ACTION  EJECUTAR("DPCREACLI",oPosCmd:oCodCli)

   oBtn:cToolTip:="Creación Rápida de Cliente"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\FILTRAR.BMP";
            TOP PROMPT "Filtrar"; 
              ACTION  EJECUTAR("BRWSETFILTER",oPosCmd:oBrwFocus)

   oBtn:cToolTip:="Filtrar Registros"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\OPTIONS.BMP",NIL,"BITMAPS\OPTIONSG.BMP";
            TOP PROMPT "Opciones"; 
              ACTION  EJECUTAR("BRWSETOPTIONS",oPosCmd:oBrwFocus);
          WHEN LEN(oPosCmd:oBrwF:aArrayData)>1

   oBtn:cToolTip:="Filtrar según Valores Comunes"



   DEFINE BUTTON oPosCmd:oBtnDel;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XDELETE.BMP",NIL,"BITMAPS\XDELETEG.BMP";
            TOP PROMPT "Eliminar"; 
              ACTION  oPosCmd:BRWDELITEM();
          WHEN oPosCmd:nTotal>0

  oPosCmd:oBtnDel:cToolTip:="Remover Item"

IF nWidth>400

 
     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\EXCEL.BMP";
              TOP PROMPT "Excel"; 
              ACTION  (EJECUTAR("BRWTOEXCEL",oPosCmd:oBrwF,oPosCmd:cTitle,oPosCmd:cNombre))

     oBtn:cToolTip:="Exportar hacia Excel"

     oPosCmd:oBtnXls:=oBtn

ENDIF

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\html.BMP";
            TOP PROMPT "Html"; 
              ACTION  (EJECUTAR("BRWTOHTML",oPosCmd:oBrwF))

   oBtn:cToolTip:="Generar Archivo html"

   oPosCmd:oBtnHtml:=oBtn

 

IF nWidth>300

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\PREVIEW.BMP";
            TOP PROMPT "Preview"; 
              ACTION  (EJECUTAR("BRWPREVIEW",oPosCmd:oBrwF))

   oBtn:cToolTip:="Previsualización"

   oPosCmd:oBtnPreview:=oBtn

ENDIF

   IF ISSQLGET("DPREPORTES","REP_CODIGO","BRPLANTILLADOC")

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XPRINT.BMP";
              TOP PROMPT "Imprimir"; 
              ACTION  oPosCmd:IMPRIMIR()

      oBtn:cToolTip:="Imprimir"

     oPosCmd:oBtnPrint:=oBtn

   ENDIF

IF nWidth>700


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\QUERY.BMP";
          ACTION oPosCmd:BRWQUERY()

   oBtn:cToolTip:="Imprimir"

ENDIF




   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xTOP.BMP";
            TOP PROMPT "Primero"; 
              ACTION  (oPosCmd:oBrwF:GoTop(),oPosCmd:oBrwF:Setfocus())

IF nWidth>800 .OR. nWidth=0

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xSIG.BMP";
            TOP PROMPT "Avance"; 
              ACTION  (oPosCmd:oBrwF:PageDown(),oPosCmd:oBrwF:Setfocus())

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xANT.BMP";
            TOP PROMPT "Anterior"; 
              ACTION  (oPosCmd:oBrwF:PageUp(),oPosCmd:oBrwF:Setfocus())

ENDIF


  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xFIN.BMP";
            TOP PROMPT "Ultimo"; 
              ACTION  (oPosCmd:oBrwF:GoBottom(),oPosCmd:oBrwF:Setfocus())


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
            TOP PROMPT "Cerrar"; 
              ACTION  oPosCmd:Close()

  oPosCmd:oBrwF:SetColor(0,oPosCmd:nClrPane1)
  oPosCmd:oBrw:SetColor(0,oPosCmd:nClrPane1)

  EVAL(oPosCmd:oBrwF:bChange)
 
  oBar:SetColor(CLR_BLACK,oDp:nGris)

  DEFINE FONT oFont   NAME "Tahoma"      SIZE 0, -14


  oPosCmd:SETBTNBAR(40+15,40+10,oBar)

  nColM:=85

  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris),nColM:=nColM+o:nWidth()})

  nAdd:=0
  nCol:=15
  nLin:=50+7+4+nAdd

  @ nLin+00,nCol+71 BMPGET oPosCmd:oCodCli VAR oPosCmd:cCodCli;
                    VALID oPosCmd:ValCodCli();
                    NAME "BITMAPS\FIND.BMP";
                    ACTION oPosCmd:LBXCLIENTES();
                    SIZE 130,21 OF oPosCmd:oBar FONT oFontB PIXEL

  oPosCmd:oCodCli:bkeyDown:={|nkey| IIF(nKey=13, oPosCmd:VALCODCLI(),NIL) }


  @ oPosCmd:oCodCli:nTop(),oPosCmd:oCodCli:nRight()+20 GET oPosCmd:oNomCli VAR oPosCmd:cNomCLi    OF oBar;
                                                       SIZE 150+150,20 PIXEL FONT oFontB

  oPosCmd:oNomCli:bkeyDown:={|nkey| IIF(nKey=13, oPosCmd:BUSCARCLIENTE(),NIL) }

 

  @ nLin+00,nCol+00 SAY "RIF Cliente "  OF oBar SIZE 70,20 BORDER PIXEL RIGHT COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont

  @ nLin+21,nCol+00 SAY "Mesa  "     OF oBar SIZE 70,20 BORDER PIXEL RIGHT COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont
  @ nLin+42,nCol+00 SAY "Mesero "    OF oBar SIZE 70,20 BORDER PIXEL RIGHT COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont
  @ nLin+63,nCol+00 SAY "Producto "  OF oBar SIZE 70,20 BORDER PIXEL RIGHT COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont
  @ nLin+84,nCol+00 SAY "Cantidad "  OF oBar SIZE 70,20 BORDER PIXEL RIGHT COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont

  @ nLin+00,nCol+530 SAY " Número " OF oBar SIZE 60,20 BORDER;
                     PIXEL RIGHT COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont PIXEL

  @ nLin+00,nCol+600 SAY oPosCmd:oNumero PROMPT " "+oPosCmd:cNumero  OF oBar;
                     SIZE 90,20 BORDER PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFontB

  @ nLin+21,nCol+071 BMPGET oPosCmd:oMesa  VAR oPosCmd:cMesa;
                     NAME "BITMAPS\Calendar.bmp";
                     ACTION  (oDpLbx:=DpLbx("DPVENDEDOR",NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,oPosCmd:oMesa),;
                              oDpLbx:GetValue("VEN_CODIGO",oPosCmd:oMesa));
                     OF oBar PIXEL SIZE 87,20;
                     VALID oPosCmd:VALCODVEN();
                     FONT oFontB

  @ oPosCmd:oMesa:nTop(),oPosCmd:oMesa:nRight()+20 SAY oPosCmd:oMesaNombre;
                   	 PROMPT " "+SQLGET("DPVENDEDOR","VEN_NOMBRE","VEN_CODIGO"+GetWhere("=",oPosCmd:cMesa))+" " OF oBar;
                    SIZE 390,20 BORDER PIXEL  COLOR oDp:nClrYellowText,oDp:nClrYellow

  @ nLin+42,nCol+071 BMPGET oPosCmd:oCodPer VAR oPosCmd:cCodPer OF oBar PIXEL SIZE 70,20;
                     ACTION  (oDpLbx:=DpLbx("DPPERSONAL",NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,oPosCmd:oCodPer),;
                              oDpLbx:GetValue("PER_CODIGO",oPosCmd:oCodPer));
                     VALID oPosCmd:VALCODPER();
                     FONT oFontB

  oPosCmd:oCodPer:bkeyDown:={|nkey| IIF(nKey=13, oPosCmd:VALCODPER(),NIL) }

  @ oPosCmd:oCodPer:nTop(),oPosCmd:oCodPer:nRight()+20 SAY oPosCmd:oPersona;
                   	 PROMPT " "+SQLGET("DPPERSONAL","PER_NOMBRE","PER_CODIGO"+GetWhere("=",oPosCmd:cCodPer))+" " OF oBar;
                    SIZE 390,20 BORDER PIXEL  COLOR oDp:nClrYellowText,oDp:nClrYellow


  @ nLin+63,nCol+71 BMPGET oPosCmd:oCodInv VAR oPosCmd:cCodInv;
                    VALID oPosCmd:ValCodInv();
                    NAME "BITMAPS\FIND.BMP";
                    ACTION (oDpLbx:=DpLbx("dpinv.LBX",NIL,"LEFT(INV_ESTADO,1)"+GetWhere("=","A")+oPosCmd:cWhereInv,NIL,NIL,NIL,NIL,NIL,NIL,oPosCmd:oCodInv),;
                            oDpLbx:GetValue("INV_CODIGO",oPosCmd:oCodInv));
                    SIZE 130,21 OF oPosCmd:oBar FONT oFontB PIXEL

  oPosCmd:oCodInv:bkeyDown:={|nkey| IIF(nKey=13, oPosCmd:ValCodInv(),NIL) }

  @ oPosCmd:oCodInv:nTop(),oPosCmd:oCodInv:nRight()+20 SAY oPosCmd:oSayInv PROMPT " "+SQLGET("DPINV","INV_DESCRI","INV_CODIGO"+GetWhere("=",oPosCmd:cCodInv))+" " OF oBar;
    SIZE 390,20 BORDER PIXEL  COLOR oDp:nClrYellowText,oDp:nClrYellow

  @ nLin+84,nCol+071 GET oPosCmd:oCantid   VAR oPosCmd:nCantid    OF oBar PIXEL SIZE 087,20;
                     PICTURE "99,999.99";
                     VALID oPosCmd:VALCANTID();
                     FONT oFontB RIGHT

  oPosCmd:oCantid:bkeyDown:={|nKey| IIF(nKey=13,oPosCmd:VALCANTID(),NIL)}

  nAdd:=10

  @ 02+45,nColM SAY oPosCmd:oTextMemo PROMPT " Descripción y Observaciones" OF oBar SIZE oBar:nWidth()-(nColM)-18,20 PIXEL;
                COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont BORDER FONT oFontB

  @ 23+45,nColM GET oPosCmd:oDescri VAR oPosCmd:cDescri OF oBar SIZE oBar:nWidth()-(nColM)-18,20 PIXEL  FONT oFontB
//  @ 44+45,nColM GET oPosCmd:oMemo   VAR oPosCmd:cMemo   OF oBar SIZE oBar:nWidth()-(nColM)-18,oBar:nHeight()-(50+80) PIXEL MULTI FONT oFontC

  BMPGETBTN(oPosCmd:oCodCli)
  BMPGETBTN(oPosCmd:oCodInv)

  BMPGETBTN(oPosCmd:oCodPer)
  BMPGETBTN(oPosCmd:oMesa)

  oPosCmd:cFileBmp:=""

 // oPosCmd:SETTIPDOC(oPosCmd:cTipDoc)

  oPosCmd:nMtoBs   :=0 // Monto Bs

  oPosCmd:oBar:=oBar
 
  IF !oPosCmd:oBrwG=NIL
     oPosCmd:oBrwG:SetColor(0,oPosCmd:nClrPane1)
  ENDIF

  oPosCmd:nColM:=nColM

  oPosCmd:oWnd:bResized:={|| oPosCmd:oSplitH:AdjLeft(),;
                               oPosCmd:oSplitV:AdjLeft(),;
                               oPosCmd:oSplitV:AdjRight(),;
                               oPosCmd:oDescri:SetSize(oPosCmd:oBar:nWidth()-(oPosCmd:nColM)-18,20,.T.),;
                               oPosCmd:oTextMemo:SetSize(oPosCmd:oBar:nWidth()-(oPosCmd:nColM)-18,20,.T.)}

//,;
//                               oPosCmd:oMemo:SetSize(oPosCmd:oBar:nWidth()-(oPosCmd:nColM)-18,oPosCmd:oBar:nHeight()-50,.T.) }

RETURN .T.

FUNCTION INVBUSCARMOD()
RETURN .T.

FUNCTION INVBUSCARPIEZA()
RETURN .T.

FUNCTION INVBUSCARANO(cWhereMar)
  LOCAL cWhere:="",cWhereD

  oPosCmd:GetDataLic(.F.,cWhere,oPosCmd:oBrw)
  DPFOCUS(oPosCmd:oBrw)

RETURN .T.

/*
// Evento para presionar CLICK
*/
FUNCTION RUNCLICK()
RETURN .T.


/*
// Imprimir
*/
FUNCTION IMPRIMIR()
RETURN .T.

FUNCTION LEEFECHAS()
RETURN .T.


FUNCTION HACERWHERE(dDesde,dHasta,cWhere_,lRun)
RETURN cWhere


FUNCTION LEERDATA(cWhere,oBrw,cServer,cTableA)
   LOCAL aData:={},aTotal:={},oCol,cSql,aLines:={}
   LOCAL oDb

   DEFAULT cWhere:=""

   IF !Empty(cServer)

     IF !EJECUTAR("DPSERVERDBOPEN",cServer)
        RETURN .F.
     ENDIF

     oDb:=oDp:oDb

   ENDIF

   DEFAULT cTableA:="DPAUDELIMODCNF"

   cSql:=" SELECT * FROM XTABLA"

   cSql:=EJECUTAR("WHERE_VAR",cSql)

   oDp:lExcluye:=.T.

   aData:=ASQL(cSql,oDb)

   oDp:cWhere:=cWhere

   IF EMPTY(aData)
      aData:=EJECUTAR("SQLARRAYEMPTY",cSql,oDb)
   ENDIF

RETURN aData


FUNCTION SAVEPERIODO()
RETURN .T.

/*
// Permite Crear Filtros para las Búquedas
*/
FUNCTION BRWQUERY()
     EJECUTAR("BRWQUERY",oPosCmd)
RETURN .T.

/*
// Ejecución Cambio de Linea
*/
FUNCTION BRWCHANGEF()
  LOCAL aLine   :=oPosCmd:oBrwF:aArrayData[oPosCmd:oBrwF:nArrayAt]
  LOCAL cMesa   :=aLine[1]
  LOCAL cMesero :=SQLGET("DPMOVINV_CROSSD","MOV_CODPER","MOV_CODVEN"+GetWhere("=",cMesa))

  oPosCmd:GETDATAMESA(cMesa)

  IF ValType(oPosCmd:oMesa)="O"
    oPosCmd:oMesa:VarPut(cMesa,.T.)
    oPosCmd:oCodPer:VarPut(cMesero,.T.)
    oPosCmd:oCodInv:VarPut(CTOEMPTY(oPosCmd:cCodInv),.T.)
    DPFOCUS(oPosCmd:oCodInv)
  ENDIF

RETURN NIL

/*
// Refrescar Browse
*/
FUNCTION BRWREFRESCAR()
    LOCAL cWhere

    IF Type("oPosCmd")="O" .AND. oPosCmd:oWnd:hWnd>0

      cWhere:=" "+IIF(!Empty("oPosCmd":cWhere_),"oPosCmd":cWhere_,"oPosCmd":cWhere)
      cWhere:=STRTRAN(cWhere," WHERE ","")

      oPosCmd:LEERDATA(oPosCmd:cWhere_,oPosCmd:oBrwF,oPosCmd:cServer)
      oPosCmd:oWnd:Show()
      oPosCmd:oWnd:Maximize()

    ENDIF

RETURN NIL

FUNCTION TXTGUARDAR()
RETURN .T.

FUNCTION BRWRESTOREPAR()
RETURN EJECUTAR("BRWRESTOREPAR",oPosCmd)

FUNCTION VALDPCLIENTES()
  LOCAL lOk,cWhere
  LOCAL cRif:=oPosCmd:cCodCli
  LOCAL cNombre:=SQLGET("DPCLIENTES","CLI_NOMBRE","CLI_RIF"+GetWhere("=",oPosCmd:cCodCli))
  LOCAL cCodigo
 
  cCodigo:=SQLGET("DPCLIENTES","CLI_CODIGO","CLI_RIF"+GetWhere("=",cRif))

  IF !Empty(cCodigo)
//   oPosCmd:oCodCli:VarPut(cRCodigo,.T.)
//   cNombre:=SQLGET("DPCLIENTES","CLI_NOMBRE","CLI_CODIGO"+GetWhere("=",oPosCmd:cCodCli))
     EJECUTAR("DPCLIENTESTORIF",cCodigo)
  ENDIF  

  IF !Empty(cNombre)
     oPosCmd:oNomCli:VarPut(cNombre,.T.)
  ENDIF

  DPFOCUS(oPosCmd:oCodInv)

  IF !Empty(cRif)
    cWhere:=[MOV_CODCTA]+GetWhere("=",cRif)
    oPosCmd:GetDataLic(.F.,cWhere,oPosCmd:oBrw)
  ENDIF


/*
  IF !oPosCmd:lValRif
     RETURN .T.
  ENDIF

  MsgRun("Verificando RIF "+cRif,"Por Favor, Espere",;
         {|| lOk:=EJECUTAR("VALRIFSENIAT",cRif,!ISDIGIT(cRif),!ISDIGIT(cRif),NIL,.T.) })

  IF !Empty(oDp:aRif)
     oPosCmd:oNomCli:VarPut(oDp:aRif[1],.T.)
     oPosCmd:oNomCli:Refresh(.T.)
  ENDIF
*/

RETURN .T.

FUNCTION VALDPESTRUCTORG()
  LOCAL lOk
  LOCAL cRif:=oPosCmd:cCodCli
  LOCAL cNombre:=SQLGET("DPESTRUCTORG","EOR_DESCRI","EOR_CODIGO"+GetWhere("=",oPosCmd:cCodCli))
  LOCAL cCodigo
 
  IF !Empty(cNombre)
     oPosCmd:oNomCli:VarPut(cNombre,.T.)
  ENDIF

RETURN .T.


FUNCTION VALCODINV()
  LOCAL lOk,nCount
  LOCAL cNombre:=SQLGET("DPINV","INV_DESCRI","INV_CODIGO"+GetWhere("=",oPosCmd:cCodInv))
  LOCAL oInv   
  LOCAL nCol   :=IIF(oPosCmd:cZonaNL="N",3,5)
  LOCAL nPorIva:=0

  oPosCmd:oSayInv:Refresh(.T.)

  IF !ISSQLFIND("DPINV","INV_CODIGO"+GetWhere("=",oPosCmd:cCodInv)) 
     EJECUTAR("VALFINDCODENAME",oPosCmd:oCodInv,"DPINV","INV_CODIGO","INV_DESCRI") 
     RETURN .F.
  ENDIF

  oInv:=OpenTable(" SELECT INV_DESCRI,INV_IVA,IME_UNDMED,PRE_LISTA,PRE_CODMON,PRE_PRECIO,TPP_INCIVA "+;
                  " FROM DPINV"+;
                  " LEFT  JOIN VIEW_UNDMEDXINV   ON INV_CODIGO=IME_CODIGO "+;
                  " LEFT  JOIN VIEW_DPINVPRECIOS ON DPINV.INV_CODIGO=PRE_CODIGO "+;
                  " LEFT 	 JOIN DPPRECIOTIP       ON PRE_LISTA=TPP_CODIGO "+;
                  " WHERE INV_CODIGO"+GetWhere("=",oPosCmd:cCodInv))

//  oInv:Browse()

  AEVAL(oInv:aFields,{|a,n| oPosCmd:Set(a[1],oInv:FieldGet(n))})

  oPosCmd:IME_UNDMED:=oInv:IME_UNDMED
  oPosCmd:INV_IVA   :=oInv:INV_IVA
  oPosCmd:PRE_LISTA :=oInv:PRE_LISTA
  oPosCmd:PRE_CODMON:=oInv:PRE_CODMON
  oPosCmd:PRE_PRECIO:=oInv:PRE_PRECIO
  oPosCmd:PRE_PREDIV:=oInv:PRE_PRECIO // Precio Divisa
  oPosCmd:MOV_TOTDIV:=oPosCmd:PRE_PREDIV 
  oPosCmd:INV_DESCRI:=oInv:INV_DESCRI
  oPosCmd:nMontoAdd := 0 // monto Adicional por los contornos

  // ? oInv:RecCount(),CLPCOPY(oDp:cSql)
  // oInv:Browse()
  oInv:End()

  IF Empty(oPosCmd:PRE_PRECIO)
    oPosCmd:oCodInv:MsgErr("Producto no Tiene Precio")
    RETURN .F.
  ENDIF


  //  ? oPosCmd:INV_IVA,"oPosCmd:INV_IVA"
  nPorIva:=EJECUTAR("IVACAL",oPosCmd:INV_IVA,nCol,oPosCmd:dFecha) 

  IF Empty(cNombre)
     EVAL(oPosCmd:oCodInv:bAction)
     RETURN .F.
  ENDIF

  oPosCmd:CMDADDITEM(.F.)

//  oPosCmd:GetDataLic(.F.,"INV_CODIGO"+GetWhere("=",oPosCmd:cCodInv),oPosCmd:oBrw)

RETURN .T.

FUNCTION GetDataLic(lEmpty,cWhere,oBrw2)
  LOCAL aData,cSql,oDb,cSql2

  DEFAULT lEmpty:=.T.

  cSql:=[ SELECT MOV_ITEM,MOV_CODVEN,MOV_CODPER,MOV_CODIGO,INV_DESCRI,MOV_UNDMED,MOV_CANTID,MOV_PRECIO,MOV_MTOCLA,MOV_TIPIVA,MOV_MTODIV ]+;
        [ FROM DPMOVINV_CROSSD ]+;
        [ INNER JOIN DPINV ON MOV_CODIGO=INV_CODIGO ]+;
        [ LEFT JOIN DPMEMO ON MOV_NUMMEM=MEM_NUMERO ]+;
        [ WHERE ]+IF(Empty(cWhere),"",cWhere+" AND ")+[ MOV_INVACT=1 ]+;
        [ ORDER BY MOV_ITEM ]

  DPWRITE("TEMP\DPASISTAT_INT.SQL",cSql)

  IF lEmpty

   aData:=EJECUTAR("SQLARRAYEMPTY",cSql,oDb)

 ELSE

    aData:=ASQL(cSql,.T.)

    IF Empty(aData)
       aData:=ACLONE(oPosCmd:aData2)
    ENDIF

/*
    IF Empty(aData) .AND. cSql<>cSql2
       aData:=ASQL(cSql2,.T.)
       DPWRITE("TEMP\DPASISVTA_CRA.SQL",oDp:cSql)
    ENDIF

    IF Empty(aData)
      aData:=ACLONE(oPosCmd:aData2)
      aData[1,2]:="No Encontrado"
      // EJECUTAR("SQLARRAYEMPTY",cSql,oDb)
    ENDIF
*/
 ENDIF

 IF ValType(oBrw2)="O"
    oBrw2:aArrayData:=ACLONE(aData)
    oBrw2:nArrayAt:=1
    oBrw2:nRowSel :=1
    oBrw2:Gotop()
    oBrw2:Refresh(.T.)
    EVAL(oBrw2:bChange)
    oPosCmd:oBrwFocus:=oBrw2
    CursorArrow()
 ENDIF

RETURN aData

FUNCTION RUNCLICKBRW2()
  LOCAL aLine  :=ACLONE(oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt])
  LOCAL aData  :=ACLONE(oPosCmd:aDataM),cPrecio,aTotal:={}
  LOCAL nAt    :=oPosCmd:oBrw:nArrayAt
  LOCAL nRowSel:=oPosCmd:oBrw:nRowSel

  IF Empty(aLine[1]) .OR. Empty(aLine[oPosCmd:nColPrecio])
     RETURN .F.
  ENDIF

  IF Empty(aData[1,1])
     aData:={}
  ENDIF

  cPrecio:=ALLTRIM(FDP(aLine[oPosCmd:nColPrecio],"999,999,999,999.99"))
 
  AADD(aData,{ALLTRIM(aLine[2])+CRLF+aLine[1]+" "+cPrecio,oPosCmd:nCantid,oPosCmd:nCantid*aLine[oPosCmd:nColDolar],ACLONE(aLine)})

  oPosCmd:oBrwF:aArrayData:=ACLONE(aData)
  oPosCmd:oBrwF:GoBottom()

? "RUNCLICKBRW2"

  EJECUTAR("BRWCALTOTALES",oPosCmd:oBrwF,.T.)
 
  oPosCmd:aData:=ACLONE(aData)

  ARREDUCE(oPosCmd:oBrw:aArrayData,oPosCmd:oBrw:nArrayAt)

  oPosCmd:oBrwFocus:=oPosCmd:oBrw

  IF Empty(oPosCmd:oBrw:aArrayData)
    oPosCmd:oBrw:aArrayData:=ACLONE(oPosCmd:aData2)
    oPosCmd:oBrwFocus:=oPosCmd:oBrwF
  ENDIF
 
  oPosCmd:oBrw:nArrayAt:=MIN(oPosCmd:oBrw:nArrayAt,LEN(oPosCmd:oBrw:aArrayData))
  oPosCmd:oBrw:DrawLine(.T.)
// nArrayAt

  oPosCmd:oBrw:nColSel:=oPosCmd:nColCantid
  oPosCmd:oBrw:nRowSel:=MIN(oPosCmd:oBrw:nRowSel,nRowSel)
  oPosCmd:oBrw:Refresh(.F.)

  // Restaura Cantidad
//  oPosCmd:oHoras:VarPut(oPosCmd:nCantOrg,.T.)
 
  oPosCmd:CALTOTAL() // Calcular Totales
  oPosCmd:oBrwF:GoBottom(.T.)

RETURN .T.

/*
// Calcular Total e IVA
*/
FUNCTION CALTOTAL()
 LOCAL aData  :=oPosCmd:oBrwF:aArrayData,I,cTipIva
 LOCAL nMtoIva:=0,nMtoBase:=0,nPorIva:=0,aLine,aTotal
 LOCAL nCol   :=3

 IF !Empty(oPosCmd:cCodCli)
    nCol   :=IIF(SQLGET("DPCLIENTES","CLI_ZONANL","CLI_CODIGO"+GetWhere("=",oPosCmd:cCodCli),NIL,oDp:oDbLic)="N",3,5)
 ENDIF

 oPosCmd:nMtoIva:=0

 FOR I=1 TO LEN(aData)

     aLine  :=aData[I,4]

     IF !Empty(aLine)

       cTipIva:=aLine[14+1]
       nPorIva:=0

       IF oPosCmd:lIva
         nPorIva:=EJECUTAR("IVACAL",cTipIva,nCol,oPosCmd:dFecha)
       ENDIF

       oPosCmd:nMtoIva:=oPosCmd:nMtoIva+PORCEN(aData[I,3],nPorIva)

     ENDIF

  NEXT I

/*
  aTotal:=ATOTALES(aData)
  oPosCmd:nMtoBase:=aTotal[3]
  oPosCmd:nMtoNeto:=oPosCmd:nMtoBase+oPosCmd:nMtoIva
  oPosCmd:nMtoBs  :=oPosCmd:nMontoDiv*oPosCmd:nMtoNeto

// ? oPosCmd:nMtoIva,"oPosCmd:nMtoIva",oPosCmd:nMtoNeto

  oPosCmd:nTotal:=aTotal[3]
  oPosCmd:oBtnSave:ForWhen(.T.)

  oPosCmd:oMtoBase:Refresh(.T.)
  oPosCmd:oMtoIva:Refresh(.T.)
  oPosCmd:oMtoNeto:Refresh(.T.)
  oPosCmd:oMtoBs:Refresh(.T.)
*/
  oPosCmd:oBtnDel:ForWhen(.T.)

RETURN .T.

FUNCTION BRWCHANGE2()
   LOCAL cWhere  :=""
   LOCAL aLine   :=oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt]
   LOCAL cFileBmp:=aLine[LEN(aLine)]
   LOCAL aLineF  :=oPosCmd:oBrwF:aArrayData[oPosCmd:oBrwF:nArrayAt]
   LOCAL dFecha  :=aLineF[1]
   LOCAL cCodPer :=oPosCmd:oBrwG:aArrayData[oPosCmd:oBrwG:nArrayAt,1]
   LOCAL cRif    :=oPosCmd:cCodCli

   IF ValType(oPosCmd:oBtnInv)="O"
      oPosCmd:oBtnInv:ForWhen(.T.)
   ENDIF

   IF !Empty(cRif)
     cWhere:=[MOV_CODCTA]+GetWhere("=",cRif)
   ENDIF

   IF !Empty(cWhere) .AND. !Empty(cCodPer) 
 
     cWhere:=cWhere+" AND MOV_CODPER"+GetWhere("=",cCodPer)

   ELSE

     IF !Empty(cCodPer)
       cWhere:=cWhere+" AND MOV_CODPER"+GetWhere("=",cCodPer)
     ENDIF

   ENDIF

   IF !Empty(cWhere)
    // oPosCmd:GetDataLic(.F.,cWhere,oPosCmd:oBrw)
   ENDIF

RETURN .T.

FUNCTION BRWCHANGEG()
   LOCAL aLine   	:=oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt]
   LOCAL cFileBmp:=aLine[LEN(aLine)]
   LOCAL aLineF  :=oPosCmd:oBrwF:aArrayData[oPosCmd:oBrwF:nArrayAt]
   LOCAL dFecha  :=aLineF[1]
   LOCAL cCodPer :=oPosCmd:oBrwG:aArrayData[oPosCmd:oBrwG:nArrayAt,1]
   LOCAL cRif    :=oPosCmd:cCodCli,cWhere:=""

   oPosCmd:oBtnInv:ForWhen(.T.)

   IF !Empty(cRif)

     cWhere:=[MOV_CODCTA]+GetWhere("=",cRif)

     IF !Empty(cCodPer)
       cWhere:=cWhere+" AND  MOV_CODPER"+GetWhere("=",cCodPer)
     ENDIF

   ELSE

     IF !Empty(cCodPer)
       cWhere:=" MOV_CODPER"+GetWhere("=",cCodPer)
     ENDIF

   ENDIF

   IF !Empty(cWhere)
     oPosCmd:GetDataLic(.F.,cWhere,oPosCmd:oBrw)
   ENDIF

   // IF !Empty(cCodPer)
   //   oPosCmd:GETDATAMESA(cCodPer)
   // ENDIF

RETURN .T.



FUNCTION VERFOTO(cFichero)
/*
  DEFAULT cFichero:="FOTOS\sensoroxigeno.bmp"

  IF !FILE(cFichero)
     cFichero:="FOTOS\SINIMAGEN.bmp"
  ENDIF

  oPosCmd:oImg:LoadBmp(cFichero)

  sysrefresh()
*/
RETURN .T.

/*
// Asigna Tipo de Documento
*/
FUNCTION SETTIPDOC(cTipDoc)
  LOCAL cScope,cCodSuc:=oDp:cSucursal
  LOCAL cNumero
  LOCAL oData  :=DATASET("SUC_V"+oDp:cSucursal,"ALL")
  LOCAL cNumIni:=oData:Get(cTipDoc+"Numero",STRZERO(0,10))

  oData:End()

// cNumFis   :=oData:Get(oTipCliCLI:cTipDoc+"NumFis",STRZERO(0,10))
// oTipCliCLI:TDC_PICFIS:=oData:Get(oTipCliCLI:cTipDoc+"PicFis",REPLI("9",10) )


  oPosCmd:cTipDoc:=cTipDoc
//  oPosCmd:oTipCli:Refresh(.T.)

  cScope:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
          "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
          "DOC_TIPTRA"+GetWhere("=","D")

// Obtiene Numero de Documento Cuando No es Impresora Epson
//  cNumero:=SQLINCREMENTAL("DPDOCCLI","DOC_NUMERO",cScope)
	

  IF oPosCmd:nOption=1

    cNumero:=SQLINCREMENTAL("DPMOVINV_TIN","MOV_DOCUME","MOV_CODSUC"+GetWhere("=",oDp:cSucursal)+" AND "+;
                                           "MOV_APLORG"+GetWhere("=","P"),,,.T.)

    cNumero:=RIGHT(cNumero,10)
    cNumero:=IIF(cNumero>cNumIni,cNumero,cNumIni)

    oPosCmd:lIva     :=SQLGET("DPTIPDOCCLI","TDC_IVA","TDC_TIPO"+GetWhere("=",cTipDoc))

    oPosCmd:cNumero:=cNumero
    oPosCmd:oNumero:Refresh(.T.)

  ENDIF

RETURN .T.

FUNCTION SELPLANTILLA()
RETURN .T.

FUNCTION  VERTREE(oTree,cPrompt)
RETURN .T.
/*
// Genera Correspondencia Masiva
*/
FUNCTION GUARDARDOC()
  LOCAL dHasta :=oPosCmd:dHasta
  LOCAL x      :=oPosCmd:oBrwF:aArrayData:=ACLONE(oPosCmd:aData),y:=oPosCmd:oBrwF:Refresh(.f.)
  LOCAL cDescri:=ALLTRIM(SQLGET("DPTIPDOCCLI","TDC_DESCRI","TDC_TIPO"+GetWhere("=",oPosCmd:cTipDoc)))
  LOCAL aData  :=ACLONE(oPosCmd:oBrwF:aArrayData)
  LOCAL nMonto :=0

  oPosCmd:CALTOTAL()
  oPosCmd:SETTIPDOC(oPosCmd:cTipDoc)

  IF Empty(oPosCmd:cCodCli)
    oPosCmd:oCodCli:MsgErr("Código de Cliente Requerido","Validación")
    RETURN .F.
  ENDIF

 
  nMonto :=oPosCmd:nMtoNeto

  IF !MsgNoYes("Desea "+IF(oPosCmd:nOption=1,"Crear","Modificar")+" Tarea #"+oPosCmd:cNumero+" "+CRLF+"Horas "+ALLTRIM(TRAN(oPosCmd:nHorasT,"99.99")))
     RETURN .T.
  ENDIF

  CursorWait()
  ADEPURA(aData,{|a,n|a[3]=0 })

  oPosCmd:MOV_CODSUC:=oPosCmd:cCodSuc
  oPosCmd:MOV_DOCUME:=oPosCmd:cNumero

  //EJECUTAR("DPASISTAR_INTCREAMOV",oPosCmd,oPosCmd:cCodSuc,oPosCmd:cCodCli,aData,oPosCmd:cTipDoc,oPosCmd:lHtml,oPosCmd:lAuto)
  // 
  //   EJECUTAR("MDILBXREFRESH",oPosCmd)

  IF oPosCmd:nOption=3
    oPosCmd:Close()
    RETURN NIL
  ENDIF



  // Reinicia el Documento
  oPosCmd:aData          :=ACLONE(oPosCmd:aVacio)
  oPosCmd:oBrwF:aArrayData:=ACLONE(oPosCmd:aVacio)
 
  oPosCmd:oBrwF:nArrayAt:=MIN(oPosCmd:oBrwF:nArrayAt,LEN(oPosCmd:oBrwF:aArrayData))
  oPosCmd:oBrwF:nRowSel :=MIN(oPosCmd:oBrwF:nRowSel ,oPosCmd:oBrwF:nArrayAt)

  oPosCmd:oBrwF:Refresh(.F.)

  oPosCmd:CALTOTAL() // Calcular Totales

  oPosCmd:oCodCli:VarPut(CTOEMPTY(oPosCmd:cCodCli),.T.)
  oPosCmd:oNomCli:VarPut(CTOEMPTY(oPosCmd:cNomCLi),.T.)
  oPosCmd:oDescri:VarPut(CTOEMPTY(oPosCmd:cDescri),.T.)
  oPosCmd:oMemo:VarPut(CTOEMPTY(oPosCmd:cMemo),.T.)



  // Refresca las tareas del personal
  oPosCmd:VALCODPER()

RETURN .T.

FUNCTION VERPRODUCTO()
 LOCAL aLine:=oPosCmd:oBrwFocus:aArrayData[oPosCmd:oBrwFocus:nArrayAt]

// ? aLine,oPosCmd:oBrwFocus

 IF Empty(aLine[1])
    RETURN .T.
 ENDIF

 IF LEN(aLine)>10
    EJECUTAR("DPINV",0,aLine[1])
    RETURN .F.
 ENDIF

 aLine:=aLine[4]
 IF LEN(aLine)>10
    EJECUTAR("DPINV",0,aLine[1])
    RETURN .F.
 ENDIF

// ? oPosCmd:oBrwFocus:ClassName(),aLine[1],LEN(aLine)
// ViewArray(aLine)

RETURN .T.

/*
// Puede cambiar la cantidad en el Browse
*/
FUNCTION PUTCANTID(oCol,uValue,nCol)
  oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt,nCol+0]:=uValue
  oPosCmd:oBrw:DrawLine(.T.)
RETURN .T.

FUNCTION PUTDOLAR(oCol,uValue,nCol)
  LOCAL nBs:=ROUND(uValue*oPosCmd:nValCam,2)

  oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt,nCol+0]:=uValue
  oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt,nCol+1]:=nBs
  oPosCmd:oBrw:DrawLine(.T.)

  oPosCmd:oBrw:nColSel:=nCol+1

RETURN .T.

FUNCTION PUTMONTO(oCol,uValue,nCol)
  LOCAL nUsd:=ROUND(uValue/oPosCmd:nValCam,2)

  oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt,nCol+0]:=uValue
  oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt,nCol-1]:=nUsd
// oPosCmd:oBrw:nColSel:=10
// oPosCmd:RUNCLICKBRW2()
// oPosCmd:oBrw:Refresh(.F.) // DrawLine(.T.)
 oPosCmd:oBrw:nColSel:=nCol+1 // 10+1n

RETURN .T.

FUNCTION BRWDELITEM()
  LOCAL aLine:={}

  IF !MsgNoYes("Desea Remover Item "+LSTR(oPosCmd:oBrwF:nArrayAt))
     RETURN .T.
  ENDIF


  aLine:=ACLONE(oPosCmd:oBrwF:aArrayData[oPosCmd:oBrwF:nArrayAt,4])

  IF !Empty(aLine)
    AINSERTAR(oPosCmd:oBrw:aArrayData,1,aLine)
    oPosCmd:oBrw:nArrayAt:=1
    oPosCmd:oBrw:GoTop()
    oPosCmd:oBrw:Refresh(.F.)
  ENDIF

  ARREDUCE(oPosCmd:oBrwF:aArrayData,oPosCmd:oBrwF:nArrayAt)

  IF Empty(oPosCmd:oBrwF:aArrayData)
    oPosCmd:aData          :=ACLONE(oPosCmd:aVacio)
    oPosCmd:oBrwF:aArrayData:=ACLONE(oPosCmd:aVacio)
  ENDIF

  oPosCmd:oBrwF:nArrayAt:=MIN(oPosCmd:oBrwF:nArrayAt,LEN(oPosCmd:oBrwF:aArrayData))
  oPosCmd:oBrwF:nRowSel :=MIN(oPosCmd:oBrwF:nRowSel ,oPosCmd:oBrwF:nArrayAt)

  oPosCmd:oBrwF:Refresh(.F.)

  oPosCmd:CALTOTAL() // Calcular Totales


RETURN .T.


FUNCTION RUNCLICKBRWG()
  LOCAL aLine :=ACLONE(oPosCmd:oBrwG:aArrayData[oPosCmd:oBrwG:nArrayAt])
  LOCAL cWhere:="MOV_CODPER"+GetWhere("=",aLine[1])

  IF Empty(oPosCmd:cCodPer)
     oPosCmd:oCodPer:VarPut(aLine[1],.T.)
     EVAL(oPosCmd:oCodPer:bValid)
  ENDIF

  oPosCmd:oBrwG:aArrayData[oPosCmd:oBrwG:nArrayAt,4]:=!oPosCmd:oBrwG:aArrayData[oPosCmd:oBrwG:nArrayAt,4]
  oPosCmd:oBrwG:DrawLine(.T.)

  oPosCmd:GetDataLic(.F.,cWhere,oPosCmd:oBrw)
  DPFOCUS(oPosCmd:oBrw)

RETURN .T.

FUNCTION BUSCARCLIENTE()
  LOCAL cWhere

  IF Empty(oPosCmd:cNomCLi)
     RETURN .T.
  ENDIF

  cWhere:="CLI_NOMBRE"+GetWhere(" LIKE ","%"+ALLTRIM(oPosCmd:cNomCLi)+"%")

  oDpLbx:=DpLbx("DPCLIENTES",NIL,cWhere) 
  oDpLbx:GetValue("CLI_CODIGO",oPosCmd:oCodCli)

RETURN .T.

FUNCTION SETTIPCLI(cTable)

   oPosCmd:cTipCli:=cTable
   oPosCmd:oTipCli:Refresh(.T.)

RETURN .T.

FUNCTION LBXCLIENTES()

  IF oPosCmd:cTipCli="DPCLIENTES"
     oDpLbx:=DpLbx("DPCLIENTES",NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,oPosCmd:oCodCli)
     oDpLbx:GetValue("CLI_RIF",oPosCmd:oCodCli)
  ENDIF

  IF oPosCmd:cTipCli="DPESTRUCTORG"
     oDpLbx:=DpLbx("DPESTRUCTORG",NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,oPosCmd:oCodCli)
     oDpLbx:GetValue("EOR_CODIGO",oPosCmd:oCodCli)
  ENDIF


RETURN .T.

FUNCTION VALCODCLI()

  IF oPosCmd:cTipCli="DPCLIENTES"
     RETURN oPosCmd:VALDPCLIENTES()
  ENDIF

//  IF oPosCmd:cTipCli="DPESTRUCTORG"
//     RETURN oPosCmd:VALDPESTRUCTORG()
//  ENDIF

RETURN .T.

FUNCTION VALCODPER()
   LOCAL cNombre:=SQLGET("DPPERSONAL","PER_NOMBRE","PER_CODIGO"+GetWhere("=",oPosCmd:cCodPer))
   LOCAL nAt    :=0

   oPosCmd:oPersona:SetText(cNombre)
   oPosCmd:oPersona:Refresh(.T.)

   oPosCmd:lFindCodPer:=ISSQLFIND("DPPERSONAL","PER_CODIGO"+GetWhere("=",oPosCmd:cCodPer))

   IF !oPosCmd:lFindCodPer
     EVAL(oPosCmd:oCodPer:bAction)
     RETURN .F.
   ENDIF

/*
   IF ValType(oPosCmd:oBrwG)="O"

     nAt    :=ASCAN(oPosCmd:oBrwG:aArrayData,{|a,n| ALLTRIM(a[1])=ALLTRIM(oPosCmd:cCodPer)})

     IF nAt>0
       oPosCmd:oBrwG:aArrayData[nAt,4]:=.T.
     ENDIF

     oPosCmd:oBrwG:Refresh(.F.)

   ENDIF
*/

   DPFOCUS(oPosCmd:oCodInv)

RETURN .T.

FUNCTION VALCODVEN()
   // LOCAL cNombre:=SQLGET("DPVENDEDOR","VEN_NOMBRE","VEN_CODIGO"+GetWhere("=",oPosCmd:cMesa))
   // oPosCmd:oMesaNombre:SetText(cNombre)

   oPosCmd:oMesaNombre:Refresh(.T.)

   oPosCmd:lFindCodVen:=ISSQLFIND("DPVENDEDOR","VEN_CODIGO"+GetWhere("=",oPosCmd:cMesa))

   IF !oPosCmd:lFindCodVen
     EVAL(oPosCmd:oMesa:bAction)
     RETURN .F.
   ENDIF

RETURN .T.


FUNCTION SETTIEMPO()

   oPosCmd:GETHORARIOAM() 

RETURN .T.

FUNCTION CALHORASAMPM()
RETURN .T.

FUNCTION CALTOTALHORAS()
RETURN .T.


FUNCTION GETHORARIOAM()
RETURN .T.

FUNCTION GETDATAMESA(cMesa,dFecha)
  LOCAL aDataM:={},cWhere,aLine:={}
  LOCAL cSql  :=""

  cWhere:="MOV_CODVEN"+GetWhere("=",cMesa)

  cSql:=[ SELECT MOV_ITEM,MOV_CODVEN,MOV_CODPER,MOV_CODIGO,INV_DESCRI,MOV_UNDMED,MOV_CANTID,MOV_PRECIO,MOV_MTOCLA,MOV_TIPIVA,MOV_MTODIV ]+;
        [ FROM DPMOVINV_CROSSD ]+;
        [ INNER JOIN DPINV ON MOV_CODIGO=INV_CODIGO ]+;
        [ LEFT JOIN DPMEMO ON MOV_NUMMEM=MEM_NUMERO ]+;
        [ WHERE MOV_CODVEN]+GetWhere("=",cMesa)+[ AND  MOV_INVACT=1 ]+;
        [ ORDER BY MOV_ITEM ]

  aDataM:=ASQL(cSql)

  IF Empty(aDataM)
    aDataM:=ACLONE(oPosCmd:aDataM)
  ENDIF

  aLine:=ACLONE(aDataM[1])
  AEVAL(aLine,{|a,n| aLine[n]:=CTOEMPTY(a)})
  AADD(aDataM,aLine)

  oPosCmd:oBrw:aArrayData:=ACLONE(aDataM)
  oPosCmd:oBrw:nArrayAt:=1
  oPosCmd:oBrw:nRowSel :=1
  oPosCmd:oBrw:GoBottom(.T.)
  oPosCmd:oBrw:Refresh(.F.)

RETURN .T.

FUNCTION VALCANTID()

  oPosCmd:MOV_TOTDIV:=oPosCmd:PRE_PREDIV*oPosCmd:nCantid
  oPosCmd:MOV_TOTAL :=oPosCmd:PRE_PRECIO*oPosCmd:nCantid

  oPosCmd:CMDADDITEM(.T.)

  oPosCmd:oCantid:oJump:=oPosCmd:oCodInv
  DPFOCUS(oPosCmd:oCodInv)

RETURN .T.

FUNCTION CMDADDITEM(lAdd)
   LOCAL nAt  :=oPosCmd:oBrw:nArrayAt
   LOCAL aLine:=ACLONE(oPosCmd:oBrw:aArrayData[oPosCmd:oBrw:nArrayAt])
   LOCAL cItem:=aLine[oPosCmd:nColItem]

   DEFAULT lAdd:=.F.

   IF Empty(cItem)
      cItem:=SQLINCREMENTAL("DPMOVINV_CROSSD","MOV_ITEM","MOV_CODVEN"+GetWhere("=",oPosCmd:cMesa),NIL,NIL,.T.,3)
   ENDIF

  //  cSql:=[ SELECT MOV_ITEM,MOV_CODVEN,MOV_CODPER,MOV_CODIGO,INV_DESCRI,MOV_UNDMED,MOV_CANTID,MOV_PRECIO,MOV_TIPIVA,MOV_TOTAL,MOV_MTODIV ]+;
  //        [ FROM DPMOVINV_CROSSD ]+;

   oPosCmd:oBrw:aArrayData[nAt,oPosCmd:nColItem  ]:=cItem
   oPosCmd:oBrw:aArrayData[nAt,oPosCmd:nColMesa  ]:=oPosCmd:cMesa
   oPosCmd:oBrw:aArrayData[nAt,oPosCmd:nColMesero]:=oPosCmd:cCodPer
   oPosCmd:oBrw:aArrayData[nAt,oPosCmd:nColCodInv]:=oPosCmd:cCodInv
   oPosCmd:oBrw:aArrayData[nAt,oPosCmd:nColDescri]:=oPosCmd:INV_DESCRI

   oPosCmd:oBrw:aArrayData[nAt,oPosCmd:nColUndMed ]:=oPosCmd:IME_UNDMED
   oPosCmd:oBrw:aArrayData[nAt,oPosCmd:nColCantid ]:=oPosCmd:nCantid
   oPosCmd:oBrw:aArrayData[nAt,oPosCmd:nColPrecio ]:=oPosCmd:PRE_PRECIO
   oPosCmd:oBrw:aArrayData[nAt,oPosCmd:nColIVA    ]:=oPosCmd:INV_IVA
   oPosCmd:oBrw:aArrayData[nAt,oPosCmd:nColMtoAdd ]:=oPosCmd:nMontoAdd
   oPosCmd:oBrw:aArrayData[nAt,oPosCmd:nColTotalD ]:=oPosCmd:MOV_TOTDIV

   oPosCmd:oBrw:DrawLine(.T.)

   IF lAdd

     // Nuevo Registro
     // ? oPosCmd:oDPMOVINV:cTable,oPosCmd:oDPMOVINV:Classname()

     oPosCmd:oDPMOVINV:AppendBlank()
     oPosCmd:oDPMOVINV:lAuditar:=.F.
     oPosCmd:oDPMOVINV:SetForeignkeyOff()
     oPosCmd:oDPMOVINV:Replace("MOV_ITEM"  ,cItem)
     oPosCmd:oDPMOVINV:Replace("MOV_CODALM",oDp:cAlmacen   ) 
     oPosCmd:oDPMOVINV:Replace("MOV_CODTRA"  ,"S000"         ) 
     oPosCmd:oDPMOVINV:Replace("MOV_CODVEN",oPosCmd:cMesa  ) 
     oPosCmd:oDPMOVINV:Replace("MOV_CODPER",oPosCmd:cCodPer)
     oPosCmd:oDPMOVINV:Replace("MOV_CODCTA",oPosCmd:cCodCli) // Para llevar o Delivery, nombre del cliente. 
     oPosCmd:oDPMOVINV:Replace("MOV_CANTID",oPosCmd:nCantid)
     oPosCmd:oDPMOVINV:Replace("MOV_UNDMED",oPosCmd:IME_UNDMED)
     oPosCmd:oDPMOVINV:Replace("MOV_CODIGO",oPosCmd:cCodInv)
     oPosCmd:oDPMOVINV:Replace("MOV_CODCTA",oPosCmd:cCodCli)
     oPosCmd:oDPMOVINV:Replace("MOV_PRECIO",oPosCmd:PRE_PRECIO)
     oPosCmd:oDPMOVINV:Replace("MOV_TOTAL" ,oPosCmd:MOV_TOTAL )
     oPosCmd:oDPMOVINV:Replace("MOV_MTODIV",oPosCmd:MOV_TOTDIV)
     oPosCmd:oDPMOVINV:Replace("MOV_FECHA" ,oDp:dFecha        )
     oPosCmd:oDPMOVINV:Replace("MOV_FECHA" ,oDp:cHora         )
     oPosCmd:oDPMOVINV:Replace("MOV_INVACT",1                 )
     oPosCmd:oDPMOVINV:Replace("MOV_TIPO"  ,"I"               )
     oPosCmd:oDPMOVINV:Replace("MOV_ITEM_A",oPosCmd:cModo     )


     oPosCmd:oDPMOVINV:Commit("")

//  ? CLPCOPY(oDp:cSql)

     AEVAL(aLine,{|a,n| aLine[n]:=CTOEMPTY(a)})
     AADD(oPosCmd:oBrw:aArrayData,aLine)
     oPosCmd:oBrw:nArrayAt++
     oPosCmd:oBrw:nRowSel++
     oPosCmd:oBrw:GoBottom(.T.)
     oPosCmd:oBrw:Refresh(.F.)

     oPosCmd:oBrw:Refresh(.F.) // DrawLine(.T.)
     oPosCmd:oCodInv:VarPut(CTOEMPTY(oPosCmd:cCodInv),.T.)

     DPFOCUS(oPosCmd:oCodInv)

   ENDIF

RETURN .T.
// EOF
