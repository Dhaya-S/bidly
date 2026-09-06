$jdk = "C:\Program Files\Android\Android Studio\jbr\bin"
$jar = "C:\Users\archana\.gradle\caches\modules-2\files-2.1\org.postgresql\postgresql\42.7.4\264310fd7b2cd76738787dc0b9f7ea2e3b11adc1\postgresql-42.7.4.jar"
& "$jdk\javac.exe" -cp $jar ApplyV32.java
& "$jdk\java.exe" -cp ".;$jar" ApplyV32
