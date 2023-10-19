.PHONY : asdf-install \
	start stop \
	clean \
	client \
	dashboard

#########################
# Default Configuration #
#########################

kubeconfig=${PWD}/postgresql-testing-env.kubeconfig
kubeversion=$(shell grep "kubectl " .tool-versions | cut -d " " -f 2)
namespace=default
k8scluster=k8s-postgresql-testing-env

postgresqlInstance=postgresql-testing
postgresqlVersion=16.0.0
postgresqlMainPassword=$(shell openssl rand -base64 64 | tr -d '\n' | xargs echo)
postgresqlUser=testuser
postgresqlPassword=$(shell openssl rand -base64 64 | tr -d '\n' | xargs echo)
postgresqlDb=testdb


minikube=true
minikubeResources=--memory 8192 --cpus 4
# https://minikube.sigs.k8s.io/docs/drivers/
minikubeDriver=docker
minikubePersistantPath=${PWD}/persistentVolumesData/pv-$(k8scluster)
minikubeMountPath=/tmp/hostpath_pv_data
minikubeNodes=3

#######################
# Makefile operations #
#######################

export KUBECONFIG := $(kubeconfig)
export PGVERSION := $(postgresqlVersion)
export PGINSTANCENAME := $(postgresqlInstance)

asdf-install :
# https://asdf-vm.com/guide/getting-started.html
	@asdf plugin-add helm
	@asdf plugin-add kubectl
	@asdf plugin-add minikube
	@asdf install

start :
	@test -d $(persistantMountPath) || mkdir $(persistantMountPath)
ifeq ($(minikube), true)
  ifeq ($(minikubeDriver), docker)
	@minikube start -p $(k8scluster) $(minikubeResources) \
	  --kubernetes-version=$(kubeversion) \
	  --driver=$(minikubeDriver) \
	  --nodes $(minikubeNodes) \
	  --mount --mount-string $(minikubePersistantPath):$(minikubeMountPath)
  else
	@minikube start -p $(k8scluster) $(minikubeResources) \
	  --kubernetes-version=$(kubeversion) \
	  --driver=$(minikubeDriver) \
	  --nodes $(minikubeNodes)
  endif
endif
	@kubectl apply -n $(namespace) -f kubernetes/pv-postgresql-data.yml
	@kubectl apply -n $(namespace) -f kubernetes/pvc-postgresql-data.yml

	@helm install -n $(namespace) $(postgresqlInstance) oci://registry-1.docker.io/bitnamicharts/postgresql \
	  --set primary.persistence.existingClaim=pvc-postgresql-data \
	  --set volumePermissions.enabled=true \
	  --set global.postgresql.auth.postgresPassword="$(postgresqlMainPassword)" \
	  --set global.postgresql.auth.username="$(postgresqlUser)" \
	  --set global.postgresql.auth.password=$(postgresqlPassword) \
	  --set global.postgresql.auth.database=$(postgresqlDb) \
	  --set image.tag=$(postgresqlVersion)
	@echo
	@echo You can now set your env:
	@echo  export KUBECONFIG="$(kubeconfig)"

stop :
ifeq ($(minikube), true)
	@minikube stop -p $(k8scluster)
else
	@echo This operation is for minikube driver only !
endif

clean :
	@cat kubernetes/pod-postgresql-client.yaml | envsubst | kubectl delete -n $(namespace) -f -
	@helm delete -n $(namespace) $(postgresqlInstance)
	@kubectl delete -n $(namespace) -f kubernetes/pvc-postgresql-data.yml
	@kubectl delete -n $(namespace) -f kubernetes/pv-postgresql-data.yml
ifeq ($(minikube), true)
	@minikube delete -p $(k8scluster)
endif

client :
	@cat kubernetes/pod-postgresql-client.yaml | envsubst | kubectl apply -n $(namespace) -f -
	@kubectl exec -n $(namespace) -it $(postgresqlInstance)-client -- \
	  psql -h postgresql-testing.$(namespace).svc.cluster.local -U postgres -d $(postgresqlDb)

dashboard:
ifeq ($(minikube), true)
	@minikube dashboard -p $(k8scluster)
else
	@echo This operation is for minikube driver only !
endif
