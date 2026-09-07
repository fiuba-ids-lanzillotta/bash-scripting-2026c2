# Proyecto Fase 1 - Bash

Scripts en Bash para la Fase 1 de Introducción al Desarrollo de Software.

## Archivos

- `proyecto.sh` - Script principal con el menú de opciones.
- `consolidar.sh` - Proceso en background que consolida archivos `.txt` de la carpeta `entrada`.
- `alumnos1.txt` y `alumnos2.txt` - Archivos de ejemplo con registros de alumnos.

## Uso

Definir la variable de ambiente `FILENAME` con el nombre base del archivo de salida (sin la extensión `.txt`).

```bash
export FILENAME=alumnos
bash proyecto.sh
```

### Opciones del menú

1. **Crear entorno**: crea el directorio `~/EPNro1` con las subcarpetas `entrada`, `salida` y `procesado`, y copia `consolidar.sh` dentro.
2. **Correr proceso**: inicia `consolidar.sh` en background para procesar archivos `.txt` de `entrada`.
3. **Listado ordenado por padrón**: muestra el contenido de `~/EPNro1/salida/${FILENAME}.txt` ordenado por número de padrón.
4. **10 notas más altas**: muestra los 10 registros con las notas más altas.
5. **Buscar por padrón**: solicita un número de padrón y muestra su registro.
6. **Visualizar log**: muestra el archivo `~/EPNro1/procesado.log`.
7. **Salir**: cierra el menú.

### Parámetro `-d`

Para eliminar todo el entorno creado y terminar los procesos en background:

```bash
bash proyecto.sh -d
```

## Formato de archivos de entrada

Cada línea debe contener cuatro campos separados por espacios:

```
Nro_Padron Nombre Apellido email nota
```

Ejemplo:

```
122332 Juan Lopez jlopez@fi.uba.ar 8
100998 Pedro Valdez pvaldez@fi.uba.ar 5
```

## Prueba rápida

```bash
export FILENAME=alumnos
bash proyecto.sh
# Opción 1 -> crear entorno
# Opción 2 -> iniciar proceso consolidador
# Copiar los archivos de ejemplo a ~/EPNro1/entrada
cp alumnos1.txt alumnos2.txt ~/EPNro1/entrada
# Esperar unos segundos y usar las opciones 3, 4, 5 o 6
# Opción 7 -> salir
# bash proyecto.sh -d -> limpiar todo
```
