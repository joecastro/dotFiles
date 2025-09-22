"""Manage the lifecycle of a personal EC2 workstation instance."""
from __future__ import annotations

import argparse
import base64
import json
import subprocess
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from textwrap import dedent
from aws.aws_clients_ex import AwsEx, AwsError

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

        config = WorkstationConfig(**config_data)

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
        )

    def save(self) -> None:
        self.META_FILE.write_text(json.dumps(asdict(self), indent=2))

    @classmethod
    def clear(cls) -> None:
        try:
            cls.META_FILE.unlink()
        except FileNotFoundError:
            pass


@dataclass
class InstanceStatus:
    instance_id: str
    instance_status: str
    system_status: str
    public_ip: str | None

    @property
    def is_healthy(self) -> bool:
        return self.instance_status == "ok" and self.system_status == "ok"

    def __str__(self) -> str:
        ip = self.public_ip or "<none>"
        status = "healthy" if self.is_healthy else "unhealthy"
        return (
            f"Instance {self.instance_id}: {status}\n"
            f"  instance_status: {self.instance_status}\n"
            f"  system_status: {self.system_status}\n"
            f"  public_ip: {ip}"
        )


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

        status_info: InstanceStatus | None = None
        try:
            instance_id = self._launch_instance(ami_id, user_data)
            self.aws.ec2.get_waiter("instance_running").wait(InstanceIds=[instance_id])
            print("Waiting for instance status checks to pass...")
            self._ensure_ssh_access(instance_id)
            summary = self._wait_for_status_ok(instance_id, show_progress=True)
            status_info = self._build_instance_status(instance_id, summary)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            sys.exit(1)

        public_ip = status_info.public_ip if status_info else self._current_public_ip(instance_id)
        if not public_ip:
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
            public_ip=public_ip,
        )
        metadata.save()

        self._print_connect_info(metadata.public_ip)

    def teardown(self) -> None:
        metadata = self._load_metadata_or_exit("No metadata found. Cannot clean up.")

        try:
            self.status(instance_id=metadata.instance_id, wait=False, check_only=True)
        except AwsError:
            pass

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
            state = self.aws.ec2.get_instance_state(metadata.instance_id)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            sys.exit(1)
        if state is None:
            print(f"Instance {metadata.instance_id} not found", file=sys.stderr)
            sys.exit(1)
        if state == "terminated":
            print(f"Instance {metadata.instance_id} is terminated; re-run create", file=sys.stderr)
            sys.exit(1)

        if state == "stopped":
            print(f"Starting instance {metadata.instance_id}...")
            try:
                self.aws.ec2.start_instance(metadata.instance_id)
            except AwsError as exc:
                print(exc, file=sys.stderr)
                sys.exit(1)
        elif state != "running":
            print(f"Instance {metadata.instance_id} in state '{state}', waiting until running...")
            self.aws.ec2.get_waiter("instance_running").wait(InstanceIds=[metadata.instance_id])

        print("Waiting for instance status checks to pass...")
        self._ensure_ssh_access(metadata.instance_id)
        summary: dict | None = None
        try:
            summary = self._wait_for_status_ok(metadata.instance_id, show_progress=True)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            sys.exit(1)

        status_info = self._build_instance_status(metadata.instance_id, summary)

        metadata.public_ip = status_info.public_ip
        metadata.save()
        self._print_connect_info(metadata.public_ip)

    def shutdown(self) -> None:
        metadata = self._load_metadata_or_exit("No metadata found. Run create first.")

        try:
            state = self.aws.ec2.get_instance_state(metadata.instance_id)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            sys.exit(1)
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

        status_info = self.status(instance_id=metadata.instance_id, wait=False, check_only=True)
        if status_info.public_ip:
            metadata.public_ip = status_info.public_ip
            metadata.save()
            self._print_connect_info(status_info.public_ip)
        else:
            print("Instance has no public IP. Start it or check the AWS console.", file=sys.stderr)
            try:
                state = self.aws.ec2.get_instance_state(metadata.instance_id)
            except AwsError as exc:
                print(exc, file=sys.stderr)
                return
            print(f"Instance state: {state}")

    def status(
        self,
        instance_id: str | None = None,
        *,
        wait: bool = True,
        check_only: bool = False,
        wait_timeout: int = STATUS_DEFAULT_TIMEOUT,
        wait_interval: int = STATUS_DEFAULT_POLL_INTERVAL,
    ) -> InstanceStatus:
        metadata: WorkstationMetadata | None = None
        if instance_id is None:
            metadata = self._load_metadata_or_exit("No metadata found. Run create first.")
            instance_id = metadata.instance_id

        summary: dict | None = None
        if wait:
            if not check_only:
                print(f"Waiting for instance status checks to pass for {instance_id}...")
            try:
                summary = self._wait_for_status_ok(
                    instance_id,
                    show_progress=not check_only,
                    timeout=wait_timeout,
                    poll_interval=wait_interval,
                )
            except AwsError as exc:
                if check_only:
                    raise
                print(f"Status check for {instance_id} did not pass: {exc}", file=sys.stderr)
                if exc.original:
                    print(exc.original, file=sys.stderr)

        status = self._build_instance_status(instance_id, summary)

        if metadata and status.public_ip and metadata.public_ip != status.public_ip:
            metadata.public_ip = status.public_ip
            metadata.save()

        if not check_only:
            print(status)
        return status

    def list_volumes(self) -> None:
        metadata: WorkstationMetadata | None = None
        try:
            metadata = WorkstationMetadata.load()
        except ValueError as exc:
            print(f"Warning: {exc}", file=sys.stderr)
        if metadata:
            self.config = metadata.config

        filters = [{"Name": f"tag:{self.config.tag_key}", "Values": [self.config.tag_value]}]
        try:
            response = self.aws.ec2.describe_volumes(Filters=filters)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            sys.exit(1)

        volumes = response.get("Volumes", [])
        if not volumes:
            print("No managed EBS volumes found.")
            return

        volumes.sort(key=lambda vol: vol.get("VolumeId", ""))
        print("Managed volumes:")
        for volume in volumes:
            vol_id = volume.get("VolumeId", "<unknown>")
            size = volume.get("Size")
            state = volume.get("State", "unknown")
            attachments = volume.get("Attachments", []) or []
            attachment_info = (
                ", ".join(
                    f"{att.get('InstanceId', '?')}:{att.get('Device', '?')}"
                    for att in attachments
                )
                if attachments
                else "<detached>"
            )
            name = self._tag_value(volume.get("Tags"), "Name") or "-"
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
        instance_id = metadata.instance_id

        try:
            instance = self.aws.ec2.describe_instance(instance_id)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            sys.exit(1)

        size_gib = size or self.config.data_volume_size
        if size_gib <= 0:
            print("Volume size must be greater than zero.", file=sys.stderr)
            sys.exit(1)

        existing_devices = {
            mapping.get("DeviceName")
            for mapping in instance.get("BlockDeviceMappings", []) or []
            if mapping.get("DeviceName")
        }
        if attach and device in existing_devices:
            print(
                f"Device {device} is already in use on instance {instance_id}. "
                "Use --volume-device to choose an unused device.",
                file=sys.stderr,
            )
            sys.exit(1)

        availability_zone = instance["Placement"]["AvailabilityZone"]
        volume_name = name or f"{self.config.instance_name}-data"
        tags = [
            {"Key": "Name", "Value": volume_name},
            {"Key": self.config.tag_key, "Value": self.config.tag_value},
        ]

        try:
            volume = self.aws.ec2.create_volume(
                AvailabilityZone=availability_zone,
                Size=size_gib,
                VolumeType="gp3",
                TagSpecifications=[{"ResourceType": "volume", "Tags": tags}],
            )
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            sys.exit(1)

        volume_id = volume.get("VolumeId", "<unknown>")
        print(f"Created volume {volume_id} ({size_gib} GiB) in {availability_zone}")
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
                InstanceId=instance_id,
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

        print(f"Attached {volume_id} to {instance_id} as {device}")

    def detach_volume(self, volume_id: str, *, force: bool) -> None:
        metadata = self._load_metadata_or_exit("No metadata found. Run create first.")
        volume = self._ensure_managed_volume(volume_id)

        attachments = [
            att
            for att in volume.get("Attachments", []) or []
            if att.get("InstanceId") == metadata.instance_id
        ]
        if not attachments:
            print(f"Volume {volume_id} is not attached to instance {metadata.instance_id}.")
            return

        attachment = attachments[0]
        device = attachment.get("Device", "<unknown>")
        print(f"Detaching volume {volume_id} from {metadata.instance_id} ({device})")
        try:
            self.aws.ec2.detach_volume(
                VolumeId=volume_id,
                InstanceId=metadata.instance_id,
                Force=force,
            )
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            sys.exit(1)

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

        attachments = volume.get("Attachments", []) or []
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
            attachments = volume.get("Attachments", []) or []
            if attachments:
                print(
                    f"Unable to detach volume {volume_id}; aborting delete.",
                    file=sys.stderr,
                )
                sys.exit(1)

        print(f"Deleting volume {volume_id}...")
        try:
            self.aws.ec2.delete_volume(volume_id)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            sys.exit(1)

        try:
            self.aws.ec2.get_waiter("volume_deleted").wait(VolumeIds=[volume_id])
        except Exception as exc:  # pragma: no cover - waiter exceptions are rare
            print(f"Warning: unable to confirm deletion for {volume_id}: {exc}", file=sys.stderr)

        print(f"Volume {volume_id} deleted")

        if metadata and metadata.volume_id == volume_id:
            metadata.volume_id = None
            metadata.save()

    @staticmethod
    def _tag_value(tags: list[dict] | None, key: str) -> str | None:
        for tag in tags or []:
            if tag.get("Key") == key:
                return tag.get("Value")
        return None

    def _is_managed_volume(self, volume: dict) -> bool:
        return self._tag_value(volume.get("Tags"), self.config.tag_key) == self.config.tag_value

    def _ensure_managed_volume(self, volume_id: str) -> dict:
        try:
            response = self.aws.ec2.describe_volumes(VolumeIds=[volume_id])
        except AwsError as exc:
            print(exc, file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            sys.exit(1)

        volumes = response.get("Volumes", [])
        if not volumes:
            print(f"Volume {volume_id} not found", file=sys.stderr)
            sys.exit(1)

        volume = volumes[0]
        if not self._is_managed_volume(volume):
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
            apt install -y e2fsprogs curl gnupg

            if ! command -v eza >/dev/null 2>&1; then
              mkdir -p /etc/apt/keyrings
              wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
              echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" > /etc/apt/sources.list.d/gierens.list
              chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
              apt update
              apt install -y eza
            fi

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
        instance_id = instance["InstanceId"]
        print(f"Instance ID: {instance_id}")
        return instance_id

    def _create_and_attach_volume(self, instance_id: str) -> str:
        instance = self.aws.ec2.describe_instance(instance_id)
        cfg = self.config
        az = instance["Placement"]["AvailabilityZone"]

        volume = self.aws.ec2.create_volume(
            AvailabilityZone=az,
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

    def _current_public_ip(self, instance_id: str) -> str | None:
        try:
            public_ip = self.aws.ec2.current_public_ip(instance_id)
        except AwsError as exc:
            print(exc, file=sys.stderr)
            return None
        return public_ip or None

    def _print_connect_info(self, public_ip: str | None) -> None:
        if public_ip:
            print("\nConnect using:")
            print(f"ssh ubuntu@{public_ip}")
        else:
            print("Instance running but no public IP assigned yet. Check the AWS console for networking status.")

    def _ensure_ssh_access(self, instance_id: str) -> None:
        try:
            instance = self.aws.ec2.describe_instance(instance_id)
        except AwsError as exc:
            print(f"Warning: unable to inspect instance {instance_id} for security groups: {exc}", file=sys.stderr)
            if exc.original:
                print(exc.original, file=sys.stderr)
            return

        cidr = self.config.ssh_cidr
        for sg in instance.get("SecurityGroups", []):
            sg_id = sg.get("GroupId")
            if not sg_id:
                continue
            try:
                added = self.aws.ec2.ensure_security_group_ingress(
                    group_id=sg_id,
                    cidr=cidr,
                    ip_protocol="tcp",
                    from_port=22,
                    to_port=22,
                )
                if added:
                    print(f"Authorized SSH (22/tcp) from {cidr} on security group {sg_id}.")
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
                    f"Warning: unable to ensure SSH ingress on {sg_id}: {exc}",
                    file=sys.stderr,
                )
                if exc.original:
                    print(exc.original, file=sys.stderr)

    def _wait_for_status_ok(
        self,
        instance_id: str,
        *,
        show_progress: bool,
        timeout: int | None = None,
        poll_interval: int | None = None,
    ) -> dict:
        return self.aws.ec2.wait_for_instance_status_ok(
            instance_id,
            timeout=timeout or STATUS_DEFAULT_TIMEOUT,
            poll_interval=poll_interval or STATUS_DEFAULT_POLL_INTERVAL,
            on_update=self._print_status_progress if show_progress else None,
        )

    def _print_status_progress(self, summary: dict) -> None:
        instance_status = summary.get("instance_status", "unknown")
        system_status = summary.get("system_status", "unknown")
        print(
            f"  status checks: instance={instance_status}, system={system_status}"
        )

    def _build_instance_status(
        self,
        instance_id: str,
        summary: dict | None = None,
    ) -> InstanceStatus:
        if summary is None:
            summary = self.aws.ec2.instance_status_summary(instance_id)
        public_ip = self._current_public_ip(instance_id)
        return InstanceStatus(
            instance_id=instance_id,
            instance_status=summary.get("instance_status", "unknown"),
            system_status=summary.get("system_status", "unknown"),
            public_ip=public_ip,
        )

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
        manager.status()
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
