#!/bin/bash
echo "Testing position 5 (should be NEW-14T):"
printf "5\nq\n" | timeout 10 ./pooltool.sh drives select 2>/dev/null | grep -E "(Selected|Position|Drive|ERROR|Found)" || echo "Test completed"

echo
echo "Testing drive name DRU01:"
printf "DRU01\nq\n" | timeout 10 ./pooltool.sh drives select 2>/dev/null | grep -E "(Selected|Position|Drive|ERROR|Found)" || echo "Test completed"
