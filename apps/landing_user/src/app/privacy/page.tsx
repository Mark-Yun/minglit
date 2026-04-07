import React from 'react';

export default function PrivacyPage() {
  return (
    <div className="max-w-3xl mx-auto px-6 py-12 text-gray-800 font-sans">
      <h1 className="text-3xl font-bold text-gray-900 mb-8 pb-4 border-b-2 border-gray-900 text-center">
        개인정보 처리방침
      </h1>

      <p className="text-sm leading-relaxed mb-8 bg-gray-50 p-4 rounded-xl border border-gray-100">
        <strong>밍글릿(Minglit)</strong>(이하 &apos;회사&apos;)은 정보통신망 이용촉진 및 정보보호 등에 관한 법률, 개인정보보호법 등 관련 법령을 준수하며, 이용자의 개인정보 보호를 위해 최선을 다하고 있습니다.
      </p>

      {/* 1. 수집 항목 및 목적 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          1. 개인정보의 수집 항목 및 목적
        </h2>
        
        <div className="space-y-6">
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">1) 수집 항목</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              {/* Fix #1141: 회원가입 수집 항목을 실제 수집 항목과 일치하도록 수정 */}
              <li><strong>회원가입:</strong> 이름, 이메일, 프로필 사진, 관심 태그, 기기 정보, 이용 기록</li>
              <li><strong>본인확인:</strong> 이름, 생년월일, 성별, 내/외국인 정보, 휴대폰 번호, CI/DI (연계정보)</li>
              <li><strong>자격 인증(선택):</strong> 직업, 소속, 직무, 증빙 서류(명함, 재직증명서, 자격증 사본 등)</li>
              <li><strong>결제 및 서비스 이용:</strong> 결제 기록(카드사, 승인번호 등), 접속 로그, 쿠키, 서비스 이용 기록</li>
              {/* Fix #1157: 관심 태그 수집 항목 추가 */}
              <li><strong>서비스 이용(선택):</strong> 관심 태그 (이벤트 추천 목적, 회원 탈퇴 시 즉시 파기)</li>
              {/* Fix #762: marketing_consent 수집 항목 추가 */}
              <li><strong>마케팅 수신 동의(선택):</strong> 마케팅 수신 동의 여부</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">2) 수집 및 이용 목적</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>회원제 서비스 이용에 따른 본인 식별 및 가입 의사 확인</li>
              <li><strong>모임 참여 자격 확인 및 파트너 승인 심사</strong></li>
              <li>서비스 이행(QR 체크인) 및 결제·정산 처리</li>
              <li>부정 이용 방지 및 비인가 사용 방지</li>
            </ul>
          </div>
        </div>
      </section>

      {/* 2. 처리 및 보유 기간 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          2. 개인정보의 처리 및 보유 기간
        </h2>
        <p className="text-sm text-gray-600 mb-4">
          회사는 원칙적으로 개인정보 수집 및 이용 목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다. 단, 다음의 정보는 아래의 이유로 명시한 기간 동안 보존합니다.
        </p>

        <h3 className="font-bold mb-3 text-gray-900 text-base">1) 회사 내부 방침에 의한 정보 보유</h3>
        <ul className="list-disc pl-5 mb-6 space-y-2 text-sm text-gray-600">
          <li><strong>자격 인증 정보(증빙 서류):</strong> <span className="font-bold text-gray-900">1년</span> (최신성 유지 및 재인증 편의 제공)</li>
          <li><strong>부정 이용 기록:</strong> 1년 (재가입 방지 및 분쟁 해결)</li>
          {/* Fix #1157: 관심 태그 보유기간 명시 — 탈퇴 시 즉시 파기 */}
          <li><strong>관심 태그, 이용 기록, 기기 정보:</strong> 회원 탈퇴 시 즉시 파기</li>
        </ul>

        <h3 className="font-bold mb-3 text-gray-900 text-base">2) 관련 법령에 의한 정보 보유</h3>
        <div className="overflow-x-auto">
          <table className="w-full text-xs text-left border-collapse border border-gray-200">
            <thead className="bg-gray-50 text-gray-700">
              <tr>
                <th className="p-3 border border-gray-200">보존 항목</th>
                <th className="p-3 border border-gray-200">근거 법령</th>
                <th className="p-3 border border-gray-200">보존 기간</th>
              </tr>
            </thead>
            <tbody className="text-gray-600">
              <tr>
                <td className="p-3 border border-gray-200">계약 또는 청약철회 등에 관한 기록</td>
                <td className="p-3 border border-gray-200">전자상거래법</td>
                <td className="p-3 border border-gray-200">5년</td>
              </tr>
              <tr>
                <td className="p-3 border border-gray-200">대금결제 및 재화 등의 공급에 관한 기록</td>
                <td className="p-3 border border-gray-200">전자상거래법</td>
                <td className="p-3 border border-gray-200">5년</td>
              </tr>
              <tr>
                <td className="p-3 border border-gray-200">소비자의 불만 또는 분쟁처리에 관한 기록</td>
                <td className="p-3 border border-gray-200">전자상거래법</td>
                <td className="p-3 border border-gray-200">3년</td>
              </tr>
              <tr>
                <td className="p-3 border border-gray-200">로그인 기록</td>
                <td className="p-3 border border-gray-200">통신비밀보호법</td>
                <td className="p-3 border border-gray-200">3개월</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      {/* 3. 제3자 제공 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          3. 개인정보의 제3자 제공
        </h2>
        <p className="text-sm text-gray-600 mb-4">
          회사는 이용자의 동의 없이 개인정보를 외부에 제공하지 않습니다. 단, 서비스 이행을 위해 아래와 같이 제공합니다.
        </p>
        <div className="overflow-x-auto mb-4">
          <table className="w-full text-xs text-left border-collapse border border-gray-200">
            <thead className="bg-gray-50 text-gray-700">
              <tr>
                <th className="p-3 border border-gray-200">제공받는 자</th>
                <th className="p-3 border border-gray-200">제공 목적</th>
                <th className="p-3 border border-gray-200">제공 항목</th>
                <th className="p-3 border border-gray-200">보유 기간</th>
              </tr>
            </thead>
            <tbody className="text-gray-600">
              <tr>
                <td className="p-3 border border-gray-200 font-bold text-gray-900">모임 주최자(파트너)</td>
                <td className="p-3 border border-gray-200">참여 승인 심사, 본인 확인, 출석 체크</td>
                {/* Fix #1141: 제공 항목에서 이메일 제거, 이름(닉네임)/연령대/자격 인증 정보로 수정 — 보유기간 30일로 통일 */}
                <td className="p-3 border border-gray-200">이름(닉네임), 연령대, 자격 인증 정보(직업/소속 — 본인인증 완료 유저만)</td>
                <td className="p-3 border border-gray-200 font-bold">이벤트 종료 후 30일</td>
              </tr>
            </tbody>
          </table>
        </div>
        <p className="text-sm font-bold text-gray-900 bg-gray-50 p-3 rounded-lg border border-gray-100">
          ※ 이용자는 파트너에 대한 정보 제공을 거부할 수 있으며(조회 제한 설정), 이 경우 파트너 승인이 필요한 모임 참여가 제한될 수 있습니다.
        </p>
      </section>

      {/* Fix #762: 제4조 해외 이전 고지 + 위탁 업체 업데이트 */}
      {/* 4. 처리 위탁 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          4. 개인정보 처리의 위탁
        </h2>

        <h3 className="font-bold mb-3 text-gray-900 text-base">1) 국내 위탁</h3>
        <ul className="list-disc pl-5 mb-6 space-y-2 text-sm text-gray-600">
          <li><strong>결제 처리:</strong> 포트원, KG이니시스 등 PG사</li>
          <li><strong>본인 확인:</strong> 다날, 나이스평가정보 등 본인확인 기관</li>
          <li><strong>알림 발송:</strong> 카카오(알림톡), 문자 발송 대행사</li>
        </ul>

        <h3 className="font-bold mb-3 text-gray-900 text-base">2) 국외 이전 (개인정보보호법 제28조의8)</h3>
        <p className="text-sm text-gray-600 mb-4">
          회사는 서비스 제공을 위해 아래와 같이 개인정보를 국외로 이전하고 있습니다.
        </p>
        <div className="overflow-x-auto">
          <table className="w-full text-xs text-left border-collapse border border-gray-200">
            <thead className="bg-gray-50 text-gray-700">
              <tr>
                <th className="p-3 border border-gray-200">수탁자</th>
                <th className="p-3 border border-gray-200">국가</th>
                <th className="p-3 border border-gray-200">위탁 업무</th>
                <th className="p-3 border border-gray-200">이전 항목</th>
              </tr>
            </thead>
            <tbody className="text-gray-600">
              <tr>
                <td className="p-3 border border-gray-200 font-bold text-gray-900">Supabase Inc.</td>
                <td className="p-3 border border-gray-200">미국</td>
                <td className="p-3 border border-gray-200">서버 운영, DB 호스팅</td>
                <td className="p-3 border border-gray-200">전체 개인정보</td>
              </tr>
              <tr>
                <td className="p-3 border border-gray-200 font-bold text-gray-900">Vercel Inc.</td>
                <td className="p-3 border border-gray-200">미국</td>
                <td className="p-3 border border-gray-200">웹 호스팅</td>
                <td className="p-3 border border-gray-200">접속 로그</td>
              </tr>
              <tr>
                <td className="p-3 border border-gray-200 font-bold text-gray-900">Sentry (Functional Software Inc.)</td>
                <td className="p-3 border border-gray-200">미국</td>
                <td className="p-3 border border-gray-200">에러 모니터링</td>
                <td className="p-3 border border-gray-200">에러 로그 (개인정보 포함 가능)</td>
              </tr>
              <tr>
                <td className="p-3 border border-gray-200 font-bold text-gray-900">Axiom Inc.</td>
                <td className="p-3 border border-gray-200">미국</td>
                <td className="p-3 border border-gray-200">로그 수집</td>
                <td className="p-3 border border-gray-200">서비스 로그 (개인정보 포함 가능)</td>
              </tr>
              <tr>
                <td className="p-3 border border-gray-200 font-bold text-gray-900">Statsig Inc.</td>
                <td className="p-3 border border-gray-200">미국</td>
                <td className="p-3 border border-gray-200">서비스 분석</td>
                <td className="p-3 border border-gray-200">이용자 ID, 이벤트 데이터</td>
              </tr>
              <tr>
                <td className="p-3 border border-gray-200 font-bold text-gray-900">OpenAI Inc.</td>
                <td className="p-3 border border-gray-200">미국</td>
                <td className="p-3 border border-gray-200">프로필 임베딩 생성</td>
                <td className="p-3 border border-gray-200">프로필 텍스트</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      {/* 5. 파기 절차 및 방법 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          5. 개인정보의 파기 절차 및 방법
        </h2>
        <ul className="list-disc pl-5 space-y-3 text-sm text-gray-600">
          <li><strong>파기 절차:</strong> 목적이 달성된 정보는 별도의 DB로 옮겨져 내부 방침 및 기타 관련 법령에 의한 정보보호 사유에 따라 일정 기간 저장된 후 파기됩니다.</li>
          <li><strong>파기 방법:</strong> 전자적 파일 형태는 기술적 방법을 사용하여 삭제하며, 종이 문서는 분쇄하거나 소각합니다.</li>
        </ul>
      </section>

      {/* 6. 이용자의 권리 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          6. 이용자의 권리와 행사 방법
        </h2>
        <p className="text-sm text-gray-600 leading-relaxed">
          이용자는 언제든지 자신의 개인정보를 조회하거나 수정할 수 있으며, 수집 및 이용에 대한 동의 철회(회원탈퇴)를 요청할 수 있습니다. 앱 내 [설정 &gt; 계정 관리] 메뉴 또는 고객센터를 통해 가능합니다.
        </p>
      </section>

      {/* 7. 책임자 정보 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          7. 개인정보 보호책임자 및 담당 부서
        </h2>
        <div className="bg-gray-50 p-6 rounded-2xl border border-gray-100 text-sm text-gray-600">
          <ul className="space-y-2">
            <li><span className="font-bold text-gray-900 w-20 inline-block">성명</span> 윤민혁</li>
            <li><span className="font-bold text-gray-900 w-20 inline-block">직책</span> 대표</li>
            <li><span className="font-bold text-gray-900 w-20 inline-block">연락처</span> contact@minglit.com</li>
          </ul>
        </div>
      </section>

      <footer className="mt-20 pt-10 border-t border-gray-100 text-xs text-gray-400 space-y-1">
        <p>공고일자: 2026년 3월 29일</p>
        <p>시행일자: 2026년 4월 5일</p>
        <p className="mt-4">© 2026 Minglit. All rights reserved.</p>
      </footer>
    </div>
  );
}
