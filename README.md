# Deepin Gettext Tools

The tools of gettext function wrapper.

Currently supported languages: Python, QML, Go lang

## Dependencies

* python
* qtbase5
* qtdeclarative5

## Installation

```
mkdir build; cd build
qmake ..
make && make install
```

## Usage

* build deepin-lupdate
* update pot file
* generate mo files

```
deepin-lupdate --help
deepin-generate-mo --help
deepin-update-pot --help
```

## Getting help

Any usage issues can ask for help via

* [Gitter](https://gitter.im/orgs/linuxdeepin/rooms)
* [IRC channel](https://webchat.freenode.net/?channels=deepin)
* [Forum](https://bbs.deepin.org)
* [WiKi](http://wiki.deepin.org/)

## Getting involved

We encourage you to report issues and contribute changes

* [Contribution guide for users](http://wiki.deepin.org/index.php?title=Contribution_Guidelines_for_Users)
* [Contribution guide for developers](http://wiki.deepin.org/index.php?title=Contribution_Guidelines_for_Developers).

## License

Deepin Gettext Tools is licensed under [GPLv3](LICENSE).
