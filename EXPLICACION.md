# Explicación paso a paso de los scripts

Este documento está pensado para acompañar la presentación del proyecto a estudiantes de primer año. Explica, línea por línea y comando por comando, qué hace cada script y por qué se eligió esa forma de resolverlo.

---

## 1. ¿Qué hace el proyecto?

El proyecto consta de dos scripts de Bash:

- `proyecto.sh`: muestra un menú interactivo. Desde allí se crea un entorno de carpetas, se inicia un proceso en background, se consultan datos y se limpia todo al final si se usó el flag `-d`.
- `consolidar.sh`: es el proceso en background. Se queda corriendo, revisa cada 5 segundos la carpeta `entrada`, toma los archivos `.txt`, les agrega su contenido al archivo final y los mueve a `procesado`. Además escribe un log.

Ambos scripts están escritos **sin funciones**, siguiendo la consigna.

---

## 2. Conceptos generales que se usan

### `#!/bin/bash`

Es la primera línea de ambos scripts. Se llama **shebang** y le dice al sistema operativo: "Este archivo debe ejecutarse con el intérprete `/bin/bash`".

### Variables

En Bash se asignan así:

```bash
NOMBRE=valor
```

**Importante:** no debe haber espacios alrededor del `=`.

Para usar el valor de una variable se escribe `$NOMBRE` o, para evitar confusiones, `"${NOMBRE}"`.

### Variable de entorno `FILENAME`

`FILENAME` es el nombre base del archivo de salida. Si el usuario ejecuta:

```bash
export FILENAME=alumnos
```

entonces el archivo final se llamará `alumnos.txt` y quedará en `~/EPNro1/salida/`.

`export` se usa para que los procesos hijos (como `consolidar.sh`) también vean esa variable.

### Parámetros del script

`$1`, `$2`, etc. son los argumentos que se le pasan al script. `$0` es el nombre del script.

`${1:-}` significa: "usa `$1`, pero si no existe devuelve una cadena vacía". Así evitamos errores si el usuario no pasó ningún parámetro.

### Comillas

- `"$HOME"`: las comillas dobles permiten que se expandan variables (`$HOME` se reemplaza por `/home/usuario`).
- `'texto'`: las comillas simples NO expanden variables.

---

## 3. Explicación de `proyecto.sh`

```bash
#!/bin/bash
```
Indica que se interpreta con Bash.

```bash
SALIR=0
LIMPIAR=0
```

Son dos **variables centinela** (o banderas):

- `SALIR` controla cuándo termina el menú. `0` significa "seguir mostrando el menú"; `1` significa "salir".
- `LIMPIAR` controla si al final hay que borrar el entorno. `0` significa "no limpiar"; `1` significa "limpiar".

Se usan en lugar de `while true` y `exit 0` para poder dejar el bloque de limpieza al final del script.

```bash
if [ "${1:-}" = "-d" ]; then
    LIMPIAR=1
fi
```

Si el primer parámetro (`$1`) es `-d`, se activa la limpieza. El menú igual se muestra. Solo se cambia el comportamiento final.

```bash
if [ -z "$FILENAME" ]; then
    echo "Error: debe definir la variable de ambiente FILENAME."
    echo "Ejemplo: export FILENAME=alumnos"
    exit 1
fi
```

`-z` pregunta si la cadena está vacía. Si `FILENAME` no fue definida, el script avisa y termina con código de error `1`.

```bash
if [ -n "$FILENAME" ]; then
    export FILENAME
fi
```

`-n` pregunta si la cadena NO está vacía. Si `FILENAME` tiene valor, se exporta para que `consolidar.sh` (que se ejecuta como proceso hijo) pueda leerla.

```bash
while [ "$SALIR" -eq 0 ]; do
```

`while` es un bucle. La condición `[ "$SALIR" -eq 0 ]` se lee como: "mientras SALIR sea igual a 0". Mientras sea cierto, se repite el menú.

```bash
    echo "-----------------------------------"
    echo "Menu Principal"
    echo "1) Crear entorno"
    ...
```

`echo` imprime texto en pantalla. Aquí se dibuja el menú.

```bash
    read -p "Ingrese una opcion: " opcion || break
```

`read -p "texto" variable` muestra el texto y espera que el usuario escriba algo. Lo que escriba se guarda en `opcion`.

`||` significa "o, en caso de que falle". Si el usuario presiona `Ctrl+D` (fin de archivo), `read` falla y entonces se ejecuta `break`, que sale del `while`.

```bash
    case "$opcion" in
```

`case` es como un `switch` de otros lenguajes. Compara el valor de `opcion` contra varios patrones.

---

### Opción 1: Crear entorno

```bash
        1)
            mkdir -p "$HOME/EPNro1/entrada"
            mkdir -p "$HOME/EPNro1/salida"
            mkdir -p "$HOME/EPNro1/procesado"
```

`mkdir` crea directorios. La opción `-p` significa "crear también los directorios padres si no existen". Así se crean `entrada`, `salida` y `procesado` dentro de `EPNro1`.

```bash
            SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
```

- `$0` es el nombre con el que se invocó al script.
- `dirname "$0"` devuelve el directorio donde está el script.
- `cd` entra a ese directorio.
- `2>/dev/null` oculta posibles mensajes de error.
- `pwd` devuelve la ruta absoluta.
- `$( ... )` captura el resultado y lo guarda en `SCRIPT_DIR`.

Esto permite encontrar `consolidar.sh` aunque se ejecute `proyecto.sh` desde otro directorio.

```bash
            if [ -f "$SCRIPT_DIR/consolidar.sh" ]; then
                cp "$SCRIPT_DIR/consolidar.sh" "$HOME/EPNro1/consolidar.sh"
                chmod +x "$HOME/EPNro1/consolidar.sh"
                echo "Entorno creado y consolidar.sh copiado."
            else
                echo "Entorno creado. No se encontro consolidar.sh junto al script principal."
            fi
```

`-f` verifica si el archivo existe. Si existe, se copia a `~/EPNro1/` y se le da permiso de ejecución con `chmod +x`.

---

### Opción 2: Correr proceso

```bash
        2)
            if [ ! -f "$HOME/EPNro1/consolidar.sh" ]; then
                echo "Primero debe crear el entorno con la opcion 1."
            else
                nohup "$HOME/EPNro1/consolidar.sh" >/dev/null 2>&1 &

                echo "$!" > "$HOME/EPNro1/consolidar.pid"
                echo "Proceso consolidar.sh iniciado en background (PID $!)."
            fi
```

`! -f` significa "no existe el archivo". Si no se creó el entorno, avisa.

Si existe, se ejecuta:

```bash
nohup "$HOME/EPNro1/consolidar.sh" >/dev/null 2>&1 &
```

Desglose:

- `nohup`: "no hang up". Evita que el proceso se cierre cuando el usuario cierra la terminal.
- `>/dev/null`: redirige la salida estándar (lo que imprimiría por pantalla) a "la nada".
- `2>&1`: redirige la salida de errores (`2`) a donde apunta la salida estándar (`1`), o sea, también a `/dev/null`.
- `&`: ejecuta el comando en segundo plano (background).

```bash
                echo "$!" > "$HOME/EPNro1/consolidar.pid"
```

`$!` es una variable especial que guarda el número de proceso (PID) del último comando ejecutado en background. Se guarda en un archivo para poder matarlo después.

---

### Opción 3: Listado ordenado por padrón

```bash
        3)
            SALIDA="$HOME/EPNro1/salida/${FILENAME}.txt"

            if [ -f "$SALIDA" ]; then
                echo "Listado de alumnos ordenados por numero de padron:"
                sort -n -k1,1 "$SALIDA"
            else
                echo "No existe el archivo $SALIDA"
            fi
```

`sort -n -k1,1 archivo`:

- `sort`: ordena líneas.
- `-n`: orden numérico (no alfabético).
- `-k1,1`: ordena usando solo la primera columna.

El formato de los archivos tiene el padrón como primera columna, así que ordena por padrón.

---

### Opción 4: Las 10 notas más altas

```bash
        4)
            SALIDA="$HOME/EPNro1/salida/${FILENAME}.txt"

            if [ -f "$SALIDA" ]; then
                echo "10 notas mas altas:"

                awk '{print $NF "|" $0}' "$SALIDA" | sort -t'|' -nr -k1,1 | head -n 10 | cut -d'|' -f2-
```

Este es un **pipeline** (varios comandos unidos por `|`). Veamos cada parte:

#### `awk '{print $NF "|" $0}'`

- `awk` lee línea por línea.
- `$NF` es el **último campo** de la línea. En nuestro formato, el último campo es la nota.
- `$0` es la línea completa.
- `"|"` es un separador inventado (`|`) que no aparece en los datos.

Entonces, si la línea es:

```
122332 Juan Lopez jlopez@fi.uba.ar 8
```

`awk` produce:

```
8|122332 Juan Lopez jlopez@fi.uba.ar 8
```

Se agrega la nota al principio para poder ordenar por ella.

#### `sort -t'|' -nr -k1,1`

- `-t'|'`: indica que el separador de columnas es `|`.
- `-n`: orden numérico.
- `-r`: reverso (de mayor a menor).
- `-k1,1`: ordena por la primera columna, que ahora es la nota.

#### `head -n 10`

`head` muestra solo las primeras 10 líneas del resultado. Así obtenemos las 10 notas más altas.

#### `cut -d'|' -f2-`

- `cut` corta columnas.
- `-d'|'`: separador `|`.
- `-f2-`: desde la segunda columna en adelante.

Esto quita la nota auxiliar que agregamos al principio, dejando solo la línea original:

```
122332 Juan Lopez jlopez@fi.uba.ar 8
```

---

### Opción 5: Buscar por padrón

```bash
        5)
            SALIDA="$HOME/EPNro1/salida/${FILENAME}.txt"

            if [ -f "$SALIDA" ]; then
                read -p "Ingrese numero de padron: " padron

                RESULTADO="$(grep -w "^$padron" "$SALIDA")"

                if [ -n "$RESULTADO" ]; then
                    echo "$RESULTADO"
                else
                    echo "No se encontro el padron $padron."
                fi
```

`grep -w "^$padron" archivo`:

- `grep` busca líneas que coincidan con un patrón.
- `^` significa "al principio de la línea".
- `$padron` es el número ingresado por el usuario.
- `-w` significa "palabra completa". Así evitamos que buscar `12` coincida con `122332`.

`$( ... )` captura el resultado del `grep` y lo guarda en `RESULTADO`.

`[ -n "$RESULTADO" ]` verifica que `RESULTADO` no esté vacío. Si se encontró algo, se imprime; si no, se avisa.

---

### Opción 6: Visualizar log

```bash
        6)
            LOG="$HOME/EPNro1/procesado.log"

            if [ -f "$LOG" ]; then
                echo "Contenido del log:"
                cat "$LOG"
            else
                echo "No existe el archivo de log $LOG"
            fi
```

`cat archivo` muestra todo el contenido del archivo en pantalla.

---

### Opción 7: Salir

```bash
        7)
            echo "Saliendo..."
            SALIR=1
```

Cambia la centinela `SALIR` a `1`. En la próxima vuelta del `while`, la condición `[ "$SALIR" -eq 0 ]` será falsa y el bucle terminará.

```bash
    if [ "$SALIR" -eq 1 ]; then
        continue
    fi
```

Si el usuario eligió salir, `continue` salta directamente a la siguiente evaluación del `while`. Así no se ejecuta el `read -p "Presione ENTER..."` de espera.

```bash
    echo
    read -p "Presione ENTER para continuar..." || break
    echo
done
```

Espera que el usuario presione ENTER antes de mostrar el menú nuevamente. `|| break` permite salir si el usuario presiona `Ctrl+D`.

```bash
if [ "$LIMPIAR" -eq 1 ]; then
    echo "Eliminando entorno..."

    PID_FILE="$HOME/EPNro1/consolidar.pid"

    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null

        rm -f "$PID_FILE"
    fi

    pkill -f "[c]onsolidar.sh" 2>/dev/null

    rm -rf "$HOME/EPNro1"

    echo "Entorno eliminado."
fi
```

Este bloque se ejecuta solo si `LIMPIAR` vale `1`, es decir, si se invocó el script con `-d`.

- `kill "$(cat "$PID_FILE")"`: lee el PID guardado y mata ese proceso.
- `pkill -f "[c]onsolidar.sh"`: busca procesos cuya línea de comandos contenga `consolidar.sh` y los mata. El patrón `[c]onsolidar.sh` evita que el propio comando `pkill` se identifique a sí mismo.
- `rm -rf "$HOME/EPNro1"`: borra el directorio completo.

---

## 4. Explicación de `consolidar.sh`

```bash
#!/bin/bash
```

Igual que antes, indica que se ejecuta con Bash.

```bash
EP_DIR="$HOME/EPNro1"
ENTRADA_DIR="$EP_DIR/entrada"
SALIDA_DIR="$EP_DIR/salida"
PROCESADO_DIR="$EP_DIR/procesado"
LOG_FILE="$EP_DIR/procesado.log"

SALIDA_FILE="$SALIDA_DIR/${FILENAME}.txt"
```

Se definen rutas usando variables para que el código sea más claro y fácil de mantener.

```bash
mkdir -p "$ENTRADA_DIR"
mkdir -p "$SALIDA_DIR"
mkdir -p "$PROCESADO_DIR"
```

Crea las carpetas si no existen. El `-p` evita errores si ya existen.

```bash
while true; do
```

Bucle infinito. El proceso se queda corriendo para siempre (hasta que se lo mate).

```bash
    for archivo in "$ENTRADA_DIR"/*.txt; do
```

Itera sobre todos los archivos `.txt` de la carpeta `entrada`.

```bash
        [ -e "$archivo" ] || continue
```

`-e` pregunta si el archivo existe. Si no existe (por ejemplo, si la carpeta está vacía y el glob `*.txt` no coincidió con nada), `continue` salta a la siguiente iteración.

```bash
        cat "$archivo" >> "$SALIDA_FILE"
```

`cat archivo` muestra el contenido. `>>` significa "agregar al final" del archivo destino. Así se concatenan todos los archivos de entrada en uno solo.

```bash
        mv "$archivo" "$PROCESADO_DIR/"
```

Mueve el archivo original a la carpeta `procesado`.

```bash
        FECHA="$(date '+%d/%m/%Y %H:%M:%S')"
```

`date` devuelve la fecha y hora actual con el formato indicado:

- `%d` día
- `%m` mes
- `%Y` año
- `%H` hora
- `%M` minutos
- `%S` segundos

```bash
        NOMBRE_ARCHIVO="$(basename "$archivo")"
```

`basename` obtiene solo el nombre del archivo, sin la ruta.

```bash
        echo "$FECHA - Procesado archivo $NOMBRE_ARCHIVO" >> "$LOG_FILE"
```

Escribe una línea en el log con el formato pedido:

```
18/08/2026 18:25:32 - Procesado archivo alumnos1.txt
```

```bash
    done

    sleep 5
done
```

`sleep 5` espera 5 segundos antes de volver a revisar la carpeta. Luego el `while` se repite.

---

## 5. Resumen del flujo

```
Usuario ejecuta proyecto.sh
        │
        ▼
¿Se pasó -d? ──Sí──► LIMPIAR = 1
        │ No
        ▼
¿Está definido FILENAME?
        │
        ▼
Mostrar menú
        │
        ├── 1) Crear entorno
        ├── 2) Arrancar consolidar.sh en background
        ├── 3) Ver alumnos ordenados por padrón
        ├── 4) Ver 10 notas más altas
        ├── 5) Buscar alumno por padrón
        ├── 6) Ver log
        └── 7) Salir
        │
        ▼
¿LIMPIAR = 1?
        │ Sí
        ▼
   Matar procesos y borrar ~/EPNro1
```

---

## 6. Notas para el docente

- Los scripts no declaran funciones, cumpliendo la consigna.
- El pipeline de la opción 4 (`awk | sort | head | cut`) es una forma robusta de ordenar por la última columna, ya que el nombre y apellido pueden ocupar dos campos.
- `nohup` con `&` garantiza que `consolidar.sh` siga corriendo aunque se cierre la terminal.
- El `|| break` después de los `read` evita bucles infinitos si el usuario cierra la entrada estándar (`Ctrl+D`).
- `mkdir -p` permite volver a crear el entorno sin errores si ya existía.
