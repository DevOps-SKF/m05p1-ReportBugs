#
DIR=_mirror
REGNAME=asrud
CONTNAME=m05p1r
all: sync build

sync: clean
	@date
	@echo "Downloading..."
	wget -r --no-verbose --convert-links --no-parent \
		--adjust-extension --page-requisites --no-directories \
		--domains=www.chiark.greenend.org.uk \
		--content-on-error=on \
		--directory-prefix=$(DIR) \
		https://www.chiark.greenend.org.uk/~sgtatham/bugs-ru.html || echo "Donwload complete"

build: 
	@echo "Prepare index.hml"
	cp $(DIR)/bugs.html $(DIR)/index.html
	@echo "Building Docker container"
	docker build --rm -f "Dockerfile" -t $(REGNAME)/$(CONTNAME):latest .
	docker save $(REGNAME)/$(CONTNAME):latest -o $(CONTNAME).tar
	gzip -f $(CONTNAME).tar 
	mv $(CONTNAME).tar.gz $(CONTNAME).tgz

stop:
	docker ps | grep $(CONTNAME) && (echo -n "stopping... "; docker stop $(CONTNAME)) || echo ""
	docker ps -a | grep $(CONTNAME) && (echo -n "deleting... "; docker rm $(CONTNAME)) || echo ""

deploy: stop
	docker run -d -p 8080:80 --name $(CONTNAME) --restart=no $(REGNAME)/$(CONTNAME) 

install: uninstall
	@date
	(crontab -l ; echo "45 3 * * 6 make -C /home/anton/SKF/m05p1-ReportBugs all > /tmp/m05p1.log ") | crontab -
	@echo "crontab after install:"
	@crontab -l
	@echo ""

uninstall:
	crontab -l | grep -v "m05p1-ReportBugs" | crontab
	@echo "crontab after uninstall:"
	@crontab -l
	@echo ""

clean:
	@date
	rm -rf $(DIR)/*
	[ -f *.tgz ] && rm *.tgz || echo ""
