FROM maven:3.5 as base
ENV CLUSTER_NAME=foxpass
COPY . /opt
WORKDIR /opt
RUN mvn install package -DskipTests=true

FROM scratch
LABEL maintainer="Bryan Bojorque <bryan@foxpass.com>"
WORKDIR /opt
COPY --from=base . /
