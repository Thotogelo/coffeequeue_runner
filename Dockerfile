# Stage 1 — Build
FROM maven:3.9.8-eclipse-temurin-21 AS builder
LABEL authors="thotogelo"
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package

# Stage 2 — Runtime
FROM eclipse-temurin:21-jdk-jammy
WORKDIR /app

# Copy the built jar
COPY --from=builder /app/target/*.jar app.jar

# Environment variables (can be overridden in docker-compose)
ENV SPRING_PROFILES_ACTIVE=prod
ENV SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/appdb
ENV SPRING_DATASOURCE_USERNAME=postgres
ENV SPRING_DATASOURCE_PASSWORD=postgres

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
