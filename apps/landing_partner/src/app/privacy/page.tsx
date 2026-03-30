import React from 'react';

export default function PartnerPrivacyPage() {
  return (
    <div className="max-w-3xl mx-auto px-6 py-12 text-gray-800 font-sans">
      <h1 className="text-2xl font-bold text-gray-900 mb-4 pb-4 border-b-2 border-[#6C3CE1] text-center">
        파트너 개인정보처리방침
      </h1>
      <p className="text-sm text-gray-600 mb-12 text-center">
        밍글릿이 파트너(모임 주최자)의 개인정보를 처리하는 방침을 안내드립니다.
      </p>

      {/* Section 1: 수집 항목 및 목적 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          1. 개인정보의 수집 항목 및 목적
        </h2>
        <div className="overflow-x-auto">
          <table className="w-full text-xs border-collapse">
            <thead>
              <tr className="bg-[#F5F0FF]">
                <th className="text-left p-3 text-[#6C3CE1] font-bold border-b">분류</th>
                <th className="text-left p-3 text-[#6C3CE1] font-bold border-b">수집 항목</th>
                <th className="text-left p-3 text-[#6C3CE1] font-bold border-b">수집 목적</th>
              </tr>
            </thead>
            <tbody className="text-gray-600">
              <tr className="border-b border-gray-100">
                <td className="p-3">파트너 가입</td>
                <td className="p-3">이메일, 비밀번호</td>
                <td className="p-3">계정 생성 및 로그인</td>
              </tr>
              <tr className="border-b border-gray-100">
                <td className="p-3">사업자 신원 확인</td>
                <td className="p-3">사업자등록번호, 상호, 대표자명, 업태/종목</td>
                <td className="p-3">파트너 자격 확인, 계약 이행</td>
              </tr>
              <tr className="border-b border-gray-100">
                <td className="p-3">정산</td>
                <td className="p-3">은행명, 계좌번호, 예금주, 통장 사본</td>
                <td className="p-3">수익금 정산 처리</td>
              </tr>
              <tr className="border-b border-gray-100">
                <td className="p-3">대표자 본인확인</td>
                <td className="p-3">이름, 생년월일, 연락처</td>
                <td className="p-3">본인 확인, 계약 체결</td>
              </tr>
              <tr className="border-b border-gray-100">
                <td className="p-3">행사 운영</td>
                <td className="p-3">행사명, 장소, 일시, 참가자 현황</td>
                <td className="p-3">서비스 제공</td>
              </tr>
              <tr>
                <td className="p-3">서비스 이용</td>
                <td className="p-3">접속 로그, 쿠키, 서비스 이용 기록</td>
                <td className="p-3">부정 이용 방지, 서비스 개선</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      {/* Section 2: 보유 기간 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          2. 개인정보의 처리 및 보유 기간
        </h2>
        <p className="text-sm text-gray-600 mb-4">
          원칙적으로 개인정보의 수집 및 이용 목적이 달성되면 지체 없이 파기합니다. 단, 관계 법령에 따라 일정 기간 보관합니다.
        </p>
        <div className="overflow-x-auto">
          <table className="w-full text-xs border-collapse">
            <thead>
              <tr className="bg-[#F5F0FF]">
                <th className="text-left p-3 text-[#6C3CE1] font-bold border-b">보존 항목</th>
                <th className="text-left p-3 text-[#6C3CE1] font-bold border-b">근거 법령</th>
                <th className="text-left p-3 text-[#6C3CE1] font-bold border-b">보존 기간</th>
              </tr>
            </thead>
            <tbody className="text-gray-600">
              <tr className="border-b border-gray-100">
                <td className="p-3">계약 또는 청약철회 등에 관한 기록</td>
                <td className="p-3">전자상거래법</td>
                <td className="p-3">5년</td>
              </tr>
              <tr className="border-b border-gray-100">
                <td className="p-3">대금결제 및 재화 등의 공급에 관한 기록</td>
                <td className="p-3">전자상거래법</td>
                <td className="p-3">5년</td>
              </tr>
              <tr className="border-b border-gray-100">
                <td className="p-3">소비자 불만 또는 분쟁처리에 관한 기록</td>
                <td className="p-3">전자상거래법</td>
                <td className="p-3">3년</td>
              </tr>
              <tr className="border-b border-gray-100">
                <td className="p-3">세금계산서 등 세무 관련 기록</td>
                <td className="p-3">부가가치세법</td>
                <td className="p-3">5년</td>
              </tr>
              <tr>
                <td className="p-3">로그인 기록</td>
                <td className="p-3">통신비밀보호법</td>
                <td className="p-3">3개월</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      {/* Section 3: 제3자 제공 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          3. 개인정보의 제3자 제공
        </h2>
        <p className="text-sm text-gray-600">
          회사는 파트너의 개인정보를 제3자에게 제공하지 않습니다. 단, 행사 참여자에게 파트너의 <strong>상호</strong> 및 <strong>대표자명</strong>을 주최자 확인 목적으로 제공할 수 있습니다.
        </p>
      </section>

      {/* Section 4: 위탁 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          4. 개인정보 처리의 위탁
        </h2>
        <p className="text-sm text-gray-600 mb-4">
          회사는 원활한 서비스 제공을 위해 다음과 같이 개인정보 처리를 위탁하고 있습니다.
        </p>
        <div className="overflow-x-auto">
          <table className="w-full text-xs border-collapse">
            <thead>
              <tr className="bg-[#F5F0FF]">
                <th className="text-left p-3 text-[#6C3CE1] font-bold border-b">수탁자</th>
                <th className="text-left p-3 text-[#6C3CE1] font-bold border-b">위탁 업무</th>
              </tr>
            </thead>
            <tbody className="text-gray-600">
              <tr className="border-b border-gray-100">
                <td className="p-3">포트원, KG이니시스</td>
                <td className="p-3">결제 및 정산 처리</td>
              </tr>
              <tr className="border-b border-gray-100">
                <td className="p-3">다날, 나이스평가정보</td>
                <td className="p-3">본인 확인</td>
              </tr>
              <tr className="border-b border-gray-100">
                <td className="p-3">카카오(알림톡), 문자 발송 대행사</td>
                <td className="p-3">알림 발송</td>
              </tr>
              <tr>
                <td className="p-3">Supabase, Vercel</td>
                <td className="p-3">서버 운영 및 인프라</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      {/* Section 5: 국외 이전 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          5. 개인정보의 국외 이전
        </h2>
        <div className="overflow-x-auto mb-4">
          <table className="w-full text-xs border-collapse">
            <thead>
              <tr className="bg-[#F5F0FF]">
                <th className="text-left p-3 text-[#6C3CE1] font-bold border-b">항목</th>
                <th className="text-left p-3 text-[#6C3CE1] font-bold border-b">내용</th>
              </tr>
            </thead>
            <tbody className="text-gray-600">
              <tr className="border-b border-gray-100">
                <td className="p-3">수탁업체</td>
                <td className="p-3">Supabase Inc.</td>
              </tr>
              <tr className="border-b border-gray-100">
                <td className="p-3">소재지</td>
                <td className="p-3">미국 캘리포니아주</td>
              </tr>
              <tr className="border-b border-gray-100">
                <td className="p-3">이전 항목</td>
                <td className="p-3">본 처리방침에 기재된 수집 항목 전체</td>
              </tr>
              <tr className="border-b border-gray-100">
                <td className="p-3">이전 목적</td>
                <td className="p-3">데이터베이스 운영 및 서버 인프라 관리</td>
              </tr>
              <tr>
                <td className="p-3">보유 기간</td>
                <td className="p-3">회원 탈퇴 또는 계약 종료 후 관계 법령에 따른 보관 기간까지</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div className="bg-amber-50 border-l-4 border-amber-300 p-4 rounded-r-xl">
          <p className="text-sm font-bold text-amber-800">
            국외 이전에 대한 구체적인 사항은 국내 법령(개인정보보호법 제28조)을 준수하며, 이용자의 권리를 보장합니다.
          </p>
        </div>
      </section>

      {/* Section 6: 파기 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          6. 개인정보의 파기 절차 및 방법
        </h2>
        <div className="space-y-4">
          <div>
            <h3 className="font-bold mb-2 text-gray-900 text-sm">파기 절차</h3>
            <p className="text-sm text-gray-600">
              파트너가 회원 탈퇴를 요청하거나 개인정보의 수집·이용 목적이 달성된 후, 해당 정보를 지체 없이 파기합니다. 단, 관계 법령에 따라 보존해야 하는 정보는 법정 보유 기간 동안 안전하게 보관합니다.
            </p>
          </div>
          <div>
            <h3 className="font-bold mb-2 text-gray-900 text-sm">파기 방법</h3>
            <p className="text-sm text-gray-600">
              전자적 파일 형태로 저장된 개인정보는 복구 불가능한 방법으로 영구 삭제하며, 종이 문서는 분쇄기로 분쇄 또는 소각합니다.
            </p>
          </div>
        </div>
      </section>

      {/* Section 7: 이용자 권리 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          7. 이용자의 권리와 행사 방법
        </h2>
        <p className="text-sm text-gray-600">
          파트너는 언제든지 자신의 개인정보를 조회·수정·삭제할 수 있으며, 처리 정지를 요구할 수 있습니다. 이용자 권리 행사는 파트너 대시보드 내 <strong>[설정 &gt; 계정 관리]</strong> 또는 고객센터(<a href="mailto:contact@minglit.com" className="text-[#6C3CE1] underline">contact@minglit.com</a>)를 통해 요청할 수 있습니다.
        </p>
      </section>

      {/* Section 8: 안전성 확보 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          8. 개인정보의 안전성 확보 조치
        </h2>
        <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
          <li><strong>암호화:</strong> 비밀번호는 단방향 해시로 저장되며, 민감 정보는 전송 구간 TLS 1.2+ 암호화를 적용합니다.</li>
          <li><strong>접근 제한:</strong> 개인정보 처리 시스템에 대한 접근 권한을 최소 권한 원칙에 따라 관리합니다.</li>
          <li><strong>로그 관리:</strong> 개인정보 처리 시스템의 접속 기록은 관계 법령에 따른 기간 동안 보관 및 관리합니다.</li>
          <li><strong>물리적 보안:</strong> 서버실 출입 통제 및 문서 보관 시 잠금장치를 설치합니다.</li>
        </ul>
      </section>

      {/* Section 9: 자동화 결정 거부권 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          9. 자동화된 결정에 대한 거부·설명 요구권
        </h2>
        <p className="text-sm text-gray-600">
          현재 밍글릿은 자동화된 결정(프로파일링 등)을 적용하고 있지 않습니다. 향후 자동화된 결정을 도입할 경우 사전 고지하고 이용자의 거부권을 보장합니다.
        </p>
      </section>

      {/* Section 10: 보호책임자 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          10. 개인정보 보호책임자
        </h2>
        <div className="bg-[#F5F0FF] p-6 rounded-2xl">
          <ul className="space-y-2 text-sm text-gray-600">
            <li><span className="font-bold text-gray-900 w-24 inline-block">성명</span> 윤민혁</li>
            <li><span className="font-bold text-gray-900 w-24 inline-block">직책</span> 대표</li>
            <li><span className="font-bold text-gray-900 w-24 inline-block">연락처</span> <a href="mailto:contact@minglit.com" className="text-[#6C3CE1] underline">contact@minglit.com</a></li>
          </ul>
        </div>
      </section>

      {/* Footer */}
      <footer className="mt-20 pt-10 border-t border-gray-100 bg-gray-50 p-8 rounded-2xl">
        <ul className="space-y-2 text-sm text-gray-600">
          <li><span className="font-bold text-gray-900 w-32 inline-block">공고일자</span> 2026년 3월 30일</li>
          <li><span className="font-bold text-gray-900 w-32 inline-block">시행일자</span> 2026년 3월 30일</li>
        </ul>
        <p className="mt-8 text-xs text-gray-500">© 2026 Minglit. All rights reserved.</p>
      </footer>
    </div>
  );
}
