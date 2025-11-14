# stage-1
FROM amazoncorretto:11-alpine-jdk as builder
RUN mkdir -p /app/source
COPY . /app/source
WORKDIR /app/source

# make wrapper executable and build
RUN chmod +x ./mvnw && ./mvnw -B package

#stage-2
FROM amazoncorretto:11-alpine-jdk
COPY --from=builder /app/source/target/*.jar /app/app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
