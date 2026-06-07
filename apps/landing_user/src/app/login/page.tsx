import Link from "next/link";

type LoginPageProps = {
  searchParams: Promise<{ next?: string }>;
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const { next } = await searchParams;
  const returnTo = normalizeReturnPath(next);

  return (
    <main className="web-login-intent">
      <section className="web-login-intent__panel" aria-labelledby="login-title">
        <div className="minglit-logo web-login-intent__logo" aria-hidden="true">
          <span className="minglit-logo__mark">M</span>
          <span className="minglit-logo__text">Minglit</span>
        </div>
        <h1 id="login-title">로그인이 필요해요</h1>
        <p>신청과 결제는 로그인 후 이어갈 수 있습니다. 보던 이벤트로 돌아가 정보를 계속 확인할 수 있어요.</p>
        <div className="web-login-intent__actions">
          <Link className="web-login-intent__primary" href={returnTo}>
            보던 이벤트로 돌아가기
          </Link>
          <Link className="web-login-intent__secondary" href="/">
            이벤트 둘러보기
          </Link>
        </div>
      </section>
    </main>
  );
}

function normalizeReturnPath(value?: string): string {
  if (!value || !value.startsWith("/") || value.startsWith("//")) return "/";

  return value;
}
