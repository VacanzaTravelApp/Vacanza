# ========== BUILD STAGE ==========
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /app

# Bağımlılıkları cache'e alma
COPY backend/pom.xml .
RUN mvn -q -DskipTests dependency:resolve

# Kodları kopyala ve build et
COPY backend/src ./src
RUN mvn -q -DskipTests package

# ========== RUNTIME STAGE ==========
FROM eclipse-temurin:17-jre
WORKDIR /app

# Jar dosyasını builder stage’den kopyala
COPY --from=builder /app/target/*.jar app.jar

# Profil env'den gelecek (.env veya compose'da)
ENV SPRING_PROFILES_ACTIVE=default

# JVM için default memory opsiyonları
ENV JAVA_OPTS="-Xms256m -Xmx512m"

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
