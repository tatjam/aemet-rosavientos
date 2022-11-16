import pixie
import request
import math
import strutils

let WIDTH = 2048.0
let HEIGHT = 2048.0
let MARGEN_LEYENDA = 400.0
let MARGEN = 100.0

var font = readFont("Roboto-Regular_1.ttf")

# Agrupamos en 16 direcciones y 5 velocidades
# se indexa de la forma tabla[rumbo[velocidad]]
let nombres = ["E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW", "N", "NNE", "NE", "ENE"]
type TablaFrecuenciaVientos* = array[16, array[5, int]]

proc indice_rumbo(dir: float): int =
    if dir >= 8 and dir <= 10: return 0
    elif dir >= 10 and dir <= 12: return 1
    elif dir >= 12 and dir <= 15: return 2
    elif dir >= 15 and dir <= 17: return 3
    elif dir >= 17 and dir <= 19: return 4
    elif dir >= 19 and dir <= 21: return 5
    elif dir >= 21 and dir <= 24: return 6
    elif dir >= 24 and dir <= 26: return 7
    elif dir >= 26 and dir <= 28: return 8
    elif dir >= 28 and dir <= 30: return 9
    elif dir >= 30 and dir <= 33: return 10
    elif dir >= 33 and dir <= 35: return 11
    elif (dir >= 35 and dir <= 36) or dir <= 1: return 12
    elif dir >= 1 and dir <= 3: return 13
    elif dir >= 3 and dir <= 6: return 14
    elif dir >= 6 and dir <= 8: return 15

proc indice_vel(vel: float, max: float, min: float): int = 
    for i in 0..4:
        let lbound = min + i.toFloat * (max - min) / 10
        let ubound = min + (i + 1).toFloat * (max - min) / 10
        if vel <= ubound and vel >= lbound:
            return i

proc max_min_vel(datos: seq[DatoDiario]): (float, float) = 
    var maxvel = 1.0
    var minvel = 99999999.0
    for dato in datos:
        if dato.racha > maxvel:
            maxvel = dato.racha
        if dato.racha < minvel:
            minvel = dato.racha

    return (maxvel, minvel)



proc generar_tabla_frecuencias(datos: seq[DatoDiario]): TablaFrecuenciaVientos =
    let (max, min) = max_min_vel(datos)

    for dato in datos:
        let idx_vel = indice_vel(dato.racha, max, min)
        let idx_dir = indice_rumbo(dato.dir_rachamax)
        result[idx_dir][idx_vel] = result[idx_dir][idx_vel] + 1
        # echo result[idx_dir][idx_vel]

    return result

# genera un csv
proc escribir(tabla: TablaFrecuenciaVientos, datos: seq[DatoDiario], max: float, min: float): string = 
    
    var maxrumbo: array[16, float]
    for i in 0..15:
        maxrumbo[i] = 0.0
    
    for dato in datos:
        let rumbo = indice_rumbo(dato.dir_rachamax)
        if dato.racha > maxrumbo[rumbo]:
            maxrumbo[rumbo] = dato.racha

    result = result & "vel / dir,"
    for i in 0..14:
        result = result & nombres[i]
        result = result & ", "
    result = result & nombres[15]
    result = result & "\n"
    
    var maxfreq = 0
    var minfreq = 99999
    var total = 0
    for i in 0..4:
        for j in 0..15:
            if tabla[j][i] > maxfreq:
                maxfreq = tabla[j][i]
            if tabla[j][i] < minfreq:
                minfreq = tabla[j][i]
            total = total + tabla[j][i]

    # Dividimos en 5 velocidades
    for i in 0..4:
        let lbound = (min + i.toFloat * (max - min) / 10).formatFloat(ffDecimal, 1)
        let ubound = (min + (i + 1).toFloat * (max - min) / 10).formatFloat(ffDecimal, 1)
        result = result & lbound & " - " & ubound & " m/s,"
        for rumbo in 0..14:
            let freq = tabla[rumbo][i]
            let valor = (freq / total * 100.0).formatFloat(ffDecimal, 3)
            result = result & valor & ", "
        
        result = result & (tabla[15][i] / total * 100.0).formatFloat(ffDecimal, 3) & "\n"

    # Fila final, velocidad maxima en cada direccion
    result = result & "vmax (m/s)," 
    for rumbo in 0..14:
        result = result & maxrumbo[rumbo].formatFloat(ffDecimal, 3) & ","
    result = result & maxrumbo[15].formatFloat(ffDecimal, 3)


proc dibujar_rosa_base(image: Image): float =
    let ctx_out = newContext(image)

    # Circulo base
    ctx_out.strokeStyle = rgba(0, 0, 0, 255)
    ctx_out.lineWidth = 4.0

    var radio = WIDTH / 2 - MARGEN

    ctx_out.circle(WIDTH / 2, HEIGHT / 2, radio)
    ctx_out.stroke()


    for i in 0..15:
        let ctx = newContext(image)
        # Lines radiales (dividen en 16 pedazos la circunferencia)
        ctx.strokeStyle = rgba(0, 0, 0, 255)
        ctx.lineWidth = 2.0

        let alpha = i.toFloat * 2.0 * PI / 16.0
        let endx = cos(alpha) * radio
        let endy = sin(alpha) * radio
        ctx.moveTo(WIDTH / 2, HEIGHT / 2)
        ctx.lineTo(WIDTH / 2 + endx, HEIGHT / 2 + endy)
        ctx.stroke()

        let nombre = nombres[i]
        image.fillText(font.typeset(nombre, vec2(100, 100), HorizontalAlignment.CenterAlign, VerticalAlignment.MiddleAlign), 
            translate(vec2(WIDTH / 2 + endx * 1.07, HEIGHT / 2 + endy * 1.07)) * scale(vec2(4.0, 4.0)) * translate(vec2(-50, -50)))

    return radio


proc dibujar_rosa_maxvel(image: Image, datos: seq[DatoDiario], maxvel: float) = 
    let radio = dibujar_rosa_base(image)
    
    # Poligono de racha maxima en cada direccion
    var maxrumbo: array[16, float]
    for i in 0..15:
        maxrumbo[i] = 0.0
    
    for dato in datos:
        let rumbo = indice_rumbo(dato.dir_rachamax)
        if dato.racha > maxrumbo[rumbo]:
            maxrumbo[rumbo] = dato.racha

    let ctx = newContext(image)
    ctx.lineWidth = 4.0
    ctx.strokeStyle = rgba(0, 0, 255, 255)
    ctx.fillStyle = rgba(0, 0, 255, 128)
    var first = true
    var firstx = 0.0
    var firsty = 0.0

    for rumbo in 0..15:
        let vel = maxrumbo[rumbo]
        let rad = vel / maxvel
        let alpha = rumbo.toFloat * PI / 8.0
        let posx = cos(alpha) * rad * radio + WIDTH / 2
        let posy = sin(alpha) * rad * radio + HEIGHT / 2
        if first:
            ctx.moveTo(posx, posy)
            first = false
            firstx = posx 
            firsty = posy
        else:
            ctx.lineTo(posx, posy)
    ctx.lineTo(firstx, firsty)
    ctx.fill()
    ctx.stroke()


    # Dividimos en 10 segmentos
    for i in 1..10:
        let ctx = newContext(image)

        let vel_equiv = i.toFloat * maxvel / 10.0
        let rad_equiv = i.toFloat * radio / 10.0
        ctx.circle(WIDTH / 2, HEIGHT / 2, rad_equiv)
        ctx.stroke()
        
        var nombre = vel_equiv.formatFloat(ffDecimal, 1)
        if i == 10:
            nombre = nombre & "m/s"
        image.fillText(font.typeset(nombre, vec2(100, 100), HorizontalAlignment.CenterAlign, VerticalAlignment.MiddleAlign), 
            translate(vec2(WIDTH / 2 - 35, HEIGHT / 2 - rad_equiv - 20)) * scale(vec2(3.0, 3.0)) * translate(vec2(-50, -50)))

proc dibujar_rosa_freq(image: Image, maxvel: float, minvel: float, tabla: TablaFrecuenciaVientos) =
    let radio = dibujar_rosa_base(image)

    var maxfreq = 0
    var minfreq = 99999
    var total = 0
    for i in 0..4:
        for j in 0..15:
            if tabla[j][i] > maxfreq:
                maxfreq = tabla[j][i]
            if tabla[j][i] < minfreq:
                minfreq = tabla[j][i]
            total = total + tabla[j][i]



    # Dibujamos los polígonos de cada velocidad
    #for vel in 0..9:
    var prevx = 0.0
    var prevy = 0.0
    var firstx = 0.0
    var firsty = 0.0

    let colores = [rgba(128, 128, 255, 255), rgba(0, 255, 0, 255), rgba(255, 128, 128, 255), rgba(64, 0, 64, 255), rgba(255, 191, 127, 255)]

    for vel in 0..4:
        let color = colores[vel]
        var first = true
        for rumbo in 0..15:
            let ctx = newContext(image)
            ctx.lineWidth = 4.0 + vel.toFloat * 1.5
            ctx.strokeStyle = color
            let frecuencia = tabla[rumbo][vel]
            let rad = frecuencia.toFloat / maxfreq.toFloat
            let alpha = rumbo.toFloat * PI / 8.0
            let posx = cos(alpha) * rad * radio + WIDTH / 2
            let posy = sin(alpha) * rad * radio + HEIGHT / 2
            # echo rad

            if first:
                first = false
                firstx = posx
                firsty = posy
            else:
                ctx.moveTo(prevx, prevy)
                ctx.lineTo(posx, posy)
            
            prevx = posx
            prevy = posy
            ctx.stroke()

        let ctx = newContext(image)
        ctx.lineWidth = 5.0
        ctx.strokeStyle = color
        ctx.moveTo(firstx, firsty)
        ctx.lineTo(prevx, prevy)
        ctx.stroke()

    # Dividimos en 10 segmentos
    for i in 1..10:
        let ctx = newContext(image)

        let f_equiv = i.toFloat * maxfreq.toFloat / (total.toFloat * 10)
        let rad_equiv = i.toFloat * radio / 10.0
        ctx.circle(WIDTH / 2, HEIGHT / 2, rad_equiv)
        ctx.stroke()
        
        let nombre = (f_equiv * 100).formatFloat(ffDecimal, 1) & "%"
        image.fillText(font.typeset(nombre, vec2(100, 100), HorizontalAlignment.CenterAlign, VerticalAlignment.MiddleAlign), 
            translate(vec2(WIDTH / 2 - 35, HEIGHT / 2 - rad_equiv - 20)) * scale(vec2(3.0, 3.0)) * translate(vec2(-50, -50)))


    # Dibujamos la leyenda
    for i in 0..4:
        let lbound = minvel + i.toFloat * (maxvel - minvel) / 10
        let ubound = minvel + (i + 1).toFloat * (maxvel - minvel) / 10

        let ctx = newContext(image)
        ctx.lineWidth = 4.0 + i.toFloat * 1.5
        ctx.strokeStyle = colores[i]
        ctx.moveTo(WIDTH / 2 + 250.0, HEIGHT + 50 + i.toFloat * 75)
        ctx.lineTo(WIDTH / 2 + 400.0, HEIGHT + 50 + i.toFloat * 75)
        ctx.stroke()
 
        let nombre = lbound.formatFloat(ffDecimal, 1) & " - " & ubound.formatFloat(ffDecimal, 1) & " m/s"
        image.fillText(font.typeset(nombre, vec2(100, 100), HorizontalAlignment.CenterAlign, VerticalAlignment.MiddleAlign), 
            translate(vec2(WIDTH / 2 + 650.0, HEIGHT + 50 + i.toFloat * 75)) * scale(vec2(5.0, 5.0)) * translate(vec2(-50, -50)))



proc rosa_vientos*(filename: string, datos: seq[DatoDiario]) =
    let image_freq = newImage(WIDTH.int, HEIGHT.int + MARGEN_LEYENDA.int)
    let image_maxvel = newImage(WIDTH.int, HEIGHT.int)

    image_freq.fill(rgba(255, 255, 255, 255))
    image_maxvel.fill(rgba(255, 255, 255, 255))

    let tabla = generar_tabla_frecuencias(datos)
    let (maxvel, minvel) = max_min_vel(datos)

    let csv = tabla.escribir(datos, maxvel, minvel)
    writeFile(filename & "_tabla.csv", csv)

    image_freq.dibujar_rosa_freq(maxvel, minvel, tabla)
    image_maxvel.dibujar_rosa_maxvel(datos, maxvel)
    
    image_freq.writeFile(filename & "_freq.png")
    image_maxvel.writeFile(filename & "_maxvel.png")

