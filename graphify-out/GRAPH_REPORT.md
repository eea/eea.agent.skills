# Graph Report - .  (2026-05-02)

## Corpus Check
- Corpus is ~7,594 words - fits in a single context window. You may not need a graph.

## Summary
- 67 nodes · 119 edges · 11 communities detected
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 21 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Project Structure & Directories|Project Structure & Directories]]
- [[_COMMUNITY_EEA Overrides & Validation|EEA Overrides & Validation]]
- [[_COMMUNITY_Shared Resources & Sync Strategy|Shared Resources & Sync Strategy]]
- [[_COMMUNITY_Docker Expert & Related Skills|Docker Expert & Related Skills]]
- [[_COMMUNITY_Build & Distribution|Build & Distribution]]
- [[_COMMUNITY_Data Report Workflow|Data Report Workflow]]
- [[_COMMUNITY_Development Workflow|Development Workflow]]
- [[_COMMUNITY_Docker Compose|Docker Compose]]
- [[_COMMUNITY_Image Size Optimization|Image Size Optimization]]
- [[_COMMUNITY_Dockerfile Optimization|Dockerfile Optimization]]
- [[_COMMUNITY_Container Security|Container Security]]

## God Nodes (most connected - your core abstractions)
1. `EEA Agent Skills` - 17 edges
2. `Docker Expert Merged Skill` - 16 edges
3. `Docker Expert Upstream Skill` - 13 edges
4. `EEA-Specific Overrides for docker-expert` - 11 edges
5. `Restructure Plan: Agentget Compatibility` - 9 edges
6. `Upstream Sync Strategy` - 8 edges
7. `Adding a New Skill` - 6 edges
8. `Initial Repository Setup v1.0.0` - 6 edges
9. `Two-File Overlay Pattern` - 5 edges
10. `shared/ Directory` - 5 edges

## Surprising Connections (you probably didn't know these)
- `CI Validation Workflow` --semantically_similar_to--> `Validation`  [INFERRED] [semantically similar]
  README.md → CONTRIBUTING.md
- `Dockerfile Optimization & Multi-Stage Builds` --semantically_similar_to--> `Dockerfile Optimization (Upstream)`  [INFERRED] [semantically similar]
  skills/docker-expert/SKILL.md → src/skills/docker-expert/SKILL.md
- `Container Security Hardening` --semantically_similar_to--> `Container Security Hardening (Upstream)`  [INFERRED] [semantically similar]
  skills/docker-expert/SKILL.md → src/skills/docker-expert/SKILL.md
- `Docker Compose Orchestration` --semantically_similar_to--> `Docker Compose Orchestration (Upstream)`  [INFERRED] [semantically similar]
  skills/docker-expert/SKILL.md → src/skills/docker-expert/SKILL.md
- `Image Size Optimization` --semantically_similar_to--> `Image Size Optimization (Upstream)`  [INFERRED] [semantically similar]
  skills/docker-expert/SKILL.md → src/skills/docker-expert/SKILL.md

## Hyperedges (group relationships)
- **Agentget Discovery Patterns** — readme_agents_dir, readme_instructions_dir, readme_rules_dir, readme_plugins_dir, skills_readme_distributable [INFERRED 0.80]
- **Docker Expert Two-File Overlay** — src_skill_docker_expert, eea_overrides_docker_expert, skill_docker_expert [EXTRACTED 1.00]
- **Shared Cross-Skill Fragments** — design_foundations_eea, data_schemas_eea, eea_style_guide [EXTRACTED 1.00]

## Communities

### Community 0 - "Project Structure & Directories"
Cohesion: 0.19
Nodes (16): Agents Directory, Instructions Directory, Plugins Directory, agents/ Directory, EEA Agent Skills, instructions/ Directory, plugins/ Directory, rules/ Directory (+8 more)

### Community 1 - "EEA Overrides & Validation"
Cohesion: 0.21
Nodes (13): Skill Structure Convention, Validation, Build Cache for EEA Nexus Registry, Docker Compose for EEA Services, EEA-Specific Overrides for docker-expert, Internal Registry Access, EEA Security Compliance, CI Validation Workflow (+5 more)

### Community 2 - "Shared Resources & Sync Strategy"
Cohesion: 0.32
Nodes (12): Commit dist/ Directory v1.1.0, Initial Repository Setup v1.0.0, Restructure for Agentget Compatibility v1.2.0, Adding a New Skill, Catalog Update, EEA Data Schemas, EEA Design Foundations, EEA Style Guide (+4 more)

### Community 3 - "Docker Expert & Related Skills"
Cohesion: 0.43
Nodes (8): database-expert, devops-expert, Docker Expert Merged Skill, Performance & Resource Management, github-actions-expert, kubernetes-expert, Docker Expert Upstream Skill, Performance & Resource Management (Upstream)

### Community 4 - "Build & Distribution"
Cohesion: 0.67
Nodes (4): scripts/build.sh, Distributable Skills, Source Skills Directory, Build Process

### Community 5 - "Data Report Workflow"
Cohesion: 0.83
Nodes (4): chart Skill, doc Skill, Data Report Workflow, xlsx Skill

### Community 6 - "Development Workflow"
Cohesion: 1.0
Nodes (2): Development Workflow Integration, Development Workflow Integration (Upstream)

### Community 7 - "Docker Compose"
Cohesion: 1.0
Nodes (2): Docker Compose Orchestration, Docker Compose Orchestration (Upstream)

### Community 8 - "Image Size Optimization"
Cohesion: 1.0
Nodes (2): Image Size Optimization, Image Size Optimization (Upstream)

### Community 9 - "Dockerfile Optimization"
Cohesion: 1.0
Nodes (2): Dockerfile Optimization & Multi-Stage Builds, Dockerfile Optimization (Upstream)

### Community 10 - "Container Security"
Cohesion: 1.0
Nodes (2): Container Security Hardening, Container Security Hardening (Upstream)

## Knowledge Gaps
- **10 isolated node(s):** `workflows/ Directory`, `Upstream Sync Check`, `Instructions Directory`, `Agents Directory`, `Directory Mapping` (+5 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Development Workflow`** (2 nodes): `Development Workflow Integration`, `Development Workflow Integration (Upstream)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Docker Compose`** (2 nodes): `Docker Compose Orchestration`, `Docker Compose Orchestration (Upstream)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Image Size Optimization`** (2 nodes): `Image Size Optimization`, `Image Size Optimization (Upstream)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Dockerfile Optimization`** (2 nodes): `Dockerfile Optimization & Multi-Stage Builds`, `Dockerfile Optimization (Upstream)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Container Security`** (2 nodes): `Container Security Hardening`, `Container Security Hardening (Upstream)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `EEA Agent Skills` connect `Project Structure & Directories` to `EEA Overrides & Validation`, `Shared Resources & Sync Strategy`, `Docker Expert & Related Skills`, `Build & Distribution`?**
  _High betweenness centrality (0.486) - this node is a cross-community bridge._
- **Why does `Docker Expert Merged Skill` connect `Docker Expert & Related Skills` to `Project Structure & Directories`, `EEA Overrides & Validation`, `Build & Distribution`, `Development Workflow`, `Docker Compose`, `Image Size Optimization`, `Dockerfile Optimization`, `Container Security`?**
  _High betweenness centrality (0.465) - this node is a cross-community bridge._
- **Why does `EEA-Specific Overrides for docker-expert` connect `EEA Overrides & Validation` to `Docker Expert & Related Skills`, `Build & Distribution`?**
  _High betweenness centrality (0.177) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `Docker Expert Merged Skill` (e.g. with `Docker Expert Upstream Skill` and `EEA-Specific Overrides for docker-expert`) actually correct?**
  _`Docker Expert Merged Skill` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `EEA-Specific Overrides for docker-expert` (e.g. with `EEA Override Rules` and `Docker Expert Merged Skill`) actually correct?**
  _`EEA-Specific Overrides for docker-expert` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `Restructure Plan: Agentget Compatibility` (e.g. with `skills/ Directory` and `src/skills/ Directory`) actually correct?**
  _`Restructure Plan: Agentget Compatibility` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `workflows/ Directory`, `Upstream Sync Check`, `Instructions Directory` to the rest of the system?**
  _10 weakly-connected nodes found - possible documentation gaps or missing edges._