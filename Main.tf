provider "aws" {
  region  = "ap-south-1"
  profile =  "chirag"
}

resource "aws_security_group" "tasksg" {
 name      = "mytask1_security_group"
 description = "task1 security group"
// vpc_id      = vpc-0c632bf88df9afb11

 ingress { 
   from_port    = 80
   to_port      = 80 
   protocol     = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }
 ingress { 
   from_port    = 22
   to_port      = 22
   protocol     = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 } 
  egress {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
   }
 
 tags = {
  Name = "mytask1_security_group"
 }
}

resource "aws_instance" "taskos" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "my_key"
  security_groups = [ "mytask1_security_group" ]

connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/CHIRAG/Downloads/my_key.pem")
    host     = aws_instance.taskos.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "Task1OS"
  }

}


resource "aws_ebs_volume" "myebs" {
  availability_zone = aws_instance.taskos.availability_zone
  size              = 1
  tags = {
    Name = "task_ebs"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.myebs.id
  instance_id = aws_instance.taskos.id
}

resource "null_resource" "taskos"  {

depends_on = [
    aws_volume_attachment.ebs_att,
  ]


 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/CHIRAG/Downloads/my_key.pem")
    host     = aws_instance.taskos.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/vimallinuxworld13/multicloud.git /var/www/html/"
    ]
  }
}


resource "aws_s3_bucket" "mys3" {
  bucket = "chirag887567"
  acl    = "public-read"

  versioning {
    enabled = true
  }
  
  tags = {
    Name = "Mybucket"
  }
}
resource "aws_s3_bucket_object" "file_upload" {
  bucket = "chirag887567"
  key    = "vimalsir.png"
  source = "file(C:/Users/CHIRAG/Pictures/Screenshots/vimalsir.png)"
  acl = "public-read"
  //content_type = "image or jpeg"
  }


resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "chirag887567.s3.amazonaws.com"
    origin_id   = "S3-chirag887567"

  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "chirag887567.s3.amazonaws.com"
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-chirag887567"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-chirag887567"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-chirag887567"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }



  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

