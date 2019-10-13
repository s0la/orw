#!/bin/bash

kill ${1-$(ps -ef | awk '$8 == "simplescreenrecorder" {print $2}')}
