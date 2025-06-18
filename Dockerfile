# Stage 1: Build the Micronaut application
# Use a robust JDK image for compilation
FROM openjdk:17-jdk-slim AS builder

# Set the working directory inside the builder container
WORKDIR /app

# Copy the Gradle/Maven wrapper and build files first to leverage Docker layer caching
# If using Gradle:
COPY gradlew .
COPY gradle/ gradle/
COPY build.gradle .
COPY settings.gradle .
# Copy Micronaut-specific build files if any (e.g., src/main/resources/application.yml)
# This helps with caching if application.yml changes less frequently than source code
COPY src/main/resources/application.properties src/main/resources/

# Copy your Micronaut application source code
COPY src/ src/

# Build the Micronaut application to create the Fat JAR
# If using Gradle:
# The Micronaut `shadowJar` task (provided by `io.micronaut.application` plugin)
# creates the executable JAR, typically in build/libs/
RUN ./gradlew clean shadowJar

# If using Maven:
# RUN mvn clean package -DskipTests
# The Maven `package` goal creates the executable JAR, typically in target/
# Make sure your Maven build produces a single executable JAR.

# Stage 2: Create the final lean runtime image
# Use a smaller JRE image for the runtime environment
FROM openjdk:17-jre-slim

# Set the working directory for the application
WORKDIR /app

# Copy the executable JAR from the builder stage
# Adjust the path based on your build tool's output:
# For Gradle (shadowJar): copy from /app/build/libs/your-app-version-all.jar
# For Maven: copy from /app/target/your-app-version.jar
# Replace 'your-app-version-all.jar' with your actual JAR file name.
# You might need to make the JAR name dynamic in CI/CD, or rely on a generic name.
# For simplicity, let's assume a generic name for the final JAR
COPY --from=builder /app/build/libs/*.jar app.jar
# If using Maven, it might be:
# COPY --from=builder /app/target/*.jar app.jar

# Cloud Run expects applications to listen on the port specified by the PORT environment variable.
# Micronaut applications automatically pick up the PORT environment variable if configured correctly.
ENV PORT 8080
EXPOSE 8080

# Command to run the Micronaut application
# This assumes the application is an executable JAR
CMD ["java", "-Dmicronaut.server.port=${PORT}", "-jar", "app.jar"]

# Optional: Add health checks for faster deployment and better resilience
# HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl --fail http://localhost:8080/health || exit 1