import request
import times

# Imprime en terminal la T de referencia
proc T_referencia*(datos: seq[DatoDiario]) = 
    # Obtener el mes mas caluroso de media
    var media_mensual: array[Month, float]
    var num_mensual: array[Month, int]

    for dato in datos:
        media_mensual[dato.dia.month()] = media_mensual[dato.dia.month()] + dato.tmedia
        num_mensual[dato.dia.month()] = num_mensual[dato.dia.month()] + 1
    for m in Month:
        media_mensual[m] = media_mensual[m] / num_mensual[m].toFloat
    
    var max_mes: Month
    var max_T = -10000.0

    for m in Month:
        if media_mensual[m] > max_T:
            max_mes = m
            max_T = media_mensual[m]

    echo "El mes mas caluroso es: " & $max_mes

    var media_maximas = 0.0
    var num_maximas = 0
    for dato in datos:
        if dato.dia.month() == max_mes:
            media_maximas = media_maximas + dato.tmaxima
            num_maximas = num_maximas + 1
    
    var tref = media_maximas / num_maximas.toFloat

    echo "La temperatura de referencia es: " & $tref & "C"