#!/bin/bash
cd "$(dirname "$0")"
./otelcol --config=config/collector-secure.yaml
