locals {
  test_host_ip = chomp(data.http.myip.response_body)
  environment  = "Development"
  location     = "East US"
}
