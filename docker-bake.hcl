# Env variable defalts
variable "JENKINS_DIR" { default = "./repos/pic-sure-all-in-one" }
variable "JENKINS_GIT_HASH" { default = "main" }
variable "API_DIR" { default = "./repos/pic-sure" }
variable "API_GIT_HASH" { default = "main" }
variable "HPDS_DIR" { default = "./repos/pic-sure-hpds" }
variable "HPDS_GIT_HASH" { default = "main" }
variable "AUTH_DIR" { default = "./repos/pic-sure-auth-microapp" }
variable "AUTH_GIT_HASH" { default = "main" }
variable "MIGRATIONS_DIR" { default = "./repos/PIC-SURE-Migrations" }
variable "MIGRATIONS_GIT_HASH" { default = "main" }
variable "FRONTEND_DIR" { default = "./repos/PIC-SURE-Frontend" }
variable "FRONTEND_GIT_HASH" { default = "main" }
variable "DICTIONARY_DIR" { default = "./repos/picsure-dictionary" }
variable "DICTIONARY_GIT_HASH" { default = "main" }
variable "DICTIONARY_ETL_DIR" { default = "./repos/picsure-dictionary-etl" }
variable "DICTIONARY_ETL_GIT_HASH" { default = "main" }
variable "UPLOADER_DIR" { default = "./repos/pic-sure-services" }
variable "UPLOADER_GIT_HASH" { default = "main" }
variable "AGGREGATE_DIR" { default = "./repos/pic-sure" }
variable "AGGREGATE_GIT_HASH" { default = "main" }
variable "PASSTHRU_DIR" { default = "./repos/pic-sure-gic-common-frontend" }
variable "PASSTHRU_GIT_HASH" { default = "main" }

group "default" { # Standalone setup
  targets = ["jenkins", "httpd", "psama", "wildfly", "dictionary-api", "hpds"]
}

group "federated" {
  targets = ["jenkins", "httpd", "psama", "wildfly", "dictionary-api", "passthru"]
}

group "networked" {
  targets = ["jenkins", "httpd", "psama", "wildfly", "dictionary-api", "dictionary-aggregator", "hpds", "uploader"]
}

target "jenkins" {
  context = "${JENKINS_DIR}/jenkins/jenkins-docker"
  dockerfile = "Dockerfile"
  tags = [
    "pic-sure-jenkins:${JENKINS_GIT_HASH}",
    "pic-sure-jenkins:LATEST"
  ]
}

target "httpd" {
  context = "${FRONTEND_DIR}"
  dockerfile = "Dockerfile"
  tags = [
    "hms-dbmi/pic-sure-frontend:${FRONTEND_GIT_HASH}",
    "hms-dbmi/pic-sure-frontend:LATEST"
  ]
}

target "psama" {
  context = "${AUTH_DIR}/pic-sure-auth-services"
  dockerfile = "Dockerfile"
  tags = [
    "hms-dbmi/psama:${AUTH_GIT_HASH}",
    "hms-dbmi/psama:LATEST"
  ]
}

target "wildfly" {
  context = "${API_DIR}/pic-sure-api-war"
  dockerfile = "Dockerfile"
  tags = [
    "hms-dbmi/pic-sure-wildfly:${API_GIT_HASH}",
    "hms-dbmi/pic-sure-wildfly:LATEST"
  ]
}

target "dictionary-api" {
  context = "${DICTIONARY_DIR}"
  dockerfile = "Dockerfile"
  tags = [
    "avillach/dictionary-api:${DICTIONARY_GIT_HASH}",
    "avillach/dictionary-api:latest"
  ]
}

target "dictionary-aggregator" {
  context = "${DICTIONARY_DIR}/aggregate"
  dockerfile = "Dockerfile"
  tags = [
    "avillach/dictionary-dump:${DICTIONARY_GIT_HASH}",
    "avillach/dictionary-dump:latest"
  ]
}

target "hpds" {
  context = "${HPDS_DIR}/docker/pic-sure-hpds"
  dockerfile = "Dockerfile"
  tags = [
    "hms-dbmi/pic-sure-hpds:${HPDS_GIT_HASH}",
    "hms-dbmi/pic-sure-hpds:LATEST"
  ]
}

target "passthru" {
  context = "${PASSTHRU_DIR}/pic-sure-passthru-resource"
  dockerfile = "Dockerfile"
  tags = [
    "hms-dbmi/pic-sure-passthru:${PASSTHRU_GIT_HASH}",
    "hms-dbmi/pic-sure-passthru:LATEST"
  ]
}

target "uploader" {
  context = "${UPLOADER_DIR}/uploader"
  dockerfile = "Dockerfile"
  tags = [
    "lukesikinabch/gic-uploader:${UPLOADER_GIT_HASH}",
    "lukesikinabch/gic-uploader:LATEST"
  ]
}

target "uploader" {
  context = "${UPLOADER_DIR}/uploader"
  dockerfile = "Dockerfile"
  tags = [
    "lukesikinabch/gic-uploader:${UPLOADER_GIT_HASH}",
    "lukesikinabch/gic-uploader:LATEST"
  ]
}