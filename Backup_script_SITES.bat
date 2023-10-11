@echo off
setlocal enabledelayedexpansion


set "source=c:\MAMP\htdocs\"
set "destination=c:\backup\sites"
set "delete_after_days=30"

mkdir %destination%

:: Check if the script is running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :runScript
) else (
    echo Requesting administrative privileges...
    goto :getAdmin
)

:getAdmin
:: Request administrative privileges
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /b

:runScript

for /d %%a in ("%source%*") do (
    set "folder=%%~na"
    for /f "tokens=2 delims==" %%b in ('wmic os get localdatetime /value') do set "datetime=%%b"
    set "datestamp=!datetime:~0,8!"
    set "timestamp=!datetime:~8,6!"
    set "timestamp=!timestamp:~0,2!-!timestamp:~2,2!-!timestamp:~4,2!"
    set "zipname=!destination!!folder!_!datestamp!_!timestamp!.zip"
    set "delete_date=!date:~6,4!!date:~3,2!!date:~0,2!"
    set "delete_date=!delete_date: =0!"
    set "archive_date="
    if exist "!zipname!" (
        for /f "tokens=1-3 delims=: " %%c in ('dir /tw "!zipname!" ^| findstr /i "1 File(s)"') do (
            set "archive_date=%%c%%a%%b"
            set "archive_date=!archive_date: =0!"
        )
    )
    if not defined archive_date (
        "C:\Program Files\7-Zip\7z.exe" a -tzip "!zipname!" "%%a\*"
        echo "New archive created for folder !folder!."
    ) else (
        set /a "days_old=!delete_date!-!archive_date!"
        if !days_old! gtr %delete_after_days% (
            del "!zipname!"
            "C:\Program Files\7-Zip\7z.exe" a -tzip "!zipname!" "%%a\*"
            echo "Old archive deleted and new archive created for folder !folder!."
        ) else (
            echo "Archive for folder !folder! is up to date."
        )
    )
)

echo "All subfolders have been archived."