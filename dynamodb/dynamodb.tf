variable "game_monitoring_table_name" {
  type = string
}

variable "game_monitoring_id_column_name" {
  type = string
}


resource "aws_dynamodb_table" "gamestacks" {
  name         = var.game_monitoring_table_name
  hash_key     = var.game_monitoring_id_column_name
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = var.game_monitoring_id_column_name
    type = "S"
  }

}
