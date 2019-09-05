# make for windows http://gnuwin32.sourceforge.net/packages/make.htm
DC = docker-compose
CERT_DIR = ./docker/nginx/cert
ART = $(DC) exec app php artisan
COMPOSER = $(DC) exec app composer

##help			Shows this help
help:
	@cat makefile | grep "##." | sed '2d;s/##//;s/://'

##new			Create new laravel application
new: dhparam cert up create-project

##npm-install			Install node modules
npm-install:
	$(DC) exec node npm install

##mix-dev			Run all Mix tasks
mix-dev:
	$(DC) exec node npm run dev

##mix-watch			Run Mix watch for changes
mix-watch:
	$(DC) exec node npm run watch

##mix-watch-poll			Run Mix watch-poll for changes
mix-watch-poll:
	$(DC) exec node npm run watch-poll

##mix-production			Run all Mix tasks and minify output
mix-production:
	$(DC) exec node npm run production

##create-project
create-project:
	$(COMPOSER) create-project --prefer-dist laravel/laravel src
	$(DC) exec app mv ./src/{*,.[^.]*} ./
	$(DC) exec app rm -rf ./src
	$(COMPOSER) require barryvdh/laravel-ide-helper --dev
	$(ART) vendor:publish --provider="Barryvdh\LaravelIdeHelper\IdeHelperServiceProvider" --tag=config
	$(DC) exec app echo "" >> ./.editorconfig
	$(DC) exec app echo "[Makefile]" >> ./.editorconfig
	$(DC) exec app echo "indent_style = tab" >> ./.editorconfig

##install			Initial setup of application with autostarting containers
install: dhparam cert env up composer key migrate seed test-coverage

##start			Start containers with checking certificate expires
start: dhparam cert up

##stop			Down containers (down alias)
stop: down

##cert			Create/renew certificate
cert:
	@if ! openssl x509 -checkend 86400 -noout -in $(CERT_DIR)/localhost.crt; then\
		echo -e "Certificate not found or has expired or will do so within 24 hours!";\
		echo -e "New certificate will be generated here.";\
		echo -e "In common case you will need to press \"Enter\" key a few times.";\
		openssl req -x509 -nodes -days 1825 -newkey rsa:2048 -keyout $(CERT_DIR)/localhost.key -out $(CERT_DIR)/localhost.crt -config $(CERT_DIR)/localhost.conf;\
	fi;\

##dhparam			Generate dhparam.pem if it is not exists
dhparam:
	@if [ ! -f $(CERT_DIR)/dhparam.pem ]; then\
		openssl dhparam -out $(CERT_DIR)/dhparam.pem 2048;\
	fi;\

##env			Copy .env file if it is not exists
env:
	@if [ ! -f ./.env ]; then\
		cp ./.env.example ./.env;\
	fi;\

##key			Generate application key
key:
	$(ART) key:generate

##work			Start worker
work:
	$(ART) queue:work

##bash			Open the app container bash
bash:
	$(DC) exec app bash

##up			Up containers with rebuild
up:
	$(DC) up --build -d

##composer		Install composer requirements
composer:
	$(COMPOSER) install

##down			Down containers
down:
	$(DC) down

##test			Run tests
test:
	$(DC) exec app ./vendor/bin/phpunit

##test-coverage		Run tests with coverage
test-coverage:
	$(DC) exec app ./vendor/bin/phpunit --coverage-html ./public/coverage/

##migrate			Run migrations
migrate:
	$(ART) migrate

##rollback			Rollback migration
rollback:
	$(ART) migrate:rollback

##seed			Seeding the database
seed:
	$(ART) db:seed

##load			Dump the autoloader
load:
	$(COMPOSER) dumpautoload

##ps			Show runned containers
ps:
	$(DC) ps

##require			Require composer dependency
require:
	$(COMPOSER) require $(filter-out $@,$(MAKECMDGOALS))

##remove			Remove composer dependency
remove:
	$(COMPOSER) remove $(filter-out $@,$(MAKECMDGOALS))

##ide-helper			Generate IDE helper file
ide-helper:
	$(ART) clear-compiled
	$(ART) ide-helper:generate
	$(ART) optimize

##ws			Start websocket listener
ws:
	$(ART) websockets:serve

##art			Run artisan command
art:
	$(ART) $(filter-out $@,$(MAKECMDGOALS))

##clear			Clear all cached rosurces
clear:
	$(ART) clear-compiled
	$(ART) auth:clear-resets
	$(ART) cache:clear
	$(ART) config:clear
	$(ART) optimize:clear
	$(ART) view:clear
	$(ART) route:clear

%:#Dyrty hack for replace original behavior with goals
	@:
