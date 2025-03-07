MAJOR_VERSION?=5
PLUGINDEV_PROJECT_DIR?=/Users/andrew/webdev/sites/plugindev/cms_v${MAJOR_VERSION}/
VENDOR?=nystudio107
PROJECT_PATH?=${VENDOR}/$(shell basename $(CURDIR))

.PHONY: dev docs release

# Start up the buildchain dev server
dev:
# Start up the docs dev server
docs:
# Run code quality tools, tests, and build the buildchain & docs in preparation for a release
release: --code-quality --code-tests --buildchain-clean-build --docs-clean-build
# The internal targets used by the dev & release targets
--buildchain-clean-build:
--code-quality:
	${MAKE} -C ${PLUGINDEV_PROJECT_DIR} -- ecs check vendor/${PROJECT_PATH}/src --fix
	${MAKE} -C ${PLUGINDEV_PROJECT_DIR} -- phpstan analyze -c vendor/${PROJECT_PATH}/phpstan.neon
--code-tests:
	${MAKE} -C ${PLUGINDEV_PROJECT_DIR} -- pest --configuration=vendor/nystudio107/craft-twig-sandbox/phpunit.xml --test-directory=vendor/nystudio107/craft-twig-sandbox/tests
--docs-clean-build:
