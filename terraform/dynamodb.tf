resource "aws_dynamodb_table" "HAL_TEXT_AUDIT" {
  "attribute" {
    name = "MessageID"
    type = "S"
  }
  hash_key = "MessageID"
  name = "HAL_TEXT_AUDIT"
  read_capacity = 1
  write_capacity = 1
}