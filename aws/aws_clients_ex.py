from __future__ import annotations

import time
from typing import Any, Callable, TYPE_CHECKING
import boto3
from botocore.exceptions import ClientError

class AwsError(Exception):
    """Friendly wrapper around botocore ClientError."""

    def __init__(self, message: str, original: Exception | None = None) -> None:
        super().__init__(message)
        self.original = original

if TYPE_CHECKING:
    from mypy_boto3_ec2 import EC2Client
    from mypy_boto3_eks import EKSClient
    from mypy_boto3_eks.type_defs import FargateProfileTypeDef, DeleteNodegroupResponseTypeDef
    from mypy_boto3_elbv2 import ElasticLoadBalancingv2Client
    from mypy_boto3_elb import ElasticLoadBalancingClient
    from mypy_boto3_ecr import ECRClient
    from mypy_boto3_logs import CloudWatchLogsClient
    from mypy_boto3_iam import IAMClient
    from mypy_boto3_s3 import S3Client
    from mypy_boto3_kms import KMSClient
    from mypy_boto3_sts import STSClient
    from boto3.session import Session
    from botocore.client import BaseClient

class AwsEx:
    def __init__(self, profile: str, region: str) -> None:
        self.profile = profile
        self.region = region
        self.session: Session = boto3.Session(profile_name=profile, region_name=region)
        self._clients: dict[str, BaseClient] = {}
        self._ec2_ex: EC2Ex | None = None
        self._eks_ex: EKSEx | None = None
        self._elbv2_ex: ELBv2Ex | None = None
        self._elb_ex: ELBEx | None = None
        self._ecr_ex: ECREx | None = None
        self._logs_ex: LogsEx | None = None
        self._iam_ex: IAMEx | None = None
        self._s3_ex: S3Ex | None = None
        self._kms_ex: KMSEx | None = None
        self._sts_ex: STSEx | None = None

    def client(self, name: str) -> BaseClient:
        if name not in self._clients:
            if name in ("iam", "s3"):
                self._clients[name] = self.session.client(name)
            else:
                self._clients[name] = self.session.client(name, region_name=self.region)
        return self._clients[name]

    @property
    def ec2(self) -> EC2Ex:
        if self._ec2_ex is None:
            self._ec2_ex = EC2Ex(self.client("ec2"))
        return self._ec2_ex

    @property
    def eks(self) -> EKSEx:
        if self._eks_ex is None:
            self._eks_ex = EKSEx(self.client("eks"))
        return self._eks_ex

    @property
    def elbv2(self) -> ELBv2Ex:
        if self._elbv2_ex is None:
            self._elbv2_ex = ELBv2Ex(self.client("elbv2"))
        return self._elbv2_ex

    @property
    def elb(self) -> ELBEx:
        if self._elb_ex is None:
            self._elb_ex = ELBEx(self.client("elb"))
        return self._elb_ex

    @property
    def ecr(self) -> ECREx:
        if self._ecr_ex is None:
            self._ecr_ex = ECREx(self.client("ecr"))
        return self._ecr_ex

    @property
    def logs(self) -> LogsEx:
        if self._logs_ex is None:
            self._logs_ex = LogsEx(self.client("logs"))
        return self._logs_ex

    @property
    def iam(self) -> IAMEx:
        if self._iam_ex is None:
            self._iam_ex = IAMEx(self.client("iam"))
        return self._iam_ex

    @property
    def s3(self) -> S3Ex:
        if self._s3_ex is None:
            self._s3_ex = S3Ex(self.client("s3"), self.session)
        return self._s3_ex

    @property
    def kms(self) -> "KMSEx":
        if self._kms_ex is None:
            self._kms_ex = KMSEx(self.client("kms"))
        return self._kms_ex

    @property
    def sts(self) -> STSEx:
        if self._sts_ex is None:
            self._sts_ex = STSEx(self.client("sts"))
        return self._sts_ex


class EC2RouteEx:
    def __init__(self, props: dict) -> None:
        self._props = props

    def __getattr__(self, name: str) -> Any:
        return self._props.get(name)

    @property
    def destination_cidr_block(self) -> str | None:
        return self._props.get("DestinationCidrBlock")

    @property
    def gateway_id(self) -> str | None:
        return self._props.get("GatewayId")

    @property
    def origin(self) -> str | None:
        return self._props.get("Origin")

    @property
    def nat_gateway_id(self) -> str | None:
        return self._props.get("NatGatewayId")

    @property
    def destination_ipv6_cidr_block(self) -> str | None:
        return self._props.get("DestinationIpv6CidrBlock")

    @property
    def state(self) -> str | None:
        return self._props.get("State")


class EC2RouteTableAssociationEx:
    def __init__(self, props: dict) -> None:
        self._props = props

    def __getattr__(self, name: str) -> Any:
        return self._props.get(name)

    @property
    def route_table_association_id(self) -> str | None:
        return self._props.get("RouteTableAssociationId")

    @property
    def subnet_id(self) -> str | None:
        return self._props.get("SubnetId")

    @property
    def is_main(self) -> bool:
        return self._props.get("Main", False)


class EC2RouteTableEx:
    def __init__(self, props) -> None:
        self._props = props

    def __getattr__(self, name: str) -> Any:
        return self._props.get(name)

    @property
    def route_table_id(self) -> str | None:
        return self._props.get("RouteTableId")

    @property
    def routes(self) -> list[EC2RouteEx]:
        return [EC2RouteEx(r) for r in self._props.get("Routes", []) or []]

    @property
    def associations(self) -> list[EC2RouteTableAssociationEx]:
        return [EC2RouteTableAssociationEx(a) for a in self._props.get("Associations", []) or []]


class EC2SecurityGroupEx:
    def __init__(self, group_id: str, props: dict | None) -> None:
        self._group_id = group_id
        self._props = props

    def __str__(self) -> str:
        return self._group_id

    @property
    def id(self) -> str:
        return self._group_id

    @property
    def props(self) -> dict | None:
        return self._props

class EC2InstanceEx:
    def __init__(self, instance_id: str, props: dict | None) -> None:
        self._instance_id = instance_id
        self._props = props

    def __str__(self) -> str:
        return self._instance_id

    @property
    def instance_id(self) -> str:
        return self._instance_id

    @property
    def availability_zone(self) -> str | None:
        if self._props and "Placement" in self._props:
            return self._props["Placement"].get("AvailabilityZone")
        return None

    @property
    def security_groups(self) -> list[EC2SecurityGroupEx]:
        if self._props:
            return [EC2SecurityGroupEx(g["GroupId"], g)
                    for g in (self._props.get("SecurityGroups", []) or [])
                    if g.get("GroupId")]
        return []

    @property
    def public_dns_name(self) -> str | None:
        if self._props:
            return self._props.get("PublicDnsName")
        return None

    @property
    def public_ip(self) -> str | None:
        if self._props and "PublicIpAddress" in self._props:
            return self._props.get("PublicIpAddress", "")
        return None

    @property
    def props(self) -> dict | None:
        return self._props

    @property
    def state(self) -> str | None:
        if self._props and "State" in self._props:
            state = self._props.get("State") or {}
            return state.get("Name")
        return None

class EC2InstanceStatusEx:
    def __init__(self, instance_id: str, instance_status: str, system_status: str) -> None:
        self._instance_id = instance_id
        self._instance_status = instance_status
        self._system_status = system_status

    @property
    def instance_id(self) -> str:
        return self._instance_id

    @property
    def instance_status(self) -> str:
        return self._instance_status

    @property
    def system_status(self) -> str:
        return self._system_status


class EC2ElasticIPEx:
    def __init__(self, allocation_id: str, props: dict | None) -> None:
        self._allocation_id = allocation_id
        self._props = props

    def __str__(self) -> str:
        return self._allocation_id

    @property
    def allocation_id(self) -> str:
        return self._allocation_id

    @property
    def props(self) -> dict | None:
        return self._props


class EC2VolumeEx:
    def __init__(self, volume_id: str, props: dict | None) -> None:
        self._volume_id = volume_id
        self._props = props
        self._tags = {tag["Key"]: tag["Value"] for tag in props.get("Tags", [])}

    def __str__(self) -> str:
        return self._volume_id

    @property
    def volume_id(self) -> str:
        return self._volume_id

    @property
    def tags(self) -> dict[str, str]:
        return self._tags

    @property
    def volume_type(self) -> str | None:
        return self._props.get("VolumeType")

    @property
    def props(self) -> dict | None:
        return self._props


class EC2Ex:
    def __init__(self, client: EC2Client) -> None:
        self._client: EC2Client = client

    # def __getattr__(self, name: str) -> Any:
    #     return getattr(self._client, name)

    def get_waiter(self, name: str):
        return self._client.get_waiter(name)

    def find_latest_image(self, owners: list[str], name_pattern: str) -> str:
        try:
            response = self._client.describe_images(
                Owners=owners,
                Filters=[{"Name": "name", "Values": [name_pattern]}],
            )
        except ClientError as exc:
            raise AwsError("Failed to describe images", exc)
        images = response.get("Images", [])
        if not images:
            raise AwsError(f"No images found for pattern {name_pattern}")
        latest = max(images, key=lambda img: img["CreationDate"])
        return latest["ImageId"]

    def terminate_instance(self, instance_id: str, wait: bool = True) -> None:
        try:
            self._client.terminate_instances(InstanceIds=[instance_id])
            if wait:
                self._client.get_waiter("instance_terminated").wait(InstanceIds=[instance_id])
        except ClientError as exc:
            raise AwsError(f"Failed to terminate instance {instance_id}", exc)

    def delete_volume(self, volume_id: str) -> None:
        try:
            self._client.delete_volume(VolumeId=volume_id)
        except ClientError as exc:
            raise AwsError(f"Failed to delete volume {volume_id}", exc)

    def release_elastic_ip(self, allocation_id: str) -> None:
        try:
            self._client.release_address(AllocationId=allocation_id)
        except ClientError as exc:
            raise AwsError(f"Failed to release Elastic IP {allocation_id}", exc)

    def launch_instance(self, **kwargs) -> EC2InstanceEx:
        try:
            response = self._client.run_instances(**kwargs)
        except ClientError as exc:
            raise AwsError("Failed to launch instance", exc)
        instance_props = response.get("Instances", [])[0]
        return EC2InstanceEx(instance_props["InstanceId"], instance_props)

    def ensure_key_pair_exists(self, key_name: str) -> None:
        try:
            self._client.describe_key_pairs(KeyNames=[key_name])
        except ClientError as exc:
            error_code = exc.response.get("Error", {}).get("Code", "")
            if error_code == "InvalidKeyPair.NotFound":
                raise AwsError(f"Key pair '{key_name}' not found in region {self._client.meta.region_name}", exc)
            raise AwsError(f"Failed to describe key pair {key_name}", exc)

    def import_key_pair(self, key_name: str, public_key_material: str) -> None:
        try:
            self._client.import_key_pair(KeyName=key_name, PublicKeyMaterial=public_key_material)
        except ClientError as exc:
            raise AwsError(f"Failed to import key pair {key_name}", exc)

    def start_instance(self, instance_id: str, wait: bool = True) -> None:
        try:
            self._client.start_instances(InstanceIds=[instance_id])
            if wait:
                self._client.get_waiter("instance_running").wait(InstanceIds=[instance_id])
        except ClientError as exc:
            raise AwsError(f"Failed to start instance {instance_id}", exc)

    def instance_status_summary(self, instance_id: str) -> EC2InstanceStatusEx:
        try:
            response = self._client.describe_instance_status(
                InstanceIds=[instance_id], IncludeAllInstances=True
            )
        except ClientError as exc:
            raise AwsError(f"Failed to describe instance status for {instance_id}", exc)

        statuses = response.get("InstanceStatuses", [])
        if not statuses:
            return EC2InstanceStatusEx(
                instance_id=instance_id,
                instance_status="unknown",
                system_status="unknown",
            )

        entry = statuses[0]
        instance_status = entry.get("InstanceStatus", {}).get("Status", "unknown")
        system_status = entry.get("SystemStatus", {}).get("Status", "unknown")
        return EC2InstanceStatusEx(
            instance_id=instance_id,
            instance_status=instance_status,
            system_status=system_status,
        )

    def ensure_security_group_ingress(
        self,
        *,
        group_id: str,
        cidr: str,
        ip_protocol: str,
        from_port: int,
        to_port: int,
    ) -> bool:
        try:
            self._client.authorize_security_group_ingress(
                GroupId=group_id,
                IpPermissions=[
                    {
                        "IpProtocol": ip_protocol,
                        "FromPort": from_port,
                        "ToPort": to_port,
                        "IpRanges": [{"CidrIp": cidr}],
                    }
                ],
            )
            return True
        except ClientError as exc:
            code = exc.response.get("Error", {}).get("Code", "")
            if code in {"InvalidPermission.Duplicate", "InvalidPermission.UserIdGroupPair"}:
                return False
            raise AwsError(
                f"Failed to authorize ingress on security group {group_id} ({cidr} {ip_protocol} {from_port}-{to_port})",
                exc,
            )

    def stop_instance(self, instance_id: str, wait: bool = True) -> None:
        try:
            self._client.stop_instances(InstanceIds=[instance_id])
            if wait:
                self._client.get_waiter("instance_stopped").wait(InstanceIds=[instance_id])
        except ClientError as exc:
            raise AwsError(f"Failed to stop instance {instance_id}", exc)

    def allocate_address(self) -> dict:
        try:
            return self._client.allocate_address(Domain="vpc")
        except ClientError as exc:
            raise AwsError("Failed to allocate Elastic IP", exc)

    def associate_address(self, instance_id: str, allocation_id: str, allow_reassociation: bool = True) -> None:
        try:
            self._client.associate_address(
                InstanceId=instance_id,
                AllocationId=allocation_id,
                AllowReassociation=allow_reassociation,
            )
        except ClientError as exc:
            raise AwsError(f"Failed to associate Elastic IP {allocation_id}", exc)

    def describe_addresses(self, allocation_ids: list[str]) -> dict:
        try:
            return self._client.describe_addresses(AllocationIds=allocation_ids)
        except ClientError as exc:
            raise AwsError("Failed to describe Elastic IP addresses", exc)

    def describe_instance(self, instance_id: str) -> EC2InstanceEx:
        try:
            response = self._client.describe_instances(InstanceIds=[instance_id])
        except ClientError as exc:
            raise AwsError(f"Failed to describe instance {instance_id}", exc)
        reservations = response.get("Reservations", [])
        if not reservations:
            raise AwsError(f"Instance {instance_id} not found")
        return EC2InstanceEx(instance_id, reservations[0]["Instances"][0])

    def create_volume(self, **kwargs) -> dict:
        try:
            return self._client.create_volume(**kwargs)
        except ClientError as exc:
            raise AwsError("Failed to create volume", exc)

    def attach_volume(self, **kwargs) -> None:
        try:
            self._client.attach_volume(**kwargs)
        except ClientError as exc:
            raise AwsError("Failed to attach volume", exc)

    def describe_volumes(self, volume_ids: list[str] | None) -> list[EC2VolumeEx]:
        if volume_ids is None:
            response = self._client.describe_volumes()
        else:
            response = self._client.describe_volumes(VolumeIds=volume_ids)
        volumes = response.get("Volumes", [])
        if not volumes:
            return []
        return [EC2VolumeEx(v["VolumeId"], v) for v in volumes]

    def detach_volume(self, **kwargs) -> None:
        try:
            self._client.detach_volume(**kwargs)
        except ClientError as exc:
            raise AwsError("Failed to detach volume", exc)

    def list_instances(self) -> list[EC2InstanceEx]:
        instances: list[EC2InstanceEx] = []
        next_token: str | None = None
        filters = [{"Name": "instance-state-name", "Values": ["pending", "running", "stopping", "stopped"]}]
        while True:
            try:
                if next_token:
                    resp = self._client.describe_instances(Filters=filters, NextToken=next_token)
                else:
                    resp = self._client.describe_instances(Filters=filters)
            except ClientError:
                break
            for res in resp.get("Reservations", []) or []:
                for inst in res.get("Instances", []) or []:
                    iid = inst.get("InstanceId")
                    if iid:
                        instances.append(EC2InstanceEx(iid, inst))
            next_token = resp.get("NextToken")
            if not next_token:
                break
        return instances

    def list_nat_gateway_ids(self) -> list[str]:
        try:
            return [g["NatGatewayId"] for g in self._client.describe_nat_gateways().get("NatGateways", [])]
        except ClientError:
            return []

    def list_elastic_ips(self) -> list[EC2ElasticIPEx]:
        try:
            return [EC2ElasticIPEx(a["AllocationId"], a) for a in self._client.describe_addresses().get("Addresses", [])]
        except ClientError:
            return []

    def list_non_default_vpc_ids(self) -> list[str]:
        try:
            resp = self._client.describe_vpcs(Filters=[{"Name": "isDefault", "Values": ["false"]}])
            return [v["VpcId"] for v in resp.get("Vpcs", [])]
        except ClientError:
            return []

    def list_vpc_endpoint_ids(self, vpc_id: str) -> list[str]:
        try:
            resp = self._client.describe_vpc_endpoints(Filters=[{"Name": "vpc-id", "Values": [vpc_id]}])
            return [e.get("VpcEndpointId") for e in resp.get("VpcEndpoints", []) if e.get("VpcEndpointId")]
        except ClientError:
            return []

    def delete_vpc_endpoints(self, *, VpcEndpointIds: list[str]) -> None:
        try:
            self._client.delete_vpc_endpoints(VpcEndpointIds=VpcEndpointIds)
        except ClientError as exc:
            raise AwsError(
                f"Failed to delete VPC endpoints: {', '.join(VpcEndpointIds)}",
                exc,
            )

    def list_internet_gateway_ids_for_vpc(self, vpc_id: str) -> list[str]:
        try:
            resp = self._client.describe_internet_gateways(Filters=[{"Name": "attachment.vpc-id", "Values": [vpc_id]}])
            return [g.get("InternetGatewayId") for g in resp.get("InternetGateways", []) if g.get("InternetGatewayId")]
        except ClientError:
            return []

    def detach_internet_gateway(self, *, InternetGatewayId: str, VpcId: str) -> None:
        try:
            self._client.detach_internet_gateway(InternetGatewayId=InternetGatewayId, VpcId=VpcId)
        except ClientError as exc:
            raise AwsError(
                f"Failed to detach internet gateway {InternetGatewayId} from VPC {VpcId}",
                exc,
            )

    def delete_internet_gateway(self, *, InternetGatewayId: str) -> None:
        try:
            self._client.delete_internet_gateway(InternetGatewayId=InternetGatewayId)
        except ClientError as exc:
            raise AwsError(f"Failed to delete internet gateway {InternetGatewayId}", exc)

    def list_route_tables_for_vpc(self, vpc_id: str) -> list[EC2RouteTableEx]:
        try:
            resp = self._client.describe_route_tables(Filters=[{"Name": "vpc-id", "Values": [vpc_id]}])
            route_tables = resp.get("RouteTables", []) or []
            route_tables = [EC2RouteTableEx(rt) for rt in route_tables if rt.get("RouteTableId")]
            return route_tables
        except ClientError:
            return []

    def list_security_group_ids_for_vpc(self, vpc_id: str, exclude_default: bool = True) -> list[str]:
        try:
            resp = self._client.describe_security_groups(Filters=[{"Name": "vpc-id", "Values": [vpc_id]}])
            groups = resp.get("SecurityGroups", []) or []
            if exclude_default:
                groups = [g for g in groups if g.get("GroupName") != "default"]
            return [g.get("GroupId") for g in groups if g.get("GroupId")]
        except ClientError:
            return []

    def list_subnet_ids_for_vpc(self, vpc_id: str) -> list[str]:
        try:
            resp = self._client.describe_subnets(Filters=[{"Name": "vpc-id", "Values": [vpc_id]}])
            return [s.get("SubnetId") for s in resp.get("Subnets", []) if s.get("SubnetId")]
        except ClientError:
            return []

    def list_non_default_network_acl_ids(self, vpc_id: str) -> list[str]:
        try:
            resp = self._client.describe_network_acls(Filters=[{"Name": "vpc-id", "Values": [vpc_id]}])
            return [n.get("NetworkAclId") for n in resp.get("NetworkAcls", []) if not n.get("IsDefault") and n.get("NetworkAclId")]
        except ClientError:
            return []

    def list_available_eni_ids_for_vpc(self, vpc_id: str) -> list[str]:
        try:
            resp = self._client.describe_network_interfaces(
                Filters=[{"Name": "vpc-id", "Values": [vpc_id]}, {"Name": "status", "Values": ["available"]}]
            )
            return [e.get("NetworkInterfaceId") for e in resp.get("NetworkInterfaces", []) if e.get("NetworkInterfaceId")]
        except ClientError:
            return []

    def delete_network_interface(self, *, NetworkInterfaceId: str) -> None:
        try:
            self._client.delete_network_interface(NetworkInterfaceId=NetworkInterfaceId)
        except ClientError as exc:
            raise AwsError(f"Failed to delete network interface {NetworkInterfaceId}", exc)

    def get_security_group(self, sg_id: str) -> dict:
        try:
            resp = self._client.describe_security_groups(GroupIds=[sg_id])
            groups = resp.get("SecurityGroups", []) or []
            return groups[0] if groups else {}
        except ClientError:
            return {}

    def get_nat_gateway_state(self, nat_id: str) -> str | None:
        try:
            resp = self._client.describe_nat_gateways(NatGatewayIds=[nat_id])
            ngws = resp.get("NatGateways", [])
            if not ngws:
                return None
            return ngws[0].get("State")
        except ClientError:
            return None

    def revoke_all_sg_rules(self, sg_id: str) -> None:
        sg = self.get_security_group(sg_id)
        if not sg:
            return
        for perm in sg.get("IpPermissionsEgress", []) or []:
            self._client.revoke_security_group_egress(GroupId=sg_id, IpPermissions=[perm])
        for perm in sg.get("IpPermissions", []) or []:
            self._client.revoke_security_group_ingress(GroupId=sg_id, IpPermissions=[perm])

    def delete_security_group(self, *, GroupId: str) -> None:
        try:
            self._client.delete_security_group(GroupId=GroupId)
        except ClientError as exc:
            raise AwsError(f"Failed to delete security group {GroupId}", exc)

    def terminate_instance(self, instance: EC2InstanceEx | str, wait: bool = False) -> None:
        instance_id = instance.instance_id if isinstance(instance, EC2InstanceEx) else instance
        self._client.terminate_instances(InstanceIds=[instance_id])
        if wait:
            self._client.get_waiter("instance_terminated").wait(InstanceIds=[instance_id])

    def delete_nat_gateway(self, nat_id: str) -> None:
        self._client.delete_nat_gateway(NatGatewayId=nat_id)

    def delete_route(self, route_table: EC2RouteTableEx, route: EC2RouteEx) -> None:
        if route.destination_cidr_block:
            self._client.delete_route(RouteTableId=route_table.route_table_id, DestinationCidrBlock=route.destination_cidr_block)
        elif route.destination_ipv6_cidr_block:
            self._client.delete_route(RouteTableId=route_table.route_table_id, DestinationIpv6CidrBlock=route.destination_ipv6_cidr_block)
        else:
            raise ValueError("Route has no destination_cidr_block or destination_ipv6_cidr_block")

    def delete_route_table(self, route_table: EC2RouteTableEx) -> None:
        self._client.delete_route_table(RouteTableId=route_table.route_table_id)

    def disassociate_route_table(self, association: EC2RouteTableAssociationEx) -> None:
        self._client.disassociate_route_table(AssociationId=association.route_table_association_id)

    def delete_vpc(self, *, VpcId: str) -> None:
        try:
            self._client.delete_vpc(VpcId=VpcId)
        except ClientError as exc:
            raise AwsError(f"Failed to delete VPC {VpcId}", exc)

    def delete_subnet(self, *, SubnetId: str) -> None:
        try:
            self._client.delete_subnet(SubnetId=SubnetId)
        except ClientError as exc:
            raise AwsError(f"Failed to delete subnet {SubnetId}", exc)

    def delete_network_acl(self, *, NetworkAclId: str) -> None:
        try:
            self._client.delete_network_acl(NetworkAclId=NetworkAclId)
        except ClientError as exc:
            raise AwsError(f"Failed to delete network ACL {NetworkAclId}", exc)


class EKSNodegroupEx:
    def __init__(self, cluster_name: str, nodegroup_name: str, props: dict | None) -> None:
        self._cluster_name = cluster_name
        self._nodegroup_name = nodegroup_name
        self._props = props

    def __str__(self) -> str:
        return f"{self._cluster_name}/{self._nodegroup_name}"

    @property
    def cluster_name(self) -> str:
        return self._cluster_name

    @property
    def nodegroup_name(self) -> str:
        return self._nodegroup_name

    @property
    def props(self) -> dict | None:
        return self._props



class EKSClusterEx:
    def __init__(self, cluster_name: str, props: dict | None) -> None:
        self._cluster_name = cluster_name
        self._props = props

    def __str__(self) -> str:
        return self._cluster_name

    @property
    def cluster_name(self) -> str:
        return self._cluster_name

    @property
    def props(self) -> dict | None:
        return self._props



class EKSEx:
    def __init__(self, client: EKSClient) -> None:
        self._client: EKSClient = client

    # def __getattr__(self, name: str) -> Any:
    #    return getattr(self._client, name)

    def list_clusters(self) -> list[EKSClusterEx]:
        try:
            return [EKSClusterEx(c, None) for c in self._client.list_clusters().get("clusters", [])]
        except ClientError:
            return []

    def list_nodegroups(self, cluster: EKSClusterEx) -> list[EKSNodegroupEx]:
        try:
            pages = self._client.get_paginator("list_nodegroups").paginate(clusterName=cluster.cluster_name)
            return [EKSNodegroupEx(cluster.cluster_name, ng, {}) for page in pages for ng in page.get("nodegroups", [])]
        except ClientError:
            return []

    def list_fargate_profile_names(self, cluster: EKSClusterEx) -> list[str]:
        try:
            pages = self._client.get_paginator("list_fargate_profiles").paginate(clusterName=cluster.cluster_name)
            fargate_profiles: list[FargateProfileTypeDef] = [fp for page in pages for fp in page.get("fargateProfiles", [])]
            return [fp.fargateProfileName for fp in fargate_profiles]
        except ClientError:
            return []

    def list_addons(self, cluster: EKSClusterEx) -> list[str]:
        try:
            pages = self._client.get_paginator("list_addons").paginate(clusterName=cluster.cluster_name)
            return [a for page in pages for a in page.get("addons", [])]
        except ClientError:
            return []

    def delete_nodegroup(self, cluster: EKSClusterEx, nodegroup: EKSNodegroupEx) -> EKSNodegroupEx | None:
        try:
            resp: DeleteNodegroupResponseTypeDef = self._client.delete_nodegroup(clusterName=cluster.cluster_name, nodegroupName=nodegroup.nodegroup_name)
            return EKSNodegroupEx(cluster.cluster_name, nodegroup.nodegroup_name, resp.get("nodegroup"))
        except ClientError:
            pass
        return None

    def delete_fargate_profile(self, cluster: EKSClusterEx, profile_name: str) -> None:
        try:
            self._client.delete_fargate_profile(clusterName=cluster.cluster_name, fargateProfileName=profile_name)
        except ClientError:
            pass

    def delete_addon(self, cluster: EKSClusterEx, addon_name: str) -> None:
        try:
            self._client.delete_addon(clusterName=cluster.cluster_name, addonName=addon_name)
        except ClientError:
            pass

    def delete_cluster(self, cluster: EKSClusterEx) -> EKSClusterEx | None:
        try:
            resp = self._client.delete_cluster(name=cluster.cluster_name)
            return EKSClusterEx(cluster.cluster_name, resp.get("cluster"))
        except ClientError:
            pass
        return None


class ELBv2Ex:
    def __init__(self, client: ElasticLoadBalancingv2Client) -> None:
        self._client: ElasticLoadBalancingv2Client = client

    def __getattr__(self, name: str) -> Any:
        return getattr(self._client, name)

    def list_load_balancer_arns(self) -> list[str]:
        try:
            pages = self._client.get_paginator("describe_load_balancers").paginate()
            return [lb["LoadBalancerArn"] for page in pages for lb in page.get("LoadBalancers", [])]
        except ClientError:
            return []

    def list_target_group_arns(self, load_balancer_arn: str) -> list[str]:
        try:
            pages = self._client.get_paginator("describe_target_groups").paginate(LoadBalancerArn=load_balancer_arn)
            return [tg["TargetGroupArn"] for page in pages for tg in page.get("TargetGroups", [])]
        except ClientError:
            return []


class ELBEx:
    def __init__(self, client: ElasticLoadBalancingClient) -> None:
        self._client: ElasticLoadBalancingClient = client

    def __getattr__(self, name: str) -> Any:
        return getattr(self._client, name)

    def list_load_balancer_names(self) -> list[str]:
        try:
            pages = self._client.get_paginator("describe_load_balancers").paginate()
            return [lb["LoadBalancerName"] for page in pages for lb in page.get("LoadBalancerDescriptions", [])]
        except ClientError:
            return []


class ECRRepoEx:
    def __init__(self, repository_name: str) -> None:
        self._repository_name = repository_name

    def __str__(self) -> str:
        return self._repository_name

    @property
    def repository_name(self) -> str:
        return self._repository_name


class ECRImageEx:
    def __init__(self, image_id: dict) -> None:
        self._image_id = image_id

    def __getattr__(self, name: str) -> Any:
        return self._image_id.get(name)

    @property
    def image_digest(self) -> str | None:
        return self._image_id.get("imageDigest")

    @property
    def image_tag(self) -> str | None:
        return self._image_id.get("imageTag")


class ECREx:
    def __init__(self, client: ECRClient) -> None:
        self._client: ECRClient = client

    def __getattr__(self, name: str) -> Any:
        return getattr(self._client, name)

    def list_repositories(self) -> list[ECRRepoEx]:
        try:
            pages = self._client.get_paginator("describe_repositories").paginate()
            return [ECRRepoEx(r["repositoryName"]) for page in pages for r in page.get("repositories", [])]
        except ClientError:
            return []

    def list_images(self, repository: ECRRepoEx) -> list[ECRImageEx]:
        try:
            pages = self._client.get_paginator("list_images").paginate(repositoryName=repository.repository_name)
            return [ECRImageEx(i) for page in pages for i in page.get("imageIds", [])]
        except ClientError:
            return []

    def delete_images(self, repository: ECRRepoEx, images: ECRImageEx | list[ECRImageEx]) -> None:
        if not images:
            return
        if not isinstance(images, list):
            images = [images]

        try:
            self._client.batch_delete_image(
                repositoryName=repository.repository_name,
                imageIds=[{"imageDigest": i.image_digest} if i.image_digest else {"imageTag": i.image_tag} for i in images]
            )
        except ClientError:
            pass

    def delete_repository(self, repository: ECRRepoEx, force: bool = True) -> None:
        try:
            self._client.delete_repository(repositoryName=repository.repository_name, force=force)
        except ClientError:
            pass


class LogsEx:
    def __init__(self, client: CloudWatchLogsClient) -> None:
        self._client: CloudWatchLogsClient = client

    def __getattr__(self, name: str) -> Any:
        return getattr(self._client, name)

    def list_log_group_names(self) -> list[str]:
        try:
            pages = self._client.get_paginator("describe_log_groups").paginate()
            return [g["logGroupName"] for page in pages for g in page.get("logGroups", [])]
        except ClientError:
            return []


class IAMEx:
    def __init__(self, client: IAMClient) -> None:
        self._client: IAMClient = client

    def __getattr__(self, name: str) -> Any:
        return getattr(self._client, name)

    def list_oidc_provider_arns(self) -> list[str]:
        try:
            return [p["Arn"] for p in self._client.list_open_id_connect_providers().get("OpenIDConnectProviderList", [])]
        except ClientError:
            return []

    def list_local_policy_arns(self) -> list[str]:
        try:
            pages = self._client.get_paginator("list_policies").paginate(Scope="Local")
            return [p["Arn"] for page in pages for p in page.get("Policies", [])]
        except ClientError:
            return []

    def list_role_names(self) -> list[str]:
        try:
            pages = self._client.get_paginator("list_roles").paginate()
            return [r["RoleName"] for page in pages for r in page.get("Roles", [])]
        except ClientError:
            return []

    def list_user_names(self) -> list[str]:
        try:
            pages = self._client.get_paginator("list_users").paginate()
            return [u["UserName"] for page in pages for u in page.get("Users", [])]
        except ClientError:
            return []

    # The following helpers mirror raw IAM calls but swallow ClientError
    # to simplify callers that only need empty defaults on failure.
    def list_entities_for_policy(self, *args: Any, **kwargs: Any) -> dict:
        try:
            return self._client.list_entities_for_policy(*args, **kwargs)
        except ClientError:
            return {}

    def list_policy_versions(self, *args: Any, **kwargs: Any) -> dict:
        try:
            return self._client.list_policy_versions(*args, **kwargs)
        except ClientError:
            return {}

    def list_attached_role_policies(self, *args: Any, **kwargs: Any) -> dict:
        try:
            return self._client.list_attached_role_policies(*args, **kwargs)
        except ClientError:
            return {}

    def list_role_policies(self, *args: Any, **kwargs: Any) -> dict:
        try:
            return self._client.list_role_policies(*args, **kwargs)
        except ClientError:
            return {}

    def list_instance_profiles_for_role(self, *args: Any, **kwargs: Any) -> dict:
        try:
            return self._client.list_instance_profiles_for_role(*args, **kwargs)
        except ClientError:
            return {}


class S3BucketEx:
    def __init__(self, name: str) -> None:
        self._name = name

    def __str__(self) -> str:
        return self._name

    @property
    def name(self) -> str:
        return self._name


class S3Ex:
    def __init__(self, client: S3Client, session: Session) -> None:
        self._client: S3Client = client
        self._session: Session = session

    def __getattr__(self, name: str) -> Any:
        return getattr(self._client, name)

    def list_buckets(self) -> list[S3BucketEx]:
        try:
            return [S3BucketEx(b["Name"]) for b in self._client.list_buckets().get("Buckets", [])]
        except ClientError:
            return []

    def delete_bucket_force(self, bucket: S3BucketEx) -> None:
        # Delete all versions/markers then delete bucket
        s3res = self._session.resource("s3")
        bucket = s3res.Bucket(bucket.name)
        try:
            bucket.object_versions.delete()
        except ClientError as e:
            print(f"Failed to delete S3 object versions for {bucket.name}: {e}")
        try:
            bucket.objects.delete()
        except ClientError as e:
            print(f"S3 object delete failed for {bucket.name}: {e}")
        try:
            bucket.delete()
        except ClientError as e:
            print(f"S3 bucket delete failed for {bucket.name}: {e}")


class KMSKeyMetadataEx:
    def __init__(self, props: dict) -> None:
        self._props = props

    def __getattr__(self, name: str) -> Any:
        return self._props.get(name)

    @property
    def key_manager(self) -> str | None:
        return self._props.get("KeyManager")

    @property
    def key_state(self) -> str | None:
        return self._props.get("KeyState")


class KMSKeyEx:
    def __init__(self, key_id: str) -> None:
        self._key_id = key_id

    @property
    def key_id(self) -> str:
        return self._key_id

    def __str__(self) -> str:
        return self._key_id


class KMSAliasEx:
    def __init__(self, alias_name: str, arn: str, target_key: KMSKeyEx | None) -> None:
        self._alias_name = alias_name
        self._arn = arn
        self._target_key = target_key

    @property
    def alias_name(self) -> str:
        return self._alias_name

    def __str__(self) -> str:
        return self._alias_name

    @property
    def is_customer(self) -> bool:
        return self._alias_name.startswith("alias/") and not self._alias_name.startswith("alias/aws/")

    @property
    def arn(self) -> str:
        return self._arn

    @property
    def target(self) -> KMSKeyEx | None:
        return KMSKeyEx(self._target_key) if self._target_key else None


class KMSEx:
    def __init__(self, client: KMSClient) -> None:
        self._client: KMSClient = client

    #def __getattr__(self, name: str) -> Any:
    #    return getattr(self._client, name)

    def list_keys(self) -> list[KMSKeyEx]:
        try:
            pages = self._client.get_paginator("list_keys").paginate()
            return [KMSKeyEx(k["KeyId"]) for page in pages for k in page.get("Keys", [])]
        except ClientError:
            return []

    def describe_key(self, key: KMSKeyEx) -> KMSKeyMetadataEx | None:
        try:
            resp = self._client.describe_key(KeyId=key.key_id)
            return KMSKeyMetadataEx(resp.get("KeyMetadata", {}))
        except ClientError:
            return None

    def list_customer_keys(self) -> list[KMSKeyEx]:
        keys = self.list_keys()
        out: list[KMSKeyEx] = []
        for k in keys:
            meta = self.describe_key(k)
            if not meta or meta.key_manager != "CUSTOMER" or meta.key_state == "PendingDeletion":
                continue
            out.append(k)
        return out

    def schedule_key_deletion(self, key: KMSKeyEx, pending_window_days: int = 7) -> None:
        try:
            self._client.schedule_key_deletion(KeyId=key.key_id, PendingWindowInDays=pending_window_days)
        except ClientError:
            pass

    def list_aliases(self, customer_only: bool) -> list[KMSAliasEx]:
        try:
            pages = self._client.get_paginator("list_aliases").paginate()
            aliases = [KMSAliasEx(a["AliasName"], a["AliasArn"], a.get("TargetKeyId")) for page in pages for a in page.get("Aliases", [])]
            if customer_only:
                aliases = [a for a in aliases if a.is_customer]
            return aliases
        except ClientError:
            return []

    def delete_alias(self, alias: KMSAliasEx) -> None:
        try:
            self._client.delete_alias(AliasName=alias.alias_name)
        except ClientError:
            pass


class IAMCallerIdentityEx:
    def __init__(self, identity: dict) -> None:
        self._identity = identity

    @property
    def account(self) -> str | None:
        return self._identity.get("Account", "<unknown>")

    @property
    def arn(self) -> str | None:
        return self._identity.get("Arn", "<unknown>")

    @property
    def userId(self) -> str | None:
        return self._identity.get("UserId", "<unknown>")

    def __getattr__(self, name: str) -> Any:
        return self._identity.get(name)


class STSEx:
    def __init__(self, client: STSClient) -> None:
        self._client: STSClient = client

    def __getattr__(self, name: str) -> Any:
        return getattr(self._client, name)

    def get_caller_identity(self) -> IAMCallerIdentityEx:
        try:
            identity = self._client.get_caller_identity()
            return IAMCallerIdentityEx(identity)
        except ClientError:
            return IAMCallerIdentityEx({})
