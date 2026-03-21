# Panel Template: Infrastructure Review

Use this template when evaluating infrastructure designs, IaC (Terraform, Pulumi, etc.), cloud
architecture, network topology, or platform engineering decisions.

## Suggested areas and evaluators

### Area 1: Reliability and availability (3-4 evaluators)

| ID    | Specialisation                    | Focus                                      |
| ----- | --------------------------------- | ------------------------------------------ |
| REL-1 | High availability and redundancy  | Single points of failure? Failover?        |
| REL-2 | Backup and disaster recovery      | RPO/RTO defined? Tested?                   |
| REL-3 | Capacity planning and autoscaling | Can it handle growth?                      |
| REL-4 | Monitoring and alerting           | Will operators know when something breaks? |

### Area 2: Security and compliance (3-4 evaluators)

| ID    | Specialisation                    | Focus                                   |
| ----- | --------------------------------- | --------------------------------------- |
| SEC-1 | Network security and segmentation | Firewall rules, VPCs, zero trust?       |
| SEC-2 | Identity and access management    | IAM policies, least privilege?          |
| SEC-3 | Encryption and secrets management | Data at rest, in transit, key rotation? |
| SEC-4 | Compliance and audit              | SOC2, ISO 27001, GDPR requirements?     |

### Area 3: Cost and operations (2-4 evaluators)

| ID    | Specialisation                   | Focus                                    |
| ----- | -------------------------------- | ---------------------------------------- |
| OPS-1 | Cost optimisation                | Right-sizing, reserved instances, waste? |
| OPS-2 | IaC quality and drift detection  | Is infrastructure properly codified?     |
| OPS-3 | Deployment and change management | How are changes rolled out? Rollback?    |
| OPS-4 | Vendor lock-in and portability   | Can you move if needed?                  |

## Suggested minimum panel

For a quick review: REL-1, REL-4, SEC-1, SEC-2, OPS-1 (5 evaluators, 1 batch)

For a thorough review: All evaluators above (10-12 evaluators, 2-3 batches)
