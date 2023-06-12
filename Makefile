.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


##@ Testing:

.PHONY: clean-lingering-resources
clean-lingering-resources:
	@echo Cleanup potential leftovers…
	@-kubectl delete csidrivers.storage.k8s.io csi.spiffe.io \
		&>/dev/null || true
	@-kubectl delete ns \
		$$(kubectl get ns -o json | jq -r '.items[] | .metadata.name' | grep spire) \
		&>/dev/null || true
	@-kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io \
		$$(kubectl get validatingwebhookconfigurations.admissionregistration.k8s.io -o json | jq -r '.items[] | .metadata.name' | grep spire) \
		&>/dev/null || true

.PHONY: test
test: install-test-dependencies ## Run tests using Helm chart-testing (ensure to run on dedicated test cluster)
	@echo Running tests…
	@ct install --config ct.yaml

.PHONY: install-test-dependencies
install-test-dependencies: ## Install test dependency resources
	@echo Installing test dependencies…
	@.github/tests/pre-install.sh

.PHONY: cleanup-test-dependencies
cleanup-test-dependencies: ## Cleans up all test dependencies resources
	@echo Uninstalling test dependencies…
	@helm uninstall -n cert-manager cert-manager 2>/dev/null || true
	@kubectl delete ns cert-manager 2>/dev/null || true
	@helm uninstall -n prometheus kube-prometheus-stack 2>/dev/null || true
	@kubectl delete ns prometheus 2>/dev/null || true
	@helm uninstall -n mysql mysql 2>/dev/null|| true
	@kubectl delete ns mysql 2>/dev/null || true
	@helm uninstall -n postgresql postgresql 2>/dev/null || true
	@kubectl delete ns postgresql 2>/dev/null || true
	@helm uninstall -n ingress-nginx ingress-nginx 2>/dev/null || true
	@kubectl delete ns ingress-nginx 2>/dev/null || true
