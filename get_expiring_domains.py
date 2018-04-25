#!/usr/bin/env python

'''
get expiring domains from dropcatch.com(alphabet only, for other domains, modify 'pattern').

Usage:
    ./get_expiring_domains [args]
    
    args:
        -h|--help       print this usage
        
        -d|--date=      specify a date of expiring domains(format: 2018-04-24), default to today
        -s|--suffix=    specify a suffix of domain, default to "com"
        -l|--len=       specify max len of domain name, default to 0 (any len)
        -k|--keyword=   specify keyword in domain, default to "" (no keyword)
        
        -f|--file=      input file(CSV) to be parsed. default to "" (download from web). if this is set, -d|--date will be ignored.

'''


import os
import re
import sys
import getopt
import datetime
import urllib
import shutil
import zipfile
import time


DEBUG = 0
now = datetime.datetime.now()

def debug(str):
    if DEBUG == 1:
        print str

def usage():
    print __doc__


### parse args
try:
    opts, args = getopt.getopt(sys.argv[1:], "hd:s:l:k:f:", ["help", "date=", "suffix=", "len=", "keyword=", "file="])
except getopt.GetoptError as err:
    # print help information and exit:
    print str(err)  # will print something like "option -a not recognized"
    usage()
    sys.exit(2)

debug(opts)
debug(args)

date = now.strftime("%Y-%m-%d") # today by default
suffix = "com"
max_len = 0
keyword = ""
input_file = ""
for o, a in opts:
    if o in ("-h", "--help"):
        usage()
        sys.exit(2)
    elif o in ("-d", "--date"):
        date = a
    elif o in ("-s", "--suffix"):
        suffix = a.lower()
    elif o in ("-l", "--len"):
        max_len = int(a)
    elif o in ("-k", "--keyword"):
        keyword = a.lower()
    elif o in ("-f", "--file"):
        input_file = a
    else:
        assert False, "unhandled option"


debug(date)
debug(suffix)
debug(max_len)
debug(keyword)
debug(input_file)


cwd = os.getcwd()

if len(input_file) == 0:
    ### change workding dir
    working_dir = "{}{}{}".format(cwd, os.sep, date)
    debug(working_dir)

    if os.path.exists(working_dir):
        shutil.rmtree(working_dir)
        time.sleep(0.5)
    os.mkdir(working_dir)
    os.chdir(working_dir)


    ### download expiring domains
    zip_url = "https://www.dropcatch.com/DownloadCenter/ExpiringDomainsCSV?date={}".format(date)
    zip_file = "ExpiringDomains_{}.zip".format(date)
    print "Downloading {} ...".format(zip_url)
    urllib.urlretrieve(zip_url, zip_file)

    ### extract downloaded .zip file
    zip_ref = zipfile.ZipFile(zip_file, "r")
    zip_ref.extractall(".")
    zip_ref.close()

### parse the .csv file
csv_file = "ExpiringDomains_{}.csv".format(date)
if len(input_file) != 0:
    csv_file = input_file

output_file = "output.txt"
pattern = "^([a-z]+).{},.{},.*".format(suffix, suffix) # alphabet
if len(keyword) > 0:
    pattern = "^(.*{}.*).{},.{},.*".format(keyword, suffix, suffix)

out = open(output_file, "w")

try:
    with open(csv_file, "r") as csv_content:
        for line in csv_content:
            match = re.match(pattern, line.lower())
            if match:
                domain = match.group(1)
                if max_len > 0:
                    if len(domain) <= max_len:
                        print domain + ".{}".format(suffix)
                        out.write(domain + ".{}\r\n".format(suffix))
                else:
                    print domain + ".{}".format(suffix)
                    out.write(domain + ".{}\r\n".format(suffix))
except IOError:
    print "IOError"


### cleanup


### back to CWD
os.chdir(cwd)

print
print "-= DONE =-"
print
