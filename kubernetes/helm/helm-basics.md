# What is Helm

- **Helm** is a **package manager** for K8s, it allows us to **bring all of the YAML** files together in a **Chart**.
- A Chart can have a **Name**, **Description**, and **Version**.
- A Chart **groups** all the **YAML** files together in a **Templates** folder.
- To make the Chart **reusable** we have the ability to inject **Values** as parameters.

# Helm 3 Big Concepts:

- A **Chart** is a Helm package. It contains all of the resource definitions necessary to run an application, tool, or service inside of a Kubernetes cluster.

- A **Repository** is a place where charts can be collected and shared.

- A **Release** is an instance of a chart running in a Kubernetes cluster. One chart can often be installed many times into the same cluster. And **each time it is installed, a new release is created**.

Helm installs **charts** into Kubernetes, creating a new **release** for each installation. And to find new charts, you can search Helm chart **repositories**.

<br/>

# Helm CLI - Most Useful Commands

## Search for packages

Searches the **Artifact Hub**, which lists helm charts from dozens of different repositories:

`helm search hub [search name]`

Searches the repositories that you have added to your local helm client

Add a repo: `helm repo add [name you want] [url]`

Search: `helm search repo [search name]`

This search is done over local data, and no public network connection is needed.

_Ref: [https://helm.sh/docs/intro/using_helm/#helm-search-finding-charts](https://helm.sh/docs/intro/using_helm/#helm-search-finding-charts)_

## Installing packages

To install a new package

`helm install [release name you pick] [chart name]`

If you want Helm to generate a name for you, leave off the release name and use `--generate-name`

To keep track of a release's state, or to re-read configuration information.

`helm status [release name]`

If you want to download and look at the files for a published chart, without installing it, you can do so with:

`helm pull [chartrepo/chartname]`

_Ref: [https://helm.sh/docs/intro/using_helm/#helm-install-installing-a-package](https://helm.sh/docs/intro/using_helm/#helm-install-installing-a-package)_

## Customizing the Chart before installing

Installing the way we have here will only use the default configuration options for this chart. Many times, you will want to customize the chart to use your preferred configuration.

To see what options are configurable on a chart.

`helm show values [chart name]`

You can then override any of the settings in a YAML formatted file, and then pass that file during installation.

`helm install -f [values.yaml] [chart name] --generate-name`

There are two ways to pass configuration data during install:

- `--values` (or `-f`): Specify a YAML file with overrides. This can be specified multiple times and the rightmost file will take precedence.
- `--set`: Specify overrides on the command line.

If both are used, -`-set` values are merged into `--values` with **higher precedence**.

- Overrides specified with `--set` are persisted in a **ConfigMap**.
- Values that have been `--set` can be viewed for a given release with
  `helm get values <release-name>`
  And they can be cleared by running `helm upgrade` with `--reset-values` specified.

_Ref: [https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing)_

## Creating Your Own Charts

To create a Helm Chart

`helm create [chart name]`

Now there is a chart. You can edit it and create your own templates.

To validates that it is well-formed:

`helm lint`

Package the chart up for distribution (the output will be a `.tgz` file)

`helm package [Chart Name]`

Install a chart package

`helm install [Chart Name] [Chart Package]`

_Ref: [https://helm.sh/docs/intro/using_helm/#creating-your-own-charts](https://helm.sh/docs/intro/using_helm/#creating-your-own-charts)_

## Working with Helm Repositories

To list the local repositories

`helm repo list`

To add new repositories:

`helm repo add [local name] [URL]`

Because chart repositories change frequently, at any point you can make sure your Helm client is up to date by running `helm repo update`

Install remove a repository

`helm repo remove [name]`

_Ref: [https://helm.sh/docs/intro/using_helm/#helm-repo-working-with-repositories](https://helm.sh/docs/intro/using_helm/#helm-repo-working-with-repositories)_

## Upgrading a Release, and Recovering on Failure

When a new version of a chart is released, or when you want to change the configuration of your release, you can use the `helm upgrade` command.

An upgrade takes an existing release and upgrades it according to the information you provide. **It will only update things that have changed since the last release**.

`helm upgrade -f [updates.yaml] [name of the release] [chart name]`

If something does not go as planned during a release, it is easy to roll back to a previous release using `helm rollback [release name] [Revision NUMBER]`.

A **revision** is an incremental release version. Every time an install, upgrade, or rollback happens, the revision number is incremented by 1.

to see revision numbers for a certain release:

`helm history [Release name]`

_Ref: [https://helm.sh/docs/intro/using_helm/#helm-upgrade-and-helm-rollback-upgrading-a-release-and-recovering-on-failure](https://helm.sh/docs/intro/using_helm/#helm-upgrade-and-helm-rollback-upgrading-a-release-and-recovering-on-failure)_

## Uninstalling a Release

To see all the releases:

`helm list`

To uninstall a release:

`helm uninstall [release name]`

Deletion removes the release record as well. If you wish to **keep a deletion release record**, use `helm uninstall --keep-history [release name]`

show releases that were uninstalled with the `--keep-history` flag

`helm list --uninstalled`

show you all release records that Helm has retained, including records for failed or deleted items (if `--keep-history` was specified)

`helm list --all`

_Ref: [https://helm.sh/docs/intro/using_helm/#helm-uninstall-uninstalling-a-release](https://helm.sh/docs/intro/using_helm/#helm-uninstall-uninstalling-a-release)_
