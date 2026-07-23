# Project 1: 3-Tier Cloud Architecture Deployment

**Project Type:** Individual
**Duration:** 3 days (Wednesday–Friday)
**Estimated Effort:** 12–15 hours total
**Presentation:** Friday (20 minutes per student)

## Skills you will learn

- Architecture: Multi-Tier Design
- AWS: VPC
- AWS: Application Load Balancer
- AWS: EC2
- Security: Defense in Depth
- Cloud Computing: Cost Optimization
- Development Workflow: Documentation
- Development Workflow: Problem Solving

## 🎯 Project Overview

Design, build, and deploy a complete production-ready 3-tier application architecture on AWS. This is your first major cloud infrastructure project that combines everything learned in Weeks 1–3.

**What You'll Build:**

- Complete VPC with proper network segmentation
- 3-tier architecture (Presentation, Application, Data)
- Load-balanced, highly available application
- Secure networking with proper isolation
- Professional architecture documentation
- Cost analysis and optimization strategy

**Why This Matters:** This project simulates a real-world cloud engineering engagement. You'll practice:

- Architecture design decisions
- Security best practices
- Cost-conscious engineering
- Technical documentation
- Presenting technical solutions

## 📋 Project Requirements

### Must Have (Required – 80%)

**1. Network Infrastructure (25%)**

- VPC with /16 CIDR block
- 6 subnets across 2 Availability Zones:
  - 2 public subnets (presentation tier)
  - 2 private subnets (application tier)
  - 2 private subnets (data tier)
- Internet Gateway attached to VPC
- NAT Gateway (at least 1) for private subnet internet access
- Route tables properly configured

**2. Tier 1: Presentation Layer (15%)**

- Application Load Balancer (internet-facing)
- Deployed in public subnets across 2 AZs
- Listener on port 80 (HTTP)
- Health check configured

**3. Tier 2: Application Layer (20%)**

- Minimum 3 EC2 instances running web application
- Deployed in private subnets across 2 AZs
- Registered with ALB target group
- Application displays:
  - Instance ID
  - Availability Zone
  - Database connection status
  - Health check endpoint (`/health`)

**4. Tier 3: Data Layer (10%)**

- Database placeholder (can use EC2 with simulated DB)
- OR RDS database (bonus points)
- Deployed in isolated private subnet
- Only accessible from application tier

**5. Security Configuration (20%)**

- Security groups for each tier:
  - ALB SG: Allow 80/443 from 0.0.0.0/0
  - App SG: Allow 80/443 from ALB SG only
  - Data SG: Allow DB port from App SG only
- Principle of least privilege applied
- No direct internet access to private tiers

**6. Documentation (10%)**

- Architecture diagram (clear and professional)
- README with:
  - Architecture overview
  - Design decisions and trade-offs
  - Security strategy
  - Testing results
  - Cost breakdown

### Should Have (Recommended – 15%)

- Multi-AZ NAT Gateway (high availability)
- Auto Scaling Group for application tier
- RDS Multi-AZ database
- HTTPS listener with ACM certificate
- CloudWatch alarms for monitoring
- Centralized session storage (ElastiCache)
- VPC Flow Logs enabled
- Cost allocation tags

### Nice to Have (Bonus – 5%)

- CI/CD pipeline for deployments
- Infrastructure as Code (CloudFormation/Terraform)
- Blue-green deployment strategy
- Multi-region architecture design
- Disaster recovery plan
- Monitoring dashboard (CloudWatch/Grafana)

## 📅 Project Schedule

### Day 1 (Wednesday): Architecture & Setup

**Morning (3–4 hours):**

- Design architecture (draw diagrams)
- Plan CIDR blocks and subnets
- Create VPC and subnets
- Set up Internet Gateway and NAT Gateway
- Configure route tables

**Checkpoint (11 AM):**

- Present architecture design to instructor
- Get feedback on network design
- Validate CIDR plan

**Afternoon (3–4 hours):**

- Create security groups for all tiers
- Deploy application tier EC2 instances
- Install and configure web application
- Set up database tier placeholder
- Test connectivity between tiers

**End of Day Deliverable:**

- Working VPC with all subnets
- EC2 instances running in private subnets
- Basic security groups configured
- Document progress and blockers

### Day 2 (Thursday): Integration & Testing

**Morning (3–4 hours):**

- Create Application Load Balancer
- Configure target groups and health checks
- Register application instances with ALB
- Configure security groups for ALB
- Test load distribution

**Afternoon (2–3 hours):**

- Refine application to show tier information
- Implement health check endpoint
- Test failover scenarios
- Validate security isolation
- Begin cost analysis

**End of Day Deliverable:**

- Fully functional load-balanced application
- All tiers communicating correctly
- Security validated
- Cost analysis started

### Day 3 (Friday): Documentation & Presentation

**Morning (2–3 hours):**

- Complete architecture documentation
- Create professional diagrams
- Finish cost analysis
- Prepare improvement proposals
- Create presentation slides

**Afternoon (2–3 hours):**

- Final testing and validation
- Practice presentation
- Clean up resources (or prepare for demo)
- Presentations start at 2 PM

## 🎤 Presentation Requirements (Friday)

**Format:** 20 minutes presentation + 5 minutes Q&A

**What to Present:**

1. **Architecture Overview (5 min)**
   - Show architecture diagram
   - Explain each tier's purpose
   - Walk through traffic flow
   - Highlight key design decisions
2. **Live Demo (5 min)**
   - Access application through ALB DNS
   - Show requests hitting different instances
   - Demonstrate health check endpoint
   - Show security group isolation (try to access private resource)
3. **Challenges & Solutions (3 min)**
   - What problems did you encounter?
   - How did you solve them?
   - What would you do differently?
4. **Cost Analysis (3 min)**
   - Monthly cost breakdown
   - Cost optimization strategies implemented
   - Projected savings opportunities
5. **Improvements & Next Steps (2 min)**
   - What would you add for production?
   - How would you scale this?
   - What are the current limitations?
6. **Q&A (5 min)**
   - Answer instructor and peer questions
   - Defend architecture decisions
   - Discuss trade-offs

**Presentation Tips:**

- Keep slides visual (diagrams > text)
- Practice the demo beforehand
- Have backup screenshots in case demo fails
- Be ready to explain WHY you made decisions
- Show enthusiasm and confidence!

## 📤 What to Submit

**Submission Type:** GitHub Repository

Create a public GitHub repository named `ce-project-1-three-tier-architecture` containing:

### Required Files

**1. README.md**

- Project overview
- Architecture description
- How to deploy/replicate
- Testing instructions
- Team member (just you)

**2. ARCHITECTURE.md**

- Detailed architecture documentation
- Component descriptions
- Network design rationale
- Security strategy
- High availability approach

**3. SECURITY.md**

- Security group rules (all tiers)
- Network isolation strategy
- IAM roles and policies
- Security best practices applied
- Potential vulnerabilities and mitigations

**4. COSTS.md**

- Itemized monthly cost breakdown
- Cost optimization strategies
- ROI analysis for optimizations
- Scaling cost projections

**5. IMPROVEMENTS.md**

- Short-term improvements (0–3 months)
- Long-term improvements (3–12 months)
- Production-readiness checklist
- Disaster recovery planning

**6. architecture/ folder**

- `architecture-diagram.png` – Main architecture
- `network-diagram.png` – VPC and subnets
- `security-groups-diagram.png` – Security boundaries
- `traffic-flow-diagram.png` – Request flow

**7. config/ folder**

- `vpc-config.txt` – VPC and subnet details
- `security-groups.txt` – All SG rules
- `load-balancer-config.txt` – ALB configuration
- `instances.txt` – EC2 instance details

**8. app/ folder**

- Application source code
- Deployment scripts
- Health check endpoint code

**9. tests/ folder**

- `test-plan.md` – Testing methodology
- `test-results.md` – Test outcomes
- `failover-test.md` – HA testing results

**10. presentation/ folder**

- Presentation slides (PDF)
- Demo script
- Screenshots for backup

### Repository Structure

```
ce-project-1-three-tier-architecture/
├── README.md
├── ARCHITECTURE.md
├── SECURITY.md
├── COSTS.md
├── IMPROVEMENTS.md
├── architecture/
│   ├── architecture-diagram.png
│   ├── network-diagram.png
│   ├── security-groups-diagram.png
│   └── traffic-flow-diagram.png
├── config/
│   ├── vpc-config.txt
│   ├── security-groups.txt
│   ├── load-balancer-config.txt
│   └── instances.txt
├── app/
│   ├── server.js (or app.py)
│   ├── package.json
│   └── deploy.sh
├── tests/
│   ├── test-plan.md
│   ├── test-results.md
│   └── failover-test.md
└── presentation/
    ├── slides.pdf
    ├── demo-script.md
    └── screenshots/
```

## 🎯 Grading Rubric (100 points)

### Technical Implementation (60 points)

**Network Infrastructure (15 pts)**

- VPC and subnets correctly configured
- Proper CIDR planning
- Internet Gateway and NAT Gateway
- Route tables configured correctly

**3-Tier Architecture (20 pts)**

- All three tiers implemented
- Load balancer configured
- Application tier functional
- Database tier accessible only from app tier

**Security (15 pts)**

- Security groups follow least privilege
- Tiers properly isolated
- No public access to private resources
- IAM roles used appropriately

**High Availability (10 pts)**

- Multi-AZ deployment
- Load balancer distributes traffic
- Health checks working
- Failover tested

### Documentation (20 points)

**Architecture Documentation (10 pts)**

- Clear, professional diagrams
- Thorough explanations
- Design rationale provided
- Trade-offs discussed

**Technical Writing (10 pts)**

- Well-organized READMEs
- Proper markdown formatting
- Code comments where appropriate
- Professional presentation

### Presentation (20 points)

**Content (10 pts)**

- Comprehensive coverage of architecture
- Clear explanation of design decisions
- Demonstrates understanding of concepts
- Addresses cost and security

**Delivery (5 pts)**

- Clear communication
- Good pacing and time management
- Engaging and confident
- Professional demeanor

**Demo (5 pts)**

- Successful live demonstration
- Shows key features
- Handles Q&A well
- Backup plan if demo fails

## 💡 Helpful Resources

**AWS Documentation**

- VPC Best Practices
- ALB Guide
- Multi-Tier Architecture

**Tools**

- Diagrams: draw.io, Lucidchart, CloudCraft
- Cost Calculator: https://calculator.aws/
- CIDR Calculator: https://www.ipaddressguide.com/cidr

**Example Applications**

- Simple Node.js app (provided in labs)
- Flask/Python app (provided in labs)
- Or create your own!

## ⚠️ Common Pitfalls to Avoid

- **Database in public subnet** – Always keep in private subnet!
- **Not testing health checks** – Verify `/health` endpoint works
- **Overly complex application** – Focus on infrastructure, not app features
- **Poor CIDR planning** – Plan for growth, don't use /28 subnets
- **Missing documentation** – Document as you build, not at the end
- **Single AZ deployment** – Always use at least 2 AZs
- **No cost analysis** – Track costs from day 1
- **Leaving resources running** – Stop/terminate when not actively working

## 🤝 Getting Help

**During Project:**

- Instructor office hours: Daily 10–11 AM and 3–4 PM
- Peer collaboration encouraged (but each student submits own work)
- AWS documentation is your friend
- Stack Overflow for specific technical issues

**Checkpoints:**

- Wednesday 11 AM: Architecture review
- Thursday 3 PM: Progress check
- Friday 9 AM: Pre-presentation review

## 🎓 Learning Outcomes

By completing this project, you will have:

- ✅ Designed and implemented production-ready cloud infrastructure
- ✅ Applied networking, security, and HA best practices
- ✅ Created professional technical documentation
- ✅ Presented technical solutions to stakeholders
- ✅ Analyzed and optimized cloud costs
- ✅ Built a portfolio piece for job interviews

## 🚀 Bonus: Take It Further

Want to stand out? Consider these enhancements:

- **Infrastructure as Code:** Write CloudFormation/Terraform
- **Monitoring:** Full CloudWatch dashboard with custom metrics
- **CI/CD:** Automate deployments with GitHub Actions
- **Blue-Green:** Implement zero-downtime deployments
- **Multi-Region:** Design (not implement) multi-region architecture
- **Disaster Recovery:** Create DR runbook and test plan

> **Remember:** This is YOUR project. Make design decisions, justify them, and learn from the experience. There's no single "right" answer – focus on understanding trade-offs and making informed choices.

Good luck! You've got this! 🎉
