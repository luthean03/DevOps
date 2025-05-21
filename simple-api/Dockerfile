# ---------- Build Stage ----------
FROM eclipse-temurin:21-jdk-alpine AS myapp-build
ENV MYAPP_HOME=/opt/myapp
WORKDIR $MYAPP_HOME

# Install Maven for building the Java project
RUN apk add --no-cache maven

# Copy Maven configuration file
COPY pom.xml .

# Copy application source code
COPY src ./src

# Build the project and skip tests to speed up the build
RUN mvn package -DskipTests


# ---------- Run Stage ----------
FROM eclipse-temurin:21-jre-alpine
ENV MYAPP_HOME=/opt/myapp
WORKDIR $MYAPP_HOME

# Copy the built JAR file from the build stage to the runtime image
COPY --from=myapp-build $MYAPP_HOME/target/*.jar $MYAPP_HOME/myapp.jar

# Set the default command to run the application
ENTRYPOINT ["java", "-jar", "myapp.jar"]
