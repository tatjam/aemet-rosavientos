import httpclient
import json
import times
import std/strutils
export json

type DatoDiario* = object 
    dia*: DateTime
    tmedia*: float
    precip*: float # mm
    tminima*: float
    tmaxima*: float
    dir_rachamax*: float # en decenas de grado 99 = variable 88 = sin dato
    racha*: float # racha maxima de viento en m/s
    velmedia*: float # velocidad media del viento en m/s (sin indicar direccion)



proc comando_rest*(apikey: string, comando: string): JsonNode = 
    var client = newHttpClient()
    var url = "https://opendata.aemet.es/opendata/api/"
    url = url & comando 
    url = url & "/?api_key=" & apikey
    return parseJson(client.getContent(url))

proc entender_datos(datos: JsonNode): seq[DatoDiario] =
    result = newSeq[DatoDiario]()
    var nohay_tmedia = false
    var nohay_precip = false
    var nohay_tminima = false
    var nohay_tmaxima = false
    var nohay_dir_rachamax = false
    var nohay_racha = false
    var nohay_velmedia = false
    # Extraemos todo lo posible
    for elem in datos:
        var datum: DatoDiario
        datum.dia = parse(elem["fecha"].getStr(), "yyyy-MM-dd")
        if elem.hasKey("tmed"):
            datum.tmedia = parseFloat(elem["tmed"].getStr().replace(",", "."))
        elif nohay_tmedia == false:
            datum.tmedia = 0.0
            echo "Faltan datos de temperatura media"
            nohay_tmedia = true
        
        if elem.hasKey("prec"):
            if elem["prec"].getStr() == "Ip":
                datum.precip = 0
            else:
                datum.precip = parseFloat(elem["prec"].getStr().replace(",", "."))
        elif nohay_precip == false:
            datum.precip = 0.0
            echo "Faltan datos de precipitación"
            nohay_precip = true
        
        if elem.hasKey("tmin"):
            datum.tminima = parseFloat(elem["tmin"].getStr().replace(",", "."))
        elif nohay_tminima == false:
            datum.tminima = 0.0
            echo "Faltan datos de temperatura minima"
            nohay_tminima = true
        
        if elem.hasKey("tmax"):
            datum.tmaxima = parseFloat(elem["tmax"].getStr().replace(",", "."))
        elif nohay_tmaxima == false:
            datum.tmaxima = 0.0
            echo "Faltan datos de temperatura maxima"
            nohay_tmaxima = true
        
        if elem.hasKey("dir"):
            datum.dir_rachamax = parseFloat(elem["dir"].getStr().replace(",", "."))
        elif nohay_dir_rachamax == false:
            datum.dir_rachamax = 0.0
            echo "Faltan datos de dirección de racha máxima"
            nohay_dir_rachamax = true
        
        if elem.hasKey("racha"):
            datum.racha = parseFloat(elem["racha"].getStr().replace(",", "."))
        elif nohay_racha == false:
            datum.racha = 0.0
            echo "Faltan datos de velocidad de racha máxima"
            nohay_racha = true
        
        if elem.hasKey("velmedia"):
            datum.velmedia = parseFloat(elem["velmedia"].getStr().replace(",", "."))
        elif nohay_velmedia == false:
            datum.velmedia = 0.0
            echo "Faltan datos de velocidad de vientos media"
            nohay_velmedia = true

        result.add(datum)
        


# Funcion monolítica que obtiene todo lo necesario
proc request*(apikey: string, estacion: string, inicio: string, final: string): seq[DatoDiario] =

    var url = "valores/climatologicos/diarios/datos/fechaini/"
    url = url & inicio & "T00:00:00UTC/fechafin/" & final & "T00:00:00UTC/estacion/" & estacion
    let json1 = comando_rest(apikey, url)
    if json1["estado"].getInt() == 200:
        var url2 = json1["datos"].getStr()
        var client = newHttpClient()
        var datos = parseJson(client.getContent(url2))
        return entender_datos(datos)
    else:
        echo "Sucedio un error durante la petición a AEMET"
        quit()

