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