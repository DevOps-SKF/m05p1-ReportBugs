#
DIR=_mirror
REGNAME=asrud
CONTNAME=m05p1r
all: download build

download: clean
	echo "Downloading..."
	wget -r --convert-links --no-parent --page-requisites \
		--adjust-extension --no-directories \
		--domains=www.chiark.greenend.org.uk \
		--content-on-error=on \
		--directory-prefix=$(DIR) \
		https://www.chiark.greenend.org.uk/~sgtatham/bugs-ru.html

build: 
	echo "Prepare index.hml"
	cp $(DIR)/bugs.html $(DIR)/index.html
	echo "Building Docker container"
	docker build --rm -f "Dockerfile" -t $(REGNAME)\$(CONTNAME):latest "."
	docker save $(REGNAME)\$(CONTNAME):latest -o $(CONTNAME).tar
	gzip -f $(CONTNAME).tar 
	docker ps | grep $(CONTNAME) && docker stop $(CONTNAME) || echo "Not running"
	docker ps -a | grep $(CONTNAME) && docker rm $(CONTNAME) || echo "Nothing to delete"
	docker run -d -p 8080:80 --name $(CONTNAME) $(REGNAME)\$(CONTNAME) 

clean:
	rm -rf $(DIR)/*
