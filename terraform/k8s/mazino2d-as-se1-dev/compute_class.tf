# Cluster-wide default ComputeClass: every Pod without an explicit class runs on Spot only.
# `podFamily` keeps Autopilot pod-based billing (pay per Pod request); without it GKE
# provisions plain Compute Engine nodes and bills the whole VM and boot disk.
# `podFamily` is only accepted when the class creates Autopilot-managed nodes.
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
