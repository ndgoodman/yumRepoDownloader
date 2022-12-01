################################
# Step 1 Build quick web-server to serve yum.
################################

FROM golang:alpine AS builder

# Update the image
RUN apk update && apk --no-cache add curl

# Copy Go Code into the alpine image
WORKDIR $GOPATH/src/fileserver
COPY main.go .
COPY go.mod .

# Enable Go Modules and download dependencys
ENV GO111MODULE=on
RUN go mod download && go mod verify

# Build the fileserver Binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' -a \
    -o /go/bin/fileserver .

################################
# Step 2 use Rocky to download yum repo for disconnected env
################################

FROM rockylinux:8.6.20227707 AS downloader
USER 0

RUN dnf install -y yum-utils createrepo

RUN  mkdir -p /var/www/html/repos \
     && reposync -g -m --repoid=baseos --newest-only --download-metadata --download-path=/var/www/html/repos/ \
     && chown -R 1001:1001 /var/www/html

################################
# Step 3 build the image with binary and software
################################
FROM scratch

# Import from builder
COPY --from=downloader /var/www/html /var/www/html
COPY --from=builder /go/bin/fileserver /go/bin/fileserver

# Use an unprivileged user.
USER 1001

# Run the fileserver
ENTRYPOINT ["/go/bin/fileserver"]
