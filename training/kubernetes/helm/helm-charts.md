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

NOTES:

- The default values file included inside of a chart must be named `values.yaml`. But files specified on the command line can be named anything.
- If the `--set` flag is used on`helm install` or `helm upgrade`, those values are simply converted to YAML on the client side.

## Scope, Dependencies, and Values

docs: [https://helm.sh/docs/topics/charts/#scope-dependencies-and-values]

## Global Values

docs: [https://helm.sh/docs/topics/charts/#global-values]

## Schema Files

Sometimes, a chart maintainer might want to define a structure on their values.

This can be done by defining a schema in the `values.schema.json` file.

A schema is represented as a JSON Schema. It might look something like this:

```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "properties": {
    "image": {
      "description": "Container Image",
      "properties": {
        "repo": {
          "type": "string"
        },
        "tag": {
          "type": "string"
        }
      },
      "type": "object"
    },
    "name": {
      "description": "Service name",
      "type": "string"
    },
    "port": {
      "description": "Port",
      "minimum": 0,
      "type": "integer"
    },
    "protocol": {
      "type": "string"
    }
  },
  "required": ["protocol", "port"],
  "title": "Values",
  "type": "object"
}
```

This schema will be applied to the values to validate it. Validation occurs when any of the following commands are invoked:

- `helm install`
- `helm upgrade`
- `helm lint`
- `helm template`

# Chart LICENSE, README and NOTES

Charts can also contain files that describe the installation, configuration, usage and license of a chart.

- A **LICENSE** is a plain text file containing the license for the chart. The chart can contain a license as it may have programming logic in the templates and would therefore not be configuration only. There can also be separate license(s) for the application installed by the chart, if required.

- A **README** for a chart should be formatted in Markdown (README.md), and should generally contain:

  - A description of the application or service the chart provides
  - Any prerequisites or requirements to run the chart
  - Descriptions of options in `values.yaml` and default values
  - Any other information that may be relevant to the installation or configuration of the chart

- The chart can also contain a short plain text **templates/NOTES**.txt file that will be printed out after installation, and when viewing the status of a release.
  This file is evaluated as a template, and can be used to display usage notes, next steps, or any other information relevant to a release of the chart. For example, instructions could be provided for connecting to a database, or accessing a web UI.

# Chart Dependencies (charts/ directory)

In Helm, one chart may depend on any number of other charts.

These dependencies can be dynamically linked using the `dependencies` field in `Chart.yaml` or brought in to the `charts/` directory and managed manually.

## Managing Dependencies with the `dependencies` field

The charts required by the current chart are defined as a list in the `dependencies` field.

```yaml
dependencies:
  - name: apache
    version: 1.2.3
    repository: https://example.com/charts
  - name: mysql
    version: 3.2.1
    repository: https://another.example.com/charts
```

- The `name` field is the name of the chart you want.
- The `version` field is the version of the chart you want.
- The `repository` field is the full URL to the chart repository. _Note that you must also use helm repo add to add that repo locally._
- You might use the name of the repo instead of URL

Once you have defined dependencies, you can `run helm dependency update` and it will use your dependency file to download all the specified charts into your `charts/` directory for you.

When `helm dependency update` retrieves charts, it will store them as chart **archives** in the `charts/` directory. So for the example above, one would expect to see the following files in the charts directory:

```
charts/
  apache-1.2.3.tgz
  mysql-3.2.1.tgz
```

### Alias field in dependencies:

In addition to the other fields above, each requirements entry may contain the optional field `alias`.

Adding an alias for a dependency chart would put a chart in dependencies using alias as name of new dependency.

Example in docs: [https://helm.sh/docs/topics/charts/#alias-field-in-dependencies]

### Tags and Condition fields in dependencies:

In addition to the other fields above, each requirements entry may contain the optional fields `tags` and `condition`.

All charts are loaded by default. If `tags` or `condition` fields are present, they will be evaluated and used to control loading for the chart(s) they are applied to.

docs for more: [https://helm.sh/docs/topics/charts/#tags-and-condition-fields-in-dependencies]

## Managing Dependencies manually via the `charts/` directory

If more control over dependencies is desired, these dependencies can be expressed explicitly by copying the dependency charts into the `charts/` directory.

docs for more: [https://helm.sh/docs/topics/charts/#managing-dependencies-manually-via-the-charts-directory]

_ref: [Chart Docs](https://helm.sh/docs/topics/charts/)_
