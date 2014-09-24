#! /usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (C) 2011 ~ 2014 Deepin, Inc.
#               2011 ~ 2014 Kaisheng Ye
#
# Author:     Kaisheng Ye <kaisheng.ye@gmail.com>
# Maintainer: Kaisheng Ye <kaisheng.ye@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import subprocess
import os
import sys
import argparse
from ConfigParser import RawConfigParser as ConfigParser

def main():
    # Read config options.
    config_parser = ConfigParser()
    config_parser.read(config_path)
    config_dir = os.path.dirname(os.path.realpath(config_path))
    os.chdir(config_dir)
    project_name = config_parser.get("locale", "project_name")
    locale_dir = os.path.abspath(config_parser.get("locale", "locale_dir"))
    mo_locale_dir = os.path.join(locale_dir, "mo")

    for f in os.listdir(locale_dir):
        lang, ext = os.path.splitext(f)
        if ext == ".po":
            mo_dir = os.path.join(mo_locale_dir, lang, "LC_MESSAGES")
            mo_path = os.path.join(mo_dir, "%s.mo" % project_name)
            po_path = os.path.join(locale_dir, f)
            subprocess.call(
                "mkdir -p %s" % mo_dir,
                shell=True
                )

            subprocess.check_call(
                "msgfmt -o %s %s" % (mo_path, po_path),
                shell=True
                )

            if copy:
                subprocess.call(
                    "sudo cp -r %s %s" % (
                        os.path.join(mo_locale_dir, lang),
                        "/usr/share/locale/"),
                    shell=True
                    )
    return 0

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
        description='Scan po files and generate mo files according to the ini config file',
        epilog='A mo folder will be generated in the locale directory')
    parser.add_argument('file',metavar='file',
        type=valid_path,
        help='A valid ini config path, full or local.')
    parser.add_argument('--nocopy', dest='no_copy', action='store_false',
        help='Stop execute "sudo cp *.mo /usr/share/locale"')

    args = parser.parse_args()
    config_path = args.file
    copy = args.no_copy

    sys.exit(main())
