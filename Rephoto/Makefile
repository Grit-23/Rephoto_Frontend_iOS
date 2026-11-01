#
#  Makefile
#  Rephoto
#
#  Created by Doyeon Kim on 10/30/26.
#
#  tuist · mockolo 버전은 mise.toml로 고정하고, 모든 호출을 mise exec로 감싼다.
#
#  처음 한 번:  brew install mise → make install → make generate → make open
#  모듈 추가:   make module type=domain name=Photo

SHELL := /bin/bash
.DEFAULT_GOAL := help

MISE ?= mise
TUIST := $(MISE) exec -- tuist
export MISE

WORKSPACE := Rephoto.xcworkspace
SCHEME ?= Rephoto
CONFIGURATION ?= Debug
DESTINATION ?= generic/platform=iOS Simulator
TEST_DESTINATION ?= platform=iOS Simulator,name=iPhone 18 Pro

.PHONY: help install generate open edit build test graph module modules mock clean

help: ## 사용 가능한 명령
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## mise 도구(tuist · mockolo)와 SPM 의존성 설치
	@$(MISE) install
	@$(TUIST) install

generate: mock ## Mock 생성 후 워크스페이스 생성
	@$(TUIST) generate --no-open

open: ## Xcode로 워크스페이스 열기
	@[ -d $(WORKSPACE) ] || $(MAKE) generate
	@open $(WORKSPACE)

edit: ## 매니페스트(Project.swift · 플러그인) 편집용 Xcode 열기 — 닫은 뒤 make generate
	@$(TUIST) edit

build: ## 빌드 (SCHEME · DESTINATION 지정 가능)
	@xcodebuild build \
		-workspace $(WORKSPACE) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-destination "$(DESTINATION)"

test: ## 테스트 (SCHEME · TEST_DESTINATION 지정 가능)
	@xcodebuild test \
		-workspace $(WORKSPACE) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-destination "$(TEST_DESTINATION)"

graph: ## 의존성 그래프(graph.png) 생성
	@$(TUIST) graph --format png --output-path .

module: ## 모듈 생성: make module type=<feature|domain|core|shared> name=<Name>
	@./Scripts/new-module "$(type)" "$(name)"

modules: ## 모듈 enum(GeneratedModules.swift) 다시 만들기
	@./Scripts/generate-modules

mock: ## Testing 모듈의 Mock(Testing/Generated/Mocks.swift) 생성
	@./Scripts/generate-mocks

clean: ## 생성된 워크스페이스 · 프로젝트 · Mock · Tuist 산출물 삭제
	@rm -rf $(WORKSPACE) Derived Tuist/.build
	@find Projects -name "*.xcodeproj" -prune -exec rm -rf {} +
	@find Projects -type d -name Derived -prune -exec rm -rf {} +
	@find Projects -type d -path "*/Testing/Generated" -prune -exec rm -rf {} +
	@echo "▶︎ clean 완료. make generate로 다시 만든다."
