
SHELL := /bin/bash

PAGES := index.html about.html documentation.html screenshots.html download.html links.html
PAGES += commercial.html vloghammer.html yosysjs.html faq.html
PAGES += $(addsuffix .html,$(basename $(wildcard cmd_*.in)))

HOST_REPO := ../yosyshq.github.io/

web: $(PAGES)

index.html:
	ln -sf about.html index.html

templates/cmd_header.in: templates/header.in
	sed -r '/<title>/ s,::,:: Command Reference ::,; s,@documentation@,1,g; s,@[a-z]+@,0,g;' < templates/header.in > templates/cmd_header.in.new
	mv templates/cmd_header.in.new templates/cmd_header.in

%.html: %.in templates/cmd_header.in templates/* files/*
	perl -pe ' #\
		if (/^@(\S+)\s*(.*)@\s*$$/) { #\
			open(F, "<templates/$$1.in") or die $$!; $$y=$$2; $$x=""; $$x.=$$_ while <F>; close F; #\
			$$_=$$x; s/\@\@/$$y/g; s/\@$(basename $@)\@/1/g; s/\@[0-9a-zA-Z_]*\@/0/g; } #\
		if (/^\[\[(.*)\]\]$$/) { $$fn = $$1; open(F, "files/$$fn") or die $$!; $$x=""; $$x.=$$_ while <F>; close F; #\
			s/([^a-zA-Z0-9 \t\n])/"&#".ord($1).";"/eg; $$_="<pre>$$x</pre>\n"; #\
			$$_ .= "<div class=\"file\"><a href=\"files/$$fn\">$$fn</a></div>\n"; } #\
		' $< > $@.new
	mv $@.new $@

update_cmd:
	rm -f cmd_*.html
	git rm --ignore-unmatch -f cmd_*.in templates/cmd_index.in
	yosys -qp 'help -write-web-command-reference-manual'
	git add cmd_*.in templates/cmd_index.in

update_show:
	git rm --ignore-unmatch -f images/show_*.png
	yosys-filterlib -verilogsim < files/cmos_cells.lib > files/cmos_cells.v
	cd files; for ys in show_*.ys; do \
		yosys $$ys -p "show -lib cmos_cells.v -lib coarse_cells.v -format png -prefix ../images/$${ys%.ys}"; \
		rm ../images/$${ys%.ys}.dot; \
	done
	rm -f files/cmos_cells.v
	git add images/show_*.png

wget_nogit:
	mkdir -p nogit
	wget -r -nH -np --cut-dirs=1 -R 'index.html*' http://bygone.clairexen.net/yosys/nogit/

# pull_nogit:
# 	mkdir -p nogit
# 	rsync -e ssh -azv --delete clifford@clifford.at:/var/www/clifford/yosys/nogit/. nogit/.
#
$(HOST_REPO):
	git clone git@github.com:YosysHQ/yosyshq.github.io.git $(HOST_REPO)

push: web | $(HOST_REPO)
	rsync -azv --delete --exclude .git --exclude .*.swp --exclude nogit . $(HOST_REPO)/yosys/.
# 	rsync -e ssh -azv --delete --exclude .git --exclude .*.swp --exclude nogit . clifford@clifford.at:/var/www/clifford/yosys/.

clean:
	rm -f $(PAGES) templates/cmd_header.in

.PHONY: web push clean
