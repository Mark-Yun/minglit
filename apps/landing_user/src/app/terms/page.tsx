import React from 'react';

export default function TermsPage() {
  return (
    <div className="max-w-3xl mx-auto px-6 py-12 text-gray-800 font-sans">
      <h1 className="text-3xl font-bold text-gray-900 mb-10 pb-4 border-b-2 border-gray-900 text-center">
        서비스 이용약관 및 정책
      </h1>

      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          1. 서비스 이용약관
        </h2>
        
        <div className="space-y-6">
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제1조 (통신판매중개자로서의 지위 및 면책)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>회사는 모임 주최자(이하 &apos;파트너&apos;)와 참여자 간의 거래를 위한 시스템을 제공하는 <strong>통신판매중개자</strong>입니다.</li>
              <li>모임의 운영, 품질, 안전에 대한 책임은 해당 파트너에게 있으며, 회사는 고의 또는 중과실이 없는 한 모임 중 발생한 도난, 상해, 분쟁 등에 대해 책임을 지지 않습니다.</li>
              <li>천재지변, 서버 점검, 네트워크 장애 등 불가항력적인 사유로 서비스가 중단될 경우 회사는 면책됩니다.</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제2조 (파트너의 의무 및 책임)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li><strong>정보의 정확성:</strong> 파트너는 모임의 일시, 장소, 자격 조건, 상세 내용 등을 실제와 다름없이 등록해야 합니다. 허위 정보로 인한 모든 법적 책임은 파트너에게 있습니다.</li>
              <li><strong>안전 관리:</strong> 파트너는 모임 진행 시 참여자의 신체적, 정신적 안전을 최우선으로 고려해야 하며, 현장에서 발생한 사고에 대한 1차적 책임은 파트너에게 귀속됩니다.</li>
              <li><strong>성실 이행:</strong> 파트너는 정해진 시간에 모임을 시작해야 하며, 임의로 모임을 취소하거나 참여자의 승인을 번복하여 신뢰를 저해해서는 안 됩니다.</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제3조 (안전 및 커뮤니티 가이드라인)</h3>
            <p className="text-sm text-gray-600 mb-2">회원은 오프라인 모임 시 다음 각 호의 안전 수칙을 준수해야 하며, 위반 시 즉시 강제 탈퇴 및 재가입이 제한됩니다.</p>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>타인에 대한 성희롱, 폭언, 폭행 및 불쾌감을 주는 행위 금지</li>
              <li>모임 내에서의 불법적인 물품 판매 및 사행성 행위 금지</li>
              <li>모임 성격과 관계없는 종교 포교, 정치적 선동, 다단계 판매 행위 금지</li>
              <li>회사는 모임 중 발생한 부적절한 행위에 대해 신고 시스템을 운영하며, 사실 확인 시 파트너 정산 보류 및 민형사상 조치에 협조할 수 있습니다.</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제4조 (회원의 금지 행위 및 직거래 방지)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>타인의 개인정보 도용 및 허위 자격 인증 정보 등록 시 즉시 이용 정지됩니다.</li>
              <li><span className="font-bold underline text-gray-900">회사가 제공하는 결제 시스템을 이용하지 않고 직접 송금을 유도하거나 요구하는 행위(직거래)는 엄격히 금지됩니다.</span> 위반 시 파트너는 서비스 이용이 영구 제한되며, 발생한 피해에 대해 회사는 책임지지 않습니다.</li>
            </ul>
          </div>
          <div>
            {/* Fix #1450: 약관 변경 고지 절차 추가 (약관규제법 제3조, 전자상거래법 제21조의2) */}
            <h3 className="font-bold mb-3 text-gray-900 text-base">제5조 (약관의 게시 및 변경)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>본 약관의 내용은 서비스 화면에 게시하거나 기타 방법으로 회원에게 공지합니다.</li>
              <li>회사는 약관을 변경할 경우 적용일 <strong>7일 전</strong>부터 변경 내용을 서비스 내 공지합니다. 다만, 회원에게 불리한 변경인 경우 <strong>30일 전</strong>부터 공지하며, 이메일 또는 앱 내 알림으로 개별 통지합니다.</li>
              <li>회원이 변경된 약관의 적용일 이후에도 서비스를 계속 이용하는 경우 변경된 약관에 동의한 것으로 봅니다. 변경된 약관에 동의하지 않는 회원은 서비스 이용을 중단하고 회원 탈퇴할 수 있습니다.</li>
            </ul>
          </div>

          <div>
            {/* Fix #1450: 손해배상 조항 추가 (약관규제법 제7조) */}
            <h3 className="font-bold mb-3 text-gray-900 text-base">제6조 (손해배상)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>회사는 회사의 귀책사유로 인해 회원에게 손해가 발생한 경우 그 손해를 배상할 책임이 있습니다.</li>
              <li>회사는 무료로 제공하는 서비스의 이용과 관련하여 회원에게 발생한 손해에 대해서는 고의 또는 중과실이 있는 경우를 제외하고 책임을 부담하지 않습니다.</li>
              <li>회사는 천재지변, 전쟁, 기간통신사업자의 서비스 중지 등 불가항력적인 사유로 서비스를 제공할 수 없는 경우에는 책임을 부담하지 않습니다.</li>
              <li>회원이 본 약관의 규정을 위반하여 회사에 손해가 발생한 경우 해당 회원은 회사에 그 손해를 배상하여야 합니다.</li>
            </ul>
          </div>

          <div>
            {/* Fix #1450: 분쟁해결 절차 추가 (약관규제법 제14조, 전자상거래법 제33조) */}
            <h3 className="font-bold mb-3 text-gray-900 text-base">제7조 (분쟁해결)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>본 약관과 관련하여 분쟁이 발생한 경우, 회사와 회원은 원만한 해결을 위해 성실히 협의합니다.</li>
              <li>전항의 협의로 해결되지 않은 경우, 회원은 한국소비자원 또는 전자거래분쟁조정위원회 등 관련 분쟁조정기관에 조정을 신청할 수 있습니다.</li>
              <li>소송이 필요한 경우 민사소송법에 따른 관할법원을 전속적 합의관할로 합니다.</li>
            </ul>
          </div>

          <div>
            {/* Fix #1450: 서비스 변경/중단 고지 의무 추가 (전자상거래법 제13조) */}
            <h3 className="font-bold mb-3 text-gray-900 text-base">제8조 (서비스 변경 및 중단)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>회사는 상당한 이유가 있는 경우 서비스의 전부 또는 일부를 변경할 수 있으며, 변경 시 사전에 공지합니다.</li>
              <li>회사가 서비스를 종료하고자 하는 경우 종료일 <strong>30일 전</strong>까지 서비스 내 공지 및 이메일 등으로 회원에게 알립니다.</li>
              <li>서비스 종료 시 미사용 결제 대금은 전액 환불합니다.</li>
            </ul>
          </div>

          <div>
            {/* Fix #1450: 지적재산권 조항 추가 */}
            <h3 className="font-bold mb-3 text-gray-900 text-base">제9조 (지적재산권)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>서비스에 대한 저작권 및 지적재산권은 회사에 귀속됩니다.</li>
              <li>회원이 서비스 내에 게시한 콘텐츠(후기, 프로필 사진 등)의 저작권은 해당 회원에게 있습니다.</li>
              <li>회사는 서비스 운영, 홍보 목적으로 회원의 게시물을 사용할 수 있으며, 이 경우 개인정보보호법에 따라 개인을 식별할 수 없도록 처리합니다.</li>
            </ul>
          </div>

          <div>
            {/* Fix #1450: 준거법 및 재판관할 추가 */}
            <h3 className="font-bold mb-3 text-gray-900 text-base">제10조 (준거법 및 재판관할)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>본 약관의 해석 및 분쟁에 관하여는 대한민국 법령을 적용합니다.</li>
            </ul>
          </div>
        </div>
      </section>

      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          2. 취소 및 환불 규정
        </h2>
        
        <div className="bg-gray-50 border-l-4 border-gray-300 p-4 mb-6 rounded-r-xl">
          <p className="text-sm font-bold text-gray-900">
            본 규정은 전자상거래법 등 관계 법령을 준수하며 모임의 특수성(사전 준비 등)을 고려하여 작성되었습니다.
          </p>
        </div>

        <div className="space-y-6">
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제1조 (참여자의 취소 및 환불)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>결제 후 2시간 이내: 전액 환불</li>
              <li>이벤트 시작 7일 전까지: 전액 환불</li>
              <li>그 외: 고객센터(support@minglit.com)로 문의</li>
            </ul>
          </div>

          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">제2조 (파트너의 귀책에 따른 처리)</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>파트너의 자격 확인 후 승인 거절 시: <span className="font-bold text-gray-900">전액 환불</span></li>
              <li>파트너의 단순 변심이나 부주의로 인한 모임 취소 시: <span className="font-bold text-gray-900">전액 환불</span> 및 파트너 페널티 부여</li>
              <li><strong>정산 보류:</strong> 파트너가 허위로 참여 인증을 하거나, 모임 개최 장소에서의 정상적인 서비스 이행이 확인되지 않은 경우 회사는 정산 대금을 보류할 수 있습니다.</li>
            </ul>
          </div>
        </div>
      </section>

      <footer className="mt-20 pt-10 border-t border-gray-100 bg-gray-50 p-8 rounded-2xl">
        <ul className="space-y-2 text-sm text-gray-600">
          <li><span className="font-bold text-gray-900 w-32 inline-block">상호</span> 밍글릿</li>
          <li><span className="font-bold text-gray-900 w-32 inline-block">대표자</span> 윤민혁</li>
          <li><span className="font-bold text-gray-900 w-32 inline-block">사업자등록번호</span> 747-53-00880</li>
        </ul>
        <p className="mt-8 text-xs text-gray-400">© 2026 Minglit. All rights reserved.</p>
      </footer>
    </div>
  );
}