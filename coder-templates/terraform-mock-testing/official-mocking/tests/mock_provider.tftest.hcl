# main.tftest.hcl

mock_provider "aws" {
  override_data {
    target = module.credentials.data.aws_s3_object.data_bucket
    values = {
      body = "{\"username\":\"username123\",\"password\":\"password123\"}"
    }
  }
}

run "test" {
  assert {
    condition     = jsondecode(local_file.credentials_json.content).username == "username123"
    error_message = "incorrect username"
  }
}
