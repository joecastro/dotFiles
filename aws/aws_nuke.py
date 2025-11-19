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
from typing import Any, Callable, Optional, TYPE_CHECKING, cast

import boto3
from boto3.session import Session
from botocore.exceptions import ClientError, NoCredentialsError

if TYPE_CHECKING:
    from mypy_boto3_ec2 import EC2Client
    from mypy_boto3_eks import EKSClient
    from mypy_boto3_elb import ElasticLoadBalancingClient
    from mypy_boto3_elbv2 import ElasticLoadBalancingv2Client
    from mypy_boto3_ecr import ECRClient
    from mypy_boto3_ecr.type_defs import ImageIdentifierTypeDef
    from mypy_boto3_iam import IAMClient
    from mypy_boto3_kms import KMSClient
    from mypy_boto3_logs import CloudWatchLogsClient
    from mypy_boto3_s3 import S3Client
    from mypy_boto3_sts import STSClient
else:  # pragma: no cover - typing only
    EC2Client = Any  # type: ignore[assignment]
    EKSClient = Any  # type: ignore[assignment]
    ElasticLoadBalancingClient = Any  # type: ignore[assignment]
    ElasticLoadBalancingv2Client = Any  # type: ignore[assignment]
    ECRClient = Any  # type: ignore[assignment]
    ImageIdentifierTypeDef = dict[str, str]  # type: ignore[assignment]
    IAMClient = Any  # type: ignore[assignment]
    KMSClient = Any  # type: ignore[assignment]
    CloudWatchLogsClient = Any  # type: ignore[assignment]
    S3Client = Any  # type: ignore[assignment]
    STSClient = Any  # type: ignore[assignment]

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


@dataclass
class AwsSnapshot:
    eks_clusters: list[str] = field(default_factory=list)
    elbv2_arns: list[str] = field(default_factory=list)
    elb_names: list[str] = field(default_factory=list)
    ecr_repos: list[str] = field(default_factory=list)
    log_groups: list[str] = field(default_factory=list)
    ec2_instances: list[str] = field(default_factory=list)
    nat_gateways: list[str] = field(default_factory=list)
    eip_allocs: list[str] = field(default_factory=list)
    vpcs_non_default: list[str] = field(default_factory=list)
    # Global
    iam_oidc_arns: list[str] = field(default_factory=list)
    iam_local_policy_arns: list[str] = field(default_factory=list)
    iam_roles: list[str] = field(default_factory=list)
    iam_users: list[str] = field(default_factory=list)
    # KMS and S3
    kms_customer_keys: list[str] = field(default_factory=list)
    kms_aliases: list[str] = field(default_factory=list)
    s3_buckets: list[str] = field(default_factory=list)

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


@dataclass
class AwsClients:
    profile: str
    region: str
    session: Session
    ec2: EC2Client
    eks: EKSClient
    elbv2: ElasticLoadBalancingv2Client
    elb: ElasticLoadBalancingClient
    ecr: ECRClient
    logs: CloudWatchLogsClient
    iam: IAMClient
    s3: S3Client
    kms: KMSClient
    sts: STSClient

    @classmethod
    def create(cls, profile: str, region: str) -> "AwsClients":
        session = boto3.Session(profile_name=profile, region_name=region)
        return cls(
            profile=profile,
            region=region,
            session=session,
            ec2=session.client("ec2", region_name=region),
            eks=session.client("eks", region_name=region),
            elbv2=session.client("elbv2", region_name=region),
            elb=session.client("elb", region_name=region),
            ecr=session.client("ecr", region_name=region),
            logs=session.client("logs", region_name=region),
            iam=session.client("iam"),
            s3=session.client("s3"),
            kms=session.client("kms", region_name=region),
            sts=session.client("sts", region_name=region),
        )


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


def _list_with_next_token(
    call: Callable[..., Any],
    result_key: str,
    token_arg: str = "NextToken",
    token_key: str = "NextToken",
    **base_kwargs: Any,
) -> list[Any]:
    items: list[Any] = []
    next_token: Optional[str] = None
    try:
        while True:
            kwargs = dict(base_kwargs)
            if next_token is not None:
                kwargs[token_arg] = next_token
            resp: Any = call(**kwargs)
            items.extend(cast(list[Any], resp.get(result_key, [])))
            next_token_value = resp.get(token_key)
            next_token = cast(Optional[str], next_token_value) if next_token_value else None
            if not next_token:
                break
    except ClientError:
        return []
    return items


def list_eks_clusters(eks: EKSClient) -> list[str]:
    try:
        names: list[str] = []
        for item in _list_with_next_token(
            eks.list_clusters,
            "clusters",
            token_arg="nextToken",
            token_key="nextToken",
        ):
            if isinstance(item, str):
                names.append(item)
        return names
    except ClientError:
        return []


def list_eks_nodegroups(eks: EKSClient, cluster_name: str) -> list[str]:
    try:
        nodegroups: list[str] = []
        for item in _list_with_next_token(
            eks.list_nodegroups,
            "nodegroups",
            token_arg="nextToken",
            token_key="nextToken",
            clusterName=cluster_name,
        ):
            if isinstance(item, str):
                nodegroups.append(item)
        return nodegroups
    except ClientError:
        return []


def list_eks_fargate_profiles(eks: EKSClient, cluster_name: str) -> list[str]:
    try:
        profiles: list[str] = []
        for item in _list_with_next_token(
            eks.list_fargate_profiles,
            "fargateProfileNames",
            token_arg="nextToken",
            token_key="nextToken",
            clusterName=cluster_name,
        ):
            if isinstance(item, str):
                profiles.append(item)
        return profiles
    except ClientError:
        return []


def list_eks_addons(eks: EKSClient, cluster_name: str) -> list[str]:
    try:
        addons: list[str] = []
        for item in _list_with_next_token(
            eks.list_addons,
            "addons",
            token_arg="nextToken",
            token_key="nextToken",
            clusterName=cluster_name,
        ):
            if isinstance(item, str):
                addons.append(item)
        return addons
    except ClientError:
        return []


def list_elbv2_load_balancer_arns(elbv2: ElasticLoadBalancingv2Client) -> list[str]:
    arns: list[str] = []
    for lb in _list_with_next_token(
        elbv2.describe_load_balancers,
        "LoadBalancers",
        token_arg="Marker",
        token_key="NextMarker",
    ):
        arn = lb.get("LoadBalancerArn") if isinstance(lb, dict) else None
        if isinstance(arn, str):
            arns.append(arn)
    return arns


def list_elbv2_target_group_arns(elbv2: ElasticLoadBalancingv2Client, lb_arn: str) -> list[str]:
    target_arns: list[str] = []
    for tg in _list_with_next_token(
        elbv2.describe_target_groups,
        "TargetGroups",
        token_arg="Marker",
        token_key="NextMarker",
        LoadBalancerArn=lb_arn,
    ):
        arn = tg.get("TargetGroupArn") if isinstance(tg, dict) else None
        if isinstance(arn, str):
            target_arns.append(arn)
    return target_arns


def list_elb_names(elb: ElasticLoadBalancingClient) -> list[str]:
    names: list[str] = []
    for lb in _list_with_next_token(
        elb.describe_load_balancers,
        "LoadBalancerDescriptions",
        token_arg="Marker",
        token_key="NextMarker",
    ):
        name = lb.get("LoadBalancerName") if isinstance(lb, dict) else None
        if isinstance(name, str):
            names.append(name)
    return names


def list_ecr_repositories(ecr: ECRClient) -> list[str]:
    repo_names: list[str] = []
    for repo in _list_with_next_token(
        ecr.describe_repositories,
        "repositories",
        token_arg="nextToken",
        token_key="nextToken",
    ):
        name = repo.get("repositoryName") if isinstance(repo, dict) else None
        if isinstance(name, str):
            repo_names.append(name)
    return repo_names


def list_ecr_image_ids(ecr: ECRClient, repository: str) -> list[ImageIdentifierTypeDef]:
    identifiers: list[ImageIdentifierTypeDef] = []
    for image in _list_with_next_token(
        ecr.list_images,
        "imageIds",
        token_arg="nextToken",
        token_key="nextToken",
        repositoryName=repository,
    ):
        if not isinstance(image, dict):
            continue
        entry: ImageIdentifierTypeDef = {}
        digest = image.get("imageDigest")
        tag = image.get("imageTag")
        if isinstance(digest, str):
            entry["imageDigest"] = digest
        if isinstance(tag, str):
            entry["imageTag"] = tag
        if entry:
            identifiers.append(entry)
    return identifiers


def list_log_group_names(logs: CloudWatchLogsClient) -> list[str]:
    log_names: list[str] = []
    for group in _list_with_next_token(
        logs.describe_log_groups,
        "logGroups",
        token_arg="nextToken",
        token_key="nextToken",
    ):
        name = group.get("logGroupName") if isinstance(group, dict) else None
        if isinstance(name, str):
            log_names.append(name)
    return log_names


def list_ec2_instances(ec2: EC2Client) -> list[str]:
    filters = [{"Name": "instance-state-name", "Values": ["pending", "running", "stopping", "stopped"]}]
    instances: list[str] = []
    next_token: Optional[str] = None
    try:
        while True:
            kwargs: dict[str, Any] = {"Filters": filters}
            if next_token:
                kwargs["NextToken"] = next_token
            resp = ec2.describe_instances(**kwargs)
            for reservation in resp.get("Reservations", []) or []:
                for inst in reservation.get("Instances", []) or []:
                    iid = inst.get("InstanceId")
                    if isinstance(iid, str):
                        instances.append(iid)
            next_token_value = resp.get("NextToken")
            next_token = cast(Optional[str], next_token_value) if next_token_value else None
            if not next_token:
                break
    except ClientError:
        return []
    return instances


def list_nat_gateway_ids(ec2: EC2Client) -> list[str]:
    gateways: list[str] = []
    next_token: Optional[str] = None
    try:
        while True:
            kwargs: dict[str, Any] = {}
            if next_token:
                kwargs["NextToken"] = next_token
            resp = ec2.describe_nat_gateways(**kwargs)
            for gateway in resp.get("NatGateways", []) or []:
                gid = gateway.get("NatGatewayId")
                if isinstance(gid, str):
                    gateways.append(gid)
            next_token_value = resp.get("NextToken")
            next_token = cast(Optional[str], next_token_value) if next_token_value else None
            if not next_token:
                break
    except ClientError:
        return []
    return gateways


def get_nat_gateway_state(ec2: EC2Client, nat_gateway_id: str) -> Optional[str]:
    try:
        resp = ec2.describe_nat_gateways(NatGatewayIds=[nat_gateway_id])
    except ClientError:
        return None
    gateways = resp.get("NatGateways", [])
    if not gateways:
        return None
    state = gateways[0].get("State")
    return state if isinstance(state, str) else None


def list_eip_allocation_ids(ec2: EC2Client) -> list[str]:
    allocations: list[str] = []
    next_token: Optional[str] = None
    try:
        while True:
            kwargs: dict[str, Any] = {}
            if next_token:
                kwargs["NextToken"] = next_token
            resp = ec2.describe_addresses(**kwargs)
            for address in resp.get("Addresses", []) or []:
                alloc = address.get("AllocationId")
                if isinstance(alloc, str):
                    allocations.append(alloc)
            next_token_value = resp.get("NextToken")
            next_token = cast(Optional[str], next_token_value) if next_token_value else None
            if not next_token:
                break
    except ClientError:
        return []
    return allocations


def list_non_default_vpc_ids(ec2: EC2Client) -> list[str]:
    try:
        resp = ec2.describe_vpcs(Filters=[{"Name": "isDefault", "Values": ["false"]}])
    except ClientError:
        return []
    vpcs: list[str] = []
    for vpc in resp.get("Vpcs", []) or []:
        vpc_id = vpc.get("VpcId")
        if isinstance(vpc_id, str):
            vpcs.append(vpc_id)
    return vpcs


def list_vpc_endpoint_ids(ec2: EC2Client, vpc_id: str) -> list[str]:
    endpoints: list[str] = []
    next_token: Optional[str] = None
    try:
        while True:
            kwargs: dict[str, Any] = {"Filters": [{"Name": "vpc-id", "Values": [vpc_id]}]}
            if next_token:
                kwargs["NextToken"] = next_token
            resp = ec2.describe_vpc_endpoints(**kwargs)
            for endpoint in resp.get("VpcEndpoints", []) or []:
                eid = endpoint.get("VpcEndpointId")
                if isinstance(eid, str):
                    endpoints.append(eid)
            next_token_value = resp.get("NextToken")
            next_token = cast(Optional[str], next_token_value) if next_token_value else None
            if not next_token:
                break
    except ClientError:
        return []
    return endpoints


def list_internet_gateway_ids_for_vpc(ec2: EC2Client, vpc_id: str) -> list[str]:
    try:
        resp = ec2.describe_internet_gateways(Filters=[{"Name": "attachment.vpc-id", "Values": [vpc_id]}])
    except ClientError:
        return []
    igw_ids: list[str] = []
    for igw in resp.get("InternetGateways", []) or []:
        igw_id = igw.get("InternetGatewayId")
        if isinstance(igw_id, str):
            igw_ids.append(igw_id)
    return igw_ids


def list_available_eni_ids_for_vpc(ec2: EC2Client, vpc_id: str) -> list[str]:
    try:
        resp = ec2.describe_network_interfaces(
            Filters=[
                {"Name": "vpc-id", "Values": [vpc_id]},
                {"Name": "status", "Values": ["available"]},
            ]
        )
    except ClientError:
        return []
    eni_ids: list[str] = []
    for eni in resp.get("NetworkInterfaces", []) or []:
        eni_id = eni.get("NetworkInterfaceId")
        if isinstance(eni_id, str):
            eni_ids.append(eni_id)
    return eni_ids


def list_security_group_ids_for_vpc(ec2: EC2Client, vpc_id: str, exclude_default: bool = True) -> list[str]:
    try:
        resp = ec2.describe_security_groups(Filters=[{"Name": "vpc-id", "Values": [vpc_id]}])
    except ClientError:
        return []
    groups = resp.get("SecurityGroups", []) or []
    if exclude_default:
        groups = [g for g in groups if g.get("GroupName") != "default"]
    sg_ids: list[str] = []
    for group in groups:
        gid = group.get("GroupId")
        if isinstance(gid, str):
            sg_ids.append(gid)
    return sg_ids


def describe_security_group(ec2: EC2Client, group_id: str) -> dict[str, Any]:
    try:
        resp = ec2.describe_security_groups(GroupIds=[group_id])
    except ClientError:
        return {}
    groups = cast(list[dict[str, Any]], resp.get("SecurityGroups", []) or [])
    return groups[0] if groups else {}


def list_subnet_ids_for_vpc(ec2: EC2Client, vpc_id: str) -> list[str]:
    try:
        resp = ec2.describe_subnets(Filters=[{"Name": "vpc-id", "Values": [vpc_id]}])
    except ClientError:
        return []
    subnet_ids: list[str] = []
    for subnet in resp.get("Subnets", []) or []:
        sid = subnet.get("SubnetId")
        if isinstance(sid, str):
            subnet_ids.append(sid)
    return subnet_ids


def list_route_tables_for_vpc(ec2: EC2Client, vpc_id: str) -> list[dict[str, Any]]:
    try:
        resp = ec2.describe_route_tables(Filters=[{"Name": "vpc-id", "Values": [vpc_id]}])
    except ClientError:
        return []
    return cast(list[dict[str, Any]], resp.get("RouteTables", []) or [])


def list_non_default_network_acl_ids(ec2: EC2Client, vpc_id: str) -> list[str]:
    try:
        resp = ec2.describe_network_acls(Filters=[{"Name": "vpc-id", "Values": [vpc_id]}])
    except ClientError:
        return []
    nacl_ids: list[str] = []
    for nacl in resp.get("NetworkAcls", []) or []:
        if nacl.get("IsDefault"):
            continue
        nacl_id = nacl.get("NetworkAclId")
        if isinstance(nacl_id, str):
            nacl_ids.append(nacl_id)
    return nacl_ids


def list_oidc_provider_arns(iam: IAMClient) -> list[str]:
    try:
        resp = iam.list_open_id_connect_providers()
    except ClientError:
        return []
    arns: list[str] = []
    for provider in resp.get("OpenIDConnectProviderList", []) or []:
        arn = provider.get("Arn")
        if isinstance(arn, str):
            arns.append(arn)
    return arns


def list_local_policy_arns(iam: IAMClient) -> list[str]:
    arns: list[str] = []
    marker: Optional[str] = None
    try:
        while True:
            kwargs: dict[str, Any] = {"Scope": "Local"}
            if marker:
                kwargs["Marker"] = marker
            resp = iam.list_policies(**kwargs)
            for policy in resp.get("Policies", []) or []:
                arn = policy.get("Arn")
                if isinstance(arn, str):
                    arns.append(arn)
            if resp.get("IsTruncated"):
                next_marker_val = resp.get("Marker") or resp.get("NextMarker")
                marker = cast(Optional[str], next_marker_val) if next_marker_val else None
                if marker is None:
                    break
            else:
                break
    except ClientError:
        return []
    return arns


def list_role_names(iam: IAMClient) -> list[str]:
    names: list[str] = []
    marker: Optional[str] = None
    try:
        while True:
            kwargs: dict[str, Any] = {}
            if marker:
                kwargs["Marker"] = marker
            resp = iam.list_roles(**kwargs)
            for role in resp.get("Roles", []) or []:
                role_name = role.get("RoleName")
                if isinstance(role_name, str):
                    names.append(role_name)
            if resp.get("IsTruncated"):
                next_marker_val = resp.get("Marker") or resp.get("NextMarker")
                marker = cast(Optional[str], next_marker_val) if next_marker_val else None
                if marker is None:
                    break
            else:
                break
    except ClientError:
        return []
    return names


def list_user_names(iam: IAMClient) -> list[str]:
    names: list[str] = []
    marker: Optional[str] = None
    try:
        while True:
            kwargs: dict[str, Any] = {}
            if marker:
                kwargs["Marker"] = marker
            resp = iam.list_users(**kwargs)
            for user in resp.get("Users", []) or []:
                username = user.get("UserName")
                if isinstance(username, str):
                    names.append(username)
            if resp.get("IsTruncated"):
                next_marker_val = resp.get("Marker") or resp.get("NextMarker")
                marker = cast(Optional[str], next_marker_val) if next_marker_val else None
                if marker is None:
                    break
            else:
                break
    except ClientError:
        return []
    return names


def list_policy_entities(iam: IAMClient, policy_arn: str) -> dict[str, Any]:
    try:
        resp = iam.list_entities_for_policy(PolicyArn=policy_arn)
        return cast(dict[str, Any], resp)
    except ClientError:
        return {}


def list_policy_versions(iam: IAMClient, policy_arn: str) -> list[dict[str, Any]]:
    try:
        resp = iam.list_policy_versions(PolicyArn=policy_arn)
    except ClientError:
        return []
    return cast(list[dict[str, Any]], resp.get("Versions", []) or [])


def list_attached_role_policies(iam: IAMClient, role_name: str) -> list[dict[str, Any]]:
    try:
        resp = iam.list_attached_role_policies(RoleName=role_name)
    except ClientError:
        return []
    return cast(list[dict[str, Any]], resp.get("AttachedPolicies", []) or [])


def list_role_policies(iam: IAMClient, role_name: str) -> list[str]:
    try:
        resp = iam.list_role_policies(RoleName=role_name)
    except ClientError:
        return []
    names = resp.get("PolicyNames", []) or []
    return [name for name in names if isinstance(name, str)]


def list_instance_profiles_for_role(iam: IAMClient, role_name: str) -> list[dict[str, Any]]:
    try:
        resp = iam.list_instance_profiles_for_role(RoleName=role_name)
    except ClientError:
        return []
    return cast(list[dict[str, Any]], resp.get("InstanceProfiles", []) or [])


def list_kms_customer_keys(kms: KMSClient) -> list[str]:
    keys: list[str] = []
    marker: Optional[str] = None
    try:
        while True:
            kwargs: dict[str, Any] = {}
            if marker:
                kwargs["Marker"] = marker
            resp = kms.list_keys(**kwargs)
            for entry in resp.get("Keys", []) or []:
                key_id = entry.get("KeyId")
                if not isinstance(key_id, str):
                    continue
                try:
                    meta = kms.describe_key(KeyId=key_id).get("KeyMetadata", {})
                except ClientError:
                    continue
                if meta.get("KeyManager") != "CUSTOMER" or meta.get("KeyState") == "PendingDeletion":
                    continue
                keys.append(key_id)
            if resp.get("Truncated"):
                marker_val = resp.get("NextMarker")
                marker = cast(Optional[str], marker_val) if marker_val else None
                if marker is None:
                    break
            else:
                break
    except ClientError:
        return []
    return keys


def list_kms_alias_names(kms: KMSClient, customer_only: bool = True) -> list[str]:
    aliases: list[str] = []
    marker: Optional[str] = None
    try:
        while True:
            kwargs: dict[str, Any] = {}
            if marker:
                kwargs["Marker"] = marker
            resp = kms.list_aliases(**kwargs)
            for alias in resp.get("Aliases", []) or []:
                name = alias.get("AliasName")
                if not isinstance(name, str):
                    continue
                if customer_only and name.startswith("alias/aws/"):
                    continue
                aliases.append(name)
            if resp.get("Truncated"):
                marker_val = resp.get("NextMarker")
                marker = cast(Optional[str], marker_val) if marker_val else None
                if marker is None:
                    break
            else:
                break
    except ClientError:
        return []
    return aliases


def list_s3_bucket_names(s3: S3Client) -> list[str]:
    try:
        resp = s3.list_buckets()
    except ClientError:
        return []
    names: list[str] = []
    for bucket in resp.get("Buckets", []) or []:
        name = bucket.get("Name")
        if isinstance(name, str):
            names.append(name)
    return names


def revoke_all_sg_rules(ec2: EC2Client, sg_id: str) -> None:
    sg = describe_security_group(ec2, sg_id)
    if not sg:
        return
    for perm in sg.get("IpPermissionsEgress", []) or []:
        try:
            ec2.revoke_security_group_egress(GroupId=sg_id, IpPermissions=[perm])
        except ClientError:
            pass
    for perm in sg.get("IpPermissions", []) or []:
        try:
            ec2.revoke_security_group_ingress(GroupId=sg_id, IpPermissions=[perm])
        except ClientError:
            pass


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


def discover(clients: AwsClients, nuke_s3: bool) -> Optional[AwsSnapshot]:
    print()
    print("=== Discovery (building plan) ===")
    snapshot = AwsSnapshot()
    # Region-scoped
    snapshot.eks_clusters = list_eks_clusters(clients.eks)
    snapshot.elbv2_arns = list_elbv2_load_balancer_arns(clients.elbv2)
    snapshot.elb_names = list_elb_names(clients.elb)
    snapshot.ecr_repos = list_ecr_repositories(clients.ecr)
    snapshot.log_groups = list_log_group_names(clients.logs)
    snapshot.ec2_instances = list_ec2_instances(clients.ec2)
    snapshot.nat_gateways = list_nat_gateway_ids(clients.ec2)
    snapshot.eip_allocs = list_eip_allocation_ids(clients.ec2)
    snapshot.vpcs_non_default = list_non_default_vpc_ids(clients.ec2)
    # Global
    snapshot.iam_oidc_arns = list_oidc_provider_arns(clients.iam)
    snapshot.iam_local_policy_arns = list_local_policy_arns(clients.iam)
    snapshot.iam_roles = list_role_names(clients.iam)
    snapshot.iam_users = list_user_names(clients.iam)
    # KMS and S3
    snapshot.kms_customer_keys = list_kms_customer_keys(clients.kms)
    snapshot.kms_aliases = list_kms_alias_names(clients.kms, customer_only=True)
    snapshot.s3_buckets = list_s3_bucket_names(clients.s3)

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


def delete_clusters(clients: AwsClients, clusters: list[str]) -> None:
    for cluster_name in clusters:
        print(f" - EKS cluster {cluster_name}")
        _teardown_cluster(clients, cluster_name)


def delete_elbs(clients: AwsClients, elbv2_arns: list[str], elb_names: list[str]) -> None:
    for arn in elbv2_arns:
        print(f" - ELBv2 {arn}")
        target_groups = list_elbv2_target_group_arns(clients.elbv2, arn)
        try:
            clients.elbv2.delete_load_balancer(LoadBalancerArn=arn)
        except ClientError as exc:
            print(f" -   ! Failed to delete load balancer {arn}: {exc}")
        for target_arn in target_groups:
            try:
                clients.elbv2.delete_target_group(TargetGroupArn=target_arn)
            except ClientError as exc:
                print(f" -   ! Failed to delete target group {target_arn}: {exc}")
    for name in elb_names:
        print(f" - Classic ELB {name}")
        try:
            clients.elb.delete_load_balancer(LoadBalancerName=name)
        except ClientError as exc:
            print(f" -   ! Failed to delete Classic ELB {name}: {exc}")


def delete_ecr(clients: AwsClients, repos: list[str]) -> None:
    for repo in repos:
        print(f" - ECR repo {repo}")
        images = list_ecr_image_ids(clients.ecr, repo)
        if images:
            print(f" -   - found {len(images)} images")
            for image in images:
                label = image.get("imageTag") or image.get("imageDigest") or "<unknown>"
                print(f" -   - image {label} (delete)")
            try:
                clients.ecr.batch_delete_image(repositoryName=repo, imageIds=images)
            except ClientError as exc:
                print(f" -   ! Failed to delete images in {repo}: {exc}")

            def _images_gone() -> bool:
                return not list_ecr_image_ids(clients.ecr, repo)

            _wait(_images_gone, f"waiting for images in {repo} to delete...")
        try:
            clients.ecr.delete_repository(repositoryName=repo, force=True)
        except ClientError as exc:
            print(f" -   ! Failed to delete repository {repo}: {exc}")


def delete_logs(clients: AwsClients, log_groups: list[str]) -> None:
    for log_group in log_groups:
        print(f" - Log group {log_group}")
        try:
            clients.logs.delete_log_group(logGroupName=log_group)
        except ClientError as exc:
            print(f" -   ! Failed to delete log group {log_group}: {exc}")


def delete_iodc_providers(clients: AwsClients, oids: list[str]) -> None:
    for oidc in oids:
        print(f" - IAM OIDC {oidc}")
        try:
            clients.iam.delete_open_id_connect_provider(OpenIDConnectProviderArn=oidc)
        except ClientError as exc:
            print(f" -   ! Failed to delete OIDC provider {oidc}: {exc}")


def delete_policies(clients: AwsClients, policies: list[str]) -> None:
    for policy in policies:
        print(f" - IAM local policy {policy} (detach + delete)")
        entities = list_policy_entities(clients.iam, policy)
        for role_item in entities.get("PolicyRoles", []) or []:
            role = role_item.get("RoleName")
            if isinstance(role, str):
                try:
                    clients.iam.detach_role_policy(RoleName=role, PolicyArn=policy)
                except ClientError:
                    pass
        for user_item in entities.get("PolicyUsers", []) or []:
            user = user_item.get("UserName")
            if isinstance(user, str):
                try:
                    clients.iam.detach_user_policy(UserName=user, PolicyArn=policy)
                except ClientError:
                    pass
        for group_item in entities.get("PolicyGroups", []) or []:
            group = group_item.get("GroupName")
            if isinstance(group, str):
                try:
                    clients.iam.detach_group_policy(GroupName=group, PolicyArn=policy)
                except ClientError:
                    pass
        versions: list[str] = []
        for version_info in list_policy_versions(clients.iam, policy):
            if version_info.get("IsDefaultVersion"):
                continue
            version_id = version_info.get("VersionId")
            if isinstance(version_id, str):
                versions.append(version_id)
        for version in versions:
            try:
                clients.iam.delete_policy_version(PolicyArn=policy, VersionId=version)
            except ClientError:
                pass
        try:
            clients.iam.delete_policy(PolicyArn=policy)
        except ClientError as exc:
            print(f" -   ! Failed to delete IAM policy {policy}: {exc}")


def delete_instances(clients: AwsClients, instances: list[str]) -> None:
    for instance_id in instances:
        print(f" - EC2 terminate {instance_id}")
        try:
            clients.ec2.terminate_instances(InstanceIds=[instance_id])
        except ClientError as exc:
            print(f" -   ! Failed to terminate instance {instance_id}: {exc}")


def delete_nat_gateways(clients: AwsClients, nat_gws: list[str]) -> None:
    for nat in nat_gws:
        print(f" - NAT GW {nat} (delete)")
        try:
            clients.ec2.delete_nat_gateway(NatGatewayId=nat)
        except ClientError as exc:
            print(f" -   ! Failed to delete NAT gateway {nat}: {exc}")
            continue

        def _nat_gw_deleted() -> bool:
            state = get_nat_gateway_state(clients.ec2, nat)
            return state is None or state == "deleted"

        _wait(_nat_gw_deleted, f"waiting for NAT {nat} to delete...")


def delete_eips(clients: AwsClients, eips: list[str]) -> None:
    for eip in eips:
        print(f" - EIP {eip} (release)")
        try:
            clients.ec2.release_address(AllocationId=eip)
        except ClientError as exc:
            print(f" -   ! Failed to release Elastic IP {eip}: {exc}")


def delete_vpcs(clients: AwsClients, vpc_ids: list[str]) -> None:
    for vpc_id in vpc_ids:
        print(f" - VPC {vpc_id} (delete)")
        try:
            clients.ec2.delete_vpc(VpcId=vpc_id)
        except ClientError as exc:
            print(f" -   ! Failed to delete VPC {vpc_id}: {exc}")


def delete_iam_roles(clients: AwsClients, roles: list[str]) -> None:
    for role_name in roles:
        print(f" - IAM role {role_name} (detach + delete)")
        for policy_item in list_attached_role_policies(clients.iam, role_name):
            policy = policy_item.get("PolicyArn")
            if isinstance(policy, str):
                try:
                    clients.iam.detach_role_policy(RoleName=role_name, PolicyArn=policy)
                except ClientError:
                    pass
        for policy_name in list_role_policies(clients.iam, role_name):
            try:
                clients.iam.delete_role_policy(RoleName=role_name, PolicyName=policy_name)
            except ClientError:
                pass
        profile_names: list[str] = []
        for profile_dict in list_instance_profiles_for_role(clients.iam, role_name):
            name = profile_dict.get("InstanceProfileName")
            if isinstance(name, str):
                profile_names.append(name)
        for profile_name in profile_names:
            try:
                clients.iam.remove_role_from_instance_profile(InstanceProfileName=profile_name, RoleName=role_name)
            except ClientError:
                pass
        for profile_name in profile_names:
            try:
                clients.iam.delete_instance_profile(InstanceProfileName=profile_name)
            except ClientError:
                pass
        try:
            clients.iam.delete_role(RoleName=role_name)
        except ClientError as exc:
            print(f" -   ! Failed to delete IAM role {role_name}: {exc}")


def delete_kms_keys(clients: AwsClients, aliases: list[str], keys: list[str]) -> None:
    for alias in aliases:
        print(f" - KMS alias {alias} (delete)")
        try:
            clients.kms.delete_alias(AliasName=alias)
        except ClientError as exc:
            print(f" -   ! Failed to delete KMS alias {alias}: {exc}")
    for key_id in keys:
        print(f" - KMS key schedule deletion {key_id}")
        try:
            clients.kms.schedule_key_deletion(KeyId=key_id, PendingWindowInDays=7)
        except ClientError as exc:
            print(f" -   ! Failed to schedule deletion for KMS key {key_id}: {exc}")


def delete_all(clients: AwsClients, snapshot: AwsSnapshot) -> None:
    print()
    print(f"=== Deleting resources ===")

    # 1) EKS clusters: nodegroups → fargate → addons → cluster
    delete_clusters(clients, snapshot.eks_clusters)

    # 2) ELBv2 / Classic ELB
    delete_elbs(clients, snapshot.elbv2_arns, snapshot.elb_names)

    # 3) ECR
    delete_ecr(clients, snapshot.ecr_repos)

    # 4) CloudWatch logs
    delete_logs(clients, snapshot.log_groups)

    # 5) IAM OIDC (global)
    delete_iodc_providers(clients, snapshot.iam_oidc_arns)

    # 6) IAM local policies
    delete_policies(clients, snapshot.iam_local_policy_arns)

    # 7) IAM roles (non-SLR)
    delete_iam_roles(clients, snapshot.iam_non_slr)

    # 8) KMS custom keys → schedule deletion
    delete_kms_keys(clients, snapshot.kms_aliases, snapshot.kms_customer_keys)

    # 9) Instances → NAT → EIPs (release)
    delete_instances(clients, snapshot.ec2_instances)

    delete_nat_gateways(clients, snapshot.nat_gateways)

    delete_eips(clients, snapshot.eip_allocs)

    # 10) Non-default VPCs (deep clean)
    delete_vpcs(clients, snapshot.vpcs_non_default)


def report_leftovers(clients: AwsClients, nuke_s3: bool) -> None:
    print()
    print("=== Post-run scan (leftovers summary) ===")
    print(f"EKS clusters:      {len(list_eks_clusters(clients.eks))}")
    print(f"ELBv2 LBs:         {len(list_elbv2_load_balancer_arns(clients.elbv2))}")
    print(f"Classic ELBs:      {len(list_elb_names(clients.elb))}")
    print(f"ECR repos:         {len(list_ecr_repositories(clients.ecr))}")
    print(f"CW Log groups:     {len(list_log_group_names(clients.logs))}")
    print(f"Non-default VPCs:  {len(list_non_default_vpc_ids(clients.ec2))}")
    print(f"IAM OIDC prov:     {len(list_oidc_provider_arns(clients.iam))}")
    print(f"IAM roles (total): {len(list_role_names(clients.iam))}")
    print(f"IAM users (kept):  {len(list_user_names(clients.iam))}")
    print(f"KMS keys (custom, not pending deletion): {len(list_kms_customer_keys(clients.kms))}")
    if nuke_s3:
        print(f"S3 buckets:        {len(list_s3_bucket_names(clients.s3))}")
    else:
        print("S3 buckets:        (skipped; --nuke-s3 not set)")
    print("If something remains due to dependency timing, re-run this script.")


def _wait(predicate: Callable[[], bool], message: str) -> None:
    start = int(time.time())
    while True:
        if predicate():
            return
        print(f" -   - {message} [{int(time.time()) - start}s elapsed]")
        if int(time.time()) - start >= TIMEOUT_SECONDS:
            print(f"Timeout after {TIMEOUT_SECONDS}s; continuing.")
            return
        time.sleep(15)


def _teardown_cluster(clients: AwsClients, cluster_name: str) -> None:
    nodegroups = list_eks_nodegroups(clients.eks, cluster_name)
    print(f" -   - found {len(nodegroups)} nodegroups")
    for nodegroup in nodegroups:
        print(f" -   - nodegroup {nodegroup} (delete)")
        try:
            clients.eks.delete_nodegroup(clusterName=cluster_name, nodegroupName=nodegroup)
        except ClientError as exc:
            print(f" -   ! Failed to delete nodegroup {nodegroup}: {exc}")

    def _ngs_gone() -> bool:
        return len(list_eks_nodegroups(clients.eks, cluster_name)) == 0

    _wait(_ngs_gone, f"waiting for nodegroups to disappear from {cluster_name}...")

    fprofiles = list_eks_fargate_profiles(clients.eks, cluster_name)
    for profile in fprofiles:
        print(f" -   - fargate profile {profile} (delete)")
        try:
            clients.eks.delete_fargate_profile(clusterName=cluster_name, fargateProfileName=profile)
        except ClientError as exc:
            print(f" -   ! Failed to delete fargate profile {profile}: {exc}")

    for addon in list_eks_addons(clients.eks, cluster_name):
        print(f" -   - addon {addon} (delete)")
        try:
            clients.eks.delete_addon(clusterName=cluster_name, addonName=addon)
        except ClientError as exc:
            print(f" -   ! Failed to delete addon {addon}: {exc}")

    print(f" -   - cluster {cluster_name} (delete)")
    try:
        clients.eks.delete_cluster(name=cluster_name)
    except ClientError as exc:
        print(f" -   ! Failed to delete cluster {cluster_name}: {exc}")

    def _cluster_gone() -> bool:
        return cluster_name not in list_eks_clusters(clients.eks)

    _wait(_cluster_gone, f"waiting for cluster {cluster_name} to be deleted...")


def _teardown_vpc_resources(clients: AwsClients, vpc_id: str) -> None:
    endpoints = list_vpc_endpoint_ids(clients.ec2, vpc_id)
    if endpoints:
        try:
            clients.ec2.delete_vpc_endpoints(VpcEndpointIds=endpoints)
        except ClientError as exc:
            print(f" -   ! Failed to delete VPC endpoints {endpoints}: {exc}")

    igws = list_internet_gateway_ids_for_vpc(clients.ec2, vpc_id)
    for igw in igws:
        try:
            clients.ec2.detach_internet_gateway(InternetGatewayId=igw, VpcId=vpc_id)
        except ClientError as exc:
            print(f" -   ! Failed to detach IGW {igw}: {exc}")
        try:
            clients.ec2.delete_internet_gateway(InternetGatewayId=igw)
        except ClientError as exc:
            print(f" -   ! Failed to delete IGW {igw}: {exc}")

    enis = list_available_eni_ids_for_vpc(clients.ec2, vpc_id)
    for eni in enis:
        try:
            clients.ec2.delete_network_interface(NetworkInterfaceId=eni)
        except ClientError as exc:
            print(f" -   ! Failed to delete ENI {eni}: {exc}")

    sgs = list_security_group_ids_for_vpc(clients.ec2, vpc_id, exclude_default=True)
    for sg in sgs:
        revoke_all_sg_rules(clients.ec2, sg)
    for sg in sgs:
        try:
            clients.ec2.delete_security_group(GroupId=sg)
        except ClientError as exc:
            print(f" -   ! Failed to delete security group {sg}: {exc}")

    subnets = list_subnet_ids_for_vpc(clients.ec2, vpc_id)
    for subnet in subnets:
        try:
            clients.ec2.delete_subnet(SubnetId=subnet)
        except ClientError as exc:
            print(f" -   ! Failed to delete subnet {subnet}: {exc}")

    route_tables = list_route_tables_for_vpc(clients.ec2, vpc_id)
    for route_table in route_tables:
        routes = route_table.get("Routes", []) or []
        for route in routes:
            if route.get("Origin") == "CreateRouteTable" or route.get("GatewayId") == "local":
                continue
            rt_id = route_table.get("RouteTableId")
            if not rt_id:
                continue
            try:
                if route.get("DestinationCidrBlock"):
                    clients.ec2.delete_route(
                        RouteTableId=rt_id,
                        DestinationCidrBlock=route["DestinationCidrBlock"],
                    )
                elif route.get("DestinationIpv6CidrBlock"):
                    clients.ec2.delete_route(
                        RouteTableId=rt_id,
                        DestinationIpv6CidrBlock=route["DestinationIpv6CidrBlock"],
                    )
            except (ClientError, KeyError):
                pass
        associations = route_table.get("Associations", []) or []
        is_main = any(a.get("Main") for a in associations)
        for association in associations:
            assoc_id = association.get("RouteTableAssociationId")
            if association.get("Main") or not assoc_id:
                continue
            try:
                clients.ec2.disassociate_route_table(AssociationId=assoc_id)
            except ClientError:
                pass
        if not is_main:
            rt_id = route_table.get("RouteTableId")
            if rt_id:
                try:
                    clients.ec2.delete_route_table(RouteTableId=rt_id)
                except ClientError as exc:
                    print(f" -   ! Failed to delete route table {rt_id}: {exc}")

    nacls = list_non_default_network_acl_ids(clients.ec2, vpc_id)
    for nacl in nacls:
        try:
            clients.ec2.delete_network_acl(NetworkAclId=nacl)
        except ClientError as exc:
            print(f" -   ! Failed to delete network ACL {nacl}: {exc}")

    enis = list_available_eni_ids_for_vpc(clients.ec2, vpc_id)
    for eni in enis:
        try:
            clients.ec2.delete_network_interface(NetworkInterfaceId=eni)
        except ClientError as exc:
            print(f" -   ! Failed to delete ENI {eni}: {exc}")

    try:
        clients.ec2.delete_vpc(VpcId=vpc_id)
    except ClientError as exc:
        print(f" -   ! Failed final VPC delete for {vpc_id}: {exc}")


def _delete_s3_buckets(clients: AwsClients, snapshot: AwsSnapshot) -> None:
    print("=== Deleting ALL S3 buckets (GLOBAL) ===")
    s3_resource = clients.session.resource("s3")
    for bucket_name in snapshot.s3_buckets:
        print(f" - S3 bucket {bucket_name}")
        bucket = s3_resource.Bucket(bucket_name)
        try:
            bucket.object_versions.delete()
        except ClientError as exc:
            print(f" -   ! Failed to delete object versions for {bucket_name}: {exc}")
        try:
            bucket.objects.delete()
        except ClientError as exc:
            print(f" -   ! Failed to delete objects for {bucket_name}: {exc}")
        try:
            bucket.delete()
        except ClientError as exc:
            print(f" -   ! Failed to delete bucket {bucket_name}: {exc}")


def main() -> int:
    cfg = load_config_from_env_and_args()

    global TIMEOUT_SECONDS
    TIMEOUT_SECONDS = cfg.wait_timeout_seconds

    clients = AwsClients.create(cfg.profile, cfg.region)

    try:
        aws_identity = clients.sts.get_caller_identity()
    except (NoCredentialsError, ClientError):
        print("ERROR: AWS credentials not configured. Set AWS_PROFILE or credentials.")
        return 1

    print("=== Confirm identity / region ===")
    print({"account": aws_identity.get("Account"), "arn": aws_identity.get("Arn")})
    print(f"Region: {cfg.region}  Profile: {cfg.profile}")

    if cfg.dry_run:
        print("THIS IS A DRY RUN. NO RESOURCES WILL BE DELETED.")
    else:
        print("THIS WILL DELETE MANY RESOURCES!")

    plan = discover(clients, cfg.nuke_s3)
    if not plan:
        return 0

    if cfg.dry_run:
        print("DRY RUN complete — no changes made.")
        return 0

    if not cfg.assume_yes:
        if not confirm():
            return 1

    delete_all(clients, plan)
    if cfg.nuke_s3:
        _delete_s3_buckets(clients, plan)
    report_leftovers(clients, cfg.nuke_s3)

    print()
    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
