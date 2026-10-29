INCLUDE Irvine32.inc


MAX_PRODUCTOS EQU 10
PRODUCTO STRUCT
  codigo BYTE 8 DUP(0)
  nombre BYTE 26 DUP(0)
  precio DWORD 0
  existencias DWORD 0
PRODUCTO ENDS


.data
menuPrincipal BYTE 13,10,'=== TIENDA DE VIDEOJUEGOS ===',13,10,'1 Alta',13,10,'2 Inventario',13,10,'3 Buscar',13,10,'4 Recibir',13,10,'5 Vender',13,10,'6 Resumen',13,10,'7 Guardar',13,10,'8 Cargar',13,10,'0 Salir',13,10,'Opcion: ',0
pedirCodigo BYTE 'Codigo ABC-123: ',0
pedirNombre BYTE 'Nombre (1-25): ',0
pedirPrecio BYTE 'Precio MXN: ',0
pedirExistencias BYTE 'Existencia (0-100): ',0
pedirCantidad BYTE 'Cantidad (>0): ',0
mensajeInvalido BYTE 'Dato invalido o fuera de rango.',13,10,0
mensajeNoEncontrado BYTE 'Producto no encontrado.',13,10,0
mensajeDuplicado BYTE 'Codigo duplicado.',13,10,0
mensajeLleno BYTE 'Capacidad de 10 productos alcanzada.',13,10,0
mensajeExito BYTE 'Operacion realizada.',13,10,0
mensajeSinExistencias BYTE 'Existencia insuficiente o limite excedido.',13,10,0
mensajeErrorArchivo BYTE 'Error de archivo o datos invalidos. Catalogo conservado.',13,10,0
mensajeGuardado BYTE 'Catalogo guardado.',13,10,0
mensajeCargado BYTE 'Catalogo cargado.',13,10,0
avisoCambios BYTE 'Hay cambios sin guardar. Salir? (S/N): ',0
avisoPocasExistencias BYTE ' *** ALERTA: existencia minima (5 o menos) ***',0
etiquetaCodigo BYTE 'Codigo: ',0
etiquetaNombre BYTE '  Nombre: ',0
etiquetaPrecio BYTE '  Precio: ',0
etiquetaExistencias BYTE '  Unidades: ',0
etiquetaUnidades BYTE 'Unidades disponibles: ',0
etiquetaValor BYTE 'Valor inventario: ',0
etiquetaIngresos BYTE 'Ingresos de esta sesion: ',0
etiquetaVenta BYTE 'Importe de venta: ',0
textoMXN BYTE ' MXN',13,10,0
nombreArchivo BYTE 'inventario.dat',0
entrada BYTE 128 DUP(0)
bufferNumero BYTE 16 DUP(0)
catalogo PRODUCTO MAX_PRODUCTOS DUP(<>)
temporal PRODUCTO MAX_PRODUCTOS DUP(<>)
cantidadProductos DWORD 0
cantidadNueva DWORD 0
ingresos DWORD 0
cambiosPendientes BYTE 0
manejadorArchivo DWORD 0
cabeceraArchivo DWORD 324E5649h
cantidadArchivo DWORD 0
bufferArchivo BYTE (8+MAX_PRODUCTOS*SIZEOF PRODUCTO) DUP(0)


.code


MostrarTexto PROC USES eax ecx edx
 call WriteString
 ret

MostrarTexto ENDP


PedirTexto PROC USES ecx edx
 call WriteString
 mov edx,OFFSET entrada
 mov ecx,SIZEOF entrada-1
 call ReadString
 ret

PedirTexto ENDP


ConvertirEntero PROC USES ebx ecx edx esi edi
 mov esi,edx
 test ecx,ecx
 jz enteroInvalido

 xor edi,edi

cicloEntero:
 movzx ebx,BYTE PTR [esi]
 cmp ebx,'0'
 jb enteroInvalido

 cmp ebx,'9'
 ja enteroInvalido

 sub ebx,'0'
 mov eax,edi
 mov edx,10
 mul edx
 test edx,edx
 jnz enteroInvalido

 add eax,ebx
 jc enteroInvalido

 mov edi,eax
 inc esi
 dec ecx
 jnz cicloEntero

 mov eax,edi
 clc
 ret


enteroInvalido:
 stc
 ret

ConvertirEntero ENDP


ConvertirPrecio PROC USES ebx ecx edx esi edi ebp
 mov esi,edx
 test ecx,ecx
 jz precioInvalido

 xor edi,edi
 xor ebp,ebp
 xor ebx,ebx

cicloPrecio:
 movzx eax,BYTE PTR [esi]
 cmp al,'.'
 je puntoDecimal

 cmp al,'0'
 jb precioInvalido

 cmp al,'9'
 ja precioInvalido

 sub eax,'0'
 cmp ebp,0
 jne digitoDecimal

 inc ebx
 cmp edi,9999
 ja precioInvalido

 imul edi,edi,10
 add edi,eax
 cmp edi,9999
 ja precioInvalido

 jmp siguientePrecio


digitoDecimal:
 cmp ebp,3
 jae precioInvalido

 imul edi,edi,10
 add edi,eax
 inc ebp
 jmp siguientePrecio


puntoDecimal:
 test ebx,ebx
 jz precioInvalido

 test ebp,ebp
 jnz precioInvalido

 mov ebp,1

siguientePrecio:
 inc esi
 dec ecx
 jnz cicloPrecio

 test ebx,ebx
 jz precioInvalido

 cmp ebp,1
 je precioInvalido

 cmp ebp,0
 jne comprobarPrecio

 imul edi,edi,100
 jmp comprobarPrecio


comprobarPrecio:
 cmp ebp,2
 jne limitePrecio

 imul edi,edi,10

limitePrecio:
 cmp edi,1
 jb precioInvalido

 cmp edi,999999
 ja precioInvalido

 mov eax,edi
 clc
 ret


precioInvalido:
 stc
 ret

ConvertirPrecio ENDP


LeerEntero PROC USES ebx ecx edx esi edi
 call PedirTexto
 mov edx,OFFSET entrada
 mov ecx,eax
 call ConvertirEntero
 jc lecturaInvalida

 cmp eax,edi
 jb lecturaInvalida

 cmp eax,ebx
 ja lecturaInvalida

 clc
 ret


lecturaInvalida:
 mov edx,OFFSET mensajeInvalido
 call MostrarTexto
 stc
 ret

LeerEntero ENDP


LeerPrecio PROC USES ecx edx
 mov edx,OFFSET pedirPrecio
 call PedirTexto
 mov edx,OFFSET entrada
 mov ecx,eax
 call ConvertirPrecio
 jnc precioLeido

 mov edx,OFFSET mensajeInvalido
 call MostrarTexto
 stc

precioLeido:
 ret

LeerPrecio ENDP


ValidarCodigo PROC USES ecx esi
 mov esi,edx
 mov ecx,3

validarLetras:
 mov al,[esi]
 cmp al,'A'
 jb codigoInvalido

 cmp al,'Z'
 ja codigoInvalido

 inc esi
 loop validarLetras

 cmp BYTE PTR [esi],'-'
 jne codigoInvalido

 inc esi
 mov ecx,3

validarDigitos:
 mov al,[esi]
 cmp al,'0'
 jb codigoInvalido

 cmp al,'9'
 ja codigoInvalido

 inc esi
 loop validarDigitos

 cmp BYTE PTR [esi],0
 jne codigoInvalido

 mov eax,1
 ret


codigoInvalido:
 xor eax,eax
 ret

ValidarCodigo ENDP


EncontrarCodigo PROC USES ebx ecx edx esi edi
 mov edi,edx
 xor ebx,ebx
 mov esi,OFFSET catalogo

siguienteProducto:
 cmp ebx,cantidadProductos
 jae codigoNoExiste

 push esi
 mov edx,edi
 mov ecx,7

compararCodigo:
 mov al,[esi]
 cmp al,[edx]
 jne codigoDistinto

 inc esi
 inc edx
 loop compararCodigo

 pop esi
 mov eax,ebx
 ret


codigoDistinto:
 pop esi
 add esi,SIZEOF PRODUCTO
 inc ebx
 jmp siguienteProducto


codigoNoExiste:
 mov eax,-1
 ret

EncontrarCodigo ENDP


LeerCodigo PROC USES edx
 mov edx,OFFSET pedirCodigo
 call PedirTexto
 cmp eax,7
 jne capturaCodigoInvalida

 mov edx,OFFSET entrada
 call ValidarCodigo
 test eax,eax
 jz capturaCodigoInvalida

 mov eax,7
 clc
 ret


capturaCodigoInvalida:
 mov edx,OFFSET mensajeInvalido
 call MostrarTexto
 stc
 ret

LeerCodigo ENDP


MostrarEntero PROC USES eax ebx ecx edx esi
 mov esi,OFFSET bufferNumero+15
 mov BYTE PTR [esi],0
 mov ebx,10

extraerDigito:
 xor edx,edx
 div ebx
 add dl,'0'
 dec esi
 mov [esi],dl
 test eax,eax
 jnz extraerDigito

 mov edx,esi
 call MostrarTexto
 ret

MostrarEntero ENDP


MostrarPrecio PROC USES eax ebx edx
 xor edx,edx
 mov ebx,100
 div ebx
 push edx
 call MostrarEntero
 mov al,'.'
 call WriteChar
 pop eax
 cmp eax,10
 jae dosDecimales

 push eax
 mov al,'0'
 call WriteChar
 pop eax

dosDecimales:
 call MostrarEntero
 mov edx,OFFSET textoMXN
 call MostrarTexto
 ret

MostrarPrecio ENDP


MostrarProducto PROC USES eax edx
 mov edx,OFFSET etiquetaCodigo
 call MostrarTexto
 mov edx,esi
 call MostrarTexto
 mov edx,OFFSET etiquetaNombre
 call MostrarTexto
 lea edx,[esi].PRODUCTO.nombre
 call MostrarTexto
 call Crlf
 mov edx,OFFSET etiquetaPrecio
 call MostrarTexto
 mov eax,[esi].PRODUCTO.precio
 call MostrarPrecio
 mov edx,OFFSET etiquetaExistencias
 call MostrarTexto
 mov eax,[esi].PRODUCTO.existencias
 call MostrarEntero
 cmp DWORD PTR [esi].PRODUCTO.existencias,5
 ja productoNormal

 mov edx,OFFSET avisoPocasExistencias
 call MostrarTexto

productoNormal:
 call Crlf
 ret

MostrarProducto ENDP


MostrarInventario PROC USES eax ecx esi
 mov esi,OFFSET catalogo
 mov ecx,cantidadProductos
 test ecx,ecx
 jz finInventario


cicloInventario:
 call MostrarProducto
 add esi,SIZEOF PRODUCTO
 loop cicloInventario


finInventario:
 ret

MostrarInventario ENDP


RegistrarProducto PROC USES eax ebx ecx edx esi edi
 cmp cantidadProductos,MAX_PRODUCTOS
 jae altaLlena

 call LeerCodigo
 jc finAlta

 mov edx,OFFSET entrada
 call EncontrarCodigo
 cmp eax,-1
 jne altaDuplicada

 mov esi,OFFSET temporal
 mov edi,esi
 mov ecx,SIZEOF PRODUCTO
 xor eax,eax
 rep stosb
 mov edi,esi
 mov esi,OFFSET entrada
 mov ecx,7
 rep movsb
 mov edx,OFFSET pedirNombre
 call PedirTexto
 cmp eax,1
 jb altaInvalida

 cmp eax,25
 ja altaInvalida

 mov ecx,eax
 mov esi,OFFSET entrada
 mov edi,OFFSET temporal.nombre
 rep movsb
 call LeerPrecio
 jc finAlta

 mov temporal.precio,eax
 mov edx,OFFSET pedirExistencias
 mov ebx,100
 xor edi,edi
 call LeerEntero
 jc finAlta

 mov temporal.existencias,eax
 mov eax,cantidadProductos
 imul eax,SIZEOF PRODUCTO
 lea edi,catalogo[eax]
 mov esi,OFFSET temporal
 mov ecx,SIZEOF PRODUCTO
 rep movsb
 inc cantidadProductos
 mov cambiosPendientes,1
 jmp altaExitosa


altaLlena:
 mov edx,OFFSET mensajeLleno
 jmp mostrarAlta


altaDuplicada:
 mov edx,OFFSET mensajeDuplicado
 jmp mostrarAlta


altaInvalida:
 mov edx,OFFSET mensajeInvalido
 jmp mostrarAlta


altaExitosa:
 mov edx,OFFSET mensajeExito

mostrarAlta:
 call MostrarTexto

finAlta:
 ret

RegistrarProducto ENDP


LocalizarProducto PROC USES eax edx
 call LeerCodigo
 jc localizacionInvalida

 mov edx,OFFSET entrada
 call EncontrarCodigo
 cmp eax,-1
 je productoNoExiste

 imul eax,SIZEOF PRODUCTO
 lea esi,catalogo[eax]
 clc
 ret


productoNoExiste:
 mov edx,OFFSET mensajeNoEncontrado
 call MostrarTexto

localizacionInvalida:
 stc
 ret

LocalizarProducto ENDP


BuscarProducto PROC USES esi
 call LocalizarProducto
 jc finBusqueda

 call MostrarProducto

finBusqueda:
 ret

BuscarProducto ENDP


RecibirMercancia PROC USES eax ebx edx edi esi
 call LocalizarProducto
 jc finRecepcion

 mov edx,OFFSET pedirCantidad
 mov ebx,100
 mov edi,1
 call LeerEntero
 jc finRecepcion

 mov ebx,[esi].PRODUCTO.existencias
 add ebx,eax
 cmp ebx,100
 ja recepcionExcesiva

 mov [esi].PRODUCTO.existencias,ebx
 mov cambiosPendientes,1
 mov edx,OFFSET mensajeExito
 jmp mostrarRecepcion


recepcionExcesiva:
 mov edx,OFFSET mensajeSinExistencias

mostrarRecepcion:
 call MostrarTexto

finRecepcion:
 ret

RecibirMercancia ENDP


VenderProducto PROC USES eax ebx ecx edx edi esi
 call LocalizarProducto
 jc finVenta

 mov edx,OFFSET pedirCantidad
 mov ebx,100
 mov edi,1
 call LeerEntero
 jc finVenta

 mov ecx,eax
 cmp ecx,[esi].PRODUCTO.existencias
 ja ventaRechazada

 mov eax,[esi].PRODUCTO.precio
 mul ecx
 test edx,edx
 jnz ventaRechazada

 mov ebx,eax
 mov edx,ingresos
 add edx,ebx
 jc ventaRechazada

 sub [esi].PRODUCTO.existencias,ecx
 mov ingresos,edx
 mov cambiosPendientes,1
 mov edx,OFFSET etiquetaVenta
 call MostrarTexto
 mov eax,ebx
 call MostrarPrecio
 jmp finVenta


ventaRechazada:
 mov edx,OFFSET mensajeSinExistencias
 call MostrarTexto

finVenta:
 ret

VenderProducto ENDP


MostrarResumen PROC USES eax ebx ecx edx esi edi
 xor edi,edi
 xor ebx,ebx
 mov esi,OFFSET catalogo
 mov ecx,cantidadProductos

cicloResumen:
 test ecx,ecx
 jz imprimirResumen

 add edi,[esi].PRODUCTO.existencias
 mov eax,[esi].PRODUCTO.precio
 mul [esi].PRODUCTO.existencias
 add ebx,eax
 add esi,SIZEOF PRODUCTO
 dec ecx
 jmp cicloResumen


imprimirResumen:
 mov edx,OFFSET etiquetaUnidades
 call MostrarTexto
 mov eax,edi
 call MostrarEntero
 call Crlf
 mov edx,OFFSET etiquetaValor
 call MostrarTexto
 mov eax,ebx
 call MostrarPrecio
 mov edx,OFFSET etiquetaIngresos
 call MostrarTexto
 mov eax,ingresos
 call MostrarPrecio
 ret

MostrarResumen ENDP


GuardarInventario PROC USES eax ecx edx esi edi
 mov cantidadArchivo,0
 mov eax,cantidadProductos
 mov cantidadArchivo,eax
 mov edi,OFFSET bufferArchivo
 mov eax,cabeceraArchivo
 stosd
 mov eax,cantidadProductos
 stosd
 mov esi,OFFSET catalogo
 mov ecx,cantidadProductos
 imul ecx,SIZEOF PRODUCTO
 rep movsb
 mov edx,OFFSET nombreArchivo
 call CreateOutputFile
 cmp eax,INVALID_HANDLE_VALUE
 je errorGuardado

 mov manejadorArchivo,eax
 mov edx,OFFSET bufferArchivo
 mov ecx,cantidadProductos
 imul ecx,SIZEOF PRODUCTO
 add ecx,8
 push ecx
 call WriteToFile
 pop ecx
 cmp eax,ecx
 jne errorCerrarGuardado

 mov eax,manejadorArchivo
 call CloseFile
 mov cambiosPendientes,0
 mov edx,OFFSET mensajeGuardado
 call MostrarTexto
 ret


errorCerrarGuardado:
 mov eax,manejadorArchivo
 call CloseFile

errorGuardado:
 mov edx,OFFSET mensajeErrorArchivo
 call MostrarTexto
 ret

GuardarInventario ENDP


CargarInventario PROC USES eax ebx ecx edx esi edi ebp
 mov edx,OFFSET nombreArchivo
 call OpenInputFile
 cmp eax,INVALID_HANDLE_VALUE
 je errorCarga

 mov manejadorArchivo,eax
 mov edx,OFFSET bufferArchivo
 mov ecx,SIZEOF bufferArchivo
 call ReadFromFile
 jc errorCerrarCarga

 mov ebp,eax
 mov eax,manejadorArchivo
 call CloseFile
 cmp ebp,8
 jb errorCarga

 cmp DWORD PTR bufferArchivo,324E5649h
 jne errorCarga

 mov eax,DWORD PTR bufferArchivo+4
 cmp eax,MAX_PRODUCTOS
 ja errorCarga

 mov cantidadNueva,eax
 imul eax,SIZEOF PRODUCTO
 add eax,8
 cmp eax,ebp
 jne errorCarga

 mov esi,OFFSET bufferArchivo+8
 xor ebx,ebx

validarRegistro:
 cmp ebx,cantidadNueva
 jae confirmarCarga

 push esi
 lea edx,[esi].PRODUCTO.codigo
 cmp BYTE PTR [edx+7],0
 jne cargaPilaError

 call ValidarCodigo
 test eax,eax
 jz cargaPilaError

 lea edi,[esi].PRODUCTO.nombre
 xor ecx,ecx

validarNombre:
 cmp ecx,26
 jae cargaPilaError

 cmp BYTE PTR [edi+ecx],0
 je finValidarNombre

 inc ecx
 jmp validarNombre


finValidarNombre:
 cmp ecx,1
 jb cargaPilaError

 cmp ecx,25
 ja cargaPilaError

 mov eax,[esi].PRODUCTO.precio
 cmp eax,1
 jb cargaPilaError

 cmp eax,999999
 ja cargaPilaError

 cmp DWORD PTR [esi].PRODUCTO.existencias,100
 ja cargaPilaError

 mov edi,OFFSET bufferArchivo+8
 mov ecx,ebx

validarUnicidad:
 test ecx,ecx
 jz codigoUnico

 push ecx
 push esi
 push edi
 mov ecx,7

compararRegistros:
 mov al,[esi]
 cmp al,[edi]
 jne registrosDistintos

 inc esi
 inc edi
 loop compararRegistros

 pop edi
 pop esi
 pop ecx
 jmp cargaPilaError


registrosDistintos:
 pop edi
 pop esi
 pop ecx
 add edi,SIZEOF PRODUCTO
 dec ecx
 jmp validarUnicidad


codigoUnico:
 pop esi
 add esi,SIZEOF PRODUCTO
 inc ebx
 jmp validarRegistro


cargaPilaError:
 pop esi
 jmp errorCarga


confirmarCarga:
 mov esi,OFFSET bufferArchivo+8
 mov edi,OFFSET catalogo
 mov ecx,cantidadNueva
 imul ecx,SIZEOF PRODUCTO
 rep movsb
 mov eax,cantidadNueva
 mov cantidadProductos,eax
 mov ingresos,0
 mov cambiosPendientes,0
 mov edx,OFFSET mensajeCargado
 call MostrarTexto
 ret


errorCerrarCarga:
 mov eax,manejadorArchivo
 call CloseFile

errorCarga:
 mov edx,OFFSET mensajeErrorArchivo
 call MostrarTexto
 ret

CargarInventario ENDP


main PROC

cicloMenu:
 mov edx,OFFSET menuPrincipal
 call PedirTexto
 cmp eax,1
 jne opcionInvalida

 mov al,entrada
 cmp al,'0'
 je opcionSalir

 cmp al,'1'
 je opcionAlta

 cmp al,'2'
 je opcionMostrar

 cmp al,'3'
 je opcionBuscar

 cmp al,'4'
 je opcionRecibir

 cmp al,'5'
 je opcionVender

 cmp al,'6'
 je opcionResumen

 cmp al,'7'
 je opcionGuardar

 cmp al,'8'
 je opcionCargar


opcionInvalida:
 mov edx,OFFSET mensajeInvalido
 call MostrarTexto
 jmp cicloMenu


opcionAlta:
 call RegistrarProducto
 jmp cicloMenu


opcionMostrar:
 call MostrarInventario
 jmp cicloMenu


opcionBuscar:
 call BuscarProducto
 jmp cicloMenu


opcionRecibir:
 call RecibirMercancia
 jmp cicloMenu


opcionVender:
 call VenderProducto
 jmp cicloMenu


opcionResumen:
 call MostrarResumen
 jmp cicloMenu


opcionGuardar:
 call GuardarInventario
 jmp cicloMenu


opcionCargar:
 call CargarInventario
 jmp cicloMenu


opcionSalir:
 cmp cambiosPendientes,0
 je mainEnd

 mov edx,OFFSET avisoCambios
 call PedirTexto
 cmp eax,1
 jne cicloMenu

 mov al,entrada
 cmp al,'S'
 je mainEnd

 cmp al,'s'
 jne cicloMenu


mainEnd:
 exit

main ENDP

END main
