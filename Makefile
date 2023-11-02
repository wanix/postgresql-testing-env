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

postgresqlInstance=postgresql-testing
postgresqlVersion=16.0.0
postgresqlMainPassword=$(shell openssl rand -base64 64 | tr -d '\n' | xargs echo)
postgresqlUser=testuser
postgresqlPassword=$(shell openssl rand -base64 64 | tr -d '\n' | xargs echo)
postgresqlDb=testdb
postgresqlDiskSize=20Gi



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

export PGVERSION := $(postgresqlVersion)
export PGINSTANCENAME := $(postgresqlInstance)
export PGMAINPASSWORD := $(postgresqlMainPassword)
export PGUSERNAME := $(postgresqlUser)
export PGUSERPASSWORD := $(postgresqlPassword)
export PGMAINDB := $(postgresqlDb)
export PGDISKSIZE := $(postgresqlDiskSize)


asdf-install :
# https://asdf-vm.com/guide/getting-started.html
	@asdf plugin-add helm
	@asdf plugin-add kubectl
	@asdf plugin-add minikube
	@asdf install

configure:
	@test -d $(minikubePersistantPath) || mkdir -p $(minikubePersistantPath)/postgresql \
											$(minikubePersistantPath)/psql \
											$(minikubePersistantPath)/pgwatch2/pg \
											$(minikubePersistantPath)/pgwatch2/grafana \
											$(minikubePersistantPath)/pgwatch2/config
	@test -d $(generated_k8s_path) || mkdir -p $(generated_k8s_path)
	@test -d $(generated_cfg_path) || mkdir -p $(generated_cfg_path)

	@cat kubernetes/cm-postgresql-client.yml.tpl  | envsubst > $(generated_k8s_path)/cm-postgresql-client.yml
	@cat kubernetes/pod-postgresql-client.yml.tpl | envsubst > $(generated_k8s_path)/pod-postgresql-client.yml
	@cat kubernetes/pv-postgresql-client.yml.tpl  | envsubst > $(generated_k8s_path)/pv-postgresql-client.yml
	@cat kubernetes/pvc-postgresql-client.yml.tpl | envsubst > $(generated_k8s_path)/pvc-postgresql-client.yml

	@cat kubernetes/pv-postgresql-data.yml.tpl  | envsubst > $(generated_k8s_path)/pv-postgresql-data.yml
	@cat kubernetes/pvc-postgresql-data.yml.tpl | envsubst > $(generated_k8s_path)/pvc-postgresql-data.yml

	@cat kubernetes/pv-pgwatch2-data.yml.tpl  | envsubst > $(generated_k8s_path)/pv-pgwatch2-data.yml
	@cat kubernetes/pvc-pgwatch2-data.yml.tpl | envsubst > $(generated_k8s_path)/pvc-pgwatch2-data.yml

ifeq ("$(wildcard $(generated_cfg_path)/helm-conf--$(postgresqlInstance).yml)","")
    #File not exists
	@envsubst < cfg/helm-conf.yaml.tpl > $(generated_cfg_path)/helm-conf--$(postgresqlInstance).yml
	@chmod 600 $(generated_cfg_path)/helm-conf--$(postgresqlInstance).yml
endif



start : configure start_minikube install_postgresql install_monitoring info

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

install_postgresql :
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/pv-postgresql-data.yml
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/pvc-postgresql-data.yml

	@helm list -n $(namespace) | egrep -q '^$(postgresqlInstance)\s' \
		|| helm install -n $(namespace) $(postgresqlInstance) oci://registry-1.docker.io/bitnamicharts/postgresql \
			-f $(generated_cfg_path)/helm-conf--$(postgresqlInstance).yml \
		&& helm upgrade -n $(namespace) $(postgresqlInstance) oci://registry-1.docker.io/bitnamicharts/postgresql \
			-f $(generated_cfg_path)/helm-conf--$(postgresqlInstance).yml

install_monitoring :
ifeq ($(minikube), true)
  ifeq ($(with_monitoring), true)
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/pv-pgwatch2-data.yml
	@kubectl apply -n $(namespace) -f $(generated_k8s_path)/pvc-pgwatch2-data.yml
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
	kubectl apply -n $(namespace) -f $(generated_k8s_path)/cm-postgresql-client.yml
	kubectl apply -n $(namespace) -f $(generated_k8s_path)/pv-postgresql-client.yml
	kubectl apply -n $(namespace) -f $(generated_k8s_path)/pvc-postgresql-client.yml
	kubectl apply -n $(namespace) -f $(generated_k8s_path)/pod-postgresql-client.yml
	@sleep 2s
	@kubectl exec -n $(namespace) -it $(postgresqlInstance)-client -- \
	  psql -h postgresql-testing.$(namespace).svc.cluster.local -U postgres -d $(postgresqlDb)

dashboard:
ifeq ($(minikube), true)
	@minikube dashboard -p $(k8scluster)
else
	@echo This operation is for minikube driver only !
endif
