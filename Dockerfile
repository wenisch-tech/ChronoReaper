####
# Stage 1 – build the application
####
FROM maven:3.9-eclipse-temurin-17@sha256:e8ef73dbd33b69fe497fd96b3bbbd85aff84ac4c564a5784ab02ad941b32c12b AS builder

WORKDIR /build
COPY pom.xml .
# Download dependencies (cached layer)
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn package -DskipTests -q

####
# Stage 2 – runtime image
####
FROM eclipse-temurin:17.0.19_10-jre-alpine@sha256:b0ae54a36f82e04dc6c45e40ca5c55762e20b9a0858ee457faf557d440a9b571

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
