import React from 'react';

export default function PartnerTermsPage() {
  return (
    <div className="max-w-3xl mx-auto px-6 py-12 text-gray-800 font-sans">
      <h1 className="text-2xl font-bold text-gray-900 mb-10 pb-4 border-b-2 border-[#6C3CE1] text-center">
        파트너 서비스 이용약관
      </h1>

      {/* Section 1: 서비스 이용약관 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          1. 서비스 이용약관
        </h2>

        <div className="space-y-6">
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제1조 (목적)</h3>
            <p className="text-sm text-gray-600">
              본 약관은 밍글릿(이하 &apos;회사&apos;)이 제공하는 파트너 서비스의 이용에 관한 회사와 파트너(모임 주최자/사업자) 간의 권리·의무 및 책임 사항을 규정함을 목적으로 합니다.
            </p>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제2조 (통신판매중개자로서의 지위 및 면책)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>회사는 모임 주최자(이하 &apos;파트너&apos;)와 참여자 간의 거래를 위한 시스템을 제공하는 <strong>통신판매중개자</strong>입니다.</li>
              <li>모임의 운영, 품질, 안전에 대한 책임은 해당 파트너에게 있으며, 회사는 고의 또는 중과실이 없는 한 모임 중 발생한 도난, 상해, 분쟁 등에 대해 책임을 지지 않습니다.</li>
              <li>천재지변, 서버 점검, 네트워크 장애 등 불가항력적인 사유로 서비스가 중단될 경우 회사는 면책됩니다.</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제3조 (파트너 가입 및 자격)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>파트너 가입 시 <strong>사업자등록번호, 상호, 대표자명</strong> 등 사업자 정보를 제출해야 합니다. 개인사업자와 법인 모두 가입 가능합니다.</li>
              <li>허위 정보를 제출한 것이 확인될 경우, 회사는 즉시 계약을 해지할 수 있습니다.</li>
              <li>유료 행사를 주최하려는 파트너는 사업자 등록이 필수이며, 무료 행사는 개인도 주최할 수 있습니다.</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제4조 (파트너의 의무 및 책임)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li><strong>행사 정보의 정확성:</strong> 파트너는 행사의 일시, 장소, 자격 조건, 상세 내용 등을 실제와 다름없이 등록해야 합니다. 허위 정보로 인한 모든 법적 책임은 파트너에게 있습니다.</li>
              <li><strong>안전 관리:</strong> 파트너는 행사 진행 시 참여자의 신체적, 정신적 안전을 최우선으로 고려해야 하며, 현장에서 발생한 사고에 대한 1차적 책임은 파트너에게 귀속됩니다.</li>
              <li><strong>성실 이행:</strong> 파트너는 정해진 시간에 행사를 시작해야 하며, 임의로 행사를 취소하거나 참여자의 승인을 번복하여 신뢰를 저해해서는 안 됩니다.</li>
              <li><strong>관련 법규 준수:</strong> 공연법, 소방법, 식품위생법 등 행사와 관련된 법규를 준수해야 합니다.</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제5조 (금지 행위)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>허위 행사 등록</li>
              <li>회사가 제공하는 결제 시스템을 이용하지 않고 직접 송금을 유도하거나 요구하는 행위(직거래)</li>
              <li>허위 참여 인증</li>
              <li>후기 조작</li>
              <li>다른 파트너의 영업 방해</li>
            </ul>
            <div className="bg-amber-50 border-l-4 border-amber-300 p-4 mt-4 rounded-r-xl">
              <p className="text-sm font-bold text-amber-800">
                직거래가 확인될 경우 파트너는 서비스 이용이 영구 제한되며, 발생한 피해에 대해 회사는 책임지지 않습니다.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Section 2: 수수료 및 정산 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          2. 수수료 및 정산
        </h2>

        <div className="space-y-6">
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제1조 (서비스 수수료)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>회사는 행사 결제 대금의 일정 비율을 서비스 수수료로 부과합니다. 구체적인 수수료율은 별도 안내 및 파트너 대시보드에서 확인할 수 있습니다.</li>
              <li>수수료율 변경 시 회사는 <strong>30일 전</strong>에 사전 공지합니다.</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제2조 (정산)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>정산은 <strong>매주</strong> 정기적으로 처리됩니다.</li>
              <li>정산 시 서비스 수수료를 공제한 후 실정산액을 파트너에게 지급합니다.</li>
              <li>정산 처리는 포트원, KG이니시스 등 PG사에 위탁하여 처리됩니다.</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제3조 (정산 보류)</h3>
            <p className="text-sm text-gray-600 mb-2">다음의 경우 회사는 정산을 보류할 수 있습니다.</p>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>이상 거래가 의심되는 경우</li>
              <li>법원의 가압류·압류 명령이 있는 경우</li>
              <li>관계 법령 위반으로 조사가 진행 중인 경우</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제4조 (환불 및 취소 시 파트너 책임)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>참여자 환불 규정은 유저 이용약관(취소 및 환불 규정)과 연동됩니다.</li>
              <li>파트너의 귀책으로 인한 행사 취소 시: <strong>전액 환불 + 페널티</strong>가 부여됩니다.</li>
              <li>파트너가 허위로 참여 인증을 하거나, 정상적인 서비스 이행이 확인되지 않은 경우 회사는 정산 대금을 보류할 수 있습니다.</li>
            </ul>
          </div>
        </div>
      </section>

      {/* Section 3: 계약 해지 및 탈퇴 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          3. 계약 해지 및 탈퇴
        </h2>

        <div className="space-y-6">
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제1조 (회사의 해지 권한)</h3>
            <p className="text-sm text-gray-600 mb-2">다음의 경우 회사는 파트너 계약을 해지할 수 있습니다.</p>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>관계 법령을 위반한 경우</li>
              <li>장기간 서비스 이용이 없는 경우</li>
              <li>참여자의 안전을 위협하는 행위를 한 경우</li>
              <li>반복적인 민원이 접수되어 시정 요구에 응하지 않은 경우</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제2조 (파트너 탈퇴)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>파트너는 미완료 행사와 미정산 잔액을 모두 해소한 후 탈퇴할 수 있습니다.</li>
              <li>탈퇴 후 개인정보는 관계 법령에 따른 보관 기간 동안 보관되며, 그 이후에는 즉시 파기됩니다.</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제3조 (관계 부인)</h3>
            <p className="text-sm text-gray-600">
              회사와 파트너는 독립적인 계약 관계이며, 본 약관은 어떠한 경우에도 프리랜서, 가맹, 고용, 대리 또는 합작 관계를 생성하지 않습니다.
            </p>
          </div>
        </div>
      </section>

      {/* Fix #1450: 일반 조항 추가 — 약관변경/손해배상/분쟁해결/서비스변경/지적재산권/준거법 */}
      {/* Section 4: 일반 조항 */}
      <section className="mb-12">
        <h2 className="text-base font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-[3px] h-4 bg-[#6C3CE1] mr-3 rounded-full" />
          4. 일반 조항
        </h2>

        <div className="space-y-6">
          <div>
            {/* Fix #1450: 약관 변경 고지 절차 (약관규제법 제3조, 전자상거래법 제21조의2) */}
            <h3 className="font-bold mb-3 text-gray-900 text-base">제1조 (약관의 게시 및 변경)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>본 약관의 내용은 서비스 화면에 게시하거나 기타 방법으로 파트너에게 공지합니다.</li>
              <li>회사는 약관을 변경할 경우 적용일 <strong>7일 전</strong>부터 변경 내용을 서비스 내 공지합니다. 다만, 파트너에게 불리한 변경인 경우 <strong>30일 전</strong>부터 공지하며, 이메일 또는 앱 내 알림으로 개별 통지합니다.</li>
              <li>파트너가 변경된 약관의 적용일 이후에도 서비스를 계속 이용하는 경우 변경된 약관에 동의한 것으로 봅니다.</li>
            </ul>
          </div>

          <div>
            {/* Fix #1450: 손해배상 — 파트너 특성 반영 (허위 정보, 직거래 위반) */}
            <h3 className="font-bold mb-3 text-gray-900 text-base">제2조 (손해배상)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>회사는 회사의 귀책사유로 인해 파트너에게 손해가 발생한 경우 그 손해를 배상할 책임이 있습니다.</li>
              <li>파트너가 허위 정보 제출, 직거래 유도, 허위 참여 인증 등 본 약관을 위반하여 회사 또는 제3자에게 손해를 입힌 경우, 해당 파트너는 그 손해를 배상하여야 합니다.</li>
              <li>회사는 천재지변, 전쟁, 기간통신사업자의 서비스 중지 등 불가항력적인 사유로 서비스를 제공할 수 없는 경우에는 책임을 부담하지 않습니다.</li>
            </ul>
          </div>

          <div>
            {/* Fix #1450: 분쟁해결 절차 (약관규제법 제14조, 전자상거래법 제33조) */}
            <h3 className="font-bold mb-3 text-gray-900 text-base">제3조 (분쟁해결)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>본 약관과 관련하여 분쟁이 발생한 경우, 회사와 파트너는 원만한 해결을 위해 성실히 협의합니다.</li>
              <li>협의로 해결되지 않은 경우, 민사소송법에 따른 관할법원을 전속적 합의관할로 합니다.</li>
            </ul>
          </div>

          <div>
            {/* Fix #1450: 서비스 변경/중단 고지 의무 (전자상거래법 제13조) */}
            <h3 className="font-bold mb-3 text-gray-900 text-base">제4조 (서비스 변경 및 중단)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>회사는 상당한 이유가 있는 경우 서비스의 전부 또는 일부를 변경할 수 있으며, 변경 시 사전에 공지합니다.</li>
              <li>회사가 서비스를 종료하고자 하는 경우 종료일 <strong>30일 전</strong>까지 서비스 내 공지 및 이메일 등으로 파트너에게 알립니다.</li>
            </ul>
          </div>

          <div>
            {/* Fix #1450: 지적재산권 조항 추가 */}
            <h3 className="font-bold mb-3 text-gray-900 text-base">제5조 (지적재산권)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>서비스에 대한 저작권 및 지적재산권은 회사에 귀속됩니다.</li>
              <li>파트너가 서비스 내에 등록한 행사 정보 및 콘텐츠의 저작권은 해당 파트너에게 있습니다.</li>
            </ul>
          </div>

          <div>
            {/* Fix #1450: 준거법 추가 */}
            <h3 className="font-bold mb-3 text-gray-900 text-base">제6조 (준거법 및 재판관할)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>본 약관의 해석 및 분쟁에 관하여는 대한민국 법령을 적용합니다.</li>
            </ul>
          </div>
        </div>
      </section>

      {/* Section 5: Footer */}
      <footer className="mt-20 pt-10 border-t border-gray-100 bg-gray-50 p-8 rounded-2xl">
        <ul className="space-y-2 text-sm text-gray-600">
          <li><span className="font-bold text-gray-900 w-32 inline-block">상호</span> 밍글릿</li>
          <li><span className="font-bold text-gray-900 w-32 inline-block">대표자</span> 윤민혁</li>
          <li><span className="font-bold text-gray-900 w-32 inline-block">사업자등록번호</span> 747-53-00880</li>
        </ul>
        <p className="mt-8 text-xs text-gray-500">© 2026 Minglit. All rights reserved.</p>
      </footer>
    </div>
  );
}
