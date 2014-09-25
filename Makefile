PREFIX = /usr

build:
	mkdir build
	cd build; qmake ../dupdate; make

clean:
	rm -rf build

install:
	mkdir -pv ${DESTDIR}${PREFIX}/lib/deepin-gettext-tools
	mkdir -pv ${DESTDIR}${PREFIX}/bin
	install -m755 build/bin/lupdate ${DESTDIR}${PREFIX}/lib/deepin-gettext-tools/
	install -m755 src/generate_mo.py ${DESTDIR}${PREFIX}/lib/deepin-gettext-tools/
	install -m755 src/update_pot.py ${DESTDIR}${PREFIX}/lib/deepin-gettext-tools/
	install -m644 src/blank.py ${DESTDIR}${PREFIX}/lib/deepin-gettext-tools/
	ln -s ${PREFIX}/lib/deepin-gettext-tools/lupdate ${DESTDIR}${PREFIX}/bin/deepin-lupdate
	ln -s ${PREFIX}/lib/deepin-gettext-tools/generate_mo.py ${DESTDIR}${PREFIX}/bin/deepin-generate-mo
	ln -s ${PREFIX}/lib/deepin-gettext-tools/update_pot.py ${DESTDIR}${PREFIX}/bin/deepin-update-pot
