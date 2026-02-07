# cd .ssh/
# ssh-keygen -f eks
resource "aws_key_pair" "eks" {
    key_name = "eks"
    public_key = file("~/.ssh/eks.pub")
}

# eks cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name = "${var.project_name}-${var.environment}"
  kubernetes_version = var.eks_version

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
    metrics-server = {}
  }

  endpoint_public_access = true
  endpoint_private_access = true
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = data.aws_ssm_parameter.vpc_id.value
  subnet_ids               = local.private_subnet_ids
  control_plane_subnet_ids = local.private_subnet_ids
  create_node_security_group = false  # aws blocking
  node_security_group_id = local.node_sg_id # aws blocking
  create_security_group      = false
  security_group_id = local.eks_control_plane_sg_id


  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    # blue deployment
    # blue = {
    #   create = var.enable_blue
    #   ami_type       = "AL2023_x86_64_STANDARD"
    #   instance_types = ["m5.xlarge"]
    #   kubernetes_version = var.eks_nodegroup_blue_version
    #   iam_role_additional_policies = {
    #     amazonEFS = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
    #     amazonEBS = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    #     AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    #     AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    #     AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    #   }

    #   key_name = aws_key_pair.eks.key_name

    #   # cluster nodes autoscaling  
    #   min_size     = 2
    #   max_size     = 10
    #   desired_size = 2

    #   labels = {
    #     nodegroup = "blue"
    #   }
    # }

    # green deployment
    # green = {
    #   create = var.enable_green
    #   ami_type       = "AL2023_x86_64_STANDARD"
    #   instance_types = ["m5.xlarge"]
    #   kubernetes_version = var.eks_nodegroup_green_version
    #   iam_role_additional_policies = {
    #     amazonEFS = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
    #     amazonEBS = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    #   }
    #     key_name = aws_key_pair.eks.key_name
    #   # cluster nodes autoscaling  
    #   min_size     = 2
    #   max_size     = 10
    #   desired_size = 2

    #   labels = {
    #     nodegroup = "green"
    #   }
    # }

    blue = {
      create = var.enable_green
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["m5.xlarge"]
      kubernetes_version = var.eks_nodegroup_blue_version
      iam_role_additional_policies = {
        amazonEFS = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        amazonEBS = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
        key_name = aws_key_pair.eks.key_name
      # cluster nodes autoscaling  
      min_size     = 2
      max_size     = 10
      desired_size = 2

      labels = {
        nodegroup = "blue"
      }
    }
  }

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}"
    }
  )
  
}