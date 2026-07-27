#!/bin/bash

SOURCE="assets/images/icon_drip_wallet.png"
ASSET_PATH="assets/images"

echo "Verificando archivo fuente..."
if [ ! -f "$SOURCE" ]; then
    echo "Error: $SOURCE no encontrado"
    exit 1
fi

echo "Generando iconos para iOS..."
sips -z 1024 1024 "$SOURCE" --out "$ASSET_PATH/icon_1024.png"
sips -z 512 512 "$SOURCE" --out "$ASSET_PATH/icon_512.png"
sips -z 180 180 "$SOURCE" --out "$ASSET_PATH/icon_180.png"
sips -z 152 152 "$SOURCE" --out "$ASSET_PATH/icon_152.png"
sips -z 120 120 "$SOURCE" --out "$ASSET_PATH/icon_120.png"

echo "Generando iconos para Android..."
sips -z 192 192 "$SOURCE" --out "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
sips -z 144 144 "$SOURCE" --out "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
sips -z 96 96 "$SOURCE" --out "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
sips -z 72 72 "$SOURCE" --out "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
sips -z 48 48 "$SOURCE" --out "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"

echo "Completado: Iconos generados correctamente"
ls -la "$ASSET_PATH"/icon_*.png
ls -la android/app/src/main/res/mipmap-*/ic_launcher.png
