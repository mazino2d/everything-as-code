# ===================================================================
# Active - Public
# ===================================================================

module "test_repo" {
  source      = "./_modules/github-repository"
  name        = "test_repo"
  description = "test_repo"
  visibility  = "public"
  topics      = ["test-repo"]
}

module "everything_as_code" {
  source      = "./_modules/github-repository"
  name        = "everything-as-code"
  description = "Infrastructure, platform, and tooling managed as code"
  visibility  = "public"
  topics      = ["terraform", "iac", "gitops", "github"]
}

module "mazino2d" {
  source      = "./_modules/github-repository"
  name        = "mazino2d"
  description = "GitHub profile README :D"
  visibility  = "public"
  topics      = ["profile"]
}

module "mazino2d_github_io" {
  source       = "./_modules/github-repository"
  name         = "mazino2d.github.io"
  description  = "My SPACE!"
  visibility   = "public"
  topics       = ["personal-website", "blog"]
  has_wiki     = false
  has_projects = false

  pages = {
    branch = "main"
    path   = "/"
  }
}

module "caketool" {
  source      = "./_modules/github-repository"
  name        = "caketool"
  description = "Machine learning library"
  visibility  = "public"
  topics      = ["machine-learning", "python"]

  pages = {
    branch = "gh-pages"
    path   = "/docs"
  }
}

module "jaffle_shop" {
  source      = "./_modules/github-repository"
  name        = "jaffle-shop"
  description = "dbt learning playground based on the Jaffle Shop demo"
  visibility  = "public"
  topics      = ["dbt", "data-engineering", "analytics"]

  pages = {
    build_type = "workflow"
  }
}

module "sim_split" {
  source      = "./_modules/github-repository"
  name        = "sim-split"
  description = "Bill splitting simulation app"
  visibility  = "public"
  topics      = ["flutter", "dart"]
}

module "staged_recipes" {
  source      = "./_modules/github-repository"
  name        = "staged-recipes"
  description = "Conda recipes staged before publishing to conda-forge"
  visibility  = "public"
  topics      = ["conda", "conda-forge", "data-science"]
}

# ===================================================================
# Archived
# ===================================================================

module "a3spy" {
  source         = "./_modules/github-repository"
  name           = "a3spy"
  description    = "Funny game (on Telegram)"
  visibility     = "public"
  topics         = ["telegram", "game", "python"]
  default_branch = "master"
  archived       = true
}

module "ex_bk" {
  source         = "./_modules/github-repository"
  name           = "ex-bk"
  description    = "ZALO AI code with my ex-bk"
  visibility     = "public"
  topics         = ["zalo", "audio", "cnn", "deep-learning", "python"]
  default_branch = "master"
  archived       = true
}

module "bypass_bkel" {
  source         = "./_modules/github-repository"
  name           = "bypass-bkel"
  description    = "Workaround for BKEL e-learning platform restrictions (HCMUT)"
  visibility     = "public"
  topics         = ["hcmut"]
  default_branch = "master"
  archived       = true
}

module "data_crawler" {
  source         = "./_modules/github-repository"
  name           = "data-crawler"
  description    = "Web scraping and data crawling utilities"
  visibility     = "public"
  topics         = ["web-scraping", "python", "data-engineering"]
  default_branch = "master"
  archived       = true
}

module "socket_chat" {
  source         = "./_modules/github-repository"
  name           = "socket-chat"
  description    = "TCP/UDP socket chat app — Computer Networks assignment (HCMUT)"
  visibility     = "public"
  topics         = ["socket", "networking", "java", "hcmut"]
  default_branch = "master"
  archived       = true
}

module "pp_course" {
  source         = "./_modules/github-repository"
  name           = "pp-course"
  description    = "Parallel Programming course assignments (HCMUT)"
  visibility     = "public"
  topics         = ["parallel-programming", "spark", "hcmut"]
  default_branch = "master"
  archived       = true
}

module "ai_course" {
  source         = "./_modules/github-repository"
  name           = "ai-course"
  description    = "Artificial Intelligence course assignments (HCMUT)"
  visibility     = "public"
  topics         = ["ai", "machine-learning", "hcmut"]
  default_branch = "master"
  archived       = true
}

module "ppl_course" {
  source         = "./_modules/github-repository"
  name           = "ppl-course"
  description    = "Custom language compiler built from scratch — Programming Principles and Language (HCMUT)"
  visibility     = "public"
  topics         = ["compiler", "python", "hcmut"]
  default_branch = "master"
  archived       = true
}

module "dsa_course" {
  source         = "./_modules/github-repository"
  name           = "dsa-course"
  description    = "Data Structures and Algorithms course assignments (HCMUT)"
  visibility     = "public"
  topics         = ["data-structures", "algorithms", "hcmut"]
  default_branch = "master"
  archived       = true
}

module "unrolled_linked_list" {
  source         = "./_modules/github-repository"
  name           = "unrolled-linked-list"
  description    = "Unrolled linked list implementation — DSA assignment (HCMUT)"
  visibility     = "public"
  topics         = ["data-structures", "cpp", "hcmut"]
  default_branch = "master"
  archived       = true
}

module "baseml" {
  source         = "./_modules/github-repository"
  name           = "baseml"
  description    = "Machine Learning course assignments and implementations (HCMUT)"
  visibility     = "public"
  topics         = ["machine-learning", "python", "hcmut"]
  default_branch = "master"
  archived       = true
}

module "utxo_selection" {
  source         = "./_modules/github-repository"
  name           = "utxo-selection"
  description    = "Mathematical models for UTXO selection in Bitcoin transactions"
  visibility     = "public"
  topics         = ["bitcoin", "blockchain", "research"]
  default_branch = "master"
  archived       = true
}

module "syscall_proc_info" {
  source         = "./_modules/github-repository"
  name           = "syscall-proc-info"
  description    = "Custom Linux kernel 5.0 system call for process info — OS assignment (HCMUT)"
  visibility     = "public"
  topics         = ["linux", "kernel", "c", "hcmut"]
  default_branch = "master"
  archived       = true
}

module "os_course" {
  source         = "./_modules/github-repository"
  name           = "os-course"
  description    = "Operating Systems course assignments (HCMUT)"
  visibility     = "public"
  topics         = ["operating-systems", "hcmut"]
  default_branch = "master"
  archived       = true
}

module "os_simulation" {
  source         = "./_modules/github-repository"
  name           = "os-simulation"
  description    = "OS process and memory scheduling simulation — OS assignment (HCMUT)"
  visibility     = "public"
  topics         = ["operating-systems", "simulation", "hcmut"]
  default_branch = "master"
  archived       = true
}
