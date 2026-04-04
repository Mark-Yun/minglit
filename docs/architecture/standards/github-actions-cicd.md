# GitHub Actions & CI/CD Automation Standard (v2.0)

**Description**: 본 문서는 OIDC 기반의 보안 인증, Sigstore를 활용한 아티팩트 빌드 증명(Attestation), 그리고 공급망 공격 방어를 위한 워크플로우 하드닝 정책을 정의합니다. 모든 DevOps 엔지니어와 에이전트는 본 정책을 릴리즈 파이프라인 설계의 절대적 기준으로 삼습니다.

**References**:
*   [GitHub: Using Artifact Attestations for Build Provenance](https://docs.github.io/en/actions/security-guides/using-artifact-attestations-to-establish-provenance-for-builds)
*   [Sigstore: Standard for Supply Chain Integrity](https://www.sigstore.dev)
*   [SLSA: Supply-chain Levels for Software Artifacts](https://slsa.dev)
*   [Google SRE: Release Engineering & Velocity](https://sre.google/sre-book/release-engineering)
*   [GitHub Security Lab: Hardening GitHub Actions](https://securitylab.github.com)

---

## 🔐 Section 1: 공급망 보안 및 아티팩트 신뢰 정책 (Supply Chain)

### [Rule 1.1] Mandatory Artifact Attestation (빌드 증명 의무화)
*   **Policy**: 모든 프로덕션용 바이너리, 컨테이너 이미지, 패키지는 반드시 **Sigstore** 기반의 증명(Attestation)을 생성해야 합니다.
*   **Standard**: 
    1. `actions/attest@v4`를 사용하여 빌드 과정의 투명성(Provenance)을 보장합니다.
    2. 생성된 아티팩트는 배포 전 반드시 `gh attestation verify`를 통해 변조 여부를 검증해야 합니다.
*   **Rationale**: 빌드 잡에서 생성된 파일이 배포 잡으로 이동하는 사이 악성 코드로 교체되는 '중간자 공격'을 원천 차단합니다. 증명 데이터는 해당 파일이 승인된 워크플로우와 커밋에서 생성되었음을 수학적으로 입증합니다.

### [Rule 1.2] Immutable Action References (SHA 고정)
*   **Policy**: 워크플로우 내에서 사용하는 모든 외부 액션은 반드시 **전체 길이의 커밋 SHA**를 참조해야 합니다. 버전 태그(예: `@v1`) 사용을 엄격히 금지합니다.
    *   **Bad**: `uses: actions/checkout@v4`
    *   **Good**: `uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1`
*   **Rationale**: 태그는 소유자에 의해 언제든 다른 커밋으로 옮겨질 수 있으나, SHA는 절대 변하지 않습니다. 이는 외부 의존성 오염으로 인한 보안 사고를 방지합니다.

---

## 🏗️ Section 2: 권한 하드닝 및 네트워크 격리 정책 (Hardening)

### [Rule 2.1] Least Privilege Token Permissions
*   **Policy**: 워크플로우 최상단에 `permissions: read-all` 또는 `none`을 명시하고, 각 잡(Job)별로 필요한 최소한의 권한만 명시적으로 부여합니다.
*   **Standard**: OIDC 기반 인증이 필요한 경우 오직 `id-token: write` 권한만 잡 단위로 허용합니다.
*   **Audit Criteria**: `GITHUB_TOKEN`에 기본값인 `write-all` 권한이 부여되어 있는가? (발견 시 Critical 취약점으로 분류)

### [Rule 2.2] Runner Network Filtering
*   **Policy**: 러너는 승인된 패키지 레지스트리(Pub.dev, npm, JSR) 및 클라우드 API 도메인 외의 외부 네트워크 연결을 차단해야 합니다.
*   **Implementation**: StepSecurity 등을 사용하여 잡 단위의 아웃바운드 트래픽 로그를 기록하고 이상 징후를 감지합니다.

---

## ⚡ Section 3: 릴리즈 무결성 및 검증 정책 (Release Integrity)

### [Rule 3.1] Software Bill of Materials (SBOM) 통합
*   **Policy**: 모든 릴리즈 아티팩트는 서명된 **SBOM**(SPDX 또는 CycloneDX 형식)을 동반해야 합니다.
*   **Rationale**: 아티팩트에 포함된 모든 오픈소스 라이브러리와 종속성의 목록을 투명하게 공개하고 취약점 스캔을 용이하게 합니다.

### [Rule 3.2] Non-bypassable Deployment Gates
*   **Policy**: 프로덕션 배포 파이프라인은 반드시 다음 두 가지 게이트를 통과해야 합니다.
    1. **Attestation Verification**: 빌드 증명 검증 성공.
    2. **Security Scan**: 고위험(Critical/High) 취약점 제로 상태 확인.

---

## 🛠️ 시니어 리뷰어 체크리스트 (Summary Checklist)

1.  [ ] **Attestation**: 프로덕션 아티팩트에 대해 `actions/attest`가 실행되었는가?
2.  [ ] **SHA Pinning**: 모든 `uses:` 절에 커밋 SHA가 명시되었는가?
3.  [ ] **OIDC**: 정적 시크릿 대신 `id-token: write`를 통한 임시 인증을 사용하는가?
4.  [ ] **Permissions**: 워크플로우 및 잡 단위의 권한(permissions)이 최소화되었는가?
5.  [ ] **SBOM**: 배포 바이너리에 대한 종속성 리스트(SBOM)가 생성되고 서명되었는가?
6.  [ ] **Verification**: 배포 스크립트에 `gh attestation verify` 단계가 포함되었는가?
