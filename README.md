# Cluster Federation

Kubernetes Cluster Federation enables users to federate multiple
Kubernetes clusters.
To know more details about the same please see the
[user guide](https://kubernetes.io/docs/concepts/cluster-administration/federation/).

# Deploying Kubernetes Cluster Federation

The prescribed mechanism to deploy Kubernetes Cluster Federation is using
[kubefed](https://kubernetes.io/docs/admin/kubefed/).
A complete guide for the same is available at
[setup cluster federation using kubefed](https://kubernetes.io/docs/tutorials/federation/set-up-cluster-federation-kubefed/).

# Building Kubernetes Cluster Federation

Building cluster federation binaries, which include fcp (short for federation
control plane) and should be as simple as running:

```shell
make
```

You can specify the docker registry to tag the image using the
KUBE_REGISTRY environment variable. Please make sure that you use
the same value in all the subsequent commands.

To push the built docker images to the registry, run:

```shell
make push
```

To initialize the deployment run:

(This pulls the installer images)

```shell
make init
```

To deploy the clusters and install the federation components, edit the
`${KUBE_ROOT}/_output/federation/config.json` file to describe your
clusters and run:

```shell
make deploy
```

To turn down the federation components and tear down the clusters run:

```shell
make destroy
```

# Ideas for improvement

1. Continue with `destroy` phase even in the face of errors.

   The bash script sets `set -e errexit` which causes the script to exit
   at the very first error. This should be the default mode for deploying
   components but not for destroying/cleanup.


[![Analytics](https://kubernetes-site.appspot.com/UA-36037335-10/GitHub/federation/README.md?pixel)]()
