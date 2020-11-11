#!/bin/bash

git archive --format=tar main | gzip -9c | ssh svjohan@svjohan-dev02 "tar --directory=/home/svjohan/Projects/Microsoft/TSPatcher -xvzf -"
