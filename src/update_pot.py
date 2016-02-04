#! /usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2015 Deepin Technology Co., Ltd.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

import argparse
from ConfigParser import RawConfigParser as ConfigParser
import os
import re
import subprocess

def remove_directory(path):
    """equivalent to command `rm -rf path`"""
    if os.path.exists(path):
        for i in os.listdir(path):
            full_path = os.path.join(path, i)
            if os.path.isdir(full_path):
                remove_directory(full_path)
            else:
                os.remove(full_path)
        os.rmdir(path)

def create_directory(directory, remove_first=False):
    '''Create directory.'''
    if remove_first and os.path.exists(directory):
        remove_directory(directory)

    if not os.path.exists(directory):
        os.makedirs(directory)

def update_pot():
    # Read config options.
    config_parser = ConfigParser()
    config_parser.read(config_path)
    config_dir = os.path.dirname(os.path.realpath(config_path))
    os.chdir(config_dir)
    project_name = config_parser.get("locale", "project_name")

    # Source dirs are separated by blank chars
    source_dirs = re.split('\s+', config_parser.get("locale", "source_dir"))

    locale_dir = os.path.abspath(config_parser.get("locale", "locale_dir"))
    create_directory(locale_dir)

    pot_filepath = os.path.join(locale_dir, project_name + ".pot")

    # Get input arguments.
    include_qml = False
    py_source_files = []
    go_source_files = []
    for source_dir in source_dirs:
        for root, dirs, files in os.walk(source_dir):
            for each_file in files:
                if each_file.startswith("."):
                    continue
                if each_file.endswith(".qml") and not include_qml:
                    include_qml = True
                if each_file.endswith(".py"):
                    py_source_files.append(os.path.join(root, each_file))
                elif each_file.endswith(".go"):
                    go_source_files.append(os.path.join(root, each_file))

    if include_qml:
        ts_filepath = os.path.join(locale_dir, project_name + ".ts")

        # Generate ts file
        ts_source_dirs = ' '.join(os.path.realpath(source_dir) for source_dir in source_dirs)
        subprocess.call(
            "deepin-lupdate -locations relative -recursive %s -ts %s" % (ts_source_dirs, ts_filepath),
            shell=True)

        # convert to pot file.
        subprocess.call(
            "lconvert -i %s -o %s" % (ts_filepath, pot_filepath),
            shell=True)

        # clean string
        clean_str = ""
        with open(pot_filepath) as fp:
            for line in fp:
                if not line.startswith("msgctxt"):
                    clean_str += line

        with open(pot_filepath, "wb") as fp:
            fp.write(clean_str)

    # Merge pot file.
    if len(py_source_files) > 0:
        if os.path.exists(pot_filepath):
            command = "xgettext -j -F -k_ -o %s %s" % (pot_filepath, ' '.join(py_source_files))
        else:
            command = "xgettext -F -k_ -o %s %s" % (pot_filepath, ' '.join(py_source_files))
        subprocess.call(command, shell=True)

    if len(go_source_files) > 0:
        if os.path.exists(pot_filepath):
            command = "xgettext -j -F --from-code=utf-8 -C -kTr -o %s %s" % (pot_filepath, ' '.join(go_source_files))
        else:
            command = "xgettext -F --from-code=utf-8 -C -kTr -o %s %s" % (pot_filepath, ' '.join(go_source_files))
        subprocess.call(command, shell=True)

def valid_path(string):
    """
    check if the path entered is a valid one
    """
    if not os.path.isfile(string):
        msg = "%s is not a valid file" % string
        raise argparse.ArgumentTypeError(msg)
    return string

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Scan msgid and generate pot file according to the ini config file',
        epilog='A domain.pot file will be generated in the locale directory')
    parser.add_argument('file',metavar='file',
        type=valid_path,
        help='A valid ini config path, full or local.')

    args = parser.parse_args()
    config_path = args.file
    update_pot()

