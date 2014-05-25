#!/bin/bash -e

ruby -e'exit [0,1].include?(rand(10)) ? 1 : 0'
