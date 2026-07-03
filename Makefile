install-common:
	install -m 755 -D vm/buskill.rules $(DESTDIR)/usr/lib/qubes-buskill/vm/buskill.rules
	install -m 755 -D vm/buskill.lock.rules $(DESTDIR)/usr/lib/qubes-buskill/vm/buskill.lock.rules
	install -m 755 -D vm/buskill-disarm.sh $(DESTDIR)/usr/lib/qubes-buskill/vm/buskill-disarm.sh

install-dom0: install-common
	install -m 755 -D qubes-rpc/buskill.lock $(DESTDIR)/etc/qubes-rpc/buskill.lock
	install -m 755 -D qubes-rpc/buskill.softShutdown $(DESTDIR)/etc/qubes-rpc/buskill.softShutdown
	install -m 755 -D qubes-rpc/buskill.hardReboot $(DESTDIR)/etc/qubes-rpc/buskill.hardReboot
	install -m 755 -D qubes-rpc/buskill.selfDestruct $(DESTDIR)/etc/qubes-rpc/buskill.selfDestruct
	install -m 644 -D qubes-rpc-policy/buskill.lock $(DESTDIR)/etc/qubes-rpc/policy/buskill.lock
	install -m 644 -D qubes-rpc-policy/buskill.softShutdown $(DESTDIR)/etc/qubes-rpc/policy/buskill.softShutdown
	install -m 644 -D qubes-rpc-policy/buskill.hardReboot $(DESTDIR)/etc/qubes-rpc/policy/buskill.hardReboot
	install -m 644 -D qubes-rpc-policy/buskill.selfDestruct $(DESTDIR)/etc/qubes-rpc/policy/buskill.selfDestruct
	install -m 755 -D dom0/buskill-postinstall.sh $(DESTDIR)/usr/lib/qubes-buskill/buskill-postinstall.sh

install-vm: install-common
	install -m 644 -D vm/70-buskill.rules $(DESTDIR)/etc/udev/rules.d/70-buskill.rules

clean:
	rm -rf pkgs
