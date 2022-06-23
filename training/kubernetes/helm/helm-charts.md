# Charts

- Helm uses a packaging format called **charts**.
- A **chart** is a **collection of files** that describe a related set of **Kubernetes resources**.
- A single chart might be used to deploy something simple, like a memcached pod, or something complex, like a full web app stack with HTTP servers, databases, caches, and so on.

Charts are created as files laid out in a particular directory tree. They can be packaged into versioned archives to be deployed.

If you want to download and look at the files for a published chart, without installing it, you can do so with `helm pull chartrepo/chartname`

This document explains the chart format, and provides basic guidance for building charts with Helm.

# The Chart File Structure

- A chart is organized as a collection of files inside of a directory.
- The directory name is the name of the chart (without versioning information).

Thus, a chart describing WordPress would be stored in a `wordpress/` directory.

Inside of this directory, Helm will expect a structure that matches this:

```
wordpress/
  Chart.yaml          # A YAML file containing information about the chart
  LICENSE             # OPTIONAL: A plain text file containing the license for the chart
  README.md           # OPTIONAL: A human-readable README file
  values.yaml         # The default configuration values for this chart
  values.schema.json  # OPTIONAL: A JSON Schema for imposing a structure on the values.yaml file
  charts/             # A directory containing any charts upon which this chart depends.
  crds/               # Custom Resource Definitions
  templates/          # A directory of templates that, when combined with values,
                      # will generate valid Kubernetes manifest files.
  templates/NOTES.txt # OPTIONAL: A plain text file containing short usage notes
```

Helm reserves use of the charts/, crds/, and templates/ directories, and of the listed file names.

# The Chart.yaml File

The Chart.yaml file is required for a chart. It contains the following fields:

```yaml
apiVersion: The chart API version (required)
name: The name of the chart (required)
version: A SemVer 2 version (required)

kubeVersion: A SemVer range of compatible Kubernetes versions (optional)
description: A single-sentence description of this project (optional)
type: The type of the chart (optional)
keywords:
  - A list of keywords about this project (optional)
home: The URL of this projects home page (optional)
sources:
  - A list of URLs to source code for this project (optional)
dependencies: # A list of the chart requirements (optional)
  - name: The name of the chart (nginx)
    version: The version of the chart ("1.2.3")
    repository: (optional) The repository URL ("https://example.com/charts") or alias ("@repo-name")
    condition: (optional) A yaml path that resolves to a boolean, used for enabling/disabling charts (e.g. subchart1.enabled )
    tags: # (optional)
      - Tags can be used to group charts for enabling/disabling together
    import-values: # (optional)
      - ImportValues holds the mapping of source values to parent key to be imported. Each item can be a string or pair of child/parent sublist items.
    alias: (optional) Alias to be used for the chart. Useful when you have to add the same chart multiple times
maintainers: # (optional)
  - name: The maintainers name (required for each maintainer)
    email: The maintainers email (optional for each maintainer)
    url: A URL for the maintainer (optional for each maintainer)
icon: A URL to an SVG or PNG image to be used as an icon (optional).
appVersion: The version of the app that this contains (optional). Needn't be SemVer. Quotes recommended.
deprecated: Whether this chart is deprecated (optional, boolean)
annotations:
  example: A list of annotations keyed by name (optional).
```

## Charts and Versioning

Every chart must have a version number. A version must follow the SemVer 2 standard. Unlike Helm Classic, Helm v2 and later uses version numbers as release markers. Packages in repositories are identified by name plus version.

For example, an `nginx` chart whose version field is set to `version: 1.2.3` will be named:

`nginx-1.2.3.tgz`

## The apiVersion Field

The `apiVersion` field should be `v2` for Helm charts that require at least `Helm 3`.

Charts supporting previous Helm versions have an apiVersion set to `v1` and are still installable by Helm 3.

## The kubeVersion Field

The optional `kubeVersion` field can define constraints on **supported Kubernetes versions**. Helm will validate the version constraints when installing the chart and fail if the cluster runs an unsupported Kubernetes version.

AND operator between Versions (Space)

`>= 1.13.0 < 1.15.0`

Which themselves can be combined with the OR || operator like in the following example

`>= 1.13.0 < 1.14.0 || >= 1.14.1 < 1.15.0`

## The appVersion Field

- This field is **informational**, and has no impact on chart version calculations.

- the `appVersion` field is not related to the version field. It is a way of specifying the version of the application.

Wrapping the version in quotes is highly recommended. It forces the YAML parser to treat the version number as a string.

## Chart Types

The type field defines the type of chart. There are two types: `application` and `library`.

- **Application** is the default type and it is the standard chart which can be operated on fully.

- The **library chart** provides utilities or functions for the chart builder. A library chart differs from an application chart because it is not installable and usually doesn't contain any resource objects.

# Templates and Values

All template files are stored in a chart's `templates/` folder. When Helm renders the charts, it will pass every file in that directory through the template engine.

Values for the templates are supplied two ways:

- Chart developers may supply a file called `values.yaml` inside of a chart. This file can contain default values.
- Chart users may supply a YAML file that contains values. This can be provided on the command line with helm install.

When a user supplies custom values, these values will override the values in the chart's values.yaml file.

## Template Files

An example template file might look something like this:

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
 name: deis-database
 namespace: deis
 labels:
   app.kubernetes.io/managed-by: deis
spec:
 replicas: 1
 selector:
   app.kubernetes.io/name: deis-database
 template:
   metadata:
     labels:
       app.kubernetes.io/name: deis-database
   spec:
     serviceAccount: deis-database
     containers:
       - name: deis-database
         image: {{ .Values.imageRegistry }}/postgres:{{ .Values.dockerTag }}
         imagePullPolicy: {{ .Values.pullPolicy }}
         ports:
           - containerPort: 5432
         env:
           - name: DATABASE_STORAGE
             value: {{ default "minio" .Values.storage }}
```

## Predefined Values

Values that are supplied via a `values.yaml` file (or via the `--set` flag) are accessible from the `.Values` object in a template. But there are other pre-defined pieces of data you can access in your templates.

The following values are pre-defined, are available to every template, and cannot be overridden. As with all values, the names are case sensitive.

- `Release.Name`: The name of the **release** (not the chart)
- `Release.Namespace`: The namespace the chart was released to.
- `Release.Service`: The service that conducted the release.
- `Release.IsUpgrade`: This is set to true if the current operation is an upgrade or rollback.
  `Release.IsInstall`: This is set to true if the current operation is an install.
- `Chart`: The contents of the `Chart.yaml`. Thus, the chart version is obtainable as `Chart.Version` and the maintainers are in `Chart.Maintainers`.
- `Files`: A map-like object containing all non-special files in the chart. This will not give you access to templates, but will give you access to additional files that are present (unless they are excluded using `.helmignore`). Files can be accessed using `{{ index .Files "file.name" }}` or using the `{{.Files.Get name }}` function. You can also access the contents of the file as `[]byte` using `{{ .Files.GetBytes }}`
- `Capabilities`: A map-like object that contains information about the versions of Kubernetes `{{ .Capabilities.KubeVersion }}` and the supported Kubernetes API versions `{{ .Capabilities.APIVersions.Has "batch/v1" }}`

## Values files

Considering the template in the previous section, a `values.yaml` file that supplies the necessary values would look like this:

```yaml
imageRegistry: "quay.io/deis"
dockerTag: "latest"
pullPolicy: "Always"
storage: "s3"
```

# Chart LICENSE, README and NOTES

# Chart Dependencies (charts/ directory)

_ref: [Chart Docs](https://helm.sh/docs/topics/charts/)_
