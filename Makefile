SHELL := /bin/bash

# Test dependencies
DEPS_DIR := deps
MINI_DIR := $(DEPS_DIR)/mini.nvim

.DEFAULT_GOAL := help

.PHONY: help test test_file lint docs docs-vimdoc docs-html build clean deps \
       screenshots screenshots-themes screenshots-renderers screenshots-features \
       screenshots-pipelines screenshots-highlights showdown gunsmoke screenshots-all \
       readme readme-check

## Show this help
help:
	@awk '/^## /{desc=substr($$0,4)} /^[a-zA-Z_-]+:/{if(desc){t=$$1;sub(/:$$/,"",t);printf "  \033[36m%-25s\033[0m %s\n",t,desc;desc=""}}' $(MAKEFILE_LIST)

## Run all tests via mini.test
test: deps
	nvim --headless -u scripts/minimal_init.lua -c "lua require('mini.test').setup(); MiniTest.run()" 2>&1

## Run a single test file (usage: make test_file FILE=tests/test_util.lua)
test_file: deps
	nvim --headless -u scripts/minimal_init.lua -c "lua require('mini.test').setup(); MiniTest.run_file('$(FILE)')" 2>&1

## Run StyLua format check
lint:
	stylua --check lua/ plugin/

## Format code with StyLua
format:
	stylua lua/ plugin/

## Generate vimdoc + HTML docs + README
docs: docs-vimdoc docs-html readme

## Generate vimdoc only (lemmy-help)
docs-vimdoc:
	scripts/gen_vimdoc.sh

## Generate HTML docs only (LDoc)
docs-html:
	scripts/gen_html.sh

## Build C library (fuzzy.so)
build:
	$(MAKE) -C csrc

## Generate all screenshots (parallel)
screenshots:
	nvim --headless -l scripts/screenshots/generate.lua -j8

## Generate theme screenshots only
screenshots-themes:
	nvim --headless -l scripts/screenshots/generate.lua -j8 --themes

## Generate renderer screenshots only
screenshots-renderers:
	nvim --headless -l scripts/screenshots/generate.lua -j8 --renderers

## Generate feature screenshots only
screenshots-features:
	nvim --headless -l scripts/screenshots/generate.lua -j8 --features

## Generate pipeline screenshots only
screenshots-pipelines:
	nvim --headless -l scripts/screenshots/generate.lua -j8 --pipelines

## Generate highlight screenshots only
screenshots-highlights:
	nvim --headless -l scripts/screenshots/generate.lua -j8 --highlights

## Generate animated showdown GIF
showdown:
	nvim --headless -l scripts/screenshots/generate.lua --showdown

## Generate animated gunsmoke GIF
gunsmoke:
	nvim --headless -l scripts/screenshots/generate.lua --gunsmoke

## Generate all screenshots + GIFs (clean first)
screenshots-all:
	rm -rf scripts/screenshots/output
	$(MAKE) screenshots showdown gunsmoke

## Generate README.md from template
readme:
	lua scripts/readme/gen_readme.lua

## Check README.md is up-to-date
readme-check:
	lua scripts/readme/gen_readme.lua --check

## Clean build artifacts
clean:
	$(MAKE) -C csrc clean

## Clone test dependencies
deps: $(MINI_DIR)

$(MINI_DIR):
	@mkdir -p $(DEPS_DIR)
	git clone --depth 1 https://github.com/echasnovski/mini.nvim $(MINI_DIR)
