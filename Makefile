
SRC= $(wildcard index.js lib/*.js)
TESTS ?= *
BIN= node_modules/.bin
C= $(BIN)/component
TEST= http://localhost:4202
PHANTOM= $(BIN)/mocha-phantomjs \
	--setting local-to-remote-url-access=true \
	--setting web-security=false

build: node_modules components $(SRC) integrations.js
	@$(C) build --dev

components: component.json
	@duo install --dev

integrations.js:
	@node bin/integrations

test/tests.js: $(wildcard lib/*/test.js)
	@node bin/tests

test/build.js: test/tests.js
	@duo build --entry test/tests.js --to test/build.js --dev

kill:
	-@test -e test/pid.txt \
		&& kill `cat test/pid.txt` \
		&& rm -f test/pid.txt

node_modules: package.json
	@npm install

server: build kill
	@TESTS=$(TESTS) node test/server &
	@sleep 1

test: build server test-style test-node
	@$(PHANTOM) $(TEST)

test-node: node_modules
	@$(BIN)/mocha --reporter spec test/node.js

test-browser: build server
	@open $(TEST)

test-coverage: build server
	@open $(TEST)/coverage

test-style: node_modules
	@$(BIN)/jscs lib/**/index.js --config=test/style.json

clean:
	rm -rf components build integrations.js

.PHONY: clean kill server test test-node test-browser test-coverage
