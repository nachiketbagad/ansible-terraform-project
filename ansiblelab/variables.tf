variable "amiid" {
  default = "ami-02d26659fd82cf299"   # Replace with valid AMI ID for your region
}

variable "type" {
  default = "t2.micro"
}

variable "pemfile" {
  default = "Yogeshkey.pem"   # Replace with your actual key pair file name
}

variable "servercount" {
  default = 1   # Number of EC2 instances you want
}
