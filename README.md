Deepin Gettext Tools
===================
The tools of gettext function wrapper.

currently supported languages: python, qml, golang

## Dependencies
* python
* qtbase5
* qtdeclarative5

## Installation
~~~
mkdir build; cd build
qmake ..
make && make install
~~~

## Usage

* build deepin-lupdate
* update pot file
* generate mo files
~~~
deepin-lupdate --help
deepin-generate-mo --help
deepin-update-pot --help
~~~

## Getting involved

We encourage you to report issues and contribute changes. Please check out the [Contribution Guidelines](http://wiki.deepin.org/index.php?title=Contribution_Guidelines) about how to proceed.

## License

GNU General Public License, Version 3.0
