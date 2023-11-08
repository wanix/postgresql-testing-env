.PHONY : asdf-install \
	configure start stop info \
	deleteCluster deleteProfile mrproper \
	client \
	dashboard

#########################
# Default Configuration #
#########################

k8scluster=k8s-postgresql-testing-env
kubeconfig=${PWD}/generated/k8s/$(k8scluster).kubeconfig
kubeversion=$(shell grep "kubectl " .tool-versions | cut -d " " -f 2)
namespace=default
with_monitoring=true

cnpgVersion=1.21.1

postgresqlInstance=postgresql-testing
postgresqlVersion=16.0
postgresqlExtension=hypopg-hll-cron
postgresqlDiskSize=20Gi
postgresqlNodes=1
postgresqlImage=ghcr.io/wanix/postgresql:$(postgresqlVersion)-$(postgresqlExtension)

minikube=true
minikubeResources=--memory 8192 --cpus 4
# https://minikube.sigs.k8s.io/docs/drivers/
minikubeDriver=docker
minikubePersistantPath=${PWD}/persistentVolumesData/$(k8scluster).d/$(postgresqlInstance)
minikubeNodes=2

generated_k8s_path=generated/k8s/$(k8scluster).d/$(postgresqlInstance)
generated_cfg_path=generated/cfg/$(k8scluster).d/$(postgresqlInstance)
kubeMountPath=/tmp/hostpath_pv_data/$(postgresqlInstance)

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

export PGCONTAINERIMAGE := $(postgresqlImage)

export PGUSERUID := $(shell id -u)
export PGUSERGID := $(shell id -g)


asdf-install :
# https://asdf-vm.com/guide/getting-started.html
	@asdf plugin-add helm
	@asdf plugin-add kubectl
	@asdf plugin-add minikube
	@asdf install

configure:
	@test -d $(minikubePersistantPath) || mkdir -p $(minikubePersistantPath)/postgresql \
											$(minikubePersistantPath)/psql
	@test -d $(generated_k8s_path) || mkdir -p $(generated_k8s_path)
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
	@cat kubernetes/cnpg-cluster-postgresql.yml.tpl  | envsubst > $(generated_k8s_path)/cnpg-cluster-postgresql.yml

start : configure start_minikube install_cloudnative_pg install_monitoring install_postgresql info

start_minikube :
ifeq ($(minikube), true)
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

install_cloudnative_pg :
	@kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/v$(cnpgVersion)/releases/cnpg-$(cnpgVersion).yaml
	@kubectl wait pod --timeout 120s --for=condition=Ready -n cnpg-system -l app.kubernetes.io/name=cloudnative-pg
	@test -f $(minikubePersistantPath)/postgresql/flag-cnpg.tmp || (sleep 10s && touch $(minikubePersistantPath)/postgresql/flag-cnpg.tmp)

install_postgresql :
	@for i in $(shell seq -w 1 $(postgresqlNodes)); do \
	    export PGNODE=$$i; \
		kubectl apply -n $(namespace) -f $(generated_k8s_path)/pv-postgresql-data-$$i.yml; \
	done
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/cnpg-cluster-postgresql.yml

install_monitoring :
ifeq ($(minikube), true)
  ifeq ($(with_monitoring), true)
	echo "Monitoring is for later"
  endif
endif

info : status
	@echo
	@echo The configuration for your chart is there with sensitive data:
	@echo   $(generated_cfg_path)/helm-conf--$(postgresqlInstance).yml
	@echo
	@echo You can now set your env:
	@echo  export KUBECONFIG="$(kubeconfig)"

status :
ifeq ($(minikube), true)
	@minikube status -p $(k8scluster) -l cluster
else
	@echo This operation is for minikube driver only !
endif

stop :
ifeq ($(minikube), true)
	-@minikube stop -p $(k8scluster)
else
	@echo This operation is for minikube driver only !
endif

deleteCluster :
ifeq ($(minikube), true)
	-@minikube delete -p $(k8scluster)
	@rm -f $(minikubePersistantPath)/postgresql/flag-cnpg.tmp
endif

mrproper: deleteCluster
	rm -f cfg/helm-conf--*.yml
	rm -Rf persistentVolumesData/*.d
	rm -Rf generated/k8s/*.d
	rm -Rf generated/cfg/*.d

deleteProfile : deleteCluster
	rm -f $(generated_k8s_path)/*.yml
	-rmdir $(generated_k8s_path)

	rm -f $(generated_cfg_path)/*.yml
	-rmdir $(generated_cfg_path)

	-rm -Rf $(minikubePersistantPath)

client :
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/cm-postgresql-client.yml
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/pv-postgresql-client.yml
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/pvc-postgresql-client.yml
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/pod-postgresql-client.yml
	@kubectl wait pod --timeout 120s --for=condition=Ready -n $(namespace) $(postgresqlInstance)-client
	@kubectl exec -n $(namespace) -it $(postgresqlInstance)-client -- /bin/bash

dashboard:
ifeq ($(minikube), true)
	@minikube dashboard -p $(k8scluster)
else
	@echo This operation is for minikube driver only !
endif
