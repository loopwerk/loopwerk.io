serve:
	liquidluck server

clean:
	rm -fr deploy

html: clean
	liquidluck build
