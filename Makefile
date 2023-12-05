.PHONY: test

build:
	gem build spinjector.gemspec

test:
	bundle exec rake test

install: clean build
	gem install spinjector-*.gem

publish: clean build
	gem push spinjector-*.gem

clean:
	rm -f spinjector-*.gem
