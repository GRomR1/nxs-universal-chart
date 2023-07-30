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
