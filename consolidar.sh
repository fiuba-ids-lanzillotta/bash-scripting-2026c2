#!/bin/bash

EP_DIR="$HOME/EPNro1"
ENTRADA_DIR="$EP_DIR/entrada"
SALIDA_DIR="$EP_DIR/salida"
PROCESADO_DIR="$EP_DIR/procesado"
LOG_FILE="$EP_DIR/procesado.log"

SALIDA_FILE="$SALIDA_DIR/${FILENAME}.txt"

mkdir -p "$ENTRADA_DIR"
mkdir -p "$SALIDA_DIR"
mkdir -p "$PROCESADO_DIR"

while true; do
    for archivo in "$ENTRADA_DIR"/*.txt; do
        [ -e "$archivo" ] || continue

        cat "$archivo" >> "$SALIDA_FILE"
        mv "$archivo" "$PROCESADO_DIR/"

        FECHA="$(date '+%d/%m/%Y %H:%M:%S')"
        NOMBRE_ARCHIVO="$(basename "$archivo")"
        echo "$FECHA - Procesado archivo $NOMBRE_ARCHIVO" >> "$LOG_FILE"
    done

    sleep 5
done
