$tempPsYamlDirPath = ".\temp\psyaml-module"

New-Item -ItemType Directory -Path $tempPsYamlDirPath
Invoke-WebRequest -Uri https://github.com/Phil-Factor/PSYaml/archive/master.zip -OutFile $tempPsYamlDirPath\PSYaml.zip
Expand-Archive -Path $tempPsYamlDirPath\PSYaml.zip -DestinationPath $tempPsYamlDirPath\out

Copy-Item -Path $tempPsYamlDirPath\out\PSYaml-master\PSYaml -Destination "C:\Program Files\WindowsPowerShell\Modules" -Recurse
