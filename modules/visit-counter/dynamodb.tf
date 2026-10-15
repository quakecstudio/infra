# One item: { id = "visits", count = N }.
resource "aws_dynamodb_table" "counter" {
  name         = "${var.name}-visit-counter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  tags         = var.tags

  attribute {
    name = "id"
    type = "S"
  }
}
