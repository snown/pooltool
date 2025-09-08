#!/bin/bash

# Quick test of visual drive selector
cd /media/tRAID/local/src/pooltool

echo "Testing visual selector with position 1:"
echo "1" | ./pooltool.sh drives select

echo -e "\n---\n"

echo "Testing visual selector with DRU01:"
echo "DRU01" | ./pooltool.sh drives select

echo -e "\n---\n"

echo "Testing visual selector with position 5 (unallocated):"
echo -e "5\nyes" | ./pooltool.sh drives select
