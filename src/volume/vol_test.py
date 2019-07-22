#!/usr/bin/env python

import subprocess
import os
import sys
import getopt
from time import sleep


opts,args = getopt.getopt(sys.argv[1:], 'td:', ['test_suits=', 'dirpath=']) 
test_suits = ""
dirpath = "./"

# slack details
slackcmd = ("./slackpost "
            "https://hooks.slack.com/services/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 "
            "sds-homestore "
            "regression-bot \""
           )

def slackpost(msg):
    cmd = slackcmd + msg + "\""
    subprocess.call(cmd, shell=True)

for opt,arg in opts:
    if opt in ('-t', '--test_suits'):
        test_suits = arg
        print(("testing suits (%s)")%(arg))
    if opt in ('-d', '--dirpath'):
        dirpath = arg
        print(("dir path (%s)")%(arg))

def normal():
    status = subprocess.check_output("./test_volume \
            --run_time=12000 --max_num_writes=5000000", shell=True)
    f = open( '/home/homestore/log_normal.txt', 'w+' )
    f.write(status)
    f.close()
    return '[  PASSED  ] 1 test' in status

def vol_delete():
    status = subprocess.check_output("./test_volume --gtest_filter=*vol_del*", shell=True)
    f = open( '/home/homestore/log_delete.txt', 'w+' )
    f.write(status)
    f.close()
    return '[  PASSED  ] 1 test' in status

def recovery():
    subprocess.call(dirpath + "test_volume --gtest_filter=*abort_random* --run_time=300 --enable_crash_handler=0", shell=True)
    subprocess.check_call(dirpath + "test_volume --gtest_filter=*recovery_random* --run_time=300 --enable_crash_handler=1", shell=True)

def mapping():
    status = subprocess.check_output("./test_mapping --num_ios=10000000", shell=True)
    f = open( '/home/homestore/log_mapping.txt', 'w+' )
    f.write(status)
    f.close()
    return '[  PASSED  ] 1 test' in status

def load():
    status = subprocess.check_output("./test_load \
            --num_io=100000000000 --num_keys=1000000 --run_time=21600 --gtest_filter=Map* ", shell=True)
    f = open( '/home/homestore/log_load.txt', 'w+' )
    f.write(status)
    f.close()
    return '[  PASSED  ] 1 test' in status

def sequence():
    slackpost("Regression Test Starting")
    if normal() == False:
        slackpost("Normal Test Failed")
        sys.exit(0)
    slackpost("Normal Test Passed")
    sleep(5)
    if load() == False:
        slackpost("Load Test Failed")
        sys.exit(0)
    slackpost("Load Test Passed")
    sleep(5)
    if mapping() == False:
        slackpost("Mapping Test Failed")
        sys.exit(0)
    slackpost("Mapping Test Passed")

if test_suits == "normal":
    normal()
    
if test_suits == "vol_del":
    vol_delete()

if test_suits == "recovery":
    recovery()
    
if test_suits == "mapping":
    mapping()

if test_suits == "sequence":
    sequence()

if test_suits == "load":
    load()
