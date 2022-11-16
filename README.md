Para utilizar el software debe estar presente un fichero llamado ``apikey.txt`` que contenga
la API key generada en opendata.aemet.es

Para generar la rosa de los vientos, se invoca el programa con un primer argumento
que representa el nombre de la estación a utilizar. Se puede concretar la fecha con el segundo y
tercer argumento, que indican la fecha de inicio y final para los calculos. Fechas en formato
``yyyy-MM-dd`` (máximo 5 años)

Ejemplo: Observacion en valladolid desde 2015 hasta 2018

``rosavientos 2422 2015-01-01 2018-01-01``


Nota: No se puede acceder desde eduroam, se deben utilizar los datos del móvil o una conexión
no institucional!

Nota: Por desgracia, la mayoría de las estaciones no están disponibles, 