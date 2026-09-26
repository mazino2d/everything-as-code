# Cluster-wide default ComputeClass: Pods without an explicit class run on Spot only.
# `podFamily` (requires `autopilot.enabled`) keeps pod-based billing instead of per-node VM billing.
resource "kubectl_manifest" "compute_class_default" {
  yaml_body = yamlencode({
    apiVersion = "cloud.google.com/v1"
    kind       = "ComputeClass"
    metadata = {
      name = "default"
    }
    spec = {
      autopilot = {
        enabled = true
      }
      priorities = [
        { podFamily = "general-purpose", spot = true },
      ]
      whenUnsatisfiable = "DoNotScaleUp"
      nodePoolAutoCreation = {
        enabled = true
      }
    }
  })
}
