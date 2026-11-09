@echo off

REM Verifica si el archivo APK existe en la carpeta "static"
IF EXIST "static\4learn.apk" (
    echo --------------------------------------------------
    echo El archivo APK fue encontrado en la carpeta static/.
    echo Copiando el archivo APK a build/web/...
    
    REM Copiar el archivo APK de static/ a build/web/
    copy /Y "static\4learn.apk" "build\web\4learn.apk"
    
    REM Verificar si el archivo se copió correctamente
    IF %ERRORLEVEL% EQU 0 (
        echo --------------------------------------------------
        echo El archivo APK se copió correctamente a build/web/.
    ) ELSE (
        echo --------------------------------------------------
        echo ERROR: No se pudo copiar el archivo APK a build/web/.
    )
) ELSE (
    echo --------------------------------------------------
    echo ERROR: El archivo APK no se encuentra en la carpeta static/.
)

pause
