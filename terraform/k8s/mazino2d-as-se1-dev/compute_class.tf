# Cluster-wide default ComputeClass: every Pod without an explicit class runs on Spot only.
resource "kubectl_manifest" "compute_class_default" {
  yaml_body = yamlencode({
    apiVersion = "cloud.google.com/v1"
    kind       = "ComputeClass"
    metadata = {
      name = "default"
    }
    spec = {
      priorities = [
        { spot = true },
      ]
      whenUnsatisfiable = "DoNotScaleUp"
      nodePoolAutoCreation = {
        enabled = true
      }
    }
  })
}
