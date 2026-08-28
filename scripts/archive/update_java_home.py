import os

path = 'android/gradle.properties'
with open(path, 'a', encoding='utf-8') as f:
    f.write('\norg.gradle.java.home=C:\\\\Program Files\\\\Java\\\\jdk-21.0.12\n')
