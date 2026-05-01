module "everything_as_code" {
  source = "./_modules/infisical-project"
  name   = "everything-as-code"
  slug   = "everything-as-code"

  identities = [
    { name = "cicd", id = module.cicd.id, role = "member" },
    { name = "k8s-operator", id = module.k8s_operator.id, role = "member" },
  ]
}
