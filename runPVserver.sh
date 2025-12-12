#!/bin/sh

xvfb-run -a -s "-screen 0 1024x768x24" /opt/paraview-5.13.1/bin/pvserver
