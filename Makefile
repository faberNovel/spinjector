build:
	gem build spinjector.gemspec

install: clean build
	gem install spinjector-*.gem

publish: clean build
	gem push spinjector-*.gem

clean:
	rm -f spinjector-*.gem
