# Unit tests

This directory includes an unit tests that can be run with [conftest](https://www.conftest.dev/) tool. All tests are written with Policy Language provided by the Open Policy Agent, see a [documentation](https://www.openpolicyagent.org/docs/latest/policy-language/) site.

# Write and run tests

> To run tests for a simplicity the created helm-release always has a name `w`.

To write a new unit-test follow to this guide:

1. Add a values-file for a new confuguration of `universal-chart` a into [`charts/universal-chart/ci/`](../ci/) direcotory. File should have name with format `<some-name>-values.yaml`.

2. Try to make k8s resources with a new vaules-file. Example create a file `configmap-only-envs-values.yaml`) and make k8s resources:
    ```bash
    cat << EOT > ./charts/universal-chart/ci/configmap-only-envs-values.yaml
    # configmap with ENVs
    envs:
      FOO: bar
      BAR: foo
      BOOL: true
      DIGIT: 123
    EOT

    helm template w --values ./charts/universal-chart/ci/configmap-only-envs-values.yaml ./charts/universal-chart/.
    ```

3. Create a test for this values. Add a new file into [charts/universal-chart/tests/policy](./policy/) directory. File should have name with format `<some-name>.rego`.

4. Write a test for a created k8s manifests from the configuration generated with a this values-file. Use policy language (uses [examples](https://www.conftest.dev/examples/) for a helping). Example test [`./policy/configmap-only-envs.rego`](./policy/configmap-only-envs.rego) for our values `configmap-only-envs-values.yaml` that will test that all generated data has a right count of envs and right value.
    ```golang
    package main
    import data.lib.kubernetes

    # ConfigMap is w-envs and have four params
    deny[msg] {
      input[i].contents.kind == "ConfigMap"
      input[i].contents.metadata.name == "w-envs"
      data := input[i].contents.data
      not count(data) == 4

      msg := "ConfigMap envs is not right. It should be 4"
    }

    # ConfigMap is w-envs and have this data
    deny[msg] {
      input[i].contents.kind == "ConfigMap"
      input[i].contents.metadata.name == "w-envs"
      data := input[i].contents.data
      not ["bar", "foo", "true", "123"] == [data.FOO, data.BAR, data.BOOL, data.DIGIT]

      msg = sprintf("ConfigMap envs has not include right values. Current - '%v'", [data])
    }

    # ConfigMap has req. labels
    deny[msg] {
      input[i].contents.kind == "ConfigMap"
      cm := input[i].contents
      labels := cm.metadata.labels
      not kubernetes.required_deployment_labels(labels)

      msg = sprintf("ConfigMap %s must include Kubernetes recommended labels", [cm.metadata.name])
    }
    ```

5. Run a test with conftest command:
    ```bash
    helm template w --values ./charts/universal-chart/ci/configmap-only-envs-values.yaml ./charts/universal-chart/. \
    | conftest test --combine -p ./charts/universal-chart/tests/policy/configmap-only-envs.rego \
        -p ./charts/universal-chart/tests/policy/lib \
        --data charts/universal-chart/ci/configmap-only-envs-values.yaml -
    ```
    Success results should be like this:
    ```
    3 tests, 3 passed, 0 warnings, 0 failures, 0 exceptions
    ```

6. When unit-test has ready to use add them into workflow to run it automatically via Github Actions. For our example add `configmap-only-envs` into [.github/worflows/conftest.yaml](../../../.github/workflows/conftest.yaml)
    ```
    jobs:
      conftest:
        runs-on: ubuntu-latest
        strategy:
          fail-fast: true
          matrix:
            sample:
              ...
              - configmap-only-envs   # add in the end on this list
    ```