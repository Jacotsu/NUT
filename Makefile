.PHONY: deb_package
.PHONY: windows_installer
.PHONY: html_docs
.PHONY: test

deb_package:
	echo "TODO"

windows_installer:
	echo "TODO"

html_docs: docs-src
	sphinx-apidoc -f -o docs nut_nutrition/
	make dirhtml -C docs-src/
	cp -rf docs-src/build/* docs
	rm -rf docs-src/build

test:
	pytest --cov nut_nutrition tests
