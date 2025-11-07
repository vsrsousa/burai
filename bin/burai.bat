@echo off
REM BURAI Launcher Script for Windows
REM
REM This script launches BURAI with the necessary JavaFX configuration.
REM For Java 11+, JavaFX requires explicit module path configuration.

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0

REM Default JavaFX library path
REM Adjust this based on your JavaFX installation location
REM Download JavaFX from https://openjfx.io/ if not already installed
if "%JAVAFX_LIB_PATH%"=="" set JAVAFX_LIB_PATH=C:\javafx-sdk\lib

REM Check if JavaFX libraries exist
if not exist "%JAVAFX_LIB_PATH%" (
    echo Error: JavaFX libraries not found at %JAVAFX_LIB_PATH%
    echo.
    echo Please download JavaFX SDK from https://openjfx.io/
    echo Extract it to a location like C:\javafx-sdk\
    echo.
    echo Then either:
    echo   1. Set JAVAFX_LIB_PATH environment variable before running:
    echo      set JAVAFX_LIB_PATH=C:\path\to\javafx\lib
    echo      burai.bat
    echo.
    echo   2. Or edit this batch file (burai.bat) and update the JAVAFX_LIB_PATH variable.
    exit /b 1
)

REM Launch BURAI with JavaFX modules
java --module-path "%JAVAFX_LIB_PATH%" --add-modules javafx.controls,javafx.fxml,javafx.web,javafx.media,javafx.swing -jar "%SCRIPT_DIR%burai.jar" %*
