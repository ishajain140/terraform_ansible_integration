#defining the provider block
provider "aws" {
  region = "ap-south-1"
  profile = "default"
	
}


#aws instance creation
resource "aws_instance" "os1" {
  ami           = "ami-010aff33ed5991201"
  instance_type = "t2.micro"
  security_groups =  [ "launch-wizard-3" ]
   key_name = "mykey1122"
  tags = {
    Name = "TerraformOS"
  }
}


#IP of aws instance retrieved
output "op1"{
value = aws_instance.os1.public_ip
}


#IP of aws instance copied to a file ip.txt in local system
resource "local_file" "ip" {
    content  = aws_instance.os1.public_ip
    filename = "ip.txt"
}


#ebs volume created
resource "aws_ebs_volume" "ebs"{
  availability_zone =  aws_instance.os1.availability_zone
  size              = 1
  tags = {
    Name = "myterraebs"
  }
}


#ebs volume attatched
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs.id
  instance_id = aws_instance.os1.id
  force_detach = true
}


#device name of ebs volume retrieved
output "op2"{
value = aws_volume_attachment.ebs_att.device_name
}


#connecting to the Ansible control node using SSH connection
resource "null_resource" "nullremote1" {
depends_on = [aws_instance.os1] 
connection {
	type     = "ssh"
	user     = "root"
	password = "${var.password}"
    	host= "${var.host}" 
}
#copying the ip.txt file to the Ansible control node from local system
provisioner "file" {
    source      = "ip.txt"
    destination = "/root/ansible_terraform/aws_instance/ip.txt"
  		   }
}


#connecting to the Linux OS having the Ansible playbook
resource "null_resource" "nullremote2" {
depends_on = [aws_volume_attachment.ebs_att]  
connection {
	type     = "ssh"
	user     = "root"
	password = "${var.password}"
    	host= "${var.host}"
}
#command to run ansible playbook on remote Linux OS
provisioner "remote-exec" {
    
    inline = [
	"cd /root/ansible_terraform/aws_instance/",
	"ansible-playbook instance.yml"
]
}
}


# to automatically open the webpage on local system
resource "null_resource" "nullremote3" {
depends_on = [null_resource.nullremote2]
provisioner "local-exec" {
command = "chrome http://${aws_instance.os1.public_ip}/web/"
}
}

