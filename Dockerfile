####
# Stage 1 – build the application
####
FROM maven:3.9-eclipse-temurin-17@sha256:880934ae394bf91bc3e57d573e4fc04774f064f3c4df7ccd7cc10b3b126737bf AS builder

WORKDIR /build
COPY pom.xml .
# Download dependencies (cached layer)
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn package -DskipTests -q

####
# Stage 2 – runtime image
####
FROM eclipse-temurin:17.0.20_8-jre-alpine@sha256:27cc0849148c0fd32ee8e95988917becf9bc96a3182a24f99d9763aa8e90f8cb

# Non-root user for security
RUN addgroup -S operator && adduser -S operator -G operator
USER operator

WORKDIR /app
COPY --from=builder /build/target/quarkus-app/lib/ /app/lib/
COPY --from=builder /build/target/quarkus-app/*.jar /app/
COPY --from=builder /build/target/quarkus-app/app/ /app/app/
COPY --from=builder /build/target/quarkus-app/quarkus/ /app/quarkus/

EXPOSE 8080 8081

ENV JAVA_OPTS="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"

ENTRYPOINT ["java", "-jar", "/app/quarkus-run.jar"]
