#!/bin/bash

SALIR=0
LIMPIAR=0

if [ "${1:-}" = "-d" ]; then
    LIMPIAR=1
fi

if [ -z "$FILENAME" ]; then
    echo "Error: debe definir la variable de ambiente FILENAME."
    echo "Ejemplo: export FILENAME=alumnos"
    exit 1
fi

if [ -n "$FILENAME" ]; then
    export FILENAME
fi

while [ "$SALIR" -eq 0 ]; do
    echo "-----------------------------------"
    echo "Menu Principal"
    echo "1) Crear entorno"
    echo "2) Correr proceso"
    echo "3) Listado de alumnos ordenados por padron"
    echo "4) 10 notas mas altas"
    echo "5) Buscar alumno por numero de padron"
    echo "6) Visualizar log"
    echo "7) Salir"
    echo "-----------------------------------"

    read -p "Ingrese una opcion: " opcion || break

    case "$opcion" in
        1)
            mkdir -p "$HOME/EPNro1/entrada"
            mkdir -p "$HOME/EPNro1/salida"
            mkdir -p "$HOME/EPNro1/procesado"

            SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
            if [ -f "$SCRIPT_DIR/consolidar.sh" ]; then
                cp "$SCRIPT_DIR/consolidar.sh" "$HOME/EPNro1/consolidar.sh"
                chmod +x "$HOME/EPNro1/consolidar.sh"
                echo "Entorno creado y consolidar.sh copiado."
            else
                echo "Entorno creado. No se encontro consolidar.sh junto al script principal."
            fi
            ;;

        2)
            if [ ! -f "$HOME/EPNro1/consolidar.sh" ]; then
                echo "Primero debe crear el entorno con la opcion 1."
            else
                nohup "$HOME/EPNro1/consolidar.sh" >/dev/null 2>&1 &
                echo "$!" > "$HOME/EPNro1/consolidar.pid"
                echo "Proceso consolidar.sh iniciado en background (PID $!)."
            fi
            ;;

        3)
            SALIDA="$HOME/EPNro1/salida/${FILENAME}.txt"
            if [ -f "$SALIDA" ]; then
                echo "Listado de alumnos ordenados por numero de padron:"
                sort -n -k1,1 "$SALIDA"
            else
                echo "No existe el archivo $SALIDA"
            fi
            ;;

        4)
            SALIDA="$HOME/EPNro1/salida/${FILENAME}.txt"
            if [ -f "$SALIDA" ]; then
                echo "10 notas mas altas:"
                awk '{print $NF "|" $0}' "$SALIDA" | sort -t'|' -nr -k1,1 | head -n 10 | cut -d'|' -f2-
            else
                echo "No existe el archivo $SALIDA"
            fi
            ;;

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
            else
                echo "No existe el archivo $SALIDA"
            fi
            ;;

        6)
            LOG="$HOME/EPNro1/procesado.log"
            if [ -f "$LOG" ]; then
                echo "Contenido del log:"
                cat "$LOG"
            else
                echo "No existe el archivo de log $LOG"
            fi
            ;;

        7)
            echo "Saliendo..."
            SALIR=1
            ;;

        *)
            echo "Opcion invalida. Intente nuevamente."
            ;;
    esac

    if [ "$SALIR" -eq 1 ]; then
        continue
    fi

    echo
    read -p "Presione ENTER para continuar..." || break
    echo
done

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
