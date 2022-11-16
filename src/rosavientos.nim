import os
import times
import request
import graficador

when isMainModule:
    var estacion = ""
    var inicio, final: DateTime
    # Interpretación de los argumentos
    if not (paramCount() == 1 or paramCount() == 3):
        echo "Cantidad de argumentos invalida. Invocar con [nombre estacion] [(fecha de inicio) (fecha final)]?"
        echo "Formato de fechas: yyyy-MM-dd     Ejemplo 2022-11-15"
        echo "Ejemplo argumentos: 2604B 2015-01-01 2018-01-01"
        quit()
    if paramCount() == 1:
        # solo estación metereologica, ultimos 5 años (casi, limite API!)
        estacion = paramStr(1)
        final = now()
        inicio = now() - 5.years + 1.days
    if paramCount() == 3:
        estacion = paramStr(1)
        inicio = parse(paramStr(2), "yyyy-MM-dd")
        final = parse(paramStr(3), "yyyy-MM-dd")

    # Cargar API key
    let apikey = readFile("apikey.txt")

    echo "Invocando Rosa de los Vientos con los siguientes parametros:"
    echo "Estacion: " & estacion
    echo "Inicio: " & inicio.format("yyyy-MM-dd")
    echo "Final: " & final.format("yyyy-MM-dd")

    let datos = request(apikey, estacion, inicio.format("yyyy-MM-dd"), final.format("yyyy-MM-dd"))
    echo "Se obtuvieron " & $len(datos) & " datos para " & $(final - inicio).inDays & " dias"
    let filename = "./out/" & estacion & "_" & inicio.format("yyyy-MM-dd") & "_" & final.format("yyyy-MM-dd")
    echo "Generando graficos en " & filename

    rosa_vientos(filename, datos)
