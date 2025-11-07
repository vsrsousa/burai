# BURAI Launcher Scripts

This directory contains launcher scripts for BURAI that simplify running the application with Java 11+.

## Why Launcher Scripts?

Starting from Java 11, JavaFX is no longer bundled with the JDK and must be explicitly configured at runtime using module path arguments. These launcher scripts automatically handle this configuration.

## Available Scripts

- **`burai`** - Linux/Mac launcher script
- **`burai.bat`** - Windows launcher script

## Usage

### Linux/Mac

```bash
./burai
```

### Windows

```cmd
burai.bat
```

## Configuration

### JavaFX Library Path

By default, the launcher scripts look for JavaFX libraries at:
- **Linux:** `/usr/share/openjfx/lib`
- **Windows:** `C:\javafx-sdk\lib`

If your JavaFX installation is in a different location, you can override it:

#### Linux/Mac
```bash
export JAVAFX_LIB_PATH=/path/to/javafx/lib
./burai
```

#### Windows
```cmd
set JAVAFX_LIB_PATH=C:\path\to\javafx\lib
burai.bat
```

## Installing JavaFX

### Ubuntu/Debian
```bash
sudo apt install openjfx
```

### Windows/Mac
Download JavaFX SDK from https://openjfx.io/ and extract it to a convenient location.

## Manual Launch (Without Scripts)

If you prefer not to use the launcher scripts, you can run BURAI directly:

```bash
java --module-path /usr/share/openjfx/lib \
     --add-modules javafx.controls,javafx.fxml,javafx.web,javafx.media,javafx.swing \
     -jar burai.jar
```

## Troubleshooting

### "JavaFX libraries not found"

This error means OpenJFX is not installed or the path is incorrect.

**Solutions:**
1. Install OpenJFX (see "Installing JavaFX" above)
2. Set the correct path using `JAVAFX_LIB_PATH` environment variable

### Graphics/Display Errors

If you see errors like "Graphics Device initialization failed" or "no suitable pipeline found", this typically means:
- Running in a headless environment (no display)
- Missing graphics libraries (install libgtk-3-0 and related packages)

For headless testing or CI environments, JavaFX requires a virtual display (e.g., Xvfb).
