#!/usr/bin/env python3

# Compiled as a module.
# To run directly for testing, use:
# python -m aws.aws_nuke

from __future__ import annotations

import argparse
import os
import sys
import time
from dataclasses import dataclass, field
from botocore.exceptions import NoCredentialsError
from aws.aws_clients_ex import AwsEx, EC2ElasticIPEx, EC2InstanceEx, ECRRepoEx, EKSClusterEx, KMSAliasEx, KMSKeyEx, S3BucketEx

TIMEOUT_SECONDS = 300

@dataclass
class Config:
    account_id: str
    region: str
    profile: str
    dry_run: bool
    nuke_s3: bool
    wait_timeout_seconds: int
    assume_yes: bool


def load_config_from_env_and_args() -> Config:
    parser = argparse.ArgumentParser(description="Nuke AWS resources in a region (use with caution)")
    parser.add_argument("--region", default=os.getenv("REGION", os.getenv("AWS_REGION", "us-west-1")))
    parser.add_argument("--profile", default=os.getenv("AWS_PROFILE", "default"))
    parser.add_argument("--account-id", default=os.getenv("ACCOUNT_ID", ""))
    parser.add_argument("--dry-run", action="store_true", default=os.getenv("DRY_RUN", "0") == "1")
    parser.add_argument("--nuke-s3", action="store_true", default=os.getenv("NUKE_S3", "0") == "1",
                        help="Delete ALL S3 buckets (global)")
    parser.add_argument("--wait-timeout", type=int, default=int(os.getenv("WAIT_TIMEOUT_SECONDS", "180")))
    parser.add_argument("--yes", action="store_true", default=False, help="Skip interactive confirmation")

    args = parser.parse_args()

    return Config(
        account_id=args.account_id,
        region=args.region,
        profile=args.profile,
        dry_run=bool(args.dry_run),
        nuke_s3=bool(args.nuke_s3),
        wait_timeout_seconds=int(args.wait_timeout),
        assume_yes=bool(args.yes),
    )


@dataclass
class AwsSnapshot:
    eks_clusters: list[EKSClusterEx] = field(default_factory=list)
    elbv2_arns: list[str] = field(default_factory=list)
    elb_names: list[str] = field(default_factory=list)
    ecr_repos: list[ECRRepoEx] = field(default_factory=list)
    log_groups: list[str] = field(default_factory=list)
    ec2_instances: list[EC2InstanceEx] = field(default_factory=list)
    nat_gateways: list[str] = field(default_factory=list)
    eip_allocs: list[EC2ElasticIPEx] = field(default_factory=list)
    vpcs_non_default: list[str] = field(default_factory=list)
    # Global
    iam_oidc_arns: list[str] = field(default_factory=list)
    iam_local_policy_arns: list[str] = field(default_factory=list)
    iam_roles: list[str] = field(default_factory=list)
    iam_users: list[str] = field(default_factory=list)
    # KMS and S3
    kms_customer_keys: list[KMSKeyEx] = field(default_factory=list)
    kms_aliases: list[KMSAliasEx] = field(default_factory=list)
    s3_buckets: list[S3BucketEx] = field(default_factory=list)

    def __post_init__(self) -> None:
        self.eks_clusters = []
        self.elbv2_arns = []
        self.elb_names = []
        self.ecr_repos = []
        self.log_groups = []
        self.ec2_instances = []
        self.nat_gateways = []
        self.eip_allocs = []
        self.vpcs_non_default = []
        self.iam_oidc_arns = []
        self.iam_local_policy_arns = []
        self.iam_roles = []
        self.iam_users = []
        self.kms_customer_keys = []
        self.kms_aliases = []
        self.s3_buckets = []

    # Split IAM roles
    @property
    def iam_service_linked(self) -> list[str]:
        return [r for r in self.iam_roles if r.startswith("AWSServiceRoleFor")]

    @property
    def iam_non_slr(self) -> list[str]:
        return [r for r in self.iam_roles if not r.startswith("AWSServiceRoleFor")]

    def print_property(self, key: str, prefix: str, empty_label: str) -> bool:
        items = list(getattr(self, key, []) or [])
        if items:
            for i in items:
                print(f"{prefix}: {i}")
            return True
        else:
            print(empty_label)
        return False


def confirm() -> bool:
    print()
    try:
        typed = input('Type "NUKE" to continue (or Ctrl+C to abort): ').strip()
    except KeyboardInterrupt:
        print()
        print("Aborted.")
        return False
    if typed != "NUKE":
        print("Aborted.")
        return False
    return True

def discover(aws: AwsEx, nuke_s3: bool) -> AwsSnapshot | None:
    print()
    print("=== Discovery (building plan) ===")
    snapshot = AwsSnapshot()
    # Region-scoped
    snapshot.eks_clusters = aws.eks.list_clusters()
    snapshot.elbv2_arns = aws.elbv2.list_load_balancer_arns()
    snapshot.elb_names = aws.elb.list_load_balancer_names()
    snapshot.ecr_repos = aws.ecr.list_repositories()
    snapshot.log_groups = aws.logs.list_log_group_names()
    snapshot.ec2_instances = aws.ec2.list_instances()
    snapshot.nat_gateways = aws.ec2.list_nat_gateway_ids()
    snapshot.eip_allocs = aws.ec2.list_elastic_ips()
    snapshot.vpcs_non_default = aws.ec2.list_non_default_vpc_ids()
    # Global
    snapshot.iam_oidc_arns = aws.iam.list_oidc_provider_arns()
    snapshot.iam_local_policy_arns = aws.iam.list_local_policy_arns()
    snapshot.iam_roles = aws.iam.list_role_names()
    snapshot.iam_users = aws.iam.list_user_names()
    # KMS and S3
    snapshot.kms_customer_keys = aws.kms.list_customer_keys()
    snapshot.kms_aliases = aws.kms.list_aliases(customer_only=True)
    snapshot.s3_buckets = aws.s3.list_buckets()

    delete_plan = [
        ("eks_clusters", "EKS Cluster", " - No EKS clusters"),
        ("elbv2_arns", "ELBv2", " - No ELBv2 load balancers"),
        ("elb_names", "Classic ELB", " - No Classic ELBs"),
        ("ecr_repos", "ECR Repo", " - No ECR repositories"),
        ("log_groups", "Log Group", " - No CloudWatch log groups"),
        ("iam_oidc_arns", "IAM OIDC", " - No IAM OIDC providers"),
        ("iam_local_policy_arns", "IAM Policy (local)", " - No IAM local policies"),
        ("iam_non_slr", "IAM Role (non-SLR)", " - No IAM roles (non-SLR)"),
        ("kms_customer_keys", "KMS Key (custom, schedule deletion)", " - No custom KMS keys"),
        ("kms_aliases", "KMS Alias", " - No KMS aliases"),
        ("ec2_instances", "EC2 Instance", " - No EC2 instances"),
        ("nat_gateways", "NAT Gateway", " - No NAT gateways"),
        ("eip_allocs", "EIP", " - No EIP allocations"),
        ("vpcs_non_default", "VPC (non-default)", " - No non-default VPCs"),
    ]

    keep_plan = [
        ("iam_users", "IAM User", " - No IAM users"),
        ("iam_service_linked", "IAM Service-Linked Role", " - No IAM Service-Linked Roles"),
    ]

    if not nuke_s3:
        keep_plan.append(("s3_buckets", "S3 Bucket", " - No S3 buckets"))
    else:
        delete_plan.append(("s3_buckets", "S3 Bucket", " - No S3 buckets"))

    # Plan printouts
    print()
    print("=== PLAN — WILL DELETE ===")
    pending_deletes = False
    for key, prefix, empty_label in delete_plan:
        pending_deletes |= snapshot.print_property(key, prefix, empty_label)

    print()
    print("=== PLAN — WILL KEEP (left intentionally) ===")
    for key, prefix, empty_label in keep_plan:
        snapshot.print_property(key, prefix, empty_label)

    print(" - AWS-managed IAM roles & policies (and service-linked roles) are kept")
    print(" - Default VPC & default security groups are kept")
    if not nuke_s3:
        print(" - All S3 buckets kept (use --nuke-s3 to delete)")

    if not pending_deletes:
        print()
        print("No resources found to delete.")
        return None

    return snapshot

def delete_clusters(aws: AwsEx, clusters: list[EKSClusterEx]) -> None:
    for cl in clusters:
        print(f" - EKS cluster {cl}")
        _teardown_cluster(aws, cl)

def delete_elbs(aws: AwsEx, elbv2_arns: list[str], elb_names: list[str]) -> None:
    for arn in elbv2_arns:
        print(f" - ELBv2 {arn}")
        tgs = aws.elbv2.list_target_group_arns(arn)
        aws.elbv2.delete_load_balancer(LoadBalancerArn=arn)
        for tg in tgs:
            aws.elbv2.delete_target_group(TargetGroupArn=tg)
    for name in elb_names:
        print(f" - Classic ELB {name}")
        aws.elb.delete_load_balancer(LoadBalancerName=name)

def delete_ecr(aws: AwsEx, repos: list[ECRRepoEx]) -> None:
    for repo in repos:
        print(f" - ECR repo {repo}")
        images = aws.ecr.list_images(repo)
        if images:
            print(f" -   - found {len(images)} images")
            for img in images:
                print(f" -   - image {img} (delete)")
            aws.ecr.batch_delete_images(repo, images)

            def _images_gone() -> bool:
                return not aws.ecr.list_images(repo)

            _wait(_images_gone, f"waiting for images in {repo} to delete...")
        aws.ecr.delete_repository(repo)

def delete_logs(aws: AwsEx, log_groups: list[str]) -> None:
    for lg in log_groups:
        print(f" - Log group {lg}")
        aws.logs.delete_log_group(logGroupName=lg)

def delete_iam_roles(aws: AwsEx, roles: list[str]) -> None:
    for rn in roles:
        print(f" - IAM role {rn} (detach + delete)")
        atts = [a["PolicyArn"] for a in aws.iam.list_attached_role_policies(RoleName=rn).get("AttachedPolicies", [])]
        for a in atts:
            aws.iam.detach_role_policy(RoleName=rn, PolicyArn=a)
        for pn in aws.iam.list_role_policies(RoleName=rn).get("PolicyNames", []):
            aws.iam.delete_role_policy(RoleName=rn, PolicyName=pn)
        profs = [p["InstanceProfileName"] for p in aws.iam.list_instance_profiles_for_role(RoleName=rn).get("InstanceProfiles", [])]
        for pr in profs:
            aws.iam.remove_role_from_instance_profile(InstanceProfileName=pr, RoleName=rn)
        for pr in profs:
            aws.iam.delete_instance_profile(InstanceProfileName=pr)
        aws.iam.delete_role(RoleName=rn)

def delete_iodc_providers(aws: AwsEx, oids: list[str]) -> None:
    for oidc in oids:
        print(f" - IAM OIDC {oidc}")
        aws.iam.delete_open_id_connect_provider(OpenIDConnectProviderArn=oidc)

def delete_policies(aws: AwsEx, policies: list[str]) -> None:
    for pol in policies:
        print(f" - IAM local policy {pol} (detach + delete)")
        ents = aws.iam.list_entities_for_policy(PolicyArn=pol)
        for rn in [r["RoleName"] for r in ents.get("PolicyRoles", [])]:
            aws.iam.detach_role_policy(RoleName=rn, PolicyArn=pol)
        for un in [u["UserName"] for u in ents.get("PolicyUsers", [])]:
            aws.iam.detach_user_policy(UserName=un, PolicyArn=pol)
        for gn in [g["GroupName"] for g in ents.get("PolicyGroups", [])]:
            aws.iam.detach_group_policy(GroupName=gn, PolicyArn=pol)
        versions = [v["VersionId"] for v in aws.iam.list_policy_versions(PolicyArn=pol).get("Versions", []) if not v.get("IsDefaultVersion")]
        for vid in versions:
            aws.iam.delete_policy_version(PolicyArn=pol, VersionId=vid)
        aws.iam.delete_policy(PolicyArn=pol)

def delete_instances(aws: AwsEx, instances: list[EC2InstanceEx]) -> None:
    for inst in instances:
        print(f" - EC2 terminate {inst}")
        aws.ec2.terminate_instance(inst)

def delete_nat_gateways(aws: AwsEx, nat_gws: list[str]) -> None:
    for nat in nat_gws:
        print(f" - NAT GW {nat} (delete)")
        aws.ec2.delete_nat_gateway(nat)

        def _nat_gw_deleted() -> bool:
            state = aws.ec2.get_nat_gateway_state(nat)
            return state is None or state == "deleted"

        _wait(_nat_gw_deleted, f"waiting for NAT {nat} to delete...")

def delete_eips(aws: AwsEx, eips: list[EC2ElasticIPEx]) -> None:
    for alloc in eips:
        print(f" - EIP {alloc} (release)")
        aws.ec2.release_elastic_ip(alloc)

def delete_vpcs(aws: AwsEx, vpc_ids: list[str]) -> None:
    for vpc_id in vpc_ids:
        print(f" - VPC {vpc_id} (delete)")
        aws.ec2.delete_vpc(VpcId=vpc_id)

def delete_iam_roles(aws: AwsEx, roles: list[str]) -> None:
    for rn in roles:
        print(f" - IAM role {rn} (detach + delete)")
        atts = [a["PolicyArn"] for a in aws.iam.list_attached_role_policies(RoleName=rn).get("AttachedPolicies", [])]
        for a in atts:
            aws.iam.detach_role_policy(RoleName=rn, PolicyArn=a)
        for pn in aws.iam.list_role_policies(RoleName=rn).get("PolicyNames", []):
            aws.iam.delete_role_policy(RoleName=rn, PolicyName=pn)
        profs = [p["InstanceProfileName"] for p in aws.iam.list_instance_profiles_for_role(RoleName=rn).get("InstanceProfiles", [])]
        for pr in profs:
            aws.iam.remove_role_from_instance_profile(InstanceProfileName=pr, RoleName=rn)
        for pr in profs:
            aws.iam.delete_instance_profile(InstanceProfileName=pr)
        aws.iam.delete_role(RoleName=rn)

def delete_kms_keys(aws: AwsEx, aliases: list[str], keys: list[KMSKeyEx]) -> None:
    for alias in aliases:
        print(f" - KMS alias {alias.alias_name} (delete)")
        aws.kms.delete_alias(alias)
    for key in keys:
        print(f" - KMS key schedule deletion {key.key_id}")
        aws.kms.schedule_key_deletion(key, 7)

def delete_all(aws: AwsEx, snapshot: AwsSnapshot) -> None:
    print()
    print(f"=== Deleting resources ===")

    # 1) EKS clusters: nodegroups → fargate → addons → cluster
    delete_clusters(aws, snapshot.eks_clusters)

    # 2) ELBv2 / Classic ELB
    delete_elbs(aws, snapshot.elbv2_arns, snapshot.elb_names)

    # 3) ECR
    delete_ecr(aws, snapshot.ecr_repos)

    # 4) CloudWatch logs
    delete_logs(aws, snapshot.log_groups)

    # 5) IAM OIDC (global)
    delete_iodc_providers(aws, snapshot.iam_oidc_arns)

    # 6) IAM local policies
    delete_policies(aws, snapshot.iam_local_policy_arns)

    # 7) IAM roles (non-SLR)
    delete_iam_roles(aws, snapshot.iam_non_slr)

    # 8) KMS custom keys → schedule deletion
    delete_kms_keys(aws, snapshot.kms_aliases, snapshot.kms_customer_keys)

    # 9) Instances → NAT → EIPs (release)
    delete_instances(aws, snapshot.ec2_instances)

    delete_nat_gateways(aws, snapshot.nat_gateways)

    delete_eips(aws, snapshot.eip_allocs)

    # 10) Non-default VPCs (deep clean)
    delete_vpcs(aws, snapshot.vpcs_non_default)


def report_leftovers(aws: AwsEx, nuke_s3: bool) -> None:
    print()
    print("=== Post-run scan (leftovers summary) ===")
    print(f"EKS clusters:      {len(aws.eks.list_clusters())}")
    print(f"ELBv2 LBs:         {len(aws.elbv2.list_load_balancer_arns())}")
    print(f"Classic ELBs:      {len(aws.elb.list_load_balancer_names())}")
    print(f"ECR repos:         {len(aws.ecr.list_repositories())}")
    print(f"CW Log groups:     {len(aws.logs.list_log_group_names())}")
    print(f"Non-default VPCs:  {len(aws.ec2.list_non_default_vpc_ids())}")
    print(f"IAM OIDC prov:     {len(aws.iam.list_oidc_provider_arns())}")
    print(f"IAM roles (total): {len(aws.iam.list_role_names())}")
    print(f"IAM users (kept):  {len(aws.iam.list_user_names())}")
    print(f"KMS keys (custom, not pending deletion): {len(aws.kms.list_customer_keys())}")
    if nuke_s3:
        print(f"S3 buckets:        {len(aws.s3.list_bucket_names())}")
    else:
        print("S3 buckets:        (skipped; --nuke-s3 not set)")
    print("If something remains due to dependency timing, re-run this script.")

def _wait(predicate, message: str) -> None:
    start = int(time.time())
    while True:
        if predicate():
            return
        print(f" -   - {message} [{int(time.time()) - start}s elapsed]")
        if int(time.time()) - start >= TIMEOUT_SECONDS:
            print(f"Timeout after {TIMEOUT_SECONDS}s; continuing.")
            return
        time.sleep(15)


def _teardown_cluster(aws: AwsEx, cluster: EKSClusterEx) -> None:
    nodegroups = aws.eks.list_nodegroups(cluster)
    print (f" -   - found {len(nodegroups)} nodegroups")
    for ng in nodegroups:
        print(f" -   - nodegroup {ng} (delete)")
        aws.eks.delete_nodegroup(cluster, ng)

    def _ngs_gone() -> bool:
        return len(aws.eks.list_nodegroups(cluster)) == 0

    _wait(_ngs_gone, f"waiting for nodegroups to disappear from {cluster}...")

    fprofiles = aws.eks.list_fargate_profile_names(cluster)
    for fp in fprofiles:
        print(f" -   - fargate profile {fp} (delete)")
        aws.eks.delete_fargate_profile(cluster, fp)

    for ad in aws.eks.list_addons(cluster):
        print(f" -   - addon {ad} (delete)")
        aws.eks.delete_addon(cluster, ad)

    print(f" -   - cluster {cluster} (delete)")
    aws.eks.delete_cluster(cluster)

    def _cluster_gone() -> bool:
        return not any(filter(lambda c: c.cluster_name == cluster.cluster_name, aws.eks.list_clusters()))

    _wait(_cluster_gone, f"waiting for cluster {cluster} to be deleted...")


def _teardown_vpc_resources(aws: AwsEx, vpc_id: str) -> None:
    # Endpoints first
    eps = aws.ec2.list_vpc_endpoint_ids(vpc_id)
    for ep in eps:
        aws.ec2.delete_vpc_endpoints(VpcEndpointIds=[ep])

    # IGWs
    igws = aws.ec2.list_internet_gateway_ids_for_vpc(vpc_id)
    for igw in igws:
        aws.ec2.detach_internet_gateway(InternetGatewayId=igw, VpcId=vpc_id)
        aws.ec2.delete_internet_gateway(InternetGatewayId=igw)

    # Route tables will be processed after subnets are removed (to avoid associations)

    # First pass ENIs (available only)
    enis = aws.ec2.list_available_eni_ids_for_vpc(vpc_id)
    for eni in enis:
        aws.ec2.delete_network_interface(NetworkInterfaceId=eni)

    # NACLs (non-default) – defer until after subnets to avoid association issues

    # Security groups (skip default)
    sgs = aws.ec2.list_security_group_ids_for_vpc(vpc_id, exclude_default=True)
    for sg in sgs:
        aws.ec2.revoke_all_sg_rules(sg)
    for sg in sgs:
        aws.ec2.delete_security_group(GroupId=sg)

    # Subnets
    subs = aws.ec2.list_subnet_ids_for_vpc(vpc_id)
    for s in subs:
        aws.ec2.delete_subnet(SubnetId=s)

    # Route tables: remove non-local routes; delete only non-main RTs (after subnets are gone)
    route_tables = aws.ec2.list_route_tables_for_vpc(vpc_id)
    for rt in route_tables:
        # Delete non-local routes first
        for r in rt.routes:
            if r.origin == "CreateRouteTable" or r.gateway_id == "local":
                continue
            aws.ec2.delete_route(rt, r)

        # Disassociate non-main associations (should be none after subnet deletion, but safe)
        is_main = any(a.is_main for a in rt.associations)
        for a in rt.associations:
            if not a.is_main and a.route_table_association_id:
                aws.ec2.disassociate_route_table(a)
        if not is_main:
            aws.ec2.delete_route_table(rt)

    # NACLs (non-default) – delete after subnets
    nacls = aws.ec2.list_non_default_network_acl_ids(vpc_id)
    for n in nacls:
        aws.ec2.delete_network_acl(NetworkAclId=n)

    # Second pass ENIs
    enis = aws.ec2.list_available_eni_ids_for_vpc(vpc_id)
    for eni in enis:
        aws.ec2.delete_network_interface(NetworkInterfaceId=eni)

    # VPC
    aws.ec2.delete_vpc(VpcId=vpc_id)



def _delete_s3_buckets(aws: AwsEx, snapshot: AwsSnapshot) -> None:
    # 11) S3 (global)
    print("=== Deleting ALL S3 buckets (GLOBAL) ===")
    for b in snapshot.s3_buckets:
        print(f" - S3 bucket {b}")
        aws.s3.delete_bucket_force(b)


def main() -> int:
    cfg = load_config_from_env_and_args()

    TIMEOUT_SECONDS = cfg.wait_timeout_seconds

    aws = AwsEx(cfg.profile, cfg.region)

    try:
        aws_identity = aws.sts.get_caller_identity()
    except NoCredentialsError as e:
        print("ERROR: AWS credentials not configured. Set AWS_PROFILE or credentials.")
        return 1

    print("=== Confirm identity / region ===")
    print({"account": aws_identity.account, "arn": aws_identity.arn})
    print(f"Region: {cfg.region}  Profile: {cfg.profile}")

    if cfg.dry_run:
        print("THIS IS A DRY RUN. NO RESOURCES WILL BE DELETED.")
    else:
        print(f"THIS WILL DELETE MANY RESOURCES!")

    plan = discover(aws, cfg.nuke_s3)
    if not plan:
        return 0

    if cfg.dry_run:
        print("DRY RUN complete — no changes made.")
        return 0

    if not cfg.assume_yes:
        if not confirm():
            return 1

    delete_all(aws, plan)
    if cfg.nuke_s3:
        _delete_s3_buckets(aws, plan)
    report_leftovers(aws, cfg.nuke_s3)

    print()
    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
