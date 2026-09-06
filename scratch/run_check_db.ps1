$pgJar = (Get-ChildItem -Path "$env:USERPROFILE\.gradle\caches" -Filter "postgresql-*.jar" -Recurse | Select-Object -First 1).FullName
Write-Host "Using PG Jar: $pgJar"
javac -cp "$pgJar" CheckDb.java
java -cp ".;$pgJar" CheckDb
