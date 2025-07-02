FROM golang:1.16.2-alpine3.13 as builder
WORKDIR /app
COPY . ./
# This is where one could build the application code as well.

FROM ubuntu:22.04
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    apt-get install -y bash && \
    apt-get install -y wget && \
    apt-get install -y systemctl && \
    apt-get install -y curl && \
    apt-get install -y unzip && \
    rm -rf /var/lib/apt/lists/*

# Copy binary to production image.
COPY --from=builder /app/start.sh /app/start.sh

# Copy Tailscale and Easytier binaries from the tailscale image on Docker Hub.
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /app/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /app/tailscale
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale
RUN wget -O /app/easytier.sh "https://raw.githubusercontent.com/EasyTier/EasyTier/main/script/install.sh" && bash /app/easytier.sh install --no-gh-proxy

COPY --from=builder /app/start.sh /app/start.sh
# Change start.sh to be executable
RUN chmod +x /app/start.sh

# Run on container startup.
CMD ["/app/start.sh"]
