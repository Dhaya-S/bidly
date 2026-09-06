$jdk = "C:\Program Files\Android\Android Studio\jbr"
$env:JAVA_HOME = $jdk
$env:PATH = "$jdk\bin;$env:PATH"
.\gradlew.bat bootJar --no-daemon
