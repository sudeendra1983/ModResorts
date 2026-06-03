# Dockerfile for ModResorts Java EE WAR application on Tomcat

# ====== Builder Stage ======
FROM maven:3.9.4-eclipse-temurin-8 AS builder

WORKDIR /workspace

# Copy pom.xml first for dependency resolution caching
COPY pom.xml ./

# Pre-download dependencies (no wrapper usage)
RUN mvn -B -q dependency:go-offline

# Copy the rest of the project
COPY src ./src
COPY WebContent ./WebContent

# Build WAR (tests skipped for faster container builds)
RUN mvn -B clean package -DskipTests

# ====== Runtime Stage ======
FROM eclipse-temurin:8-jdk

ENV TZ=UTC \
    JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseContainerSupport -XX:+UnlockExperimentalVMOptions -XX:MaxRAMPercentage=75.0" \
    CATALINA_OPTS="" \
    SPRING_PROFILES_ACTIVE=docker

# Install Tomcat
ENV CATALINA_HOME=/usr/local/tomcat
ENV PATH="$CATALINA_HOME/bin:$PATH"

RUN mkdir -p "$CATALINA_HOME" \
    && curl -fsSL https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.99/bin/apache-tomcat-8.5.99.tar.gz \
    | tar xzf - --strip-components=1 -C "$CATALINA_HOME" \
    && rm -rf "$CATALINA_HOME"/webapps/*

WORKDIR $CATALINA_HOME

# Copy built WAR from builder stage
COPY --from=builder /workspace/target/modresorts.war $CATALINA_HOME/webapps/ROOT.war

# Expose HTTP port (Tomcat default)
EXPOSE 8080

# Run Tomcat as non-root user
RUN useradd -r -u 1001 -g root appuser \
    && chown -R appuser:root "$CATALINA_HOME" \
    && chmod -R g=u "$CATALINA_HOME"

USER appuser

CMD ["sh", "-c", "catalina.sh run"]
