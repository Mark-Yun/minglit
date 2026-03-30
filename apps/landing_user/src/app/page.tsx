'use client';

import React, { useState } from 'react';
import {
  CheckCircle2,
  Search,
  ShieldCheck,
  MapPin,
  Zap,
  ArrowRight,
} from 'lucide-react';

/**
 * Minglit Logo Component (v2.12 design)
 */
const MinglitLogo = ({ size = 'md' }: { size?: 'sm' | 'md' | 'lg' }) => {
  const sizeMap = {
    sm: { symbol: 'w-8 h-8 text-lg', text: 'text-xl' },
    md: { symbol: 'w-10 h-10 text-2xl', text: 'text-3xl' },
    lg: { symbol: 'w-16 h-16 text-4xl', text: 'text-5xl' },
  };
  const currentSize = sizeMap[size];

  return (
    <div className="flex items-center gap-3 select-none group cursor-pointer">
      <div className={`${currentSize.symbol} rounded-lg flex items-center justify-center relative overflow-hidden bg-gradient-to-br from-[#4F3CFF] to-[#9900ff] shadow-lg group-hover:rotate-6 transition-transform`}>
        <div className="absolute inset-0 bg-white/10 opacity-20" />
        <span 
          className="font-racing text-white relative z-10 -mt-[3px] -ml-[3px]"
          style={{ textShadow: '2px 2px 0px #21fffe, 3px 3px 0px #ff9900' }}
        >
          M
        </span>
      </div>
      <span className={`font-racing ${currentSize.text} text-[#9900ff] tracking-wide`}>
        Minglit
      </span>
    </div>
  );
};

export default function LandingUserPage() {
  const [email, setEmail] = useState('');
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      setIsSubmitted(true);
    }, 1500);
  };

  return (
    <div className="min-h-screen bg-white text-slate-900 font-pretendard selection:bg-accent selection:text-primary overflow-x-hidden">
      {/* Glow Effects */}
      <div className="fixed top-[-10%] left-[-10%] w-[600px] h-[600px] bg-accent/15 rounded-full blur-[130px] -z-10 animate-pulse-slow" />
      <div className="fixed bottom-[-10%] right-[-10%] w-[600px] h-[600px] bg-primary/10 rounded-full blur-[130px] -z-10 animate-pulse-slow delay-1000" />

      {/* Navigation */}
      <nav className="fixed top-0 w-full z-50 bg-white/90 backdrop-blur-md border-b border-[#21fffe]/30">
        <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          <MinglitLogo size="md" />
          <div className="hidden md:block text-sm font-bold text-primary/90 font-racing tracking-wider uppercase">
            Verified Vibe, Spark Your Moment
          </div>
        </div>
      </nav>

      <main className="pt-32 pb-20">
        {/* Hero Section */}
        <section className="max-w-7xl mx-auto px-6 text-center">
          <div className="inline-flex items-center gap-2 px-5 py-2 rounded-full border-2 border-secondary text-secondary text-sm font-bold mb-8 bg-white shadow-[2px_2px_0px_0px_#FF9900] animate-bounce-slow">
            <Zap size={18} className="fill-secondary" />
            <span className="font-racing tracking-wide uppercase">Coming Soon 2026</span>
          </div>

          <h1 className="text-6xl md:text-9xl font-racing text-slate-900 mb-8 leading-none tracking-tight">
            NO FAKE,<br />
            <span className="bg-clip-text text-transparent bg-gradient-to-r from-primary via-secondary to-primary bg-[length:200%_auto] animate-gradient">
              JUST MINGLE.
            </span>
          </h1>

          <p className="text-xl md:text-2xl text-slate-600 max-w-2xl mx-auto mb-12 leading-relaxed font-semibold">
            광고와 허위 정보에 지친 당신을 위한<br />
            <span className="text-primary font-bold decoration-accent decoration-4 underline underline-offset-4">진짜 사람들의 검증된 커뮤니티</span>
          </p>

          {/* Form */}
          <div className="max-w-lg mx-auto relative z-10">
            {!isSubmitted ? (
              <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                <div className="relative group">
                  <div className="absolute -inset-1 bg-gradient-to-r from-primary via-secondary to-accent rounded-2xl blur-md opacity-30 group-hover:opacity-60 transition duration-300 animate-gradient bg-[length:200%_auto]"></div>
                  <div className="relative flex flex-col md:flex-row gap-3 p-2 bg-white rounded-2xl border-2 border-accent/50 shadow-xl">
                    <input
                      type="email"
                      placeholder="이메일을 입력하고 초대장을 받으세요"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="flex-1 px-4 py-4 outline-none text-slate-900 font-medium placeholder:text-slate-400"
                    />
                    <button
                      disabled={loading}
                      className="bg-primary text-white px-8 py-4 rounded-xl font-racing text-xl tracking-wide hover:bg-[#7a00cc] transition-all flex items-center justify-center gap-2 shadow-xl hover:shadow-2xl active:translate-y-0.5 border-2 border-primary relative overflow-hidden group/btn"
                    >
                      <span className="relative z-10 flex items-center gap-2">
                        {loading ? 'SENDING...' : 'JOIN WAITLIST'}{' '}
                        {loading ? null : <ArrowRight size={20} />}
                      </span>
                    </button>
                  </div>
                </div>
                <p className="text-sm text-slate-500 font-medium">
                  🔥 현재 <span className="text-secondary font-bold">2,401명</span>이 대기 중입니다.
                </p>
              </form>
            ) : (
              <div className="bg-accent/10 p-8 rounded-3xl border-2 border-accent text-center animate-in zoom-in duration-300 relative overflow-hidden">
                <div className="w-20 h-20 bg-gradient-to-br from-primary to-accent rounded-full flex items-center justify-center text-white mx-auto mb-4 border-4 border-white shadow-[0_0_20px_#21fffe] relative z-10">
                  <CheckCircle2 size={40} />
                </div>
                <h3 className="text-3xl font-racing text-primary mb-2">YOU ARE IN!</h3>
                <p className="text-slate-700 font-medium">가장 먼저 VVIP 초대장을 보내드릴게요.</p>
              </div>
            )}
          </div>
        </section>

        {/* Bento Grid */}
        <section className="max-w-7xl mx-auto px-6 mt-32">
          <div className="grid md:grid-cols-3 gap-6">
            {/* CURATION */}
            <div className="p-8 rounded-[2rem] bg-white border-2 border-accent/30 hover:border-primary transition-all group shadow-lg hover:shadow-[0_10px_30px_-10px_rgba(153,0,255,0.3)] hover:-translate-y-1">
              <div className="w-14 h-14 bg-primary/10 rounded-2xl flex items-center justify-center text-primary mb-6 group-hover:scale-110 group-hover:bg-primary group-hover:text-accent transition-all">
                <Search size={28} />
              </div>
              <h3 className="text-2xl font-racing text-primary mb-3 uppercase">Curation</h3>
              <p className="text-slate-600 font-medium leading-relaxed">
                흩어져 있는 수많은 모임 중,<br/>
                <span className="bg-accent/30 px-1 font-bold text-primary">밍글릿 기준</span>에 맞는 진짜만 모았습니다.
              </p>
            </div>

            {/* VERIFIED */}
            <div className="p-8 rounded-[2rem] bg-gradient-to-br from-primary to-[#7a00cc] text-white border-2 border-primary shadow-2xl hover:translate-y-[-4px] transition-all relative overflow-hidden group">
              <div className="absolute -top-20 -right-20 w-60 h-60 bg-secondary/40 rounded-full blur-[80px]" />
              <div className="w-14 h-14 bg-white/20 backdrop-blur-md rounded-2xl flex items-center justify-center text-accent mb-6 relative z-10 border border-white/30 group-hover:scale-110 transition-transform">
                <ShieldCheck size={28} />
              </div>
              <h3 className="text-2xl font-racing text-accent mb-3 relative z-10 uppercase">Verified</h3>
              <p className="opacity-90 font-medium leading-relaxed relative z-10">
                명함, 재직증명서, 신분증.<br/>
                확실한 <span className="text-secondary font-extrabold text-shadow-sm">신원 인증</span> 없이는 입장 불가.
              </p>
            </div>

            {/* LOCAL & REAL */}
            <div className="p-8 rounded-[2rem] bg-white border-2 border-accent/30 hover:border-accent transition-all group shadow-lg hover:shadow-[0_10px_30px_-10px_rgba(33,255,254,0.3)] hover:-translate-y-1">
              <div className="w-14 h-14 bg-accent/10 rounded-2xl flex items-center justify-center text-[#008c8c] mb-6 group-hover:scale-110 group-hover:bg-accent group-hover:text-white transition-all">
                <MapPin size={28} />
              </div>
              <h3 className="text-2xl font-racing text-[#4F3CFF] mb-3 uppercase">Local & Real</h3>
              <p className="text-slate-600 font-medium leading-relaxed">
                GPS와 QR 체크인으로 증명된<br/>
                <span className="bg-secondary/20 px-1 font-bold text-[#FF00E5]">현장 기반</span>의 안전한 만남.
              </p>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="max-w-7xl mx-auto px-6 mt-32 pt-10 border-t-2 border-accent/20 flex flex-col md:flex-row justify-between items-center gap-6 opacity-60">
          <MinglitLogo size="sm" />
          <div className="text-xs font-bold text-slate-400 uppercase tracking-widest">
            © 2026 Minglit. All rights reserved.
          </div>
        </footer>
      </main>
    </div>
  );
}