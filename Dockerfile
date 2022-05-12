FROM maven:3.5 as base
ENV CLUSTER_NAME=foxpass
ENV DEBIAN_FRONTEND=noninteractive

COPY . /opt
WORKDIR /opt

RUN apt-get update -y && apt-get install -y curl jq

RUN mvn install package -DskipTests=true
RUN chmod +x ./helix-core/target/helix-core-pkg/bin/*.sh
RUN chmod +x ./helix-front/target/helix-front-pkg/bin/*.sh
RUN chmod +x ./helix-rest/target/helix-rest-pkg/bin/*.sh

FROM scratch
LABEL maintainer="Bryan Bojorque <bryan@foxpass.com>"
WORKDIR /opt
COPY --from=base . /
