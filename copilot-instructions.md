## Quick context for AI coding agents

This is a tiny DevOps teaching repo that contains a minimal Node.js HTTP app and two deployment options (Ansible + AWS and a bash/AWS-CLI script + cloud-init style user-data). Keep edits minimal, explicit, and synchronized across the two deployment paths.

Key files (examples):
- `src/app.js` — canonical local Node.js app used for development. Listens on PORT or 8080.
- `bash/user-data.sh` — what EC2 instances run at boot: installs NodeJS, writes `app.js` and starts it (listens on port 80 in user-data).
- `bash/deploy-ec2-instance.sh` — AWS CLI-driven deployment that creates/reuses security groups and launches instances using `user-data.sh`.
- `ansible/create_ec2_instances_playbook.yml` — Ansible playbook using `amazon.aws` collection to create keypairs, security groups and EC2 instances.

Big picture architecture and intent
- Single-process Node HTTP app (no database or external services). The repo's purpose is to demonstrate provisioning + deploy on AWS EC2.
- Two deployment flavors:
  - Simple script + AWS CLI (`bash/deploy-ec2-instance.sh` + `bash/user-data.sh`) — suitable for interactive demos.
  - Ansible playbook (`ansible/create_ec2_instances_playbook.yml`) — suitable for infrastructure-as-code demonstrations.

Important project-specific details agents must respect
- Keep `src/app.js` and the `app.js` that `user-data.sh` writes logically consistent. Changing response shapes or port defaults should be mirrored in both places.
- Ports: `src/app.js` defaults to 8080; `user-data.sh` starts the app on port 80. Watch for this discrepancy when changing networking or security-group rules.
- Regions differ in scripts: Ansible playbook sets `AWS_REGION: us-east-2` while `deploy-ec2-instance.sh` exports `AWS_DEFAULT_REGION=us-east-1`. Do not change regions silently; surface this inconsistency in PR descriptions.
- No package.json or lockfile. Running locally requires Node installed. Prefer small, explicit changes (e.g., add a minimal `package.json` only if you update both run docs and `user-data.sh`).

Developer workflows and commands (discoverable from repo)
- Run the app locally: `node src/app.js` (requires Node.js). Default port 8080 unless PORT env is set.
- Deploy with AWS CLI script: `bash/bash/deploy-ec2-instance.sh` (needs AWS credentials configured, AWS CLI v2).
- Deploy with Ansible: `ansible-playbook ansible/create_ec2_instances_playbook.yml` (requires `ansible`, `boto3`, and `ansible-galaxy collection install amazon.aws`).

Integration points & dependencies
- AWS: scripts and playbook require valid AWS credentials and appropriate IAM permissions (EC2, KeyPair, SecurityGroup, AMI describe/run). Assume credentials are provided via environment or AWS CLI config.
- Ansible modules rely on Python `boto3`/`botocore` and `amazon.aws` collection.
- `user-data.sh` installs Node from Nodesource (Node 23.x repo). If changing Node version, update this file and the docs.

When modifying code or adding features, follow these concrete rules
- Mirror runtime behavior between `src/app.js` and `bash/user-data.sh`'s `app.js`. If you change the response body, update both files.
- If you add a new runtime dependency, add a `package.json` and update `user-data.sh` to `npm install` or include a note in PR about packaging choices.
- When changing networking (ports, security group rules), update both `ansible/create_ec2_instances_playbook.yml` and `bash/deploy-ec2-instance.sh` (they use different ports by default).
- When touching AWS region, mention the region divergence in the PR and keep defaults unchanged unless the change is intentional.

Examples to reference in code edits
- To change the HTTP response, edit `src/app.js` (development) and the heredoc in `bash/user-data.sh` (EC2 startup script).
- To change AMI selection in the playbook, see `ansible/create_ec2_instances_playbook.yml` and how it uses `ec2_ami_info` and `images[-1].image_id`.

What NOT to do
- Do not assume a containerized or package-managed runtime; there is no Dockerfile or `package.json` unless you add one deliberately.
- Do not update one deployment path (Ansible or user-data) without syncing the other or calling out the divergence in the PR.

If something is unclear, ask for: desired region, desired default port, whether to add package management (package.json) or keep the repo minimal for teaching.

Files to mention in PRs when changing behavior: `src/app.js`, `bash/user-data.sh`, `bash/deploy-ec2-instance.sh`, `ansible/create_ec2_instances_playbook.yml`, and `readme.md`.
