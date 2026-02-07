![alt text](k8-terraform.svg)

![alt text](k8-terraform-1.svg)

### Approach-1
Ingress resource in manifest yaml file, attach internal service and Ingress Controller.

### Best Approach
1. Ingress controller(install aws loadbalancer controller).
Ref: https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/

2. alb and listener and route53 of listener rule and targetgroup and listener rule(60-alb) 

3. targetgroupbinding in manifest yaml file, attach internal service.
TargetGroupBinding.
Ref: https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/targetgroupbinding/targetgroupbinding/

### EKS Managed Node Group
Ref: https://github.com/terraform-aws-modules/terraform-aws-eks