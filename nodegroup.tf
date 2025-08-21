resource "aws_iam_role" "global-node-group-role" {
  name = "node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "global-eks-worker-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.global-node-group-role.name
}

resource "aws_iam_role_policy_attachment" "global-eks-cni-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.global-node-group-role.name
}

resource "aws_iam_role_policy_attachment" "global-eks-container-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.global-node-group-role.name
}


resource "aws_eks_node_group" "global-node-group" {
  cluster_name = aws_eks_cluster.global-cluster.name
  node_group_name = "HighIn"
  node_role_arn = aws_iam_role.global-node-group-role.arn
  subnet_ids = [aws_subnet.pubsub01.id, aws_subnet.pubsub02.id] #aws_subnet.pri01.id, aws_subnet.pri02.id]
  instance_types = ["t3.medium"]

  version = "1.33"

  scaling_config {
    desired_size = 2
    max_size = 4
    min_size = 2
  }

  #  Rolling update strategy
  update_config {
    max_unavailable = 1        # Allow 1 node to be replaced at a time
    # OR you can use percentage instead of fixed count:
    # max_unavailable_percentage = 25
  }

  labels = {
    zone = "west"
  }

  depends_on = [
    aws_iam_role_policy_attachment.global-eks-cni-policy,
    aws_iam_role_policy_attachment.global-eks-container-policy,
    aws_iam_role_policy_attachment.global-eks-worker-policy,
    aws_eks_cluster.global-cluster
  ]
}
