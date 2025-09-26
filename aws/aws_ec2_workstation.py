"""Manage the lifecycle of a personal EC2 workstation instance."""
from __future__ import annotations

import argparse
import base64
import json
import subprocess
import sys
import time
from dataclasses import dataclass, asdict, fields
from pathlib import Path
from textwrap import dedent
from typing import Callable
from aws.aws_clients_ex import AwsError, AwsEx, EC2InstanceStatusEx, EC2VolumeEx, EC2InstanceEx

DEFAULT_INSTANCE_NAME = "Boxer"
DEFAULT_INSTANCE_TYPE = "t3.large"
DEFAULT_REGION = "us-west-2"
DEFAULT_SECURITY_GROUP = "default"
DEFAULT_KEY_NAME = "ec2-workstation-key"
DEFAULT_TAG_KEY = "Purpose"
DEFAULT_TAG_VALUE = "DevWorkstation"
DEFAULT_ROOT_VOLUME_SIZE = 30
DEFAULT_DATA_VOLUME_SIZE = 0
DEFAULT_SSH_CIDR = "0.0.0.0/0"
STATUS_DEFAULT_TIMEOUT = 900
STATUS_DEFAULT_POLL_INTERVAL = 10
ROOT_SSH_PATH = Path.home() / ".ssh"

@dataclass
class WorkstationConfig:
    instance_name: str
    instance_type: str
    region: str
    security_group: str
    key_name: str
    tag_key: str
    tag_value: str
    root_volume_size: int
    data_volume_size: int
    ssh_public_key: str | None = None
    ssh_cidr: str = DEFAULT_SSH_CIDR


@dataclass
class WorkstationMetadata:
    META_FILE = Path.cwd() / ".ec2-devbox-meta.json"

    instance_id: str
    volume_id: str | None
    config: WorkstationConfig
    public_ip: str | None = None
    public_dns: str | None = None

    @classmethod
    def load(cls) -> WorkstationMetadata | None:
        if not cls.META_FILE.exists():
            return None

        try:
            data = json.loads(cls.META_FILE.read_text())
        except json.JSONDecodeError as exc:  # pragma: no cover - defensive
            raise ValueError(f"Metadata file {cls.META_FILE} is not valid JSON") from exc

        try:
            config_data = data["config"]
        except KeyError as exc:
            raise ValueError(
                f"Metadata file {cls.META_FILE} is missing the 'config' section; delete it and re-run create."
            ) from exc

        allowed_keys = {f.name for f in fields(WorkstationConfig)}
        filtered_config = {k: v for k, v in config_data.items() if k in allowed_keys}
        config = WorkstationConfig(**filtered_config)

        instance_id = data.get("instance_id")
        if not instance_id:
            raise ValueError(
                f"Metadata file {cls.META_FILE} is missing the 'instance_id' field; delete it and re-run create."
            )

        return cls(
            instance_id=instance_id,
            volume_id=data.get("volume_id"),
            config=config,
            public_ip=data.get("public_ip"),
            public_dns=data.get("public_dns"),
        )

    def save(self) -> None:
        self.META_FILE.write_text(json.dumps(asdict(self), indent=2))

    @classmethod
    def clear(cls) -> None:
        try:
            cls.META_FILE.unlink()
        except FileNotFoundError:
            pass


def wait_for_condition(
    pred: Callable[[], bool],
    timeout: int,
    poll_interval: int,
) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if pred():
            return
        time.sleep(poll_interval)
    raise AwsError("Condition not met before timeout")

class WorkstationManager:
    def __init__(self, profile: str, config: WorkstationConfig) -> None:
        self.config = config
        self.profile = profile
        self.aws = AwsEx(profile=profile, region=config.region)
        self._public_key_source: str | None = None

    def create(self) -> None:
        try:
            existing = WorkstationMetadata.load()
        except ValueError as exc:
            print(exc, file=sys.stderr)
            sys.exit(1)

        if existing is not None:
            print("Metadata file already exists. Run teardown first.", file=sys.stderr)
            sys.exit(1)

        config = self.config

        public_key = self._read_public_key()

        instructions = dedent(
            f"""
            Create a new key pair and save the private key locally:
            aws ec2 create-key-pair --key-name {config.key_name} --region {config.region} \\
                --query 'KeyMaterial' --output text > {str(ROOT_SSH_PATH / (config.key_name + '.pem'))}

            Or import an existing public key:
            aws ec2 import-key-pair --key-name {config.key_name} --region {config.region} \\
                --public-key-material \"$(cat {config.ssh_public_key or str(ROOT_SSH_PATH / 'id_rsa.pub')})\"
            """
        )

        try:
            self.aws.ec2.ensure_key_pair_exists(config.key_name)
        except AwsError as exc:
            not_found = bool(
                getattr(exc.original, "response", {}).get("Error", {}).get("Code") == "InvalidKeyPair.NotFound"
            )
            if not_found:
                try:
                    self.aws.ec2.import_key_pair(config.key_name, public_key)
                    print(
                        f"Imported key pair '{config.key_name}' into region {config.region} using the local public key.",
                        file=sys.stderr,
                    )
                except AwsError as import_exc:
                    print(import_exc, file=sys.stderr)
                    if import_exc.original:
                        print(import_exc.original, file=sys.stderr)
                    print(instructions, file=sys.stderr)
                    sys.exit(1)
            else:
                print(exc, file=sys.stderr)
                if exc.original:
                    print(exc.original, file=sys.stderr)
                print(instructions, file=sys.stderr)
                sys.exit(1)
        user_data = self._build_user_data(public_key)
        self._print_config_summary()
        print("Finding latest Ubuntu 22.04 AMI...")
        ami_id = self.aws.ec2.find_latest_image(
            owners=["099720109477"],
            name_pattern="ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*",
        )
        print(f"Using AMI {ami_id}")

        instance_id = self._launch_instance(ami_id, user_data)
        self.aws.ec2.get_waiter("instance_running").wait(InstanceIds=[instance_id])
        print("Waiting for instance status checks to pass...")
        self._ensure_ssh_access(instance_id)
        try:
            summary = self.wait_for_instance_available(instance_id)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            summary = self.aws.ec2.instance_status_summary(instance_id)
        instance = self.aws.ec2.describe_instance(instance_id)

        if instance.state != "running" or summary.instance_status != "ok" or summary.system_status != "ok":
            print(
                f"Warning: instance status checks did not pass: state={instance.state}, "
                f"instance={summary.instance_status}, system={summary.system_status}",
                file=sys.stderr,
            )
        if not instance.public_ip:
            print("Warning: instance does not yet have a public IP", file=sys.stderr)

        volume_id: str | None = None
        if config.data_volume_size > 0:
            volume_id = self._create_and_attach_volume(instance_id)
        else:
            print("Skipping data volume creation (data_volume_size set to 0 GiB)")

        metadata = WorkstationMetadata(
            instance_id=instance_id,
            volume_id=volume_id,
            config=config,
            public_ip=instance.public_ip,
            public_dns=instance.public_dns_name,
        )
        metadata.save()

        self._print_connect_info(metadata.public_ip, metadata.public_dns)

    def teardown(self) -> None:
        metadata = self._load_metadata_or_exit("No metadata found. Cannot clean up.")

        try:
            self.aws.ec2.terminate_instance(metadata.instance_id)
        except AwsError as exc:
            print(f"Warning: failed to terminate instance: {exc}", file=sys.stderr)

        if metadata.volume_id:
            try:
                self.aws.ec2.delete_volume(metadata.volume_id)
            except AwsError as exc:
                print(f"Warning: failed to delete volume: {exc}", file=sys.stderr)

        WorkstationMetadata.clear()
        print("✅ Cleanup complete.")

    def start(self) -> None:
        metadata = self._load_metadata_or_exit("No metadata found. Run create first.")

        try:
            instance = self.aws.ec2.describe_instance(metadata.instance_id)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            return

        state = instance.state
        if state is None:
            print(f"Instance {metadata.instance_id} not found", file=sys.stderr)
            sys.exit(1)
        if state == "terminated":
            print(f"Instance {metadata.instance_id} is terminated; re-run create", file=sys.stderr)
            sys.exit(1)

        if state == "stopped":
            print(f"Starting instance {metadata.instance_id}...")
            self.aws.ec2.start_instance(metadata.instance_id)
        elif state != "running":
            print(f"Instance {metadata.instance_id} in state '{state}', waiting until running...")
            self.aws.ec2.get_waiter("instance_running").wait(InstanceIds=[metadata.instance_id])

        print("Waiting for instance status checks to pass...")
        self._ensure_ssh_access(metadata.instance_id)
        try:
            summary = self.wait_for_instance_available(metadata.instance_id)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            return

        if summary.instance_status != "ok" or summary.system_status != "ok":
            print(
                f"Warning: instance status checks did not pass: state={instance.state}, "
                f"instance={summary.instance_status}, system={summary.system_status}",
                file=sys.stderr,
            )
            return

        instance = self.aws.ec2.describe_instance(metadata.instance_id)
        self._update_metadata_from_instance(metadata, instance)
        self._print_connect_info(instance.public_ip, instance.public_dns_name)

    def shutdown(self) -> None:
        metadata = self._load_metadata_or_exit("No metadata found. Run create first.")

        try:
            instance = self.aws.ec2.describe_instance(metadata.instance_id)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            return

        state = instance.state
        if state in {None, "terminated"}:
            print("Instance already terminated or missing.")
            return
        if state == "stopped":
            print("Instance already stopped.")
            return

        print(f"Stopping instance {metadata.instance_id}...")
        try:
            self.aws.ec2.stop_instance(metadata.instance_id)
        except AwsError as exc:
            print(exc, file=sys.stderr)

    def connect(self) -> None:
        metadata = self._load_metadata_or_exit("No metadata found. Run create first.")

        try:
            summary = self.aws.ec2.instance_status_summary(metadata.instance_id)
            instance = self.aws.ec2.describe_instance(metadata.instance_id)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            return

        ready = (
            instance.state == "running"
            and summary.instance_status == "ok"
            and summary.system_status == "ok"
        )

        if not ready:
            print(
                "Instance is not yet available."
                f" state={instance.state or 'unknown'},"
                f" instance_status={summary.instance_status},"
                f" system_status={summary.system_status}",
                file=sys.stderr,
            )
        else:
            # Don't update the metadata unless the instance is ready...
            self._update_metadata_from_instance(metadata, instance)

        if instance.public_ip or instance.public_dns_name:
            self._print_connect_info(instance.public_ip, instance.public_dns_name)
        else:
            print(
                "Instance running but no public IP assigned yet. Check the AWS console for networking status.",
                file=sys.stderr,
            )

    def list_volumes(self) -> None:
        metadata: WorkstationMetadata | None = None
        try:
            metadata = WorkstationMetadata.load()
        except ValueError as exc:
            print(f"Warning: {exc}", file=sys.stderr)
        if metadata:
            self.config = metadata.config


        volumes = self.aws.ec2.describe_volumes(None) or []
        volumes = [
            vol
            for vol in volumes
            if vol.tags.get(self.config.tag_key) == self.config.tag_value
        ]
        if not volumes:
            print("No managed EBS volumes found.")
            return
        volumes.sort(key=lambda vol: vol.volume_id)
        print("Managed volumes:")
        for volume in volumes:
            props = volume.props or {}
            vol_id = volume.volume_id
            size = props.get("Size")
            state = props.get("State", "unknown")
            attachments = props.get("Attachments", []) or []
            attachment_info = (
                ", ".join(
                    f"{att.get('InstanceId', '?')}:{att.get('Device', '?')}"
                    for att in attachments
                )
                if attachments
                else "<detached>"
            )
            name = volume.tags["Name"] if volume.tags.get("Name") else "-"
            primary = metadata and vol_id == metadata.volume_id
            suffix = " *primary" if primary else ""
            size_display = f"{size} GiB" if size is not None else "<unknown size>"
            print(f"  {vol_id}  {size_display}  {state}  {attachment_info}  Name={name}{suffix}")

    def add_volume(
        self,
        *,
        size: int | None,
        device: str,
        name: str | None,
        attach: bool,
    ) -> None:
        metadata = self._load_metadata_or_exit("No metadata found. Run create first.")
        instance = self.aws.ec2.describe_instance(metadata.instance_id)

        size_gib = size or self.config.data_volume_size
        if size_gib <= 0:
            print("Volume size must be greater than zero.", file=sys.stderr)
            sys.exit(1)

        existing_devices = {
            mapping.get("DeviceName")
            for mapping in instance.props.get("BlockDeviceMappings", []) or []
            if mapping.get("DeviceName")
        }
        if attach and device in existing_devices:
            print(
                f"Device {device} is already in use on instance {instance.instance_id}. "
                "Use --volume-device to choose an unused device.",
                file=sys.stderr,
            )
            sys.exit(1)

        volume_name = name or f"{self.config.instance_name}-data"
        tags = [
            {"Key": "Name", "Value": volume_name},
            {"Key": self.config.tag_key, "Value": self.config.tag_value},
        ]

        volume = self.aws.ec2.create_volume(
            AvailabilityZone=instance.availability_zone,
            Size=size_gib,
            VolumeType="gp3",
            TagSpecifications=[{"ResourceType": "volume", "Tags": tags}])

        volume_id = volume.get("VolumeId", "<unknown>")
        print(f"Created volume {volume_id} ({size_gib} GiB) in {instance.availability_zone}")
        try:
            self.aws.ec2.get_waiter("volume_available").wait(VolumeIds=[volume_id])
        except Exception as exc:  # pragma: no cover - waiter exceptions are rare
            print(f"Warning: volume {volume_id} did not reach 'available' state: {exc}", file=sys.stderr)

        if not attach:
            print("Volume left unattached (--no-attach).")
            return

        try:
            self.aws.ec2.attach_volume(
                Device=device,
                InstanceId=instance.instance_id,
                VolumeId=volume_id,
            )
        except AwsError as exc:
            print(f"Volume {volume_id} created but attach failed: {exc}", file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            print("Attach the volume manually or detach/delete it as needed.")
            return

        try:
            self.aws.ec2.get_waiter("volume_in_use").wait(VolumeIds=[volume_id])
        except Exception as exc:  # pragma: no cover - waiter exceptions are rare
            print(f"Warning: unable to confirm attachment for {volume_id}: {exc}", file=sys.stderr)

        print(f"Attached {volume_id} to {instance.instance_id} as {device}")

    def detach_volume(self, volume_id: str, *, force: bool) -> None:
        metadata = self._load_metadata_or_exit("No metadata found. Run create first.")
        volume = self._ensure_managed_volume(volume_id)

        attachments = [
            att
            for att in volume.props.get("Attachments", []) or []
            if att.get("InstanceId") == metadata.instance_id
        ]
        if not attachments:
            print(f"Volume {volume_id} is not attached to instance {metadata.instance_id}.")
            return

        attachment = attachments[0]
        device = attachment.get("Device", "<unknown>")
        print(f"Detaching volume {volume_id} from {metadata.instance_id} ({device})")
        self.aws.ec2.detach_volume(
            VolumeId=volume_id,
            InstanceId=metadata.instance_id,
            Force=force)

        try:
            self.aws.ec2.get_waiter("volume_available").wait(VolumeIds=[volume_id])
        except Exception as exc:  # pragma: no cover - waiter exceptions are rare
            print(f"Warning: unable to confirm detach for {volume_id}: {exc}", file=sys.stderr)
            return

        print(f"Volume {volume_id} detached")

    def destroy_volume(self, volume_id: str, *, force_detach: bool) -> None:
        metadata: WorkstationMetadata | None = None
        try:
            metadata = WorkstationMetadata.load()
        except ValueError as exc:
            print(f"Warning: {exc}", file=sys.stderr)

        volume = self._ensure_managed_volume(volume_id)

        attachments = volume.props.get("Attachments", [])
        if attachments:
            attachment_desc = ", ".join(
                f"{att.get('InstanceId', '?')}:{att.get('Device', '?')}"
                for att in attachments
            )
            other_instances = {
                att.get("InstanceId")
                for att in attachments
                if not metadata or att.get("InstanceId") not in {metadata.instance_id}
            }
            if other_instances:
                print(
                    f"Volume {volume_id} is attached to other instances: {', '.join(sorted(other_instances))}.",
                    file=sys.stderr,
                )
                print("Detach the volume from those instances in the AWS console before retrying.", file=sys.stderr)
                sys.exit(1)

            if not force_detach:
                print(
                    f"Volume {volume_id} is attached ({attachment_desc}). Detach it first or rerun with --force-detach.",
                    file=sys.stderr,
                )
                sys.exit(1)

            print(f"Force detaching {volume_id} before deletion...")
            self.detach_volume(volume_id, force=True)
            volume = self._ensure_managed_volume(volume_id)
            attachments = volume.props.get("Attachments", []) or []
            if attachments:
                print(
                    f"Unable to detach volume {volume_id}; aborting delete.",
                    file=sys.stderr,
                )
                sys.exit(1)

        print(f"Deleting volume {volume_id}...")
        self.aws.ec2.delete_volume(volume_id)

        try:
            self.aws.ec2.get_waiter("volume_deleted").wait(VolumeIds=[volume_id])
        except Exception as exc:  # pragma: no cover - waiter exceptions are rare
            print(f"Warning: unable to confirm deletion for {volume_id}: {exc}", file=sys.stderr)

        print(f"Volume {volume_id} deleted")

        if metadata and metadata.volume_id == volume_id:
            metadata.volume_id = None
            metadata.save()

    def _ensure_managed_volume(self, volume_id: str) -> EC2VolumeEx:
        volumes = self.aws.ec2.describe_volumes([volume_id]) or []
        if not volumes:
            print(f"Volume {volume_id} not found", file=sys.stderr)
            sys.exit(1)

        volume = volumes[0]
        if volume.tags.get(self.config.tag_key) != self.config.tag_value:
            print(
                f"Volume {volume_id} does not match tag {self.config.tag_key}={self.config.tag_value}",
                file=sys.stderr,
            )
            sys.exit(1)

        return volume

    def _load_metadata_or_exit(self, missing_message: str) -> WorkstationMetadata:
        try:
            metadata = WorkstationMetadata.load()
        except ValueError as exc:
            print(exc, file=sys.stderr)
            sys.exit(1)

        if not metadata:
            print(missing_message, file=sys.stderr)
            sys.exit(1)

        self.config = metadata.config
        if self.aws.region != self.config.region:
            self.aws = AwsEx(profile=self.profile, region=self.config.region)

        return metadata

    def _read_public_key(self) -> str:
        configured = self.config.ssh_public_key
        if configured:
            candidate_paths = [Path(configured).expanduser()]
        else:
            candidate_paths = [
                ROOT_SSH_PATH / "id_rsa.pub",
                ROOT_SSH_PATH / "id_ed25519.pub",
                ROOT_SSH_PATH / f"{self.config.key_name}.pub",
                ROOT_SSH_PATH / f"{self.config.key_name}.pem",
            ]

        self._public_key_source = None
        missing: list[str] = []
        for path in candidate_paths:
            try:
                key, source = self._read_public_key_from_path(path)
            except FileNotFoundError:
                missing.append(str(path))
                continue
            except ValueError as exc:
                print(f"Warning: {exc}", file=sys.stderr)
                missing.append(str(path))
                continue
            if key:
                self._public_key_source = source
                return key

        searched = (
            ", ".join(str(path) for path in candidate_paths)
            if configured
            else ", ".join(missing)
        )
        print(
            "Unable to read an SSH public key. Specify --ssh-public-key or place a key at one of: "
            f"{searched}",
            file=sys.stderr,
        )
        sys.exit(1)

    def _read_public_key_from_path(self, path: Path) -> tuple[str, str]:
        if not path.exists():
            raise FileNotFoundError(str(path))

        text = path.read_text().strip()
        if not text:
            raise ValueError(f"Key file {path} is empty")

        if text.startswith("ssh-"):
            return text, str(path)

        if path.suffix == ".pem" or text.startswith("-----BEGIN"):
            derived = self._derive_public_key(path)
            return derived, f"{path} (derived via ssh-keygen)"

        raise ValueError(f"File {path} is not an SSH public key")

    def _derive_public_key(self, private_key_path: Path) -> str:
        try:
            result = subprocess.run(
                ["ssh-keygen", "-y", "-f", str(private_key_path)],
                check=True,
                capture_output=True,
                text=True,
            )
        except FileNotFoundError as exc:
            raise ValueError(
                "ssh-keygen is required to derive a public key from the private key at "
                f"{private_key_path}. Install OpenSSH or provide --ssh-public-key."
            ) from exc
        except subprocess.CalledProcessError as exc:
            raise ValueError(
                f"Failed to derive public key from {private_key_path}: {exc.stderr.strip()}"
            ) from exc

        derived = result.stdout.strip()
        if not derived:
            raise ValueError(f"ssh-keygen returned no public key for {private_key_path}")
        return derived

    def _build_user_data(self, public_key: str) -> str:
        instance_name = self.config.instance_name.strip()
        hostname_block = ""
        if instance_name:
            hostname_block = dedent(
                f"""
                HOSTNAME="{instance_name}"
                hostnamectl set-hostname "$HOSTNAME"
                if grep -q '^127\\.0\\.1\\.1' /etc/hosts; then
                  sed -i "s/^127\\.0\\.1\\.1.*/127.0.1.1 $HOSTNAME/" /etc/hosts
                else
                  echo "127.0.1.1 $HOSTNAME" >> /etc/hosts
                fi
                echo "$HOSTNAME" > /etc/hostname
                mkdir -p /etc/cloud/cloud.cfg.d
                cat <<'EOF' >/etc/cloud/cloud.cfg.d/99-preserve-hostname.cfg
preserve_hostname: true
EOF
                """
            ).strip()

        script = dedent(
            f"""
            #!/bin/bash
            set -euo pipefail

            DEVICE="/dev/xvdf"
            MOUNT_POINT="/mnt/work"

            {hostname_block}

            mkdir -p /home/ubuntu/.ssh
            cat <<'PUBKEY' >> /home/ubuntu/.ssh/authorized_keys
{public_key}
PUBKEY
            chown -R ubuntu:ubuntu /home/ubuntu/.ssh
            chmod 700 /home/ubuntu/.ssh
            chmod 600 /home/ubuntu/.ssh/authorized_keys

            apt update

            if [ -b "$DEVICE" ]; then
              if ! blkid "$DEVICE"; then
                mkfs.ext4 -L workdrive "$DEVICE"
              fi

              mkdir -p "$MOUNT_POINT"
              mount "$DEVICE" "$MOUNT_POINT"
              chown ubuntu:ubuntu "$MOUNT_POINT"

              UUID=$(blkid -s UUID -o value "$DEVICE")
              echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
            else
              echo "Device $DEVICE not present; skipping secondary volume setup" >&2
            fi
            """
        ).strip()
        return base64.b64encode(script.encode()).decode()

    def _launch_instance(self, ami_id: str, user_data_b64: str) -> str:
        print("Launching EC2 instance...")
        cfg = self.config
        sg_names: list[str] = []
        sg_ids: list[str] = []
        for entry in cfg.security_group.split(","):
            group = entry.strip()
            if not group:
                continue
            if group.startswith("sg-"):
                sg_ids.append(group)
            else:
                sg_names.append(group)

        instance = self.aws.ec2.launch_instance(
            ImageId=ami_id,
            InstanceType=cfg.instance_type,
            KeyName=cfg.key_name,
            UserData=user_data_b64,
            MinCount=1,
            MaxCount=1,
            TagSpecifications=[
                {
                    "ResourceType": "instance",
                    "Tags": [
                        {"Key": "Name", "Value": cfg.instance_name},
                        {"Key": cfg.tag_key, "Value": cfg.tag_value},
                    ],
                }
            ],
            BlockDeviceMappings=[
                {
                    "DeviceName": "/dev/sda1",
                    "Ebs": {"VolumeSize": cfg.root_volume_size},
                }
            ],
            **(
                {"SecurityGroupIds": sg_ids} if sg_ids else {}
            ),
            **(
                {"SecurityGroups": sg_names} if sg_names and not sg_ids else {}
            ),
        )
        print(f"Instance ID: {instance.instance_id}")
        return instance.instance_id

    def _create_and_attach_volume(self, instance_id: str) -> str:
        instance = self.aws.ec2.describe_instance(instance_id)
        cfg = self.config

        volume = self.aws.ec2.create_volume(
            AvailabilityZone=instance.availability_zone,
            Size=cfg.data_volume_size,
            VolumeType="gp3",
            TagSpecifications=[
                {
                    "ResourceType": "volume",
                    "Tags": [
                        {"Key": "Name", "Value": f"{cfg.instance_name}-data"},
                        {"Key": cfg.tag_key, "Value": cfg.tag_value},
                    ],
                }
            ],
        )
        volume_id = volume["VolumeId"]
        self.aws.ec2.get_waiter("volume_available").wait(VolumeIds=[volume_id])
        self.aws.ec2.attach_volume(Device="/dev/xvdf", InstanceId=instance_id, VolumeId=volume_id)
        print(f"Volume {volume_id} attached")
        return volume_id

    def _print_connect_info(self, public_ip: str | None, public_dns: str | None) -> None:
        address = public_dns or public_ip
        if address:
            print("\nConnect using:")
            print(f"ssh ubuntu@{address}")
            if public_ip and public_dns and public_ip != public_dns:
                print(f"(Public IP: {public_ip})")
        else:
            print("Instance running but no public network address assigned yet. Check the AWS console for networking status.")

    def _ensure_ssh_access(self, instance_id: str) -> None:
        try:
            instance = self.aws.ec2.describe_instance(instance_id)
        except AwsError as exc:
            print(f"Warning: unable to inspect instance {instance_id} for security groups: {exc}", file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            return

        cidr = self.config.ssh_cidr
        for sg in instance.security_groups:
            try:
                added = self.aws.ec2.ensure_security_group_ingress(
                    group_id=sg.id,
                    cidr=cidr,
                    ip_protocol="tcp",
                    from_port=22,
                    to_port=22,
                )
                if added:
                    print(f"Authorized SSH (22/tcp) from {cidr} on security group {sg.id}.")
            except AwsError as exc:
                code = (
                    getattr(exc.original, "response", {})
                    .get("Error", {})
                    .get("Code")
                    if exc.original
                    else ""
                )
                if code == "InvalidPermission.Duplicate":
                    continue
                print(
                    f"Warning: unable to ensure SSH ingress on {sg.id}: {exc}",
                    file=sys.stderr,
                )
                if exc.original:
                    print(exc.original, file=sys.stderr)


    def wait_for_instance_available(self, instance_id: str) -> EC2InstanceStatusEx:
        timeout_seconds = STATUS_DEFAULT_TIMEOUT
        summary: EC2InstanceStatusEx | None = None

        def predicate() -> bool:
            nonlocal summary
            summary = self.aws.ec2.instance_status_summary(instance_id)
            instance = self.aws.ec2.describe_instance(instance_id)
            print(f"  status checks for {summary.instance_id}: state={instance.state}, status={summary.instance_status}, system_status={summary.system_status}")
            return summary.instance_status == "ok" and summary.system_status == "ok"

        wait_for_condition(
            predicate,
            timeout=timeout_seconds,
            poll_interval=STATUS_DEFAULT_POLL_INTERVAL,
        )

        assert summary is not None
        return summary

    def _update_metadata_from_instance(
        self, metadata: WorkstationMetadata, instance: EC2InstanceEx
    ) -> None:
        new_ip = instance.public_ip
        new_dns = instance.public_dns_name
        if metadata.public_ip == new_ip and metadata.public_dns == new_dns:
            return
        metadata.public_ip = new_ip
        metadata.public_dns = new_dns
        metadata.save()

    def _print_config_summary(self) -> None:
        cfg = self.config
        sg_entries = [part.strip() for part in cfg.security_group.split(",") if part.strip()]
        sg_display = ", ".join(sg_entries) if sg_entries else "<default>"
        key_source = self._public_key_source or (
            cfg.ssh_public_key or str(ROOT_SSH_PATH / "id_rsa.pub")
        )
        print("\nLaunch configuration:")
        print(f"  profile: {self.profile}")
        print(f"  region: {cfg.region}")
        print(f"  instance_name: {cfg.instance_name}")
        print(f"  instance_type: {cfg.instance_type}")
        print(f"  key_pair: {cfg.key_name}")
        print(f"  ssh_public_key_source: {key_source}")
        print(f"  security_groups: {sg_display}")
        print(f"  root_volume_size: {cfg.root_volume_size} GiB")
        print(f"  data_volume_size: {cfg.data_volume_size} GiB")
        print(f"  ssh_allowed_cidr: {cfg.ssh_cidr}")
        print(f"  tags: Name={cfg.instance_name}, {cfg.tag_key}={cfg.tag_value}")


def run_status(manager: WorkstationManager):
    metadata = manager._load_metadata_or_exit("No metadata found. Run create first.")
    try:
        summary = manager.wait_for_instance_available(metadata.instance_id)
    except AwsError as exc:
        print(exc, file=sys.stderr)
        if exc.original:
            print(exc.original, file=sys.stderr)
        summary = manager.aws.ec2.instance_status_summary(metadata.instance_id)
    instance = manager.aws.ec2.describe_instance(metadata.instance_id)
    manager._update_metadata_from_instance(metadata, instance)

    ready = (
        instance.state == "running"
        and summary.instance_status == "ok"
        and summary.system_status == "ok"
    )

    public_ip = instance.public_ip or "<none>"
    public_dns = instance.public_dns_name or "<none>"

    print(
        f"Instance {metadata.instance_id}: {'available' if ready else 'unavailable'}\n"
        f"  state: {instance.state or 'unknown'}\n"
        f"  instance_status: {summary.instance_status}\n"
        f"  system_status: {summary.system_status}\n"
        f"  public_ip: {public_ip}\n"
        f"  public_dns: {public_dns}"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Manage an EC2 workstation")
    parser.add_argument(
        "mode",
        choices=[
            "create",
            "teardown",
            "start",
            "shutdown",
            "connect",
            "status",
            "list-volumes",
            "add-volume",
            "detach-volume",
            "destroy-volume",
        ],
        help="Action to perform",
    )
    parser.add_argument("--profile", default="default", help="AWS profile name (default: %(default)s)")
    parser.add_argument("--region", default=DEFAULT_REGION, help="AWS region (default: %(default)s)")
    parser.add_argument("--instance-name", default=DEFAULT_INSTANCE_NAME, help="EC2 instance name")
    parser.add_argument("--instance-type", default=DEFAULT_INSTANCE_TYPE, help="EC2 instance type")
    parser.add_argument(
        "--security-group",
        default=DEFAULT_SECURITY_GROUP,
        help="Security group name(s) or ID(s) to attach (comma separated)",
    )
    parser.add_argument("--key-name", default=DEFAULT_KEY_NAME, help="EC2 key pair name")
    parser.add_argument("--tag-key", default=DEFAULT_TAG_KEY, help="Tag key for instance resources")
    parser.add_argument("--tag-value", default=DEFAULT_TAG_VALUE, help="Tag value for instance resources")
    parser.add_argument("--root-volume-size", type=int, default=DEFAULT_ROOT_VOLUME_SIZE, help="Root volume size (GiB)")
    parser.add_argument("--data-volume-size", type=int, default=DEFAULT_DATA_VOLUME_SIZE, help="Data volume size (GiB)")
    parser.add_argument(
        "--ssh-public-key",
        help=f"Path to an SSH public key to authorize (default: {ROOT_SSH_PATH / 'id_rsa.pub'} or {ROOT_SSH_PATH / 'id_ed25519.pub'})",
    )
    parser.add_argument(
        "--ssh-cidr",
        default=DEFAULT_SSH_CIDR,
        help="CIDR block allowed to connect via SSH (default: %(default)s)",
    )
    parser.add_argument(
        "--volume-id",
        help="EBS volume ID to target (required for detach-volume)",
    )
    parser.add_argument(
        "--volume-size",
        type=int,
        help="Size in GiB for add-volume (default: data volume size from config)",
    )
    parser.add_argument(
        "--volume-device",
        default="/dev/xvdf",
        help="Device name to use when attaching a new volume (default: %(default)s)",
    )
    parser.add_argument(
        "--volume-name",
        help="Name tag to apply to a newly created volume",
    )
    parser.add_argument(
        "--no-attach",
        action="store_true",
        help="Create a volume without attaching it (for add-volume)",
    )
    parser.add_argument(
        "--force-detach",
        action="store_true",
        help="Force detach when running detach-volume",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    config = WorkstationConfig(
        instance_name=args.instance_name,
        instance_type=args.instance_type,
        region=args.region,
        security_group=args.security_group,
        key_name=args.key_name,
        tag_key=args.tag_key,
        tag_value=args.tag_value,
        root_volume_size=args.root_volume_size,
        data_volume_size=args.data_volume_size,
        ssh_public_key=args.ssh_public_key,
        ssh_cidr=args.ssh_cidr,
    )
    manager = WorkstationManager(profile=args.profile, config=config)

    if args.mode == "create":
        manager.create()
    elif args.mode == "teardown":
        manager.teardown()
    elif args.mode == "start":
        manager.start()
    elif args.mode == "shutdown":
        manager.shutdown()
    elif args.mode == "status":
        run_status(manager)
    elif args.mode == "list-volumes":
        manager.list_volumes()
    elif args.mode == "add-volume":
        manager.add_volume(
            size=args.volume_size,
            device=args.volume_device,
            name=args.volume_name,
            attach=not args.no_attach,
        )
    elif args.mode == "detach-volume":
        if not args.volume_id:
            print("detach-volume requires --volume-id", file=sys.stderr)
            sys.exit(1)
        manager.detach_volume(args.volume_id, force=args.force_detach)
    elif args.mode == "destroy-volume":
        if not args.volume_id:
            print("destroy-volume requires --volume-id", file=sys.stderr)
            sys.exit(1)
        manager.destroy_volume(args.volume_id, force_detach=args.force_detach)
    else:
        manager.connect()


if __name__ == "__main__":
    main()
