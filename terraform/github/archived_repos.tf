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
