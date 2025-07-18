IF exist "dist" (
    rmdir dist /s /q
) ELSE (
    mkdir dist
)

xcopy /s /d /i /EXCLUDE:exclusions.txt fomod dist
xcopy /s /d /i /EXCLUDE:exclusions.txt Scripts dist
xcopy /s /d /i /EXCLUDE:exclusions.txt SKSE dist
xcopy /s /d /i /EXCLUDE:exclusions.txt SkyrimNet_Sexlab dist

SpriggitCLI\Spriggit.CLI.exe convert-to-plugin -i "Spriggit\SkyrimNet_Sexlab" -o "dist\SkyrimNet_Sexlab.esp" 
