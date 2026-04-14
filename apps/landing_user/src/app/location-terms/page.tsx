import React from 'react';

export default function LocationTermsPage() {
  return (
    <div className="max-w-3xl mx-auto px-6 py-12 text-gray-800 font-sans">
      <h1 className="text-3xl font-bold text-gray-900 mb-8 pb-4 border-b-2 border-gray-900 text-center">
        위치정보 이용약관
      </h1>

      <p className="text-sm leading-relaxed mb-8 bg-gray-50 p-4 rounded-xl border border-gray-100">
        <strong>밍글릿(Minglit)</strong>(이하 &apos;회사&apos;)은 위치정보의 보호 및 이용 등에 관한 법률(이하 &apos;위치정보법&apos;)에 따라 이용자의 개인위치정보를 보호하고, 위치기반서비스를 안전하게 제공하기 위해 본 약관을 제정합니다.
      </p>

      {/* 제1조 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          제1조 (목적)
        </h2>
        <p className="text-sm text-gray-600 leading-relaxed">
          본 약관은 회사가 제공하는 위치기반서비스(이하 &apos;서비스&apos;)의 이용과 관련하여 회사와 이용자 간의 권리·의무 및 기타 필요한 사항을 규정함을 목적으로 합니다.
        </p>
      </section>

      {/* 제2조 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          제2조 (서비스 내용 및 요금)
        </h2>
        <div className="space-y-6">
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">1) 서비스 내용</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>이용자의 현재 위치를 기반으로 가까운 이벤트를 검색하고 추천하는 서비스</li>
              <li>이벤트 장소까지의 거리 정보를 제공하는 서비스</li>
            </ul>
          </div>
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">2) 이용 요금</h3>
            <p className="text-sm text-gray-600">
              위치기반서비스는 <strong>무료</strong>로 제공됩니다.
            </p>
          </div>
        </div>
      </section>

      {/* 제3조 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          제3조 (개인위치정보의 수집 방법 및 이용 범위)
        </h2>
        <div className="space-y-6">
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">1) 수집 방법</h3>
            <p className="text-sm text-gray-600">
              GPS, Wi-Fi, 기지국 정보를 통해 이용자 단말기의 위치를 수집합니다.
            </p>
          </div>
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">2) 수집 시점</h3>
            <p className="text-sm text-gray-600">
              앱 사용 중(foreground) 상태에서만 위치정보를 수집합니다. 백그라운드에서는 수집하지 않습니다.
            </p>
          </div>
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">3) 이용 범위</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>가까운 이벤트 검색 및 추천</li>
              <li>이벤트 목록 거리순 정렬</li>
              <li>이벤트 장소까지의 거리 안내</li>
            </ul>
          </div>
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">4) 보유 및 파기</h3>
            <p className="text-sm text-gray-600">
              개인위치정보는 별도로 저장하지 않으며, 서비스 제공 목적 달성 후 즉시 파기합니다.
            </p>
          </div>
        </div>
      </section>

      {/* 제4조 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          제4조 (이용약관 변경 절차)
        </h2>
        <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
          <li>회사는 본 약관을 변경하는 경우 시행 <strong>7일 전</strong>에 앱 내 공지사항을 통해 고지합니다.</li>
          <li>이용자에게 불이익이 발생하는 변경의 경우 시행 <strong>30일 전</strong>에 이메일 등 개별 통지를 합니다.</li>
          <li>변경된 약관의 시행일 이후에도 서비스를 계속 이용하는 경우, 변경된 약관에 동의한 것으로 간주합니다.</li>
        </ul>
      </section>

      {/* 제5조 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          제5조 (서비스 제한 및 중지 사유)
        </h2>
        <div className="space-y-6">
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">1) 제한 및 중지 사유</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
              <li>시스템 점검, 네트워크 장애, 천재지변 등 불가항력적인 사유</li>
              <li>기술적 사유로 인해 서비스의 정상적인 제공이 불가능한 경우</li>
            </ul>
          </div>
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">2) 공지 방법</h3>
            <p className="text-sm text-gray-600">
              서비스 제한 또는 중지 시 사전에 앱 내 공지사항을 통해 공지합니다. 단, 긴급한 경우에는 사후에 공지할 수 있습니다.
            </p>
          </div>
        </div>
      </section>

      {/* 제6조 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          제6조 (개인위치정보주체의 권리)
        </h2>
        <p className="text-sm text-gray-600 mb-4">
          이용자(개인위치정보주체)는 위치정보법 제24조에 따라 아래 권리를 행사할 수 있습니다.
        </p>
        <div className="space-y-6">
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">1) 동의 철회</h3>
            <p className="text-sm text-gray-600">
              앱 설정 &gt; 개인정보 메뉴에서 언제든지 위치정보 수집·이용에 대한 동의를 철회할 수 있습니다.
            </p>
          </div>
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">2) 열람 및 정정</h3>
            <p className="text-sm text-gray-600">
              수집된 위치정보에 대한 열람 및 정정을 요구할 수 있습니다.
            </p>
          </div>
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">3) 일시중지</h3>
            <p className="text-sm text-gray-600">
              위치정보 수집의 일시중지를 요구할 수 있습니다.
            </p>
          </div>
          <div>
            <h3 className="font-bold mb-3 text-gray-900 text-base">4) 이용·제공 내역 열람</h3>
            <p className="text-sm text-gray-600">
              위치정보 이용·제공 사실 확인자료의 열람을 요구할 수 있으며, 회사는 열람 요청 시 <strong>10일 이내</strong>에 조치합니다.
            </p>
          </div>
          <div className="bg-gray-50 border-l-4 border-gray-300 p-4 rounded-r-xl">
            <h3 className="font-bold mb-2 text-gray-900 text-base">권리 행사 방법</h3>
            <ul className="list-disc pl-5 space-y-1 text-sm text-gray-600">
              <li>이메일: <strong>support@minglit.com</strong></li>
              <li>앱 내 문의 기능을 통해 요청</li>
            </ul>
          </div>
        </div>
      </section>

      {/* 제7조 */}
      <section className="mb-12">
        <h2 className="text-xl font-bold text-gray-900 mb-6 flex items-center">
          <span className="w-1 h-5 bg-gray-400 mr-3 rounded-full" />
          제7조 (손해배상)
        </h2>
        <ul className="list-disc pl-5 space-y-2 text-sm text-gray-600">
          <li>회사의 고의 또는 과실로 인하여 이용자에게 손해가 발생한 경우, 회사는 관련 법령에 따라 그 손해를 배상합니다.</li>
          <li>이용자의 고의 또는 과실로 인하여 발생한 손해에 대해서는 회사가 책임을 지지 않습니다.</li>
        </ul>
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
