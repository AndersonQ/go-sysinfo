#!/usr/bin/env bash
set -euxo pipefail

go install github.com/elastic/go-licenser@latest
go install gotest.tools/gotestsum@latest

go mod verify
go-licenser -d
go run .ci/scripts/check_format.go
go run .ci/scripts/check_lint.go

# Cross-compile checks (only execute on Linux to avoid running this multiple times).
if [[ $(go env GOOS) == "linux" ]]; then
# Test that there are no compilation issues when not using CGO. This does
# not imply that all of these targets are supported without CGO. It's only
# a sanity check for build tag issues.
CGO_ENABLED=0 GOOS=aix     GOARCH=ppc64    go build ./...
CGO_ENABLED=0 GOOS=darwin  GOARCH=amd64    go build ./...
CGO_ENABLED=0 GOOS=darwin  GOARCH=arm64    go build ./...
CGO_ENABLED=0 GOOS=linux   GOARCH=386      go build ./...
CGO_ENABLED=0 GOOS=linux   GOARCH=amd64    go build ./...
CGO_ENABLED=0 GOOS=linux   GOARCH=arm      go build ./...
CGO_ENABLED=0 GOOS=linux   GOARCH=arm64    go build ./...
CGO_ENABLED=0 GOOS=linux   GOARCH=mips     go build ./...
CGO_ENABLED=0 GOOS=linux   GOARCH=mips64   go build ./...
CGO_ENABLED=0 GOOS=linux   GOARCH=mips64le go build ./...
CGO_ENABLED=0 GOOS=linux   GOARCH=mipsle   go build ./...
CGO_ENABLED=0 GOOS=linux   GOARCH=ppc64    go build ./...
CGO_ENABLED=0 GOOS=linux   GOARCH=ppc64le  go build ./...
CGO_ENABLED=0 GOOS=linux   GOARCH=riscv64  go build ./...
CGO_ENABLED=0 GOOS=linux   GOARCH=s390x    go build ./...
CGO_ENABLED=0 GOOS=windows GOARCH=amd64    go build ./...
CGO_ENABLED=0 GOOS=windows GOARCH=arm      go build ./...
CGO_ENABLED=0 GOOS=windows GOARCH=arm64    go build ./...
fi

# Run the tests
export OUT_FILE="build/test-report.out"
mkdir -p build
gotestsum --format testname --junitfile "build/junit-${GO_VERSION}.xml" -- -tags integration ./...
