FROM maven:3.5
ENV CLUSTER_NAME=foxpass
COPY . /opt
WORKDIR /opt

RUN mvn install package -DskipTests=true
