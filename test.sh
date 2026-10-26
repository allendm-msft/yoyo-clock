#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build/tests
swiftc Sources/MenuBarChime/TimeAnnouncer.swift \
    Tests/TimeAnnouncerTests.swift \
    -o .build/tests/TimeAnnouncerTests
.build/tests/TimeAnnouncerTests
