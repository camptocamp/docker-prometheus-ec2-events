FROM alpine:latest

RUN apk --no-cache add curl jq

ADD ec2-events.sh /
CMD /ec2-events.sh
