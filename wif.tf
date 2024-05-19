resource "google_project_service" "wif_api" {
  for_each = toset([
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

module "gh_oidc" {

  depends_on = [resource.google_service_account.github_svc]

  source            = "terraform-google-modules/github-actions-runners/google//modules/gh-oidc"
  version           = "v3.1.2" # Latest version
  project_id        = var.project_id
  pool_id           = "gh-identity-pool"
  pool_display_name = "Identity Pool"
  provider_id       = "gh-provider"
  sa_mapping = {
    (resource.google_service_account.github_svc.account_id) = {
      sa_name   = resource.google_service_account.github_svc.name
      attribute = "*"
    }
  }
}

resource "google_service_account_iam_binding" "github_svc_binding" {
  depends_on = [module.gh_oidc]
  service_account_id = google_service_account.github_svc.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/gh-identity-pool/attribute.repository/HenryXiloj/wif-gcp-githubactions-integrations"
  ]
}

