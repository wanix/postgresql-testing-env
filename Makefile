.PHONY : asdf-install \
	configure start stop info \
	deleteCluster deleteProfile mrproper \
	client \
	dashboard

#########################
# Default Configuration #
#########################

k8scluster=pg-test
kubeconfig=${PWD}/generated/k8s/$(k8scluster).kubeconfig
kubeversion=$(shell grep "kubectl " .tool-versions | cut -d " " -f 2)
namespace=pg-test
install_prometheus=true
with_monitoring=true

# https://github.com/cloudnative-pg/cloudnative-pg/tags
cnpgVersion=1.22.2

# https://github.com/cloudnative-pg/charts/tree/main/charts/cloudnative-pg
cnpgOperatorChartVersion=0.20.2  # OperatorVersion=1.22.2
cnpgClusterChartVersion=0.0.5

postgresqlInstance=postgresql-testing
postgresqlVersion=16.2
postgresqlExtension=hypopg-hll-cron
postgresqlDiskSize=20Gi
postgresqlNodes=3
postgresqlNodeMem=4Gi
postgresqlNodeCpu=2000m
postgresqlImage=ghcr.io/wanix/postgresql:$(postgresqlVersion)-$(postgresqlExtension)

minikube=true
minikubeResources=--memory 6144 --cpus 4
storage_class=manual
# https://minikube.sigs.k8s.io/docs/drivers/
minikubeDriver=docker
minikubePersistantPath=${PWD}/persistentVolumesData/$(k8scluster).d/$(postgresqlInstance)
minikubeNodes=3

generated_k8s_path=generated/k8s/$(k8scluster).d/$(postgresqlInstance)
generated_helm_values_path=generated/helm-values/$(k8scluster).d/$(postgresqlInstance)
generated_cfg_path=generated/cfg/$(k8scluster).d/$(postgresqlInstance)
kubeMountPath=/tmp/hostpath_pv_data/$(postgresqlInstance)

grafana_port=8080

#######################
# Makefile operations #
#######################

export KUBECONFIG := $(kubeconfig)
export KUBEMOUNTPATH := $(kubeMountPath)
export KSNAMESPACE := $(namespace)
export KSSHAREDSPACE := $(minikubePersistantPath)

export PGVERSION := $(postgresqlVersion)
export PGINSTANCENAME := $(postgresqlInstance)
export PGMAINPASSWORD := $(postgresqlMainPassword)
export PGUSERNAME := $(postgresqlUser)
export PGUSERPASSWORD := $(postgresqlPassword)
export PGMAINDB := $(postgresqlDb)
export PGDISKSIZE := $(postgresqlDiskSize)
export PGINSTANCESNUMBER := $(postgresqlNodes)
export PGINSTANCEMEM := $(postgresqlNodeMem)
export PGINSTANCECPU := $(postgresqlNodeCpu)
export PGSTORAGECLASS := $(storage_class)

export PGCONTAINERIMAGE := $(postgresqlImage)
export PGPROMMONITORING := $(with_monitoring)

export PGUSERUID := $(shell id -u)
export PGUSERGID := $(shell id -g)


asdf-install :
# https://asdf-vm.com/guide/getting-started.html
	@asdf plugin-add helm
	@asdf plugin-add kubectl
	@asdf plugin-add minikube
	@asdf install

configure:
	@echo "-- Creating configuration files and needed directories"
	@test -d $(minikubePersistantPath) || mkdir -p $(minikubePersistantPath)/postgresql \
											$(minikubePersistantPath)/psql
	@test -d $(generated_k8s_path) || mkdir -p $(generated_k8s_path)
	@test -d $(generated_helm_values_path) || mkdir -p $(generated_helm_values_path)
	@test -d $(generated_cfg_path) || mkdir -p $(generated_cfg_path)

	@cat kubernetes/cm-postgresql-client.yml.tpl  | envsubst > $(generated_k8s_path)/cm-postgresql-client.yml
	@cat kubernetes/pod-postgresql-client.yml.tpl | envsubst > $(generated_k8s_path)/pod-postgresql-client.yml
	@cat kubernetes/pv-postgresql-client.yml.tpl  | envsubst > $(generated_k8s_path)/pv-postgresql-client.yml
	@cat kubernetes/pvc-postgresql-client.yml.tpl | envsubst > $(generated_k8s_path)/pvc-postgresql-client.yml

	@cat kubernetes/pv-postgresql-data.yml.tpl  | envsubst > $(generated_k8s_path)/pv-postgresql-data.yml
	@for i in $(shell seq -w 1 $(postgresqlNodes)); do \
	    mkdir -p $(minikubePersistantPath)/postgresql/data-node-$$i; \
		chmod 777 $(minikubePersistantPath)/postgresql/data-node-$$i; \
		export PGNODE=$$i; \
		cat kubernetes/pv-postgresql-data.yml.tpl  | envsubst > $(generated_k8s_path)/pv-postgresql-data-$$i.yml; \
	done

	@cat kubernetes/helm-cnpg-operator.yml.tpl | envsubst > $(generated_helm_values_path)/helm-cnpg-operator.yml
	@cat kubernetes/helm-cnpg-cluster.yml.tpl | envsubst > $(generated_helm_values_path)/helm-cnpg-cluster.yml

start : configure \
	start_minikube \
	install_monitoring \
	install_cloudnative_pg_helm_chart_repo \
	install_cloudnative_pg \
	install_postgresql_cluster \
	forward_grafana info

start_minikube :
ifeq ($(minikube), true)
	@echo "-- Starting Minikube"
  ifeq ($(minikubeDriver), docker)
	@minikube start -p $(k8scluster) $(minikubeResources) \
	  --kubernetes-version=$(kubeversion) \
	  --driver=$(minikubeDriver) \
	  --nodes $(minikubeNodes) \
	  --mount --mount-string $(minikubePersistantPath):$(kubeMountPath)
  else
	@minikube start -p $(k8scluster) $(minikubeResources) \
	  --kubernetes-version=$(kubeversion) \
	  --driver=$(minikubeDriver) \
	  --nodes $(minikubeNodes)
  endif
endif

install_cloudnative_pg_helm_chart_repo :
	@echo "-- installing helm chart repo"
	@helm repo add cnpg https://cloudnative-pg.github.io/charts
	@helm repo update cnpg

install_cloudnative_pg :
	@echo "-- Installing cloudnative-pg operator"
	@helm upgrade --install cnpg --namespace cnpg-system --create-namespace  --version "$(cnpgOperatorChartVersion)" -f $(generated_helm_values_path)/helm-cnpg-operator.yml cnpg/cloudnative-pg
	@kubectl wait pod --timeout 120s --for=condition=Ready -n cnpg-system -l app.kubernetes.io/name=cloudnative-pg
	@test -f $(minikubePersistantPath)/postgresql/flag-cnpg.flag || (sleep 10s && touch $(minikubePersistantPath)/postgresql/flag-cnpg.flag)

install_postgresql_cluster :
	@echo "-- Creating PostgreSQL Cluster $(postgresqlInstance)"
	@helm upgrade --install cnpg --namespace $(namespace) --create-namespace  --version "$(cnpgClusterChartVersion)"  -f $(generated_helm_values_path)/helm-cnpg-cluster.yml cnpg/cluster
	@echo "-- Creating PostgreSQL Cluster PVs"
	@for i in $(shell seq -w 1 $(postgresqlNodes)); do \
	    export PGNODE=$$i; \
		kubectl apply -n $(namespace) -f $(generated_k8s_path)/pv-postgresql-data-$$i.yml; \
	done
	@echo "-- Waiting for cluster $(namespace) to be ready"
	@./helpers/wait_for_pods_to_exist.sh 5 60 '  waiting pod creation' -n $(namespace) -l cnpg.io/cluster=pg-cluster-$(postgresqlInstance) -l cnpg.io/instanceRole=primary
	@echo "  waiting pod availability" && kubectl wait pod --timeout 120s --for=condition=Ready -n $(namespace) -l cnpg.io/cluster=pg-cluster-$(postgresqlInstance) -l cnpg.io/instanceRole=primary

install_monitoring :
ifeq ($(install_prometheus), true)
	@echo "-- Install monitoring"
  ifeq ($(minikube), true)
	@kubectl get ns monitoring 2>&1 >/dev/null || kubectl create ns monitoring
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	@helm upgrade --install prometheus-community --namespace monitoring -f kubernetes/helm-prometheus-community-kube-prometheus-stack.yml prometheus-community/kube-prometheus-stack
  endif
endif

forward_grafana :
ifeq ($(install_prometheus), true)
  ifeq ($(minikube), true)
	@echo "-- Waiting Grafana to be available"
	@./helpers/wait_for_pods_to_exist.sh 5 60 '  waiting pod creation' -n monitoring -l app.kubernetes.io/instance=prometheus-community -l app.kubernetes.io/name=grafana
	@echo "  waiting grafana availability" && kubectl wait pod --timeout 120s --for=condition=Ready -n monitoring -l app.kubernetes.io/instance=prometheus-community -l app.kubernetes.io/name=grafana
	@test $(shell ps -ef | grep "kubectl port-forward -n monitoring svc/prometheus-community-grafana $(grafana_port):80" | grep -vc grep) -eq 0 \
	  && echo "-- Forwarding Grafana" \
	  && nohup kubectl port-forward -n monitoring svc/prometheus-community-grafana $(grafana_port):80&
  endif
endif

stop_forward_grafana :
ifeq ($(minikube), true)
  ifeq ($(install_prometheus), true)
	@test $(shell ps -ef | grep "kubectl port-forward -n monitoring svc/prometheus-community-grafana $(grafana_port):80" | grep -vc grep) -gt 0 \
		&& echo "-- Stopping Grafana port-forward" \
		&& ps -ef | grep "kubectl port-forward -n monitoring svc/prometheus-community-grafana $(grafana_port):80" \
		 | grep -v grep | sed 's/\s\+/ /g' | cut -d ' ' -f 2 | xargs kill 2> /dev/null \
		|| true
	@rm -f nohup.out
  endif
endif

info : status
	@echo
	@echo You can now set your env:
	@echo  export KUBECONFIG="$(kubeconfig)"
ifeq ($(install_prometheus), true)
  ifeq ($(minikube), true)
	$(eval grafana_user := $(shell export KUBECONFIG="$(kubeconfig)"; kubectl get secret -n monitoring prometheus-community-grafana -o jsonpath='{.data.admin-user}' | base64 -d))
	$(eval grafana_pass := $(shell export KUBECONFIG="$(kubeconfig)"; kubectl get secret -n monitoring prometheus-community-grafana -o jsonpath='{.data.admin-password}' | base64 -d))
	@echo "-- grafana credentials:"
	@echo "  $(grafana_user) // $(grafana_pass)"
	@echo "  grafana URL: http://localhost:$(grafana_port)/d/cloudnative-pg/cloudnativepg?orgId=1&refresh=30s"
  endif
endif

status :
ifeq ($(minikube), true)
	@echo "-- Minikube status"
	@minikube status -p $(k8scluster) -l cluster
else
	@echo This operation is for minikube driver only !
endif

stop : stop_forward_grafana
ifeq ($(minikube), true)
	@echo "-- Stopping Minikube cluster"
	-@minikube stop -p $(k8scluster)
	@rm -f $(minikubePersistantPath)/postgresql/*.flag
else
	@echo This operation is for minikube driver only !
endif

deleteCluster : stop_forward_grafana
ifeq ($(minikube), true)
	@echo "-- Deleting Minikube cluster"
	-@minikube delete -p $(k8scluster)
	@rm -f $(minikubePersistantPath)/postgresql/*.flag
endif

mrproper: deleteCluster
	rm -f cfg/helm-conf--*.yml
	rm -Rf generated/k8s/*.d
	rm -Rf generated/cfg/*.d
	rm -f nohup.out
	rm -Rf persistentVolumesData/*.d

deleteProfile : deleteCluster
	rm -f $(generated_k8s_path)/*.yml
	-rmdir $(generated_k8s_path)

	rm -f $(generated_helm_values_path)/*.yml
	-rmdir $(generated_helm_values_path)

	rm -f $(generated_cfg_path)/*.yml
	-rmdir $(generated_cfg_path)

	-rm -Rf $(minikubePersistantPath)

client :
	@echo "-- Creating client pod and resources"
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/cm-postgresql-client.yml
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/pv-postgresql-client.yml
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/pvc-postgresql-client.yml
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/pod-postgresql-client.yml
	@./helpers/wait_for_pods_to_exist.sh 5 60 '  waiting for $(postgresqlInstance)-client' -n $(namespace) $(postgresqlInstance)-client
	@kubectl wait pod --timeout 120s --for=condition=Ready -n $(namespace) $(postgresqlInstance)-client
	@echo "-- Connecting client pod"
	@kubectl exec -n $(namespace) -it $(postgresqlInstance)-client -- /bin/bash

dashboard:
ifeq ($(minikube), true)
	@echo "-- Launching Minikube dashboard"
	@minikube dashboard -p $(k8scluster)
else
	@echo This operation is for minikube driver only !
endif
