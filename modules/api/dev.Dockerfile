# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ! Context expected to be set to "modules" dir !

FROM golang:1.23-alpine3.21 AS AIR

RUN go install github.com/air-verse/air@latest

FROM golang:1.23-alpine3.21

# Copy air binary
COPY --from=AIR $GOPATH/bin/air $GOPATH/bin/air

# Create and cd into workspace
WORKDIR /workspace

# Copy required local modules
COPY /common/certificates /workspace/common/certificates
COPY /common/client /workspace/common/client
COPY /common/csrf /workspace/common/csrf
COPY /common/errors /workspace/common/errors
COPY /common/types /workspace/common/types
COPY /common/helpers /workspace/common/helpers

# Create and cd into api module
WORKDIR /workspace/api

# Retrieve application dependencies.
# This allows the container build to reuse cached dependencies.
# Expecting to copy go.mod and if present go.sum.
COPY api/go.* ./
RUN go mod download

# Copy local code to the container image.
COPY api/main.go .
COPY api/pkg ./pkg

EXPOSE 8000 8001
ENTRYPOINT ["air", "-c", ".air.toml", "--", "--insecure-bind-address=0.0.0.0", "--bind-address=0.0.0.0"]
