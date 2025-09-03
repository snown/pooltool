#!/bin/bash

# Test script for the system overview header
cd "$(dirname "$0")"

# Source the bootstrap to get dependencies system
source bootstrap.sh

# Load the drivevisualizer module  
dependencies::depends "pooltool/driveutils"
dependencies::depends "pooltool/capacityutils" 
dependencies::depends "pooltool/healthutils"
dependencies::depends "pooltool/drivevisualizer"

echo "Testing System Overview Header..."
echo "================================"

# Test the enhanced render function with overview mode
./pooltool.sh --test-render-overview

echo
echo "Testing standalone header function..."
test_system_overview_header
