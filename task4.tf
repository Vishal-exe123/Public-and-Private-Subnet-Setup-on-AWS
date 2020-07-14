provider "aws" {
region = "ap-south-1"
profile = "Vishterr"
}
resource "aws_vpc" "hw" {
cidr_block = "192.168.0.0/16"
instance_tenancy = "default"
tags = {
Name = "vishVpc"
}
}


resource "aws_subnet" "hw_subnet-1a" {
vpc_id = "${aws_vpc.hw.id}"
cidr_block = "192.168.0.0/24"
availability_zone = "ap-south-1a"
map_public_ip_on_launch = true
}
resource "aws_subnet" "hw_subnet-1b" {
vpc_id = "${aws_vpc.hw.id}"
cidr_block = "192.168.1.0/24"
availability_zone = "ap-south-1b"
}


resource "aws_internet_gateway" "hw_internet_gateway" {
vpc_id = "${aws_vpc.hw.id}"
tags = {
Name = "vish_internet_gateway"
}
}

resource "aws_route_table" "hw_route_table" {
vpc_id = "${aws_vpc.hw.id}"
route {
cidr_block = "0.0.0.0/0"
gateway_id = "${aws_internet_gateway.hw_internet_gateway.id}"
}
tags = {
Name = "vish_route_table"
}
}

resource "aws_route_table_association" "a" {
subnet_id = aws_subnet.hw_subnet-1a.id
route_table_id = "${aws_route_table.hw_route_table.id}"
}


resource "aws_security_group" "myweb" {
name = "myweb"
description = "Allow ssh http and icmp"
vpc_id = "${aws_vpc.hw.id}"
ingress {
description = "http"
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
description = "ssh"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
ingress {
description = "ICMP-IPv4"
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = {
Name = "myweb"
}
}

resource "aws_security_group" "mysql" {
name = "vishmysqlsg"
description = "Allow sql"
vpc_id = "${aws_vpc.hw.id}"
ingress {
description = "MYSQL"
security_groups=[ "${aws_security_group.myweb.id}" ]
from_port = 3306
to_port = 3306
protocol = "tcp"
}
egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = {
Name = "vishmysqlsg"
}
}

resource "aws_security_group" "mybastion" {
name = "vishbastionsg"
description = "Allow ssh for bastion"
vpc_id = "${aws_vpc.hw.id}"
ingress {
description = "ssh"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = {
Name = "vishbastionsg"
}
}

resource "aws_security_group" "mysqlallow" {
name = "vishmysqlallowsg"
description = "ssh allow to the mysql"
vpc_id = "${aws_vpc.hw.id}"
ingress {
description = "ssh"
security_groups=[ "${aws_security_group.mybastion.id}" ]
from_port = 22
to_port = 22
protocol = "tcp"
}
egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = {
Name = "vishmysqlallowsg"
}
}

resource "aws_instance" "myweb" {
ami = "ami-000cbce3e1b899ebd"
instance_type = "t2.micro"
key_name = "vishterrakey"
availability_zone = "ap-south-1a"
subnet_id = "${aws_subnet.hw_subnet-1a.id}"
security_groups = [ "${aws_security_group.myweb.id}" ]
tags = {
Name = "Vish_web"
}
}

resource "aws_instance" "mysqlsecure" {
ami = "ami-08706cb5f68222d09"
instance_type = "t2.micro"
key_name = "vishterrakey"
availability_zone = "ap-south-1b"
subnet_id = "${aws_subnet.hw_subnet-1b.id}"
security_groups = [ "${aws_security_group.mysql.id}" ,
"${aws_security_group.mysqlallow.id}"]
tags = {
Name = "Vishmysqlsecure"
}
}


resource "aws_instance" "mybastion" {
ami = "ami-0732b62d310b80e97"
instance_type = "t2.micro"
key_name = "vishterrakey"
availability_zone = "ap-south-1a"
subnet_id = "${aws_subnet.hw_subnet-1a.id}"
security_groups = [ "${aws_security_group.mybastion.id}" ]
tags = {
Name = "Vishbastion"
}
}

resource "aws_eip" "hw_eip" {
vpc = true
depends_on = ["aws_internet_gateway.hw_internet_gateway"]

tags = {
     Name = "vish_eip"
}
}
resource "aws_nat_gateway" "hw_nat_gateway" {
allocation_id = "${aws_eip.hw_eip.id}"
subnet_id = "${aws_subnet.hw_subnet-1a.id}"
tags = {
Name = "Vish_nat_gateway"
}
}
resource "aws_route_table" "hw_route_table2" {
vpc_id = "${aws_vpc.hw.id}"
route {
cidr_block = "0.0.0.0/0"
nat_gateway_id = "${aws_nat_gateway.hw_nat_gateway.id}"
}
}

resource "aws_route_table_association" "b" {
subnet_id = aws_subnet.hw_subnet-1b.id
route_table_id = "${aws_route_table.hw_route_table2.id}"
}
